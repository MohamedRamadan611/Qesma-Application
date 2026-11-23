import 'dart:convert';
import 'dart:typed_data';

import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';
import '../db/name_key.dart';
import 'backup_format.dart';

/// Reads and checks a backup file entirely in memory, before the importer touches the database (STANDALONE_SPEC 6.2).
/// Pure: no I/O, no logging. Every failure is a [BackupException] with a path and never a value from the file.
///
/// Order: size -> JSON -> versions -> caps -> strict typed rows -> referential integrity -> recompute check.
abstract final class BackupValidator {
  /// The newest database schema this app writes (`LocalDatabase.schemaVersion`); older files are accepted: schema 3 added
  /// expense category (optional on import, defaults to OTHER), 4 added the reminder tone, a preference the backup does not carry,
  /// and 5 the pool (treasurer_member_id, paid_from_pool, kind: optional on import, default none / 0 / PAYMENT); 6 added
  /// saved fuel prices, a device setting the backup does not carry (A168), and 7 the receipt-scan consent and counters,
  /// device state the backup does not carry either (SA12). 8 (SA15) added itemized v2: item quantity / unit price,
  /// the bill discount and amount-form service/tax; all optional on import (quantity 1, unit = amount, discount 0 on
  /// itemized rows, no amount forms), and checked against the V21 rules before anything is written. 9 (A180) added
  /// the itemized delivery (expenses.delivery_minor and the per-member part): optional on import, 0 on itemized
  /// rows, and checked against the V22 rules (it is part of the total and of each member's owed amount).
  /// 11 (A184) added expense_groups.archived_at (optional on import, null = active); the archive retention is a device setting.
  /// 10 widened the InstaPay handle to also allow an https://ipn.eg/ link: no new field, so older files import as they are.
  /// 12 (SA18, Java V23) added SHARES (expenses.period_from/to, expense_splits.share_units/present_from/present_to), the
  /// member default weight and the group budget and trip dates: all optional on import (absent = NULL), and a SHARES
  /// expense is checked against the V23 rules and recomputed by the engine before anything is written.
  static const int currentSchemaVersion = 12;

  static BackupData parse(Uint8List bytes, {int maxBytes = maxBackupBytes}) {
    if (bytes.isEmpty) throw const BackupException(BackupError.unreadable);
    if (bytes.length > maxBytes) throw const BackupException(BackupError.tooLarge);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupException(BackupError.unreadable);
    }
    if (decoded is! Map<String, dynamic>) throw const BackupException(BackupError.unreadable);
    return fromJson(decoded);
  }

  static BackupData fromJson(Map<String, dynamic> json) {
    final top = _Reader(json, '');
    final format = top.integer('formatVersion', min: 1, max: 1 << 31, error: BackupError.invalid);
    if (format > backupFormatVersion) throw const BackupException(BackupError.newerFormat, 'formatVersion');
    final schema = top.integer('schemaVersion', min: 1, max: 1 << 31);
    if (schema > currentSchemaVersion) throw const BackupException(BackupError.newerFormat, 'schemaVersion');
    final exportedAt = top.integer('exportedAt', min: 0, max: _maxTimestamp);
    final appVersion = top.string('appVersion', min: 1, max: 40);

    final rawGroups = top.list('groups');
    final rawExpenses = top.list('expenses');
    final rawMembers = top.list('members');
    final rawPayers = top.list('expense_payers');
    final rawSplits = top.list('expense_splits');
    final rawItems = top.list('expense_items');
    final rawAssignees = top.list('expense_item_assignees');
    final rawRevisions = top.list('expense_revisions');
    final rawSettlements = top.list('settlements');
    final rawHandles = top.list('payment_handles');
    if (rawGroups.length > maxBackupGroups || rawExpenses.length > maxBackupExpenses) {
      throw const BackupException(BackupError.tooLarge);
    }
    final rows = rawGroups.length +
        rawExpenses.length +
        rawMembers.length +
        rawPayers.length +
        rawSplits.length +
        rawItems.length +
        rawAssignees.length +
        rawRevisions.length +
        rawSettlements.length +
        rawHandles.length;
    if (rows > maxBackupRows) throw const BackupException(BackupError.tooLarge);

    final data = BackupData(
      formatVersion: format,
      schemaVersion: schema,
      exportedAt: exportedAt,
      appVersion: appVersion,
      profile: _profile(top.object('profile')),
      paymentHandles: _rows(rawHandles, 'payment_handles', _handle),
      groups: _rows(rawGroups, 'groups', _group),
      members: _rows(rawMembers, 'members', _member),
      expenses: _rows(rawExpenses, 'expenses', _expense),
      payers: _rows(rawPayers, 'expense_payers', _payer),
      splits: _rows(rawSplits, 'expense_splits', _split),
      items: _rows(rawItems, 'expense_items', _item),
      assignees: _rows(rawAssignees, 'expense_item_assignees', _assignee),
      revisions: _rows(rawRevisions, 'expense_revisions', _revision),
      settlements: _rows(rawSettlements, 'settlements', _settlement),
    );
    check(data);
    return data;
  }

  // ---------------------------------------------------------------------------------------------------------------
  // Strict row decoders: the types and limits of schema.drift (the database CHECKs stay the second line of defence).
  // ---------------------------------------------------------------------------------------------------------------

  static const int _maxTimestamp = 253402300799999; // 9999-12-31 in epoch ms
  static const Set<String> _groupTypes = {'TRIP', 'HOUSING', 'OUTING', 'OTHER'};
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static List<T> _rows<T>(List<Object?> raw, String table, T Function(_Reader r) decode) => [
        for (var i = 0; i < raw.length; i++) decode(_Reader(_asMap(raw[i], '$table[$i]'), '$table[$i]')),
      ];

  static Map<String, dynamic> _asMap(Object? value, String path) {
    if (value is! Map<String, dynamic>) throw BackupException(BackupError.invalid, path);
    return value;
  }

  static LocalProfileRow _profile(_Reader r) => LocalProfileRow(
        id: r.id('id'),
        displayName: r.string('display_name', min: 1, max: 60, trimmed: true),
        createdAt: r.timestamp('created_at'),
        updatedAt: r.timestamp('updated_at'),
        singleton: r.integer('singleton', min: 1, max: 1),
      );

  static PaymentHandleRow _handle(_Reader r) => PaymentHandleRow(
        id: r.id('id'),
        userId: r.id('user_id'),
        type: r.oneOf('type', const {'INSTAPAY', 'WALLET'}),
        value: r.string('value', min: 3, max: 60),
        createdAt: r.timestamp('created_at'),
        updatedAt: r.timestamp('updated_at'),
      );

  static GroupRow _group(_Reader r) => GroupRow(
        id: r.id('id'),
        ownerUserId: r.id('owner_user_id'),
        name: r.string('name', min: 1, max: 60, trimmed: true),
        type: r.oneOf('type', _groupTypes),
        currencyCode: r.currency('currency_code'),
        createdAt: r.timestamp('created_at'),
        updatedAt: r.timestamp('updated_at'),
        version: r.integer('version', min: 1, max: _maxCount),
        memberSeq: r.integer('member_seq', min: 0, max: _maxCount),
        treasurerMemberId: r.optId('treasurer_member_id'), // schema 5 (SA10); older files have none
        archivedAt: r.optTimestamp('archived_at'), // schema 11 (A184); older files have none
        // Schema 12 (A190): the trip budget settings; older files have none.
        budgetMinor: r.optInteger('budget_minor', min: 1, max: Limits.maxAmountMinor),
        tripStartDate: r.optDate('trip_start_date'),
        tripEndDate: r.optDate('trip_end_date'),
      );

  static const int _maxCount = 1 << 40;

  static MemberRow _member(_Reader r) => MemberRow(
        id: r.id('id'),
        groupId: r.id('group_id'),
        displayName: r.string('display_name', min: 1, max: 40, trimmed: true),
        nameKey: r.string('name_key', min: 1, max: 400),
        userId: r.optId('user_id'),
        sortOrder: r.integer('sort_order', min: 1, max: _maxCount),
        role: r.oneOf('role', const {'OWNER', 'ADMIN', 'MEMBER'}),
        status: r.oneOf('status', const {'ACTIVE', 'LEFT'}),
        joinedAt: r.optTimestamp('joined_at'),
        leftAt: r.optTimestamp('left_at'),
        createdAt: r.timestamp('created_at'),
        // Schema 12 (A188): the SHARES prefill; older files have none.
        defaultShareUnits: r.optInteger('default_share_units', min: Limits.minShareUnits, max: Limits.maxShareUnits),
      );

  static ExpenseRow _expense(_Reader r) {
    final splitType = r.oneOf('split_type', const {'EQUAL', 'EXACT', 'ITEMIZED', 'SHARES'});
    return ExpenseRow(
        id: r.id('id'),
        groupId: r.id('group_id'),
        title: r.string('title', min: 1, max: 100, trimmed: true),
        splitType: splitType,
        // Schema 8 (SA15): before it no discount existed, so an ITEMIZED row's discount total is 0.
        discountBps: r.optInteger('discount_bps', min: 1, max: ItemizedCalculator.maxDiscountBps),
        discountAmountMinor: r.optInteger('discount_amount_minor', min: 1, max: Limits.maxAmountMinor),
        discountMinor: r.optInteger('discount_minor', min: 0, max: Limits.maxAmountMinor) ??
            (splitType == 'ITEMIZED' ? 0 : null),
        // Schema 9 (A180): before it no delivery existed, so an ITEMIZED row's delivery is 0.
        deliveryMinor: r.optInteger('delivery_minor', min: 0, max: Limits.maxAmountMinor) ??
            (splitType == 'ITEMIZED' ? 0 : null),
        serviceAmountMinor: r.optInteger('service_amount_minor', min: 1, max: Limits.maxAmountMinor),
        taxAmountMinor: r.optInteger('tax_amount_minor', min: 1, max: Limits.maxAmountMinor),
        totalMinor: r.amount('total_minor'),
        expenseDate: r.date('expense_date'),
        subtotalMinor: r.optInteger('subtotal_minor', min: 0, max: Limits.maxAmountMinor),
        serviceBps: r.optInteger('service_bps', min: 0, max: 10000),
        serviceMinor: r.optInteger('service_minor', min: 0, max: Limits.maxAmountMinor),
        taxBps: r.optInteger('tax_bps', min: 0, max: 10000),
        taxMinor: r.optInteger('tax_minor', min: 0, max: Limits.maxAmountMinor),
        taxBase: r.optOneOf('tax_base', const {'SUBTOTAL', 'SUBTOTAL_PLUS_SERVICE'}),
        adjustmentMinor: r.optInteger('adjustment_minor', min: -Limits.maxAmountMinor, max: Limits.maxAmountMinor),
        createdByUserId: r.id('created_by_user_id'),
        createdAt: r.timestamp('created_at'),
        updatedAt: r.timestamp('updated_at'),
        deletedAt: r.optTimestamp('deleted_at'),
        version: r.integer('version', min: 1, max: _maxCount),
        category: r.optOneOf('category', const {
              'FOOD', 'TRANSPORT', 'FUEL', 'ACCOMMODATION', 'GROCERIES', 'SHOPPING', 'ENTERTAINMENT', 'BILLS', 'OTHER'
            }) ??
            'OTHER',
        paidFromPool: r.optInteger('paid_from_pool', min: 0, max: 1) ?? 0, // schema 5 (SA10)
        periodFrom: r.optDate('period_from'), // schema 12 (SA18)
        periodTo: r.optDate('period_to'),
      );
  }

  static PayerRow _payer(_Reader r) =>
      PayerRow(expenseId: r.id('expense_id'), memberId: r.id('member_id'), amountMinor: r.amount('amount_minor'));

  static SplitRow _split(_Reader r) {
    final itemsMinor = r.optInteger('items_minor', min: 0, max: Limits.maxAmountMinor);
    return SplitRow(
      expenseId: r.id('expense_id'),
      memberId: r.id('member_id'),
      owedMinor: r.integer('owed_minor', min: 0, max: Limits.maxAmountMinor),
      itemsMinor: itemsMinor,
      serviceMinor: r.optInteger('service_minor', min: 0, max: Limits.maxAmountMinor),
      taxMinor: r.optInteger('tax_minor', min: 0, max: Limits.maxAmountMinor),
      adjustmentMinor: r.optInteger('adjustment_minor', min: -Limits.maxAmountMinor, max: Limits.maxAmountMinor),
      // Schema 8 (SA15): an itemized breakdown row without it had no discount.
      discountMinor:
          r.optInteger('discount_minor', min: 0, max: Limits.maxAmountMinor) ?? (itemsMinor == null ? null : 0),
      // Schema 9 (A180): an itemized breakdown row without it had no delivery.
      deliveryMinor:
          r.optInteger('delivery_minor', min: 0, max: Limits.maxAmountMinor) ?? (itemsMinor == null ? null : 0),
      // Schema 12 (SA18): SHARES units and normalized presence.
      shareUnits: r.optInteger('share_units', min: Limits.minShareUnits, max: Limits.maxShareUnits),
      presentFrom: r.optDate('present_from'),
      presentTo: r.optDate('present_to'),
    );
  }

  static ItemRow _item(_Reader r) {
    final amountMinor = r.amount('amount_minor');
    return ItemRow(
      id: r.id('id'),
      expenseId: r.id('expense_id'),
      name: r.string('name', min: 1, max: 100, trimmed: true),
      amountMinor: amountMinor,
      sortOrder: r.integer('sort_order', min: 0, max: _maxCount),
      // Schema 8 (SA15): a line before it is 1 x its amount.
      quantity: r.optInteger('quantity', min: Item.minQuantity, max: Item.maxQuantity) ?? 1,
      unitAmountMinor: r.optInteger('unit_amount_minor', min: 1, max: Limits.maxAmountMinor) ?? amountMinor,
    );
  }

  static AssigneeRow _assignee(_Reader r) => AssigneeRow(itemId: r.id('item_id'), memberId: r.id('member_id'));

  static RevisionRow _revision(_Reader r) {
    final snapshot = r.string('snapshot', min: 2, max: 1 << 22);
    try {
      if (jsonDecode(snapshot) is! Map<String, dynamic>) throw const FormatException();
    } on FormatException {
      throw BackupException(BackupError.invalid, '${r.path}.snapshot');
    }
    return RevisionRow(
      id: r.id('id'),
      expenseId: r.id('expense_id'),
      version: r.integer('version', min: 1, max: _maxCount),
      changeType: r.oneOf('change_type', const {'CREATE', 'UPDATE', 'DELETE'}),
      snapshot: snapshot,
      changedByUserId: r.id('changed_by_user_id'),
      changedAt: r.timestamp('changed_at'),
    );
  }

  static SettlementRow _settlement(_Reader r) {
    final note = r.optString('note', min: 1, max: 200, trimmed: true);
    return SettlementRow(
      id: r.id('id'),
      groupId: r.id('group_id'),
      fromMemberId: r.id('from_member_id'),
      toMemberId: r.id('to_member_id'),
      amountMinor: r.amount('amount_minor'),
      settledOn: r.date('settled_on'),
      note: note,
      createdByUserId: r.id('created_by_user_id'),
      createdByMemberId: r.optId('created_by_member_id'),
      createdAt: r.timestamp('created_at'),
      status: r.oneOf('status', const {'PENDING', 'CONFIRMED', 'DISPUTED', 'CANCELLED'}),
      declaredAt: r.timestamp('declared_at'),
      confirmedAt: r.optTimestamp('confirmed_at'),
      disputedAt: r.optTimestamp('disputed_at'),
      cancelledAt: r.optTimestamp('cancelled_at'),
      recordedByAdmin: r.integer('recorded_by_admin', min: 0, max: 1),
      kind: r.optOneOf('kind', const {'PAYMENT', 'POOL_DEPOSIT'}) ?? 'PAYMENT', // schema 5 (SA10)
    );
  }

  // ---------------------------------------------------------------------------------------------------------------
  // Referential integrity and the recompute check.
  // ---------------------------------------------------------------------------------------------------------------

  /// Throws [BackupException] unless [data] is a self-consistent ledger. Public so the importer can re-check a
  /// [BackupData] built by tests; [fromJson] always runs it.
  static void check(BackupData data) {
    final profileId = data.profile.id;

    final groupIds = _unique(data.groups.map((g) => g.id), 'groups');
    for (var i = 0; i < data.groups.length; i++) {
      if (data.groups[i].ownerUserId != profileId) throw BackupException(BackupError.invalid, 'groups[$i].owner_user_id');
    }
    for (var i = 0; i < data.paymentHandles.length; i++) {
      if (data.paymentHandles[i].userId != profileId) {
        throw BackupException(BackupError.invalid, 'payment_handles[$i].user_id');
      }
    }
    _unique(data.paymentHandles.map((h) => h.id), 'payment_handles');
    _unique(data.paymentHandles.map((h) => h.type), 'payment_handles.type');

    // Members: group, link, one OWNER per group, sortOrder and name key unique inside the group.
    final memberGroup = <String, String>{};
    final owners = <String, int>{};
    final sortOrders = <String>{};
    final nameKeys = <String>{};
    for (var i = 0; i < data.members.length; i++) {
      final m = data.members[i];
      final at = 'members[$i]';
      if (memberGroup.containsKey(m.id)) throw BackupException(BackupError.invalid, '$at.id');
      memberGroup[m.id] = m.groupId;
      if (!groupIds.contains(m.groupId)) throw BackupException(BackupError.invalid, '$at.group_id');
      if (m.userId != null && m.userId != profileId) throw BackupException(BackupError.invalid, '$at.user_id');
      if (!sortOrders.add('${m.groupId}/${m.sortOrder}')) throw BackupException(BackupError.invalid, '$at.sort_order');
      if (m.nameKey != memberNameKey(m.displayName) || !nameKeys.add('${m.groupId}/${m.nameKey}')) {
        throw BackupException(BackupError.invalid, '$at.name_key');
      }
      if ((m.status == 'LEFT') != (m.leftAt != null)) throw BackupException(BackupError.invalid, '$at.left_at');
      if (m.role == 'OWNER') {
        if (m.userId == null || m.status != 'ACTIVE') throw BackupException(BackupError.invalid, '$at.role');
        owners[m.groupId] = (owners[m.groupId] ?? 0) + 1;
      }
    }
    for (final id in groupIds) {
      if (owners[id] != 1) throw BackupException(BackupError.invalid, 'members.role');
    }
    // SA10: a treasurer is a member of the same group (the schema's same-group triggers).
    for (var i = 0; i < data.groups.length; i++) {
      final t = data.groups[i].treasurerMemberId;
      if (t != null && memberGroup[t] != data.groups[i].id) {
        throw BackupException(BackupError.invalid, 'groups[$i].treasurer_member_id');
      }
      // Schema 12 (A190): the trip end is not before the start when both are set.
      final start = data.groups[i].tripStartDate, end = data.groups[i].tripEndDate;
      if (start != null && end != null && end.compareTo(start) < 0) {
        throw BackupException(BackupError.invalid, 'groups[$i].trip_end_date');
      }
    }

    // Expenses and their children.
    final expenseGroup = <String, String>{};
    final expenseById = <String, ExpenseRow>{};
    for (var i = 0; i < data.expenses.length; i++) {
      final e = data.expenses[i];
      if (expenseById.containsKey(e.id)) throw BackupException(BackupError.invalid, 'expenses[$i].id');
      if (!groupIds.contains(e.groupId)) throw BackupException(BackupError.invalid, 'expenses[$i].group_id');
      if (e.createdByUserId != profileId) throw BackupException(BackupError.invalid, 'expenses[$i].created_by_user_id');
      expenseById[e.id] = e;
      expenseGroup[e.id] = e.groupId;
    }

    final payerSum = <String, int>{};
    final payerKeys = <String>{};
    for (var i = 0; i < data.payers.length; i++) {
      final p = data.payers[i];
      _requireMember(memberGroup, expenseGroup, p.expenseId, p.memberId, 'expense_payers[$i]');
      if (!payerKeys.add('${p.expenseId}/${p.memberId}')) throw BackupException(BackupError.invalid, 'expense_payers[$i]');
      payerSum[p.expenseId] = (payerSum[p.expenseId] ?? 0) + p.amountMinor;
    }
    final splitSum = <String, int>{};
    final splitKeys = <String>{};
    for (var i = 0; i < data.splits.length; i++) {
      final s = data.splits[i];
      final at = 'expense_splits[$i]';
      _requireMember(memberGroup, expenseGroup, s.expenseId, s.memberId, at);
      if (!splitKeys.add('${s.expenseId}/${s.memberId}')) throw BackupException(BackupError.invalid, at);
      splitSum[s.expenseId] = (splitSum[s.expenseId] ?? 0) + s.owedMinor;
      // The breakdown is all-or-nothing and explains owed exactly; the discount part never exceeds the items (V21).
      final parts = [s.itemsMinor, s.discountMinor, s.serviceMinor, s.taxMinor, s.adjustmentMinor, s.deliveryMinor];
      if (parts.any((p) => p != null)) {
        if (parts.any((p) => p == null) ||
            s.discountMinor! > s.itemsMinor! ||
            s.owedMinor !=
                s.itemsMinor! - s.discountMinor! + s.serviceMinor! + s.taxMinor! + s.deliveryMinor! + s.adjustmentMinor!) {
          throw BackupException(BackupError.inconsistent, '$at.owed_minor');
        }
      }
    }

    final itemExpense = <String, String>{};
    final itemOrders = <String>{};
    for (var i = 0; i < data.items.length; i++) {
      final it = data.items[i];
      if (itemExpense.containsKey(it.id)) throw BackupException(BackupError.invalid, 'expense_items[$i].id');
      if (!expenseGroup.containsKey(it.expenseId)) throw BackupException(BackupError.invalid, 'expense_items[$i]');
      if (!itemOrders.add('${it.expenseId}/${it.sortOrder}')) throw BackupException(BackupError.invalid, 'expense_items[$i]');
      // A172: the line is quantity x unit price (both already range-checked, so the product fits in 64 bits).
      if (it.amountMinor != it.quantity * it.unitAmountMinor) {
        throw BackupException(BackupError.invalid, 'expense_items[$i].amount_minor');
      }
      itemExpense[it.id] = it.expenseId;
    }
    final assigneeKeys = <String>{};
    for (var i = 0; i < data.assignees.length; i++) {
      final a = data.assignees[i];
      final expenseId = itemExpense[a.itemId];
      if (expenseId == null) throw BackupException(BackupError.invalid, 'expense_item_assignees[$i]');
      if (memberGroup[a.memberId] != expenseGroup[expenseId]) {
        throw BackupException(BackupError.invalid, 'expense_item_assignees[$i]');
      }
      if (!assigneeKeys.add('${a.itemId}/${a.memberId}')) throw BackupException(BackupError.invalid, 'expense_item_assignees[$i]');
    }

    for (var i = 0; i < data.expenses.length; i++) {
      final e = data.expenses[i];
      final at = 'expenses[$i]';
      // Recompute check: every expense's payers and shares add up to its total.
      if (payerSum[e.id] != e.totalMinor || splitSum[e.id] != e.totalMinor) {
        throw BackupException(BackupError.inconsistent, '$at.total_minor');
      }
      if (e.splitType == 'ITEMIZED') {
        final subtotal = e.subtotalMinor, discount = e.discountMinor, service = e.serviceMinor, tax = e.taxMinor;
        final adjustment = e.adjustmentMinor, delivery = e.deliveryMinor;
        if (subtotal == null || discount == null || service == null || tax == null || adjustment == null ||
            delivery == null ||
            e.totalMinor != subtotal - discount + service + tax + delivery + adjustment) {
          throw BackupException(BackupError.inconsistent, '$at.total_minor');
        }
        _requireCharges(e, subtotal, discount, service, tax, at);
      } else if (e.subtotalMinor != null ||
          e.discountBps != null ||
          e.discountAmountMinor != null ||
          e.discountMinor != null ||
          e.serviceAmountMinor != null ||
          e.taxAmountMinor != null ||
          e.serviceBps != null ||
          e.serviceMinor != null ||
          e.taxBps != null ||
          e.taxMinor != null ||
          e.taxBase != null ||
          e.deliveryMinor != null ||
          e.adjustmentMinor != null) {
        throw BackupException(BackupError.invalid, at);
      }
    }

    // Schema 12 (SA18, Java V23): SHARES rows. Row rules mirror the CHECKs; the cross-table ones (units exactly on the
    // splits of a SHARES expense, presence normalized inside the period) are the validator's, like A196.
    final splitsBy = <String, List<SplitRow>>{};
    for (final s in data.splits) {
      (splitsBy[s.expenseId] ??= []).add(s);
    }
    final sortOrderOf = {for (final m in data.members) m.id: m.sortOrder};
    for (var i = 0; i < data.expenses.length; i++) {
      final e = data.expenses[i];
      final at = 'expenses[$i]';
      final splits = splitsBy[e.id] ?? const <SplitRow>[];
      final shares = e.splitType == 'SHARES';
      if (!shares) {
        if (e.periodFrom != null || e.periodTo != null) throw BackupException(BackupError.invalid, '$at.period_from');
        if (splits.any((s) => s.shareUnits != null || s.presentFrom != null || s.presentTo != null)) {
          throw BackupException(BackupError.invalid, '$at.share_units');
        }
        continue;
      }
      final from = e.periodFrom, to = e.periodTo;
      if ((from == null) != (to == null)) throw BackupException(BackupError.invalid, '$at.period_from');
      if (from != null && (to!.compareTo(from) < 0 || SplitCalculator.inclusiveDays(from, to) > Limits.maxPeriodDays)) {
        throw BackupException(BackupError.invalid, '$at.period_to');
      }
      for (final s in splits) {
        final ok = s.shareUnits != null &&
            s.itemsMinor == null &&
            (from == null
                ? s.presentFrom == null && s.presentTo == null
                : s.presentFrom != null &&
                    s.presentTo != null &&
                    s.presentFrom!.compareTo(from) >= 0 &&
                    s.presentTo!.compareTo(to!) <= 0 &&
                    s.presentTo!.compareTo(s.presentFrom!) >= 0);
        if (!ok) throw BackupException(BackupError.invalid, '$at.share_units');
      }
      // Recompute check: the stored owed amounts are what the engine gives for the stored units and presence.
      try {
        final owed = SplitCalculator.shares(
          e.totalMinor,
          [
            for (final s in splits)
              WeightedShare(s.memberId, sortOrderOf[s.memberId]!, s.shareUnits!,
                  presentFrom: s.presentFrom, presentTo: s.presentTo),
          ],
          period: from == null ? null : SharePeriod(from, to),
        );
        for (final s in splits) {
          if (owed[s.memberId] != s.owedMinor) throw BackupException(BackupError.inconsistent, '$at.owed_minor');
        }
      } on EngineException {
        throw BackupException(BackupError.inconsistent, '$at.owed_minor');
      }
    }

    // Revisions: append-only history; the newest revision carries the expense's current version.
    final newest = <String, int>{};
    final revisionKeys = <String>{};
    final revisionIds = <String>{};
    for (var i = 0; i < data.revisions.length; i++) {
      final r = data.revisions[i];
      final at = 'expense_revisions[$i]';
      if (!revisionIds.add(r.id)) throw BackupException(BackupError.invalid, '$at.id');
      if (!expenseById.containsKey(r.expenseId)) throw BackupException(BackupError.invalid, '$at.expense_id');
      if (r.changedByUserId != profileId) throw BackupException(BackupError.invalid, '$at.changed_by_user_id');
      if (!revisionKeys.add('${r.expenseId}/${r.version}')) throw BackupException(BackupError.invalid, '$at.version');
      final top = newest[r.expenseId] ?? 0;
      if (r.version > top) newest[r.expenseId] = r.version;
    }
    for (final e in data.expenses) {
      if (newest[e.id] != e.version) throw BackupException(BackupError.inconsistent, 'expense_revisions.version');
    }

    // Settlements.
    final settlementIds = <String>{};
    for (var i = 0; i < data.settlements.length; i++) {
      final s = data.settlements[i];
      final at = 'settlements[$i]';
      if (!settlementIds.add(s.id)) throw BackupException(BackupError.invalid, '$at.id');
      if (!groupIds.contains(s.groupId)) throw BackupException(BackupError.invalid, '$at.group_id');
      if (s.fromMemberId == s.toMemberId) throw BackupException(BackupError.invalid, at);
      if (memberGroup[s.fromMemberId] != s.groupId || memberGroup[s.toMemberId] != s.groupId) {
        throw BackupException(BackupError.invalid, '$at.member');
      }
      if (s.createdByUserId != profileId) throw BackupException(BackupError.invalid, '$at.created_by_user_id');
      if (s.createdByMemberId != null && memberGroup[s.createdByMemberId] != s.groupId) {
        throw BackupException(BackupError.invalid, '$at.created_by_member_id');
      }
      if ((s.status == 'CONFIRMED') != (s.confirmedAt != null) || (s.status == 'CANCELLED') != (s.cancelledAt != null)) {
        throw BackupException(BackupError.invalid, '$at.status');
      }
    }

    _recomputeBalances(data);
  }

  /// The V21 charge rules of an ITEMIZED row (A171, A173, A177): each charge in one form at most; 0 <= discount <
  /// subtotal and a discount form exactly when the discount is > 0; an amount form equals its total; a service or tax
  /// above 0 has a form; a tax base exactly when a tax.
  static void _requireCharges(ExpenseRow e, int subtotal, int discount, int service, int tax, String at) {
    final hasDiscount = e.discountBps != null || e.discountAmountMinor != null;
    final hasService = e.serviceBps != null || e.serviceAmountMinor != null;
    final hasTax = e.taxBps != null || e.taxAmountMinor != null;
    final ok = !(e.discountBps != null && e.discountAmountMinor != null) &&
        !(e.serviceBps != null && e.serviceAmountMinor != null) &&
        !(e.taxBps != null && e.taxAmountMinor != null) &&
        subtotal > 0 &&
        discount < subtotal &&
        hasDiscount == (discount > 0) &&
        (e.discountAmountMinor == null || discount == e.discountAmountMinor) &&
        (hasService || service == 0) &&
        (e.serviceAmountMinor == null || service == e.serviceAmountMinor) &&
        (hasTax || tax == 0) &&
        (e.taxAmountMinor == null || tax == e.taxAmountMinor) &&
        hasTax == (e.taxBase != null);
    if (!ok) throw BackupException(BackupError.invalid, '$at.charges');
  }

  /// Balances recomputed by the engine, group by group, from the live expenses and the CONFIRMED settlements: they
  /// must sum to 0 (the engine throws otherwise) and every referenced member must belong to the group.
  static void _recomputeBalances(BackupData data) {
    final payersBy = <String, List<Payer>>{};
    for (final p in data.payers) {
      (payersBy[p.expenseId] ??= []).add(Payer(p.memberId, p.amountMinor));
    }
    final owedBy = <String, Map<String, int>>{};
    for (final s in data.splits) {
      (owedBy[s.expenseId] ??= {})[s.memberId] = s.owedMinor;
    }
    final membersBy = <String, List<MemberRef>>{};
    for (final m in data.members) {
      (membersBy[m.groupId] ??= []).add(MemberRef(m.id, m.sortOrder));
    }
    final entriesBy = <String, List<ExpenseLedgerEntry>>{};
    for (final e in data.expenses) {
      if (e.deletedAt != null) continue;
      (entriesBy[e.groupId] ??= []).add(ExpenseLedgerEntry(payersBy[e.id] ?? const [], owedBy[e.id] ?? const {}));
    }
    final settlementsBy = <String, List<SettlementEntry>>{};
    for (final s in data.settlements) {
      if (s.status != 'CONFIRMED') continue;
      (settlementsBy[s.groupId] ??= []).add(SettlementEntry(s.fromMemberId, s.toMemberId, s.amountMinor));
    }
    for (final g in data.groups) {
      try {
        final nets = BalanceCalculator.nets(membersBy[g.id] ?? const [], entriesBy[g.id] ?? const [], settlementsBy[g.id] ?? const []);
        var sum = 0;
        for (final v in nets.values) {
          sum += v;
        }
        if (sum != 0) throw const BackupException(BackupError.inconsistent, 'balances');
      } on EngineException {
        throw const BackupException(BackupError.inconsistent, 'balances');
      }
    }
  }

  static void _requireMember(
    Map<String, String> memberGroup,
    Map<String, String> expenseGroup,
    String expenseId,
    String memberId,
    String at,
  ) {
    final group = expenseGroup[expenseId];
    if (group == null) throw BackupException(BackupError.invalid, '$at.expense_id');
    if (memberGroup[memberId] != group) throw BackupException(BackupError.invalid, '$at.member_id');
  }

  static Set<String> _unique(Iterable<String> values, String path) {
    final seen = <String>{};
    for (final v in values) {
      if (!seen.add(v)) throw BackupException(BackupError.invalid, path);
    }
    return seen;
  }
}

/// A JSON object with typed, strict accessors. A wrong type (a JSON fraction for an integer, a number for a string)
/// is an error: nothing is coerced.
final class _Reader {
  _Reader(this.map, this.path);

  final Map<String, dynamic> map;
  final String path;

  String _at(String key) => path.isEmpty ? key : '$path.$key';

  Never _fail(String key, [BackupError code = BackupError.invalid]) => throw BackupException(code, _at(key));

  List<Object?> list(String key) {
    final v = map[key];
    if (v is! List<Object?>) _fail(key);
    return v;
  }

  _Reader object(String key) {
    final v = map[key];
    if (v is! Map<String, dynamic>) _fail(key);
    return _Reader(v, _at(key));
  }

  int integer(String key, {required int min, required int max, BackupError error = BackupError.invalid}) {
    final v = map[key];
    if (v is! int || v < min || v > max) _fail(key, error);
    return v;
  }

  int? optInteger(String key, {required int min, required int max}) => map[key] == null ? null : integer(key, min: min, max: max);

  int timestamp(String key) => integer(key, min: 0, max: BackupValidator._maxTimestamp);

  int? optTimestamp(String key) => map[key] == null ? null : timestamp(key);

  int amount(String key) => integer(key, min: 1, max: Limits.maxAmountMinor);

  String string(String key, {required int min, required int max, bool trimmed = false}) {
    final v = map[key];
    if (v is! String) _fail(key);
    final length = (trimmed ? v.trim() : v).runes.length;
    if (length < min || length > max) _fail(key);
    return v;
  }

  String? optString(String key, {required int min, required int max, bool trimmed = false}) =>
      map[key] == null ? null : string(key, min: min, max: max, trimmed: trimmed);

  String id(String key) => string(key, min: 36, max: 36);

  String? optId(String key) => map[key] == null ? null : id(key);

  String oneOf(String key, Set<String> allowed) {
    final v = map[key];
    if (v is! String || !allowed.contains(v)) _fail(key);
    return v;
  }

  String? optOneOf(String key, Set<String> allowed) => map[key] == null ? null : oneOf(key, allowed);

  String currency(String key) {
    final v = map[key];
    if (v is! String || !RegExp(r'^[A-Z]{3}$').hasMatch(v)) _fail(key);
    return v;
  }

  String? optDate(String key) => map[key] == null ? null : date(key);

  String date(String key) {
    final v = map[key];
    if (v is! String || !BackupValidator._datePattern.hasMatch(v)) _fail(key);
    final y = int.parse(v.substring(0, 4)), m = int.parse(v.substring(5, 7)), d = int.parse(v.substring(8, 10));
    final parsed = DateTime.utc(y, m, d);
    if (parsed.year != y || parsed.month != m || parsed.day != d) _fail(key);
    return v;
  }
}
