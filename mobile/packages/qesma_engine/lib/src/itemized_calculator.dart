import 'bps.dart';
import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'limits.dart';
import 'lrm.dart';
import 'values.dart';

/// Which amount the tax rate applies to (spec 7.4, Decision A1); in the amount form it sets the weights only.
/// [wireName] is the API/fixture spelling.
enum TaxBase {
  subtotal('SUBTOTAL'),
  subtotalPlusService('SUBTOTAL_PLUS_SERVICE');

  const TaxBase(this.wireName);

  final String wireName;

  static TaxBase fromWire(String wireName) {
    for (final b in values) {
      if (b.wireName == wireName) return b;
    }
    throw EngineException.invalid('Unknown tax base');
  }
}

/// A charge (discount, service or tax) given either as a percentage in basis points or as an amount in piasters,
/// never both and never neither (A171, A173, A177). Ranges are checked by [ItemizedCalculator.calculate].
/// Port of the Java `ItemizedCalculator.ChargeSpec`.
final class ChargeSpec {
  const ChargeSpec.percent(int this.bps) : amountMinor = null;

  const ChargeSpec.amount(int this.amountMinor) : bps = null;

  /// The request shape rule: exactly one of [bps] and [amountMinor].
  factory ChargeSpec.of(int? bps, int? amountMinor) {
    if ((bps == null) == (amountMinor == null)) {
      throw EngineException.invalid('A charge needs either bps or amountMinor, not both');
    }
    return bps != null ? ChargeSpec.percent(bps) : ChargeSpec.amount(amountMinor!);
  }

  final int? bps;
  final int? amountMinor;

  bool get isPercent => bps != null;

  /// The charge total on [base]: `round_half_up(base x bps / 10000)` or the stated amount.
  int totalOn(int base) => isPercent ? Bps.percentOf(base, bps!) : amountMinor!;

  @override
  bool operator ==(Object other) => other is ChargeSpec && other.bps == bps && other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(bps, amountMinor);

  @override
  String toString() => isPercent ? 'ChargeSpec($bps bps)' : 'ChargeSpec($amountMinor minor)';
}

/// Tax as a rate ([TaxSpec.new], spec 7.4) or an amount ([TaxSpec.amount], A173); a null [base] defaults to
/// [TaxBase.subtotalPlusService].
final class TaxSpec {
  const TaxSpec(int this.bps, [TaxBase? base])
      : amountMinor = null,
        base = base ?? TaxBase.subtotalPlusService;

  const TaxSpec.amount(int this.amountMinor, [TaxBase? base])
      : bps = null,
        base = base ?? TaxBase.subtotalPlusService;

  factory TaxSpec.of(ChargeSpec rate, [TaxBase? base]) =>
      rate.isPercent ? TaxSpec(rate.bps!, base) : TaxSpec.amount(rate.amountMinor!, base);

  /// Null in the amount form.
  final int? bps;

  /// Null in the percent form.
  final int? amountMinor;
  final TaxBase base;

  ChargeSpec get rate => ChargeSpec.of(bps, amountMinor);

  @override
  bool operator ==(Object other) =>
      other is TaxSpec && other.bps == bps && other.amountMinor == amountMinor && other.base == base;

  @override
  int get hashCode => Object.hash(bps, amountMinor, base);
}

/// One bill line: `quantity x unitAmountMinor`, split equally among its assignees (A172).
final class Item {
  /// A legacy line given by its amount: quantity 1.
  const Item(this.name, int amountMinor, this.assigneeMemberIds)
      : quantity = 1,
        unitAmountMinor = amountMinor;

  const Item.unit(this.name, this.quantity, this.unitAmountMinor, this.assigneeMemberIds);

  /// The request shape rule (A172, A177): either a legacy [amountMinor] (quantity 1, no [quantity]), or
  /// [unitAmountMinor] with an optional [quantity] (default 1). Ranges are checked by [ItemizedCalculator.calculate].
  factory Item.of(String name, List<String> assigneeMemberIds,
      {int? amountMinor, int? unitAmountMinor, int? quantity}) {
    if (amountMinor != null && unitAmountMinor != null) {
      throw EngineException.invalid('An item has either amountMinor or unitAmountMinor, not both');
    }
    if (amountMinor != null) {
      if (quantity != null) {
        throw EngineException.invalid('quantity goes with unitAmountMinor, not with amountMinor');
      }
      return Item.unit(name, 1, amountMinor, assigneeMemberIds);
    }
    if (unitAmountMinor == null) {
      throw EngineException.invalid('An item needs amountMinor or unitAmountMinor');
    }
    return Item.unit(name, quantity ?? 1, unitAmountMinor, assigneeMemberIds);
  }

  /// Item quantity bounds (A172).
  static const int minQuantity = 1;
  static const int maxQuantity = 999;

  final String name;
  final int quantity;
  final int unitAmountMinor;
  final List<String> assigneeMemberIds;

  /// The line amount, computed exactly; overflow is a VALIDATION_ERROR (A13).
  int get amountMinor => Exact.multiply(quantity, unitAmountMinor);

  @override
  bool operator ==(Object other) =>
      other is Item &&
      other.name == name &&
      other.quantity == quantity &&
      other.unitAmountMinor == unitAmountMinor &&
      listEquals(other.assigneeMemberIds, assigneeMemberIds);

  @override
  int get hashCode => Object.hash(name, quantity, unitAmountMinor, Object.hashAll(assigneeMemberIds));

  @override
  String toString() => 'Item($name, $quantity x $unitAmountMinor, $assigneeMemberIds)';
}

/// [members] is the group roster (provides sortOrder for every id that may appear); [adjustmentMinor] is a signed
/// rounding/tip adjustment, 0 = none. A null charge is off.
final class ItemizedInput {
  /// Spec 7.4 input: service as a rate ([serviceBps] null = no service), no discount.
  const ItemizedInput(this.members, this.items, this.serviceBps, this.tax, this.adjustmentMinor)
      : discount = null,
        _service = null;

  /// STANDALONE_SPEC 18 input: every charge in either form.
  const ItemizedInput.charges(this.members, this.items,
      {this.discount, ChargeSpec? service, this.tax, this.adjustmentMinor = 0})
      : serviceBps = null,
        _service = service;

  final List<MemberRef> members;
  final List<Item> items;
  final ChargeSpec? discount;

  /// Only set by the spec 7.4 constructor; read [service].
  final int? serviceBps;
  final ChargeSpec? _service;
  final TaxSpec? tax;
  final int adjustmentMinor;

  ChargeSpec? get service => _service ?? (serviceBps == null ? null : ChargeSpec.percent(serviceBps!));
}

/// owed = items - discount + service + tax + adjustment.
final class MemberBreakdown {
  const MemberBreakdown(
      this.memberId, this.itemsMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor, this.owedMinor,
      {this.discountMinor = 0});

  final String memberId;
  final int itemsMinor;
  final int discountMinor;
  final int serviceMinor;
  final int taxMinor;
  final int adjustmentMinor;
  final int owedMinor;

  @override
  bool operator ==(Object other) =>
      other is MemberBreakdown &&
      other.memberId == memberId &&
      other.itemsMinor == itemsMinor &&
      other.discountMinor == discountMinor &&
      other.serviceMinor == serviceMinor &&
      other.taxMinor == taxMinor &&
      other.adjustmentMinor == adjustmentMinor &&
      other.owedMinor == owedMinor;

  @override
  int get hashCode =>
      Object.hash(memberId, itemsMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor);

  @override
  String toString() => 'MemberBreakdown($memberId, items $itemsMinor, discount $discountMinor, service $serviceMinor, '
      'tax $taxMinor, adjustment $adjustmentMinor, owed $owedMinor)';
}

/// [members] are in sortOrder; those who owe 0 are omitted (spec 7.4 step 6). [subtotalMinor] is the sum of the
/// lines before the discount; total = subtotal - discount + service + tax + adjustment.
final class ItemizedResult {
  ItemizedResult(this.subtotalMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor, this.totalMinor,
      List<MemberBreakdown> members, {this.discountMinor = 0})
      : members = List.unmodifiable(members);

  final int subtotalMinor;
  final int discountMinor;
  final int serviceMinor;
  final int taxMinor;
  final int adjustmentMinor;
  final int totalMinor;
  final List<MemberBreakdown> members;

  @override
  bool operator ==(Object other) =>
      other is ItemizedResult &&
      other.subtotalMinor == subtotalMinor &&
      other.discountMinor == discountMinor &&
      other.serviceMinor == serviceMinor &&
      other.taxMinor == taxMinor &&
      other.adjustmentMinor == adjustmentMinor &&
      other.totalMinor == totalMinor &&
      listEquals(other.members, members);

  @override
  int get hashCode => Object.hash(
      subtotalMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, totalMinor, Object.hashAll(members));

  @override
  String toString() => 'ItemizedResult(subtotal $subtotalMinor, discount $discountMinor, service $serviceMinor, '
      'tax $taxMinor, adjustment $adjustmentMinor, total $totalMinor, $members)';
}

/// ITEMIZED restaurant-bill split (spec 7.4, extended by STANDALONE_SPEC 18: bill discount, item quantity, service
/// and tax as amounts). Port of the Java `ItemizedCalculator`; a bill without the extensions computes as spec 7.4.
abstract final class ItemizedCalculator {
  /// A discount percentage is 0.01% .. 99.99% (A171): 100% would make the bill free.
  static const int maxDiscountBps = Bps.maxBps - 1;

  /// Runs STANDALONE_SPEC 18.2 (spec 7.4 steps 1-6). Payers are checked separately by `PayerValidator`.
  static ItemizedResult calculate(ItemizedInput input) {
    final roster = stableSortedBy(input.members, (m) => m.sortOrder); // ties keep input order, like Java
    final n = roster.length;
    if (n == 0) {
      throw EngineException.invalid('The member roster is empty');
    }
    final index = <String, int>{};
    final sortOrders = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      if (index.containsKey(roster[i].id)) {
        throw EngineException.invalid('Duplicate member in roster');
      }
      index[roster[i].id] = i;
      sortOrders[i] = roster[i].sortOrder;
    }
    if (input.items.isEmpty) {
      throw EngineException.invalid('At least one item is required');
    }
    final discount = input.discount;
    final service = input.service;
    final tax = input.tax;
    if (discount != null) {
      _checkCharge(discount, 1, maxDiscountBps, 'discount');
    }
    if (service != null) {
      _checkCharge(service, 0, Bps.maxBps, 'service');
    }
    if (tax != null) {
      _checkCharge(tax.rate, 0, Bps.maxBps, 'tax');
    }

    // Step 1: item shares, equal LRM among each item's assignees.
    final itemsMinor = List<int>.filled(n, 0);
    var subtotal = 0;
    for (final item in input.items) {
      final line = _lineAmount(item);
      final ids = item.assigneeMemberIds;
      if (ids.isEmpty) {
        throw EngineException.invalid('Every item needs at least one assignee');
      }
      final seen = <String>{};
      final idx = <int>[];
      for (final id in ids) {
        final i = index[id];
        if (i == null) {
          throw EngineException(EngineErrorCode.memberNotInGroup, 'Item assignee is not in the group');
        }
        if (!seen.add(id)) {
          throw EngineException.invalid('Duplicate assignee on an item');
        }
        idx.add(i);
      }
      idx.sort();
      final shares = Lrm.allocate(line, List<int>.filled(idx.length, 1), [for (final i in idx) sortOrders[i]]);
      for (var k = 0; k < idx.length; k++) {
        itemsMinor[idx[k]] = Exact.add(itemsMinor[idx[k]], shares[k]);
      }
      subtotal = Exact.add(subtotal, line);
    }

    // Step 2: discount off the subtotal, allocated by each member's items (A171). Without one, net == items.
    var discountTotal = 0;
    var discountMinor = List<int>.filled(n, 0);
    if (discount != null) {
      discountTotal = discount.totalOn(subtotal);
      if (discountTotal <= 0 || discountTotal >= subtotal) {
        throw EngineException.invalid('The discount must be greater than zero and less than the subtotal');
      }
      discountMinor = Lrm.allocate(discountTotal, itemsMinor, sortOrders);
    }
    final netMinor = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      netMinor[i] = itemsMinor[i] - discountMinor[i];
      if (netMinor[i] < 0) {
        // Cannot happen: each LRM part of d < W is at most ceil(d * w / W) <= w.
        throw StateError("Engine invariant violated: a discount part exceeds the member's items");
      }
    }
    final netSubtotal = subtotal - discountTotal;

    // Step 3: service, allocated by each member's net.
    var serviceTotal = 0;
    var serviceMinor = List<int>.filled(n, 0);
    if (service != null) {
      serviceTotal = service.totalOn(netSubtotal);
      serviceMinor = Lrm.allocate(serviceTotal, netMinor, sortOrders);
    }

    // Step 4: tax, allocated by each member's own base (net, or net + service).
    var taxTotal = 0;
    var taxMinor = List<int>.filled(n, 0);
    if (tax != null) {
      final baseWeights = List<int>.of(netMinor);
      var baseTotal = netSubtotal;
      if (tax.base == TaxBase.subtotalPlusService) {
        baseTotal = Exact.add(netSubtotal, serviceTotal);
        for (var i = 0; i < n; i++) {
          baseWeights[i] = Exact.add(netMinor[i], serviceMinor[i]);
        }
      }
      taxTotal = tax.rate.totalOn(baseTotal);
      taxMinor = Lrm.allocate(taxTotal, baseWeights, sortOrders);
    }

    // Step 5: signed adjustment, allocated by net shares (Lrm applies the sign afterwards).
    final adjustment = input.adjustmentMinor;
    var adjustmentMinor = List<int>.filled(n, 0);
    if (adjustment != 0) {
      adjustmentMinor = Lrm.allocate(adjustment, netMinor, sortOrders);
    }

    // Step 6: owed per member and total; total must be > 0.
    final total = Exact.add(Exact.add(netSubtotal, serviceTotal), Exact.add(taxTotal, adjustment));
    if (total <= 0) {
      throw EngineException.invalid('The bill total must be greater than zero');
    }
    final breakdown = <MemberBreakdown>[];
    var owedSum = 0;
    var discountSum = 0;
    for (var i = 0; i < n; i++) {
      final owed = Exact.add(Exact.add(netMinor[i], serviceMinor[i]), Exact.add(taxMinor[i], adjustmentMinor[i]));
      if (owed < 0) {
        // Decision A12: an adjustment must never make one member's share negative.
        throw EngineException.invalid("The adjustment makes a member's share negative");
      }
      owedSum = Exact.add(owedSum, owed);
      discountSum = Exact.add(discountSum, discountMinor[i]);
      if (owed != 0) {
        // Members owing 0 are not participants.
        breakdown.add(MemberBreakdown(
            roster[i].id, itemsMinor[i], serviceMinor[i], taxMinor[i], adjustmentMinor[i], owed,
            discountMinor: discountMinor[i]));
      }
    }
    if (owedSum != total || discountSum != discountTotal) {
      throw StateError('Engine invariant violated: parts do not sum to their totals');
    }
    return ItemizedResult(subtotal, serviceTotal, taxTotal, adjustment, total, breakdown,
        discountMinor: discountTotal);
  }

  /// Quantity 1..999, unit price > 0, line within the A43 cap; overflow is a VALIDATION_ERROR (A13).
  static int _lineAmount(Item item) {
    if (item.quantity < Item.minQuantity || item.quantity > Item.maxQuantity) {
      throw EngineException.invalid('Item quantity must be between ${Item.minQuantity} and ${Item.maxQuantity}');
    }
    if (item.unitAmountMinor <= 0) {
      throw EngineException.invalid('Item amounts must be greater than zero');
    }
    final line = item.amountMinor;
    if (!Limits.withinAmountLimit(line)) {
      throw EngineException.invalid('An item line must be at most ${Limits.maxAmountMinor}');
    }
    return line;
  }

  /// Percent form within [minBps]..[maxBps]; amount form within 1..A43 cap.
  static void _checkCharge(ChargeSpec charge, int minBps, int maxBps, String field) {
    if (charge.isPercent) {
      if (charge.bps! < minBps || charge.bps! > maxBps) {
        throw EngineException.invalid('$field basis points must be between $minBps and $maxBps');
      }
    } else if (charge.amountMinor! < 1 || !Limits.withinAmountLimit(charge.amountMinor!)) {
      throw EngineException.invalid('$field amountMinor must be between 1 and ${Limits.maxAmountMinor}');
    }
  }
}
