import 'package:built_collection/built_collection.dart';
import 'package:drift/drift.dart';
import 'package:qesma_api/qesma_api.dart';

import '../db/daos/expenses_dao.dart';
import '../db/local_database.dart';
import '../errors.dart';
import 'commands.dart';
import 'expense_calculator.dart';
import 'expense_validator.dart';
import 'field_rules.dart';
import 'idempotency_service.dart';
import 'local_context.dart';
import 'views.dart';

/// Expenses of a group (spec 3.1, 7.9, 8.2): EQUAL, EXACT and ITEMIZED with one or more payers, the preview, edits,
/// soft deletes and revisions. A port of Java `ExpenseService`: this class validates and persists; every money rule
/// is the engine's, reached only through [ExpenseCalculator]. Every write is ONE drift transaction together with its
/// revision and (create) its idempotency record (STANDALONE_SPEC 3.8).
final class ExpenseService {
  ExpenseService(this._ctx) : _idempotency = IdempotencyService(_ctx);

  final LocalContext _ctx;
  final IdempotencyService _idempotency;

  static const String createEndpoint = 'POST /api/v1/groups/{gid}/expenses';

  LocalDatabase get _db => _ctx.db;

  /// Creates an expense exactly once per Idempotency-Key ([key] is a lower-case UUID). A replay returns the stored
  /// response and writes nothing; the same key with a different request is IDEMPOTENCY_KEY_REUSED.
  Future<Outcome> create(String groupId, String key, ExpenseIn command) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final request = ExpenseValidator.validate(command);
        ExpenseValidator.requirePoolRules(request, access.group.treasurerMemberId);
        final fingerprint = IdempotencyService.fingerprint(canonical(createEndpoint, groupId, request));
        final replay = await _idempotency.findReplay(key, createEndpoint, fingerprint);
        // A body stored before SA15 lacks the itemized v2 fields; it is upgraded on the way out, never rewritten.
        if (replay != null) return Outcome(replay.status, upgradeExpenseJsonText(replay.body), replayed: replay.replayed);
        final calc = ExpenseCalculator.compute(request, access.members);
        ExpenseCalculator.requirePayersMatch(calc);
        final now = _ctx.clock();
        final graph = _graph(
          id: _ctx.newId(),
          groupId: groupId,
          createdByUserId: access.profile.id,
          createdAt: now,
          updatedAt: now,
          version: 1,
          request: request,
          calc: calc,
        );
        await _db.expensesDao.insertGraph(graph);
        final body = toJsonText(ExpenseView.serializer, expenseView(graph, access.sortOrders));
        await _revision(graph.expense.id, 1, 'CREATE', body, access.profile.id, now);
        final outcome = Outcome(201, body);
        await _idempotency.store(key, createEndpoint, fingerprint, outcome);
        return outcome;
      });

  /// Computes the split for the same body as create and saves nothing. Payers are optional here;
  /// `payersTotalMatches` reports their state instead of failing.
  Future<ExpensePreview> preview(String groupId, ExpenseIn command) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final request = ExpenseValidator.validate(command, requirePayers: false);
        final calc = ExpenseCalculator.compute(request, access.members);
        final payersMatch = ExpenseCalculator.payersMatch(calc);
        return ExpensePreview((b) => b
          ..totalMinor = calc.totalMinor
          ..subtotalMinor = calc.subtotalMinor
          ..discountMinor = calc.itemized ? calc.discountMinor : null
          ..serviceMinor = calc.itemized ? calc.serviceMinor : null
          ..taxMinor = calc.itemized ? calc.taxMinor : null
          ..adjustmentMinor = calc.itemized ? calc.adjustmentMinor : null
          ..members = ListBuilder([for (final s in calc.shares) _shareView(s)])
          ..payersTotalMatches = payersMatch);
      });

  /// Replaces a live expense under If-Match; the version goes up by one and an UPDATE revision is appended.
  Future<ExpenseView> update(String groupId, String expenseId, int expectedVersion, ExpenseIn command) =>
      _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final stored = await _liveGraph(groupId, expenseId);
        _requireVersion(stored, expectedVersion, access);
        final request = ExpenseValidator.validate(command);
        ExpenseValidator.requirePoolRules(request, access.group.treasurerMemberId);
        // A member who left may stay in an expense that already has them, but cannot be added (B12, A79).
        final kept = <String>{
          ...stored.payers.map((p) => p.memberId),
          ...stored.splits.map((s) => s.memberId),
          ...stored.assignees.map((a) => a.memberId),
        };
        final calc = ExpenseCalculator.compute(request, access.members, keptMemberIds: kept);
        ExpenseCalculator.requirePayersMatch(calc);
        final now = _ctx.clock();
        final version = stored.expense.version + 1;
        final graph = _graph(
          id: expenseId,
          groupId: groupId,
          createdByUserId: stored.expense.createdByUserId,
          createdAt: stored.expense.createdAt,
          updatedAt: now,
          version: version,
          request: request,
          calc: calc,
        );
        if (!await _db.expensesDao.replaceGraphIfVersion(graph, expectedVersion)) {
          throw LocalApiException.conflict('VERSION_CONFLICT', 'The expense was modified by someone else');
        }
        final view = expenseView(graph, access.sortOrders);
        await _revision(expenseId, version, 'UPDATE', toJsonText(ExpenseView.serializer, view), access.profile.id, now);
        return view;
      });

  /// Soft delete under If-Match: `deleted_at` is set, the version goes up and a DELETE revision keeps the last
  /// state. Returns the new version. A second delete is a plain 404.
  Future<int> delete(String groupId, String expenseId, int expectedVersion) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final stored = await _liveGraph(groupId, expenseId);
        _requireVersion(stored, expectedVersion, access);
        final now = _ctx.clock();
        final version = stored.expense.version + 1;
        final changed = await _db.expensesDao
            .softDeleteIfVersion(expenseId, expectedVersion, deletedAt: now, newVersion: version);
        if (changed == 0) throw LocalApiException.conflict('VERSION_CONFLICT', 'The expense was modified by someone else');
        final last = expenseView((await _db.expensesDao.loadGraph(expenseId))!, access.sortOrders);
        await _revision(expenseId, version, 'DELETE', toJsonText(ExpenseView.serializer, last), access.profile.id, now);
        return version;
      });

  Future<ExpenseView> get(String groupId, String expenseId) => _db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        return expenseView(await _liveGraph(groupId, expenseId), access.sortOrders);
      });

  /// Live expenses, newest `expenseDate` first, then `createdAt`, then id; optional inclusive date range, member
  /// filter (payer or share row), and category filter.
  Future<PageResponseExpenseView> list(
    String groupId, {
    required int page,
    required int size,
    String? fromDate,
    String? toDate,
    String? memberId,
    String? category,
  }) =>
      _db.transaction(() async {
        FieldRules.page(page, size);
        final cat = category == null || category.trim().isEmpty ? null : ExpenseValidator.category(category);
        if (fromDate != null && toDate != null && fromDate.compareTo(toDate) > 0) {
          throw LocalApiException.validation('fromDate must not be after toDate');
        }
        final access = await _ctx.requireGroup(groupId);
        final where = StringBuffer('e.group_id = ? AND e.deleted_at IS NULL');
        final vars = <Variable<Object>>[Variable.withString(groupId)];
        if (fromDate != null) {
          where.write(' AND e.expense_date >= ?');
          vars.add(Variable.withString(fromDate));
        }
        if (toDate != null) {
          where.write(' AND e.expense_date <= ?');
          vars.add(Variable.withString(toDate));
        }
        if (cat != null) {
          where.write(' AND e.category = ?');
          vars.add(Variable.withString(cat));
        }
        if (memberId != null) {
          where.write(' AND (EXISTS (SELECT 1 FROM expense_payers p WHERE p.expense_id = e.id AND p.member_id = ?)'
              ' OR EXISTS (SELECT 1 FROM expense_splits s WHERE s.expense_id = e.id AND s.member_id = ?))');
          vars
            ..add(Variable.withString(memberId))
            ..add(Variable.withString(memberId));
        }
        final reads = <ResultSetImplementation<dynamic, dynamic>>{_db.expenses, _db.expensePayers, _db.expenseSplits};
        final count = (await _db
                .customSelect('SELECT COUNT(*) AS n FROM expenses e WHERE $where', variables: vars, readsFrom: reads)
                .getSingle())
            .read<int>('n');
        final ids = await _db.customSelect(
          'SELECT e.id AS id FROM expenses e WHERE $where '
          'ORDER BY e.expense_date DESC, e.created_at DESC, e.id DESC LIMIT ? OFFSET ?',
          variables: [...vars, Variable.withInt(size), Variable.withInt(page * size)],
          readsFrom: reads,
        ).get();
        final views = <ExpenseView>[];
        for (final r in ids) {
          views.add(expenseView((await _db.expensesDao.loadGraph(r.read<String>('id')))!, access.sortOrders));
        }
        return PageResponseExpenseView((b) => b
          ..items = ListBuilder(views)
          ..page = page
          ..size = size
          ..totalElements = count
          ..totalPages = (count + size - 1) ~/ size);
      });

  /// History of an expense, oldest first; still available after the expense was deleted.
  Future<List<ExpenseRevisionView>> revisions(String groupId, String expenseId) => _db.transaction(() async {
        await _ctx.requireGroup(groupId);
        final expense = await _db.expensesDao.findById(expenseId);
        if (expense == null || expense.groupId != groupId) throw LocalApiException.notFound();
        final rows = await _db.revisionsDao.listByExpense(expenseId);
        return [
          for (final r in rows)
            ExpenseRevisionView((b) => b
              ..version = r.version
              ..changeType = r.changeType
              ..changedAt = utc(r.changedAt)
              ..changedByUserId = r.changedByUserId
              // Snapshots written before SA15 read back as quantity 1, no discount (A177); never rewritten.
              ..snapshot = fromJsonText(ExpenseView.serializer, upgradeExpenseJsonText(r.snapshot)).toBuilder()),
        ];
      });

  /// Canonical request of Java `RequestHasher`: fixed key order, payers/shares sorted by member id then amount,
  /// participant and assignee ids sorted, item order kept; an omitted participant list differs from an explicit one.
  /// BSA2 (A175): an item's amountMinor is its line, so `{amountMinor: 500}` and `{unitAmountMinor: 500}` are the same
  /// request; quantity and the new charge forms are hashed only when not default, so a pre-SA15 key keeps its hash.
  static Map<String, Object?> canonical(String endpoint, String groupId, ValidExpense v) {
    List<Map<String, Object?>> amounts(List<ValidAmount> list) {
      final sorted = [...list]..sort((a, b) {
          final byId = a.memberId.compareTo(b.memberId);
          return byId != 0 ? byId : a.amountMinor.compareTo(b.amountMinor);
        });
      return [
        for (final e in sorted) {'memberId': e.memberId, 'amountMinor': e.amountMinor},
      ];
    }

    return {
      'endpoint': endpoint,
      'groupId': groupId,
      'title': v.title,
      'expenseDate': v.expenseDate,
      'splitType': v.splitType,
      'totalMinor': v.totalMinor,
      // Only a non-default flag is hashed (Java RequestHasher), so keys stored before SA10 keep their hash.
      if (v.paidFromPool) 'paidFromPool': true,
      'payers': amounts(v.payers),
      'participantMemberIds': v.participantMemberIds == null ? null : ([...v.participantMemberIds!]..sort()),
      'shares': v.shares == null ? null : amounts(v.shares!),
      if (v.items != null) ...{
        'items': [
          for (final i in v.items!)
            {
              'name': i.name,
              'amountMinor': i.amountMinor,
              if (i.quantity != 1) 'quantity': i.quantity,
              'assigneeMemberIds': [...i.assigneeMemberIds]..sort(),
            },
        ],
        'serviceBps': v.serviceBps,
        'taxBps': v.taxBps,
        'taxBase': v.taxBase,
        'adjustmentMinor': v.adjustmentMinor,
        'serviceAmountMinor': ?v.serviceAmountMinor,
        'taxAmountMinor': ?v.taxAmountMinor,
        'discountBps': ?v.discountBps,
        'discountAmountMinor': ?v.discountAmountMinor,
      },
    };
  }

  // ---- helpers ------------------------------------------------------------------------------------------

  Future<ExpenseGraph> _liveGraph(String groupId, String expenseId) async {
    final graph = await _db.expensesDao.loadGraph(expenseId);
    if (graph == null || graph.expense.groupId != groupId || graph.expense.deletedAt != null) {
      throw LocalApiException.notFound();
    }
    return graph;
  }

  /// A stale If-Match is 409 VERSION_CONFLICT with `currentVersion` and the view GET returns now (A113).
  void _requireVersion(ExpenseGraph stored, int expected, GroupAccess access) {
    if (stored.expense.version != expected) {
      throw LocalApiException.versionConflict(
        'The expense was modified by someone else',
        stored.expense.version,
        toJsonValue(ExpenseView.serializer, expenseView(stored, access.sortOrders))!,
      );
    }
  }

  Future<void> _revision(String expenseId, int version, String changeType, String snapshot, String userId, int now) =>
      _db.revisionsDao.insertRevision(RevisionRow(
        id: _ctx.newId(),
        expenseId: expenseId,
        version: version,
        changeType: changeType,
        snapshot: snapshot,
        changedByUserId: userId,
        changedAt: now,
      ));

  ExpenseGraph _graph({
    required String id,
    required String groupId,
    required String createdByUserId,
    required int createdAt,
    required int updatedAt,
    required int version,
    required ValidExpense request,
    required Computation calc,
  }) {
    final itemized = calc.itemized;
    final items = <ItemRow>[];
    final assignees = <AssigneeRow>[];
    if (itemized) {
      var position = 0;
      for (final input in request.items!) {
        final itemId = _ctx.newId();
        items.add(ItemRow(
          id: itemId,
          expenseId: id,
          name: input.name,
          amountMinor: input.amountMinor,
          sortOrder: position++,
          quantity: input.quantity,
          unitAmountMinor: input.unitAmountMinor,
        ));
        for (final memberId in input.assigneeMemberIds.toSet()) {
          assignees.add(AssigneeRow(itemId: itemId, memberId: memberId));
        }
      }
    }
    return ExpenseGraph(
      expense: ExpenseRow(
        id: id,
        groupId: groupId,
        title: request.title,
        splitType: calc.splitType,
        totalMinor: calc.totalMinor,
        expenseDate: request.expenseDate,
        subtotalMinor: itemized ? calc.subtotalMinor : null,
        serviceBps: itemized ? calc.serviceBps : null,
        serviceMinor: itemized ? calc.serviceMinor : null,
        taxBps: itemized ? calc.taxBps : null,
        taxMinor: itemized ? calc.taxMinor : null,
        taxBase: itemized ? calc.taxBase : null,
        adjustmentMinor: itemized ? calc.adjustmentMinor : null,
        discountBps: itemized ? calc.discountBps : null,
        discountAmountMinor: itemized ? calc.discountAmountMinor : null,
        discountMinor: itemized ? calc.discountMinor : null,
        serviceAmountMinor: itemized ? calc.serviceAmountMinor : null,
        taxAmountMinor: itemized ? calc.taxAmountMinor : null,
        createdByUserId: createdByUserId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        version: version,
        category: request.category,
        paidFromPool: request.paidFromPool ? 1 : 0,
      ),
      payers: [for (final p in calc.payers) PayerRow(expenseId: id, memberId: p.memberId, amountMinor: p.amountMinor)],
      splits: [
        for (final s in calc.shares)
          SplitRow(
            expenseId: id,
            memberId: s.memberId,
            owedMinor: s.owedMinor,
            itemsMinor: s.itemsMinor,
            discountMinor: s.discountMinor,
            serviceMinor: s.serviceMinor,
            taxMinor: s.taxMinor,
            adjustmentMinor: s.adjustmentMinor,
          ),
      ],
      items: items,
      assignees: assignees,
    );
  }

  static ShareView _shareView(ShareComp s) => ShareView((v) => v
    ..memberId = s.memberId
    ..owedMinor = s.owedMinor
    ..itemsMinor = s.itemsMinor
    ..discountMinor = s.discountMinor
    ..serviceMinor = s.serviceMinor
    ..taxMinor = s.taxMinor
    ..adjustmentMinor = s.adjustmentMinor);
}
