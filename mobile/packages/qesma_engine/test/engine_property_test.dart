import 'dart:math';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Property tests (port of EnginePropertyTest plus the SA1 additions). Each round derives everything from a
/// fixed seed, so a failure is reproducible from the seed in the reason. No property-testing dependency.
void main() {
  test('LRM parts sum exactly, stay within one unit of the exact share, and are deterministic', () {
    for (var seed = 0; seed < 5000; seed++) {
      final rnd = Random(seed);
      final total = _between(rnd, -1000000000000, 1000000000000);
      final n = 1 + rnd.nextInt(20);
      final weights = [for (var i = 0; i < n; i++) rnd.nextInt(4) == 0 ? 0 : rnd.nextInt(1000000001)];
      final order = [for (var i = 0; i < n; i++) i];

      final parts = Lrm.allocate(total, weights, order);

      var sum = BigInt.zero;
      for (final w in weights) {
        sum += BigInt.from(w);
      }
      final equalFallback = sum == BigInt.zero;
      if (equalFallback) sum = BigInt.from(n);
      for (var i = 0; i < n; i++) {
        final weight = BigInt.from(equalFallback ? 1 : weights[i]);
        final diff = (BigInt.from(parts[i]) * sum - BigInt.from(total) * weight).abs();
        expect(diff < sum, isTrue, reason: 'seed $seed part $i off by a full unit or more');
      }
      expect(sumOf(parts), total, reason: 'seed $seed');
      expect(Lrm.allocate(total, weights, order), parts, reason: 'seed $seed deterministic');
      expect(Lrm.allocate(-total, weights, order), [for (final p in parts) -p], reason: 'seed $seed symmetric');
    }
  });

  test('EQUAL and EXACT shares sum to the total', () {
    for (var seed = 0; seed < 2000; seed++) {
      final rnd = Random(seed);
      final members = roster(1 + rnd.nextInt(30));
      final total = 1 + rnd.nextInt(5000000);
      final subset = _nonEmptySubset(rnd, members)..shuffle(rnd);
      final equal = SplitCalculator.equal(total, subset);
      expect(sumOf(equal.values), total, reason: 'seed $seed');
      expect(equal.values.every((v) => v >= 0), isTrue, reason: 'seed $seed');
      expect(SplitCalculator.equal(total, subset), equal, reason: 'seed $seed deterministic');

      final shares = [for (final m in subset) Share(m.id, rnd.nextInt(1000000))];
      final exactTotal = sumOf(shares.map((s) => s.amountMinor));
      if (exactTotal > 0) {
        expect(sumOf(SplitCalculator.exact(exactTotal, shares).values), exactTotal, reason: 'seed $seed');
      }
    }
  });

  test('ITEMIZED owed sums to the total, nobody owes a negative amount, for any service/tax/adjustment', () {
    for (var seed = 0; seed < 3000; seed++) {
      final rnd = Random(seed);
      final members = roster(2 + rnd.nextInt(7));
      final adjustment = rnd.nextInt(20001) - 10000;
      final input = ItemizedInput(
        members,
        _randomItems(rnd, members),
        rnd.nextBool() ? null : rnd.nextInt(3001),
        rnd.nextBool()
            ? null
            : TaxSpec(rnd.nextInt(3001), rnd.nextBool() ? TaxBase.subtotal : TaxBase.subtotalPlusService),
        adjustment,
      );
      final ItemizedResult r;
      try {
        r = ItemizedCalculator.calculate(input);
      } on EngineException catch (e) {
        // Only a negative adjustment can legitimately push the total (or a share) to <= 0.
        expect(e.code, EngineErrorCode.validationError, reason: 'seed $seed');
        expect(adjustment, isNegative, reason: 'seed $seed');
        continue;
      }
      expect(sumOf(r.members.map((m) => m.owedMinor)), r.totalMinor, reason: 'seed $seed');
      expect(r.totalMinor, r.subtotalMinor + r.serviceMinor + r.taxMinor + adjustment, reason: 'seed $seed');
      expect(r.members.every((m) => m.owedMinor > 0), isTrue, reason: 'seed $seed');
      expect(ItemizedCalculator.calculate(input), r, reason: 'seed $seed deterministic');
    }
  });

  test('nets sum to zero and the simplified transfers settle everything', () {
    for (var seed = 0; seed < 3000; seed++) {
      final rnd = Random(seed);
      final members = roster(2 + rnd.nextInt(7));
      final expenses = [for (var i = 0, n = 1 + rnd.nextInt(10); i < n; i++) _randomExpense(rnd, members)];
      final settlements = <SettlementEntry>[];
      for (var i = 0, n = rnd.nextInt(6); i < n; i++) {
        final from = rnd.nextInt(members.length);
        final to = (from + 1 + rnd.nextInt(members.length - 1)) % members.length;
        settlements.add(SettlementEntry(members[from].id, members[to].id, 1 + rnd.nextInt(1000000)));
      }

      final nets = BalanceCalculator.nets(members, expenses, settlements);
      expect(sumOf(nets.values), 0, reason: 'seed $seed');

      final transfers = Simplifier.simplify(nets, members);
      expect(transfers.length, lessThanOrEqualTo(members.length - 1), reason: 'seed $seed');
      final after = Map<String, int>.of(nets);
      for (final t in transfers) {
        expect(t.amountMinor, isPositive, reason: 'seed $seed');
        after[t.fromMemberId] = after[t.fromMemberId]! + t.amountMinor;
        after[t.toMemberId] = after[t.toMemberId]! - t.amountMinor;
      }
      expect(after.values.every((v) => v == 0), isTrue, reason: 'seed $seed');
      expect(Simplifier.simplify(nets, members), transfers, reason: 'seed $seed deterministic');
      expect(BalanceCalculator.nets(members, expenses, settlements), nets, reason: 'seed $seed deterministic');
    }
  });
}

/// Uniform-enough value in [lo, hi] built from two 32-bit draws (Random.nextInt is limited to 2^32).
int _between(Random rnd, int lo, int hi) {
  final raw = rnd.nextInt(1 << 31) * (1 << 32) + rnd.nextInt(1 << 32); // 0 .. 2^63-1
  return lo + raw % (hi - lo + 1);
}

List<MemberRef> _nonEmptySubset(Random rnd, List<MemberRef> members) {
  final subset = [for (final m in members) if (rnd.nextBool()) m];
  if (subset.isEmpty) subset.add(members[rnd.nextInt(members.length)]);
  return subset;
}

List<Item> _randomItems(Random rnd, List<MemberRef> members) {
  final items = <Item>[];
  for (var i = 0, count = 1 + rnd.nextInt(6); i < count; i++) {
    final assignees = [for (final m in members) if (rnd.nextInt(3) == 0) m.id];
    if (assignees.isEmpty) assignees.add(members[rnd.nextInt(members.length)].id);
    items.add(Item('item$i', 1 + rnd.nextInt(500000), assignees));
  }
  return items;
}

ExpenseLedgerEntry _randomExpense(Random rnd, List<MemberRef> members) {
  final int total;
  final Map<String, int> owed;
  switch (rnd.nextInt(3)) {
    case 0:
      total = 1 + rnd.nextInt(5000000);
      owed = SplitCalculator.equal(total, _nonEmptySubset(rnd, members));
    case 1:
      final shares = [for (final m in _nonEmptySubset(rnd, members)) Share(m.id, 1 + rnd.nextInt(1000000))];
      total = sumOf(shares.map((s) => s.amountMinor));
      owed = SplitCalculator.exact(total, shares);
    default:
      final r = ItemizedCalculator.calculate(ItemizedInput(members, _randomItems(rnd, members),
          rnd.nextBool() ? null : 1200, rnd.nextBool() ? null : const TaxSpec(1400, TaxBase.subtotalPlusService), 0));
      total = r.totalMinor;
      owed = {for (final m in r.members) m.memberId: m.owedMinor};
  }
  return ExpenseLedgerEntry(_randomPayers(rnd, members, total), owed);
}

/// Payers need not be participants (spec 7.5); amounts are positive and sum to the total.
List<Payer> _randomPayers(Random rnd, List<MemberRef> members, int total) {
  final chosen = _nonEmptySubset(rnd, members);
  final parts = Lrm.allocate(
      total, [for (var i = 0; i < chosen.length; i++) 1 + rnd.nextInt(100)], [for (final m in chosen) m.sortOrder]);
  final payers = [
    for (var i = 0; i < parts.length; i++)
      if (parts[i] > 0) Payer(chosen[i].id, parts[i]),
  ];
  PayerValidator.validate(total, payers);
  return payers;
}
