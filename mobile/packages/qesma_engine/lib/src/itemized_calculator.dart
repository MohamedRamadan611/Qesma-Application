import 'bps.dart';
import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'lrm.dart';
import 'values.dart';

/// Which amount the tax rate applies to (spec 7.4, Decision A1). [wireName] is the API/fixture spelling.
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

/// Tax rate in basis points; a null [base] defaults to [TaxBase.subtotalPlusService].
final class TaxSpec {
  const TaxSpec(this.bps, [TaxBase? base]) : base = base ?? TaxBase.subtotalPlusService;

  final int bps;
  final TaxBase base;

  @override
  bool operator ==(Object other) => other is TaxSpec && other.bps == bps && other.base == base;

  @override
  int get hashCode => Object.hash(bps, base);
}

final class Item {
  const Item(this.name, this.amountMinor, this.assigneeMemberIds);

  final String name;
  final int amountMinor;
  final List<String> assigneeMemberIds;
}

/// [members] is the group roster (provides sortOrder for every id that may appear); [serviceBps] null =
/// service disabled; [tax] null = tax disabled; [adjustmentMinor] is a signed rounding/tip adjustment, 0 = none.
final class ItemizedInput {
  const ItemizedInput(this.members, this.items, this.serviceBps, this.tax, this.adjustmentMinor);

  final List<MemberRef> members;
  final List<Item> items;
  final int? serviceBps;
  final TaxSpec? tax;
  final int adjustmentMinor;
}

final class MemberBreakdown {
  const MemberBreakdown(
      this.memberId, this.itemsMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor, this.owedMinor);

  final String memberId;
  final int itemsMinor;
  final int serviceMinor;
  final int taxMinor;
  final int adjustmentMinor;
  final int owedMinor;

  @override
  bool operator ==(Object other) =>
      other is MemberBreakdown &&
      other.memberId == memberId &&
      other.itemsMinor == itemsMinor &&
      other.serviceMinor == serviceMinor &&
      other.taxMinor == taxMinor &&
      other.adjustmentMinor == adjustmentMinor &&
      other.owedMinor == owedMinor;

  @override
  int get hashCode => Object.hash(memberId, itemsMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor);

  @override
  String toString() => 'MemberBreakdown($memberId, items $itemsMinor, service $serviceMinor, tax $taxMinor, '
      'adjustment $adjustmentMinor, owed $owedMinor)';
}

/// [members] are in sortOrder; those who owe 0 are omitted (spec 7.4 step 6).
final class ItemizedResult {
  ItemizedResult(this.subtotalMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor, this.totalMinor,
      List<MemberBreakdown> members)
      : members = List.unmodifiable(members);

  final int subtotalMinor;
  final int serviceMinor;
  final int taxMinor;
  final int adjustmentMinor;
  final int totalMinor;
  final List<MemberBreakdown> members;

  @override
  bool operator ==(Object other) =>
      other is ItemizedResult &&
      other.subtotalMinor == subtotalMinor &&
      other.serviceMinor == serviceMinor &&
      other.taxMinor == taxMinor &&
      other.adjustmentMinor == adjustmentMinor &&
      other.totalMinor == totalMinor &&
      listEquals(other.members, members);

  @override
  int get hashCode =>
      Object.hash(subtotalMinor, serviceMinor, taxMinor, adjustmentMinor, totalMinor, Object.hashAll(members));

  @override
  String toString() => 'ItemizedResult(subtotal $subtotalMinor, service $serviceMinor, tax $taxMinor, '
      'adjustment $adjustmentMinor, total $totalMinor, $members)';
}

/// ITEMIZED restaurant-bill split (spec 7.4). Port of the Java `ItemizedCalculator`.
abstract final class ItemizedCalculator {
  /// Runs spec 7.4 steps 1-6. Step 7 (payers) is checked separately by `PayerValidator`.
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
    final serviceBps = input.serviceBps;
    final tax = input.tax;
    if (serviceBps != null) {
      _checkBps(serviceBps);
    }
    if (tax != null) {
      _checkBps(tax.bps);
    }

    // Step 1: item shares, equal LRM among each item's assignees.
    final itemsMinor = List<int>.filled(n, 0);
    var subtotal = 0;
    for (final item in input.items) {
      if (item.amountMinor <= 0) {
        throw EngineException.invalid('Item amounts must be greater than zero');
      }
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
      final shares = Lrm.allocate(
          item.amountMinor, List<int>.filled(idx.length, 1), [for (final i in idx) sortOrders[i]]);
      for (var k = 0; k < idx.length; k++) {
        itemsMinor[idx[k]] = Exact.add(itemsMinor[idx[k]], shares[k]);
      }
      subtotal = Exact.add(subtotal, item.amountMinor);
    }

    // Step 2: service, allocated by each member's items.
    var serviceTotal = 0;
    var serviceMinor = List<int>.filled(n, 0);
    if (serviceBps != null) {
      serviceTotal = Bps.percentOf(subtotal, serviceBps);
      serviceMinor = Lrm.allocate(serviceTotal, itemsMinor, sortOrders);
    }

    // Step 3: tax, allocated by each member's own base.
    var taxTotal = 0;
    var taxMinor = List<int>.filled(n, 0);
    if (tax != null) {
      final baseWeights = List<int>.of(itemsMinor);
      var baseTotal = subtotal;
      if (tax.base == TaxBase.subtotalPlusService) {
        baseTotal = Exact.add(subtotal, serviceTotal);
        for (var i = 0; i < n; i++) {
          baseWeights[i] = Exact.add(itemsMinor[i], serviceMinor[i]);
        }
      }
      taxTotal = Bps.percentOf(baseTotal, tax.bps);
      taxMinor = Lrm.allocate(taxTotal, baseWeights, sortOrders);
    }

    // Step 4: signed adjustment, allocated by item subtotals (Lrm applies the sign afterwards).
    final adjustment = input.adjustmentMinor;
    var adjustmentMinor = List<int>.filled(n, 0);
    if (adjustment != 0) {
      adjustmentMinor = Lrm.allocate(adjustment, itemsMinor, sortOrders);
    }

    // Step 5: owed per member and total; total must be > 0.
    final total = Exact.add(Exact.add(subtotal, serviceTotal), Exact.add(taxTotal, adjustment));
    if (total <= 0) {
      throw EngineException.invalid('The bill total must be greater than zero');
    }
    final breakdown = <MemberBreakdown>[];
    var owedSum = 0;
    for (var i = 0; i < n; i++) {
      final owed =
          Exact.add(Exact.add(itemsMinor[i], serviceMinor[i]), Exact.add(taxMinor[i], adjustmentMinor[i]));
      if (owed < 0) {
        // Decision A12 (B3 review): an adjustment must never make one member's share negative.
        throw EngineException.invalid("The adjustment makes a member's share negative");
      }
      owedSum = Exact.add(owedSum, owed);
      if (owed != 0) {
        // Step 6: members owing 0 are not participants.
        breakdown.add(
            MemberBreakdown(roster[i].id, itemsMinor[i], serviceMinor[i], taxMinor[i], adjustmentMinor[i], owed));
      }
    }
    if (owedSum != total) {
      throw StateError('Engine invariant violated: owed does not sum to total');
    }
    return ItemizedResult(subtotal, serviceTotal, taxTotal, adjustment, total, breakdown);
  }

  static void _checkBps(int bps) {
    if (bps < 0 || bps > Bps.maxBps) {
      throw EngineException.invalid('Basis points must be between 0 and ${Bps.maxBps}');
    }
  }
}
