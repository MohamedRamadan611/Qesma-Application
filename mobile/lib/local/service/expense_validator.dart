import 'package:qesma_engine/qesma_engine.dart';

import '../errors.dart';
import 'commands.dart';
import 'field_rules.dart';

/// An item after validation, normalized (BSA2): name stripped, quantity, unit price and the line amount
/// (`quantity x unitAmountMinor`, computed by the engine) all set, assignees present.
final class ValidItem {
  const ValidItem(this.name, this.amountMinor, this.assigneeMemberIds, {int? unitAmountMinor, this.quantity = 1})
      : unitAmountMinor = unitAmountMinor ?? amountMinor;
  final String name;
  final int quantity;
  final int unitAmountMinor;

  /// The line amount.
  final int amountMinor;
  final List<String> assigneeMemberIds;
}

/// A SHARES participant after validation (A195): presence normalized, both bounds set exactly when there is a period.
final class ValidShareParticipant {
  const ValidShareParticipant(this.memberId, this.shareUnits, {this.presentFrom, this.presentTo});
  final String memberId;
  final int shareUnits;
  final String? presentFrom;
  final String? presentTo;
}

/// A payer or an EXACT share after validation.
final class ValidAmount {
  const ValidAmount(this.memberId, this.amountMinor);
  final String memberId;
  final int amountMinor;
}

/// A request that passed shape validation, with normalized text (Java `ExpenseValidator.Valid`).
/// [totalMinor] 0 means "not stated" (ITEMIZED only); [taxBase] is present exactly when a tax (either form) is.
/// Each charge is in at most one form: `*Bps` or `*AmountMinor` (BSA2, A171, A173); both null = the charge is off.
final class ValidExpense {
  const ValidExpense({
    required this.title,
    required this.expenseDate,
    required this.splitType,
    required this.totalMinor,
    required this.payers,
    required this.category,
    this.participantMemberIds,
    this.shares,
    this.items,
    this.serviceBps,
    this.serviceAmountMinor,
    this.taxBps,
    this.taxAmountMinor,
    this.taxBase,
    this.discountBps,
    this.discountAmountMinor,
    this.adjustmentMinor = 0,
    this.deliveryMinor = 0,
    this.paidFromPool = false,
    this.shareParticipants,
    this.periodFrom,
    this.periodTo,
  });

  final int? serviceAmountMinor;
  final int? taxAmountMinor;
  final int? discountBps;
  final int? discountAmountMinor;

  bool get hasTax => taxBps != null || taxAmountMinor != null;

  final String title;
  final String expenseDate;
  final String splitType;
  final int totalMinor;
  final List<ValidAmount> payers;
  final String category;
  final List<String>? participantMemberIds;
  final List<ValidAmount>? shares;
  final List<ValidItem>? items;
  final int? serviceBps;
  final int? taxBps;
  final String? taxBase;
  final int adjustmentMinor;

  /// A180: the delivery amount, 0 when absent.
  final int deliveryMinor;

  /// BSA1: a pool expense; checked against the group by [ExpenseValidator.requirePoolRules].
  final bool paidFromPool;

  /// BSA3: SHARES only (null otherwise); the period is null when the expense has none.
  final List<ValidShareParticipant>? shareParticipants;
  final String? periodFrom;
  final String? periodTo;

  bool get itemized => splitType == 'ITEMIZED';
}

/// Shape validation of a create / preview / update expense body: a port of Java `ExpenseValidator` with the same
/// check order and limits (STANDALONE_SPEC 3.2). Money rules are not here; they are the engine's.
abstract final class ExpenseValidator {
  static const int maxTitle = 100;
  static const int maxItemName = 100;
  static const int maxList = 100;
  static const int maxBps = 10000;
  static const int maxDiscountBps = ItemizedCalculator.maxDiscountBps;
  static const String minDate = '2000-01-01';
  static const String maxDate = '2100-12-31';
  static const String defaultCategory = 'OTHER';
  static const Set<String> categories = {
    'FOOD', 'TRANSPORT', 'FUEL', 'ACCOMMODATION', 'GROCERIES', 'SHOPPING', 'ENTERTAINMENT', 'BILLS', defaultCategory
  };

  /// Null or blank = OTHER; anything outside the enum is a validation error (never silently coerced).
  static String category(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaultCategory;
    final value = raw.trim().toUpperCase();
    if (!categories.contains(value)) {
      throw LocalApiException.validation('category must be one of ${categories.toList()..sort()}');
    }
    return value;
  }

  /// BSA1 (A135, Java `ExpenseValidator.requirePoolRules`): a pool expense needs a group treasurer and exactly one
  /// payer, the treasurer. Needs the group, so create and update call it right after [validate] (preview does not).
  static void requirePoolRules(ValidExpense v, String? treasurerMemberId) {
    if (!v.paidFromPool) return;
    if (treasurerMemberId == null) throw LocalApiException.validation('paidFromPool needs a group treasurer');
    if (v.payers.length != 1 || v.payers.single.memberId != treasurerMemberId) {
      throw LocalApiException.validation('A pool expense must have exactly one payer: the treasurer');
    }
  }

  /// Create and update require at least one payer; preview passes [requirePayers] false.
  static ValidExpense validate(ExpenseIn c, {bool requirePayers = true}) {
    final title = FieldRules.name(c.title, maxTitle, 'title');
    final date = c.expenseDate;
    if (date == null) throw LocalApiException.validation('expenseDate is required');
    if (date.compareTo(minDate) < 0 || date.compareTo(maxDate) > 0) {
      throw LocalApiException.validation('expenseDate must be between $minDate and $maxDate');
    }
    final type = c.splitType == null ? '' : javaStrip(c.splitType!).toUpperCase();
    final itemized = type == 'ITEMIZED';
    if (!itemized && type != 'EQUAL' && type != 'EXACT' && type != 'SHARES') {
      throw LocalApiException.validation('splitType must be EQUAL, EXACT, ITEMIZED or SHARES');
    }
    var total = 0;
    final stated = c.totalMinor;
    if (itemized) {
      if (stated != null) {
        if (stated <= 0) throw LocalApiException.validation('totalMinor must be greater than zero when given');
        capped(stated, 'totalMinor');
        total = stated;
      }
    } else {
      if (stated == null || stated <= 0) throw LocalApiException.validation('totalMinor must be greater than zero');
      capped(stated, 'totalMinor');
      total = stated;
    }
    final rawPayers = c.payers ?? const <PayerIn?>[];
    if (requirePayers && rawPayers.isEmpty) throw LocalApiException.validation('At least one payer is required');
    if (rawPayers.length > maxList) throw LocalApiException.validation('At most $maxList payers are allowed');
    final payers = <ValidAmount>[];
    for (final p in rawPayers) {
      if (p == null || p.memberId == null || p.amountMinor == null) {
        throw LocalApiException.validation('Every payer needs memberId and amountMinor');
      }
      capped(p.amountMinor!, 'payer amountMinor');
      payers.add(ValidAmount(p.memberId!, p.amountMinor!));
    }
    return switch (type) {
      'EQUAL' => _equal(c, title, date, total, payers),
      'EXACT' => _exact(c, title, date, total, payers),
      'SHARES' => _shares(c, title, date, total, payers),
      _ => _itemized(c, title, date, total, payers),
    };
  }

  static ValidExpense _equal(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectItemizedFields(c, 'EQUAL');
    _rejectSharesFields(c, 'EQUAL');
    if (c.shares != null) throw LocalApiException.validation('shares is only allowed for EXACT expenses');
    final participants = c.participantMemberIds;
    if (participants != null) {
      if (participants.isEmpty) {
        throw LocalApiException.validation('participantMemberIds must not be empty (omit it for all members)');
      }
      if (participants.length > maxList) {
        throw LocalApiException.validation('At most $maxList participants are allowed');
      }
      if (participants.any((p) => p == null)) {
        throw LocalApiException.validation('participantMemberIds must not contain null');
      }
    }
    return ValidExpense(
      title: title,
      expenseDate: date,
      splitType: 'EQUAL',
      totalMinor: total,
      payers: payers,
      category: category(c.category),
      paidFromPool: c.paidFromPool == true,
      participantMemberIds: participants?.cast<String>().toList(),
    );
  }

  static ValidExpense _exact(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectItemizedFields(c, 'EXACT');
    _rejectSharesFields(c, 'EXACT');
    if (c.participantMemberIds != null) {
      throw LocalApiException.validation('participantMemberIds is only allowed for EQUAL expenses');
    }
    final shares = c.shares;
    if (shares == null || shares.isEmpty) throw LocalApiException.validation('shares is required for EXACT expenses');
    if (shares.length > maxList) throw LocalApiException.validation('At most $maxList shares are allowed');
    final valid = <ValidAmount>[];
    for (final s in shares) {
      if (s == null || s.memberId == null || s.amountMinor == null) {
        throw LocalApiException.validation('Every share needs memberId and amountMinor');
      }
      capped(s.amountMinor!, 'share amountMinor');
      valid.add(ValidAmount(s.memberId!, s.amountMinor!));
    }
    return ValidExpense(
      title: title,
      expenseDate: date,
      splitType: 'EXACT',
      totalMinor: total,
      payers: payers,
      category: category(c.category),
      paidFromPool: c.paidFromPool == true,
      shares: valid,
    );
  }

  static ValidExpense _itemized(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectSharesFields(c, 'ITEMIZED');
    if (c.participantMemberIds != null) {
      throw LocalApiException.validation('participantMemberIds is only allowed for EQUAL expenses');
    }
    if (c.shares != null) throw LocalApiException.validation('shares is only allowed for EXACT expenses');
    final items = c.items;
    if (items == null || items.isEmpty) throw LocalApiException.validation('items is required for ITEMIZED expenses');
    if (items.length > maxList) throw LocalApiException.validation('At most $maxList items are allowed');
    final clean = <ValidItem>[];
    for (final item in items) {
      if (item == null || item.assigneeMemberIds == null) {
        throw LocalApiException.validation('Every item needs name, an amount and assigneeMemberIds');
      }
      final name = FieldRules.name(item.name, maxItemName, 'item name');
      final line = _itemLine(name, item);
      final assignees = item.assigneeMemberIds!;
      if (assignees.isEmpty) throw LocalApiException.validation('Every item needs at least one assignee');
      if (assignees.length > maxList) {
        throw LocalApiException.validation('At most $maxList assignees per item are allowed');
      }
      if (assignees.any((a) => a == null)) {
        throw LocalApiException.validation('assigneeMemberIds must not contain null');
      }
      clean.add(ValidItem(name, line.amountMinor, assignees.cast<String>().toList(),
          unitAmountMinor: line.unitAmountMinor, quantity: line.quantity));
    }
    ChargeSpec? service;
    if (c.service != null) service = _charge(c.service!.bps, c.service!.amountMinor, 'service', 0, maxBps);
    ChargeSpec? tax;
    String? taxBase;
    if (c.tax != null) {
      tax = _charge(c.tax!.bps, c.tax!.amountMinor, 'tax', 0, maxBps);
      taxBase = _taxBase(c.tax!.base);
    }
    ChargeSpec? discount;
    if (c.discount != null) {
      discount = _charge(c.discount!.bps, c.discount!.amountMinor, 'discount', 1, maxDiscountBps);
    }
    final adjustment = c.adjustmentMinor ?? 0;
    if (adjustment > Limits.maxAmountMinor || adjustment < -Limits.maxAmountMinor) {
      throw LocalApiException.validation(
        'adjustmentMinor must be between -${Limits.maxAmountMinor} and ${Limits.maxAmountMinor}',
      );
    }
    final delivery = c.deliveryMinor ?? 0;
    if (delivery < 0 || delivery > Limits.maxAmountMinor) {
      throw LocalApiException.validation('deliveryMinor must be between 0 and ${Limits.maxAmountMinor}');
    }
    return ValidExpense(
      title: title,
      expenseDate: date,
      splitType: 'ITEMIZED',
      totalMinor: total,
      payers: payers,
      category: category(c.category),
      paidFromPool: c.paidFromPool == true,
      items: clean,
      serviceBps: service?.bps,
      serviceAmountMinor: service?.amountMinor,
      taxBps: tax?.bps,
      taxAmountMinor: tax?.amountMinor,
      taxBase: taxBase,
      discountBps: discount?.bps,
      discountAmountMinor: discount?.amountMinor,
      adjustmentMinor: adjustment,
      deliveryMinor: delivery,
    );
  }

  /// SHARES (STANDALONE_SPEC 19.1, A185-A187; Java `ExpenseValidator.shares`): every rule is a 422 naming the field.
  /// The engine enforces the money-relevant rules again; this layer adds field paths, null and date-range checks, and
  /// normalizes presence (with a period, a missing bound becomes the period bound; A195).
  static ValidExpense _shares(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectItemizedFields(c, 'SHARES');
    if (c.participantMemberIds != null) {
      throw LocalApiException.validation('participantMemberIds is only allowed for EQUAL expenses (this is SHARES)');
    }
    if (c.shares != null) throw LocalApiException.validation('shares is only allowed for EXACT expenses (this is SHARES)');
    final periodFrom = c.periodFrom;
    final periodTo = c.periodTo;
    if ((periodFrom == null) != (periodTo == null)) {
      throw LocalApiException.validation('periodFrom and periodTo must both be set or both be absent');
    }
    if (periodFrom != null && periodTo != null) {
      _inDateRange(periodFrom, 'periodFrom');
      _inDateRange(periodTo, 'periodTo');
      if (periodTo.compareTo(periodFrom) < 0) throw LocalApiException.validation('periodTo must not be before periodFrom');
      if (SplitCalculator.inclusiveDays(periodFrom, periodTo) > Limits.maxPeriodDays) {
        throw LocalApiException.validation(
            'The period (periodFrom..periodTo) must be at most ${Limits.maxPeriodDays} days');
      }
    }
    final participants = c.shareParticipants;
    if (participants == null || participants.isEmpty) {
      throw LocalApiException.validation('shareParticipants is required for SHARES expenses');
    }
    if (participants.length > maxList) {
      throw LocalApiException.validation('At most $maxList shareParticipants are allowed');
    }
    final seen = <String>{};
    final clean = <ValidShareParticipant>[];
    for (var i = 0; i < participants.length; i++) {
      final path = 'shareParticipants[$i]';
      final p = participants[i];
      if (p == null || p.memberId == null) throw LocalApiException.validation('$path.memberId is required');
      if (!seen.add(p.memberId!)) throw LocalApiException.validation('$path.memberId appears more than once');
      final units = p.shareUnits;
      if (units == null || units < Limits.minShareUnits || units > Limits.maxShareUnits) {
        throw LocalApiException.validation(
            '$path.shareUnits must be between ${Limits.minShareUnits} and ${Limits.maxShareUnits}');
      }
      var from = p.presentFrom;
      var to = p.presentTo;
      if (periodFrom == null || periodTo == null) {
        if (from != null || to != null) {
          throw LocalApiException.validation('$path.presentFrom/presentTo need periodFrom and periodTo');
        }
      } else {
        // YYYY-MM-DD compares as text in calendar order.
        from ??= periodFrom;
        to ??= periodTo;
        if (from.compareTo(periodFrom) < 0 || from.compareTo(periodTo) > 0) {
          throw LocalApiException.validation('$path.presentFrom must lie inside the period');
        }
        if (to.compareTo(periodFrom) < 0 || to.compareTo(periodTo) > 0) {
          throw LocalApiException.validation('$path.presentTo must lie inside the period');
        }
        if (to.compareTo(from) < 0) throw LocalApiException.validation('$path.presentTo must not be before presentFrom');
      }
      clean.add(ValidShareParticipant(p.memberId!, units, presentFrom: from, presentTo: to));
    }
    return ValidExpense(
      title: title,
      expenseDate: date,
      splitType: 'SHARES',
      totalMinor: total,
      payers: payers,
      category: category(c.category),
      paidFromPool: c.paidFromPool == true,
      shareParticipants: clean,
      periodFrom: periodFrom,
      periodTo: periodTo,
    );
  }

  static void _inDateRange(String d, String field) {
    if (d.compareTo(minDate) < 0 || d.compareTo(maxDate) > 0) {
      throw LocalApiException.validation('$field must be between $minDate and $maxDate');
    }
  }

  /// SHARES fields on any other split type are rejected (A187).
  static void _rejectSharesFields(ExpenseIn c, String type) {
    if (c.shareParticipants != null || c.periodFrom != null || c.periodTo != null) {
      throw LocalApiException.validation(
          'shareParticipants, periodFrom and periodTo are only allowed for SHARES expenses (this is $type)');
    }
  }

  /// A172 shape and ranges (Java `ExpenseValidator.itemLine`): legacy amountMinor or unitAmountMinor with an optional
  /// quantity, never both; quantity 1..999; unit price > 0 and within the cap; the line (computed exactly by the
  /// engine) within the cap.
  static Item _itemLine(String name, ItemIn item) {
    try {
      final line = Item.of(name, const [],
          amountMinor: item.amountMinor, unitAmountMinor: item.unitAmountMinor, quantity: item.quantity);
      if (line.quantity < Item.minQuantity || line.quantity > Item.maxQuantity) {
        throw LocalApiException.validation('Item quantity must be between ${Item.minQuantity} and ${Item.maxQuantity}');
      }
      if (line.unitAmountMinor <= 0) throw LocalApiException.validation('Item amounts must be greater than zero');
      capped(line.unitAmountMinor, 'item amount');
      capped(line.amountMinor, 'item line amount (quantity x unitAmountMinor)');
      return line;
    } on EngineException catch (e) {
      throw LocalApiException.fromEngine(e);
    }
  }

  /// A charge in exactly one form (A171, A173): bps within [minBps]..[maxBps] or an amount 1..cap.
  static ChargeSpec _charge(int? bps, int? amountMinor, String field, int minBps, int maxBps) {
    if ((bps == null) == (amountMinor == null)) {
      throw LocalApiException.validation('$field needs either bps or amountMinor, not both');
    }
    if (bps != null) {
      if (bps < minBps || bps > maxBps) {
        throw LocalApiException.validation('$field.bps must be between $minBps and $maxBps');
      }
      return ChargeSpec.percent(bps);
    }
    if (amountMinor! < 1 || amountMinor > Limits.maxAmountMinor) {
      throw LocalApiException.validation('$field.amountMinor must be between 1 and ${Limits.maxAmountMinor}');
    }
    return ChargeSpec.amount(amountMinor);
  }

  /// Every amount has an upper bound so ledger sums cannot overflow (CP2-001).
  static void capped(int amountMinor, String field) {
    if (!Limits.withinAmountLimit(amountMinor)) {
      throw LocalApiException.validation('$field must be at most ${Limits.maxAmountMinor}');
    }
  }

  static void _rejectItemizedFields(ExpenseIn c, String type) {
    if (c.items != null ||
        c.service != null ||
        c.tax != null ||
        c.adjustmentMinor != null ||
        c.discount != null ||
        c.deliveryMinor != null) {
      throw LocalApiException.validation(
        'items, discount, service, tax, deliveryMinor and adjustmentMinor are only allowed for ITEMIZED expenses (this is $type)',
      );
    }
  }

  /// Null or blank defaults to SUBTOTAL_PLUS_SERVICE (A1); the default is made explicit for storage and hashing.
  static String _taxBase(String? raw) {
    if (raw == null || javaStrip(raw).isEmpty) return 'SUBTOTAL_PLUS_SERVICE';
    final base = javaStrip(raw).toUpperCase();
    if (base != 'SUBTOTAL' && base != 'SUBTOTAL_PLUS_SERVICE') {
      throw LocalApiException.validation('tax.base must be SUBTOTAL or SUBTOTAL_PLUS_SERVICE');
    }
    return base;
  }
}
