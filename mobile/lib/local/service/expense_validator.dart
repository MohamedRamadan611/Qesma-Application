import 'package:qesma_engine/qesma_engine.dart';

import '../errors.dart';
import 'commands.dart';
import 'field_rules.dart';

/// An item after validation: name stripped, amount and assignees present.
final class ValidItem {
  const ValidItem(this.name, this.amountMinor, this.assigneeMemberIds);
  final String name;
  final int amountMinor;
  final List<String> assigneeMemberIds;
}

/// A payer or an EXACT share after validation.
final class ValidAmount {
  const ValidAmount(this.memberId, this.amountMinor);
  final String memberId;
  final int amountMinor;
}

/// A request that passed shape validation, with normalized text (Java `ExpenseValidator.Valid`).
/// [totalMinor] 0 means "not stated" (ITEMIZED only); [taxBase] is present exactly when [taxBps] is.
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
    this.taxBps,
    this.taxBase,
    this.adjustmentMinor = 0,
  });

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

  bool get itemized => splitType == 'ITEMIZED';
}

/// Shape validation of a create / preview / update expense body: a port of Java `ExpenseValidator` with the same
/// check order and limits (STANDALONE_SPEC 3.2). Money rules are not here; they are the engine's.
abstract final class ExpenseValidator {
  static const int maxTitle = 100;
  static const int maxItemName = 100;
  static const int maxList = 100;
  static const int maxBps = 10000;
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
    if (!itemized && type != 'EQUAL' && type != 'EXACT') {
      throw LocalApiException.validation('splitType must be EQUAL, EXACT or ITEMIZED');
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
      _ => _itemized(c, title, date, total, payers),
    };
  }

  static ValidExpense _equal(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectItemizedFields(c, 'EQUAL');
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
      participantMemberIds: participants?.cast<String>().toList(),
    );
  }

  static ValidExpense _exact(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    _rejectItemizedFields(c, 'EXACT');
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
      shares: valid,
    );
  }

  static ValidExpense _itemized(ExpenseIn c, String title, String date, int total, List<ValidAmount> payers) {
    if (c.participantMemberIds != null) {
      throw LocalApiException.validation('participantMemberIds is only allowed for EQUAL expenses');
    }
    if (c.shares != null) throw LocalApiException.validation('shares is only allowed for EXACT expenses');
    final items = c.items;
    if (items == null || items.isEmpty) throw LocalApiException.validation('items is required for ITEMIZED expenses');
    if (items.length > maxList) throw LocalApiException.validation('At most $maxList items are allowed');
    final clean = <ValidItem>[];
    for (final item in items) {
      if (item == null || item.amountMinor == null || item.assigneeMemberIds == null) {
        throw LocalApiException.validation('Every item needs name, amountMinor and assigneeMemberIds');
      }
      final name = FieldRules.name(item.name, maxItemName, 'item name');
      if (item.amountMinor! <= 0) throw LocalApiException.validation('Item amounts must be greater than zero');
      capped(item.amountMinor!, 'item amountMinor');
      final assignees = item.assigneeMemberIds!;
      if (assignees.isEmpty) throw LocalApiException.validation('Every item needs at least one assignee');
      if (assignees.length > maxList) {
        throw LocalApiException.validation('At most $maxList assignees per item are allowed');
      }
      if (assignees.any((a) => a == null)) {
        throw LocalApiException.validation('assigneeMemberIds must not contain null');
      }
      clean.add(ValidItem(name, item.amountMinor!, assignees.cast<String>().toList()));
    }
    int? serviceBps;
    if (c.hasService) serviceBps = _bps(c.serviceBps, 'service.bps');
    int? taxBps;
    String? taxBase;
    final tax = c.tax;
    if (tax != null) {
      taxBps = _bps(tax.bps, 'tax.bps');
      taxBase = _taxBase(tax.base);
    }
    final adjustment = c.adjustmentMinor ?? 0;
    if (adjustment > Limits.maxAmountMinor || adjustment < -Limits.maxAmountMinor) {
      throw LocalApiException.validation(
        'adjustmentMinor must be between -${Limits.maxAmountMinor} and ${Limits.maxAmountMinor}',
      );
    }
    return ValidExpense(
      title: title,
      expenseDate: date,
      splitType: 'ITEMIZED',
      totalMinor: total,
      payers: payers,
      category: category(c.category),
      items: clean,
      serviceBps: serviceBps,
      taxBps: taxBps,
      taxBase: taxBase,
      adjustmentMinor: adjustment,
    );
  }

  /// Every amount has an upper bound so ledger sums cannot overflow (CP2-001).
  static void capped(int amountMinor, String field) {
    if (!Limits.withinAmountLimit(amountMinor)) {
      throw LocalApiException.validation('$field must be at most ${Limits.maxAmountMinor}');
    }
  }

  static void _rejectItemizedFields(ExpenseIn c, String type) {
    if (c.items != null || c.hasService || c.tax != null || c.adjustmentMinor != null) {
      throw LocalApiException.validation(
        'items, service, tax and adjustmentMinor are only allowed for ITEMIZED expenses (this is $type)',
      );
    }
  }

  static int _bps(int? value, String field) {
    if (value == null || value < 0 || value > maxBps) {
      throw LocalApiException.validation('$field must be between 0 and $maxBps');
    }
    return value;
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
