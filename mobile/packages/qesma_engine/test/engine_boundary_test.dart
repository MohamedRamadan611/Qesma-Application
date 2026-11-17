import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Boundaries of the product: every amount <= 10^12 piasters (Limits), lists of up to 100 members/items.
void main() {
  const max = Limits.maxAmountMinor; // 10^12
  final hundred = roster(100);

  test('the maximum amount split equally among 100 members', () {
    final owed = SplitCalculator.equal(max, hundred);
    expect(owed.length, 100);
    expect(sumOf(owed.values), max);
    expect(owed.values.toSet(), {10000000000});
    final odd = SplitCalculator.equal(max - 1, hundred); // 99 leftover units -> sortOrder 1..99
    expect(odd['m0'], 10000000000);
    expect(odd['m98'], 10000000000);
    expect(odd['m99'], 9999999999);
  });

  test('LRM with total and weights at 10^12 (products near 10^24 need BigInt)', () {
    final weights = [for (var i = 0; i < 100; i++) max - i * 7919];
    final order = [for (var i = 1; i <= 100; i++) i];
    final parts = Lrm.allocate(max, weights, order);
    expect(sumOf(parts), max);
    final negative = Lrm.allocate(-max, weights, order);
    expect(negative, [for (final p in parts) -p]);
  });

  test('100 items of 10^12 among 100 members with 100% service and 100% tax', () {
    final items = [
      for (var i = 0; i < 100; i++) Item('item$i', max, [for (var k = 0; k <= i % 7; k++) 'm${(i + k * 13) % 100}']),
    ];
    final r = ItemizedCalculator.calculate(
        ItemizedInput(hundred, items, Bps.maxBps, const TaxSpec(Bps.maxBps, TaxBase.subtotalPlusService), 0));
    expect(r.subtotalMinor, 100 * max);
    expect(r.serviceMinor, 100 * max);
    expect(r.taxMinor, 200 * max);
    expect(r.totalMinor, 400 * max);
    expect(sumOf(r.members.map((m) => m.owedMinor)), r.totalMinor);
    expect(r.members.every((m) => m.owedMinor > 0), isTrue);
  });

  test('100 maximal expenses and settlements give nets that sum to zero and settle', () {
    final expenses = [
      for (var i = 0; i < 100; i++)
        ExpenseLedgerEntry([Payer('m$i', max)], SplitCalculator.equal(max, [hundred[(i + 1) % 100], hundred[(i + 50) % 100]])),
    ];
    final settlements = [for (var i = 0; i < 100; i++) SettlementEntry('m$i', 'm${(i + 3) % 100}', max)];
    final nets = BalanceCalculator.nets(hundred, expenses, settlements);
    expect(sumOf(nets.values), 0);
    final after = Map<String, int>.of(nets);
    for (final t in Simplifier.simplify(nets, hundred)) {
      after[t.fromMemberId] = after[t.fromMemberId]! + t.amountMinor;
      after[t.toMemberId] = after[t.toMemberId]! - t.amountMinor;
    }
    expect(after.values.every((v) => v == 0), isTrue);
  });

  test('payers at the limit across 100 members', () {
    final payers = [for (var i = 0; i < 100; i++) Payer('m$i', max)];
    PayerValidator.validate(100 * max, payers);
  });

  test('the amount limit is inclusive', () {
    expect(Limits.withinAmountLimit(max), isTrue);
    expect(Limits.withinAmountLimit(max + 1), isFalse);
  });
}
