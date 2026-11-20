import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';
import '../errors.dart';
import 'expense_validator.dart';

/// One member's share as the API shows it; the five breakdown fields are set for ITEMIZED only.
final class ShareComp {
  const ShareComp(this.memberId, this.owedMinor,
      {this.itemsMinor, this.discountMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor});
  final String memberId;
  final int owedMinor;
  final int? itemsMinor;
  final int? discountMinor;
  final int? serviceMinor;
  final int? taxMinor;
  final int? adjustmentMinor;
}

/// Everything the engine decided about a request (Java `ExpenseCalculator.Computation`). Itemized fields are null
/// for EQUAL/EXACT; for ITEMIZED a charge whose two form fields (`*Bps`, `*AmountMinor`) are both null is off (its
/// amount is then 0).
final class Computation {
  const Computation({
    required this.splitType,
    required this.totalMinor,
    required this.shares,
    required this.payers,
    this.subtotalMinor,
    this.discountBps,
    this.discountAmountMinor,
    this.discountMinor = 0,
    this.serviceBps,
    this.serviceAmountMinor,
    this.serviceMinor = 0,
    this.taxBps,
    this.taxAmountMinor,
    this.taxBase,
    this.taxMinor = 0,
    this.adjustmentMinor = 0,
  });

  final String splitType;
  final int totalMinor;
  final int? subtotalMinor;
  final int? discountBps;
  final int? discountAmountMinor;
  final int discountMinor;
  final int? serviceBps;
  final int? serviceAmountMinor;
  final int? taxAmountMinor;
  final int serviceMinor;
  final int? taxBps;
  final String? taxBase;
  final int taxMinor;
  final int adjustmentMinor;
  final List<ShareComp> shares;
  final List<Payer> payers;

  bool get itemized => splitType == 'ITEMIZED';

  bool get hasDiscount => discountBps != null || discountAmountMinor != null;

  bool get hasService => serviceBps != null || serviceAmountMinor != null;

  bool get hasTax => taxBps != null || taxAmountMinor != null;
}

/// The single mapping from a validated request to engine results (port of Java `ExpenseCalculator`). Create,
/// update and preview all go through [compute], so they cannot disagree on a number or a rule. Every money rule is
/// the engine's; this class maps member ids and engine errors only.
abstract final class ExpenseCalculator {
  /// [members] is the group roster. ACTIVE members are usable; a LEFT member is usable only when the stored expense
  /// already references it ([keptMemberIds], on update), otherwise it is MEMBER_INACTIVE.
  static Computation compute(ValidExpense request, List<MemberRow> members, {Set<String> keptMemberIds = const {}}) {
    final usable = <String, MemberRef>{};
    final inactive = <String>{};
    for (final m in members) {
      if (m.status == 'LEFT' && !keptMemberIds.contains(m.id)) {
        inactive.add(m.id);
      } else {
        usable[m.id] = MemberRef(m.id, m.sortOrder);
      }
    }
    final roster = _Roster(usable, inactive);
    // Payers are resolved first, outside the engine block (same order as Java).
    final payers = [for (final p in request.payers) Payer(roster.require(p.memberId), p.amountMinor)];
    try {
      final computed = switch (request.splitType) {
        'EQUAL' => _equal(request, roster, payers),
        'EXACT' => _exact(request, roster, payers),
        _ => _itemized(request, roster, payers),
      };
      // The engine computes an ITEMIZED total itself: it must respect the same cap as a stated one (CP2-001).
      if (!Limits.withinAmountLimit(computed.totalMinor)) {
        throw LocalApiException.validation('The bill total must be at most ${Limits.maxAmountMinor}');
      }
      return computed;
    } on EngineException catch (e) {
      throw LocalApiException.fromEngine(e);
    }
  }

  /// Create and update: the payers must add up to the total, otherwise PAYERS_TOTAL_MISMATCH (or another 422).
  static void requirePayersMatch(Computation c) {
    try {
      PayerValidator.validate(c.totalMinor, c.payers);
    } on EngineException catch (e) {
      throw LocalApiException.fromEngine(e);
    }
  }

  /// Preview: a mismatch (or no payers yet) is information for the UI, not an error. Other violations still fail.
  static bool payersMatch(Computation c) {
    if (c.payers.isEmpty) return false;
    try {
      PayerValidator.validate(c.totalMinor, c.payers);
      return true;
    } on EngineException catch (e) {
      if (e.code == EngineErrorCode.payersTotalMismatch) return false;
      throw LocalApiException.fromEngine(e);
    }
  }

  static Computation _equal(ValidExpense request, _Roster roster, List<Payer> payers) {
    final ids = request.participantMemberIds;
    final participants = ids == null
        ? roster.usable.values.toList() // "All": the usable members, a snapshot
        : [for (final id in ids) roster.usable[roster.require(id)]!];
    return _plain(request, roster, SplitCalculator.equal(request.totalMinor, participants), payers);
  }

  static Computation _exact(ValidExpense request, _Roster roster, List<Payer> payers) {
    final shares = [for (final s in request.shares!) Share(roster.require(s.memberId), s.amountMinor)];
    return _plain(request, roster, SplitCalculator.exact(request.totalMinor, shares), payers);
  }

  static Computation _plain(ValidExpense request, _Roster roster, Map<String, int> owed, List<Payer> payers) {
    final entries = owed.entries.toList()
      ..sort((a, b) => roster.usable[a.key]!.sortOrder.compareTo(roster.usable[b.key]!.sortOrder));
    return Computation(
      splitType: request.splitType,
      totalMinor: request.totalMinor,
      shares: [for (final e in entries) ShareComp(e.key, e.value)],
      payers: payers,
    );
  }

  static Computation _itemized(ValidExpense request, _Roster roster, List<Payer> payers) {
    // The validator normalized every item (quantity, unit price and line are set) and allowed one form per charge.
    final items = [
      for (final item in request.items!)
        Item.unit(item.name, item.quantity, item.unitAmountMinor,
            [for (final id in item.assigneeMemberIds) roster.require(id)]),
    ];
    final tax = !request.hasTax
        ? null
        : TaxSpec.of(ChargeSpec.of(request.taxBps, request.taxAmountMinor), TaxBase.fromWire(request.taxBase!));
    final r = ItemizedCalculator.calculate(ItemizedInput.charges(
      roster.usable.values.toList(),
      items,
      discount: _spec(request.discountBps, request.discountAmountMinor),
      service: _spec(request.serviceBps, request.serviceAmountMinor),
      tax: tax,
      adjustmentMinor: request.adjustmentMinor,
    ));
    if (request.totalMinor != 0 && request.totalMinor != r.totalMinor) {
      throw const LocalApiException(422, 'SPLIT_TOTAL_MISMATCH', 'totalMinor does not match the computed bill total');
    }
    return Computation(
      splitType: 'ITEMIZED',
      totalMinor: r.totalMinor,
      subtotalMinor: r.subtotalMinor,
      discountBps: request.discountBps,
      discountAmountMinor: request.discountAmountMinor,
      discountMinor: r.discountMinor,
      serviceBps: request.serviceBps,
      serviceAmountMinor: request.serviceAmountMinor,
      serviceMinor: r.serviceMinor,
      taxBps: request.taxBps,
      taxAmountMinor: request.taxAmountMinor,
      taxBase: request.taxBase,
      taxMinor: r.taxMinor,
      adjustmentMinor: r.adjustmentMinor,
      shares: [
        for (final m in r.members)
          ShareComp(
            m.memberId,
            m.owedMinor,
            itemsMinor: m.itemsMinor,
            discountMinor: m.discountMinor,
            serviceMinor: m.serviceMinor,
            taxMinor: m.taxMinor,
            adjustmentMinor: m.adjustmentMinor,
          ),
      ],
      payers: payers,
    );
  }
}

/// Both null = the charge is off; the validator already refused both forms at once.
ChargeSpec? _spec(int? bps, int? amountMinor) =>
    bps == null && amountMinor == null ? null : ChargeSpec.of(bps, amountMinor);

final class _Roster {
  _Roster(this.usable, this.inactive);

  /// Usable members in roster (sortOrder) order.
  final Map<String, MemberRef> usable;
  final Set<String> inactive;

  /// Every referenced member must belong to the group (spec 6 notes).
  String require(String memberId) {
    if (inactive.contains(memberId)) {
      throw LocalApiException.unprocessable('MEMBER_INACTIVE', 'This member has left the group');
    }
    if (!usable.containsKey(memberId)) {
      throw LocalApiException.unprocessable('MEMBER_NOT_IN_GROUP', 'A referenced member is not part of this group');
    }
    return memberId;
  }
}
