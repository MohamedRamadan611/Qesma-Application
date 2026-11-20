import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Port of ItemizedCalculatorTest (spec 7.4). V5-V8 are also covered by the fixtures.
void main() {
  const abc = [MemberRef('A', 1), MemberRef('B', 2), MemberRef('C', 3)];

  List<Item> restaurant() => const [
        Item('Pizza', 20000, ['A', 'B']),
        Item('Pasta', 15000, ['C']),
        Item('Drinks', 9000, ['A', 'B', 'C']),
      ];

  int owed(ItemizedResult r, String id) =>
      sumOf(r.members.where((m) => m.memberId == id).map((m) => m.owedMinor));

  void expectValidation(ItemizedInput input) =>
      expect(() => ItemizedCalculator.calculate(input), throwsEngine(EngineErrorCode.validationError));

  test('service and tax match vector V5 with the breakdown', () {
    final r = ItemizedCalculator.calculate(
        ItemizedInput(abc, restaurant(), 1200, const TaxSpec(1400, TaxBase.subtotalPlusService), 0));
    expect(r.subtotalMinor, 44000);
    expect(r.serviceMinor, 5280);
    expect(r.taxMinor, 6899);
    expect(r.totalMinor, 56179);
    expect(r.members[0], const MemberBreakdown('A', 13000, 1560, 2039, 0, 16599));
  });

  test('tax without service is the same for both bases', () {
    final plusService = ItemizedCalculator.calculate(
        ItemizedInput(abc, restaurant(), null, const TaxSpec(1400, TaxBase.subtotalPlusService), 0));
    final subtotal = ItemizedCalculator.calculate(
        ItemizedInput(abc, restaurant(), null, const TaxSpec(1400, TaxBase.subtotal), 0));
    expect(plusService, subtotal);
  });

  test('tax base defaults to subtotal plus service', () {
    expect(const TaxSpec(1400).base, TaxBase.subtotalPlusService);
    expect(const TaxSpec(1400, null).base, TaxBase.subtotalPlusService);
    expect(TaxBase.fromWire('SUBTOTAL'), TaxBase.subtotal);
    expect(TaxBase.subtotalPlusService.wireName, 'SUBTOTAL_PLUS_SERVICE');
  });

  test('an item shared by seven splits exactly', () {
    final seven = [for (var i = 1; i <= 7; i++) MemberRef('$i', i)];
    final r = ItemizedCalculator.calculate(ItemizedInput(
        seven, const [Item('Feast', 10000, ['1', '2', '3', '4', '5', '6', '7'])], null, null, 0));
    expect(r.members.map((m) => m.owedMinor), [1429, 1429, 1429, 1429, 1428, 1428, 1428]);
    expect(r.totalMinor, 10000);
  });

  test('a negative adjustment is allocated by item subtotals and the sign applied', () {
    final r = ItemizedCalculator.calculate(const ItemizedInput(
        [MemberRef('A', 1), MemberRef('B', 2)],
        [Item('X', 10000, ['A']), Item('Y', 10000, ['B'])],
        null,
        null,
        -1001));
    expect(r.totalMinor, 18999);
    expect(r.adjustmentMinor, -1001);
    expect(owed(r, 'A'), 9499); // -501 (tie -> lowest sortOrder)
    expect(owed(r, 'B'), 9500); // -500
  });

  test('a positive adjustment is allocated proportionally', () {
    final r = ItemizedCalculator.calculate(const ItemizedInput(
        [MemberRef('A', 1), MemberRef('B', 2)],
        [Item('X', 10000, ['A']), Item('Y', 30000, ['B'])],
        null,
        null,
        400));
    expect(owed(r, 'A'), 10100);
    expect(owed(r, 'B'), 30300);
  });

  test('members with zero owed are dropped', () {
    final r = ItemizedCalculator.calculate(
        const ItemizedInput(abc, [Item('Solo', 5000, ['B'])], null, null, 0));
    expect(r.members.map((m) => m.memberId), ['B']);
  });

  test('the breakdown is in sortOrder whatever the roster order', () {
    final r = ItemizedCalculator.calculate(ItemizedInput(
        const [MemberRef('C', 3), MemberRef('A', 1), MemberRef('B', 2)], restaurant(), null, null, 0));
    expect(r.members.map((m) => m.memberId), ['A', 'B', 'C']);
  });

  test('the total must be positive', () {
    expectValidation(const ItemizedInput(abc, [Item('Solo', 5000, ['A'])], null, null, -5000));
  });

  test('rejects invalid input', () {
    expectValidation(const ItemizedInput(abc, [], null, null, 0));
    expectValidation(const ItemizedInput(abc, [Item('Zero', 0, ['A'])], null, null, 0));
    expectValidation(const ItemizedInput(abc, [Item('Nobody', 100, [])], null, null, 0));
    expectValidation(const ItemizedInput(abc, [Item('Dup', 100, ['A', 'A'])], null, null, 0));
    expectValidation(const ItemizedInput(abc, [Item('Ok', 100, ['A'])], 10001, null, 0));
    expectValidation(const ItemizedInput(abc, [Item('Ok', 100, ['A'])], null, TaxSpec(-1, TaxBase.subtotal), 0));
    expectValidation(const ItemizedInput(
        [MemberRef('A', 1), MemberRef('A', 2)], [Item('Ok', 100, ['A'])], null, null, 0));
    expectValidation(const ItemizedInput([], [Item('Ok', 100, ['A'])], null, null, 0));
  });

  test('an unknown assignee is MEMBER_NOT_IN_GROUP', () {
    expect(
        () => ItemizedCalculator.calculate(const ItemizedInput(abc, [Item('Ghost', 100, ['Z'])], null, null, 0)),
        throwsEngine(EngineErrorCode.memberNotInGroup));
  });

  test('huge item amounts fail with a typed error, not a wrap-around', () {
    expect(
        () => ItemizedCalculator.calculate(const ItemizedInput(
            abc, [Item('A', longMax, ['A']), Item('B', longMax, ['B'])], null, null, 0)),
        throwsAnyEngine);
  });

  // ---- SA15 (port of the BSA2 Java cases): discount, quantity, charges as amounts (STANDALONE_SPEC 18) ----------

  const ab = [MemberRef('A', 1), MemberRef('B', 2)];
  ItemizedInput meal(ChargeSpec discount) =>
      ItemizedInput.charges(ab, const [Item('Meal', 10000, ['A', 'B'])], discount: discount);
  void expectShape(void Function() call) => expect(call, throwsEngine(EngineErrorCode.validationError));

  test('the discount must be above zero and below the subtotal', () {
    expectValidation(meal(const ChargeSpec.amount(0)));
    expectValidation(meal(const ChargeSpec.amount(10000))); // equal to the subtotal (V15)
    expectValidation(meal(const ChargeSpec.amount(10001)));
    expectValidation(meal(const ChargeSpec.percent(0)));
    expectValidation(meal(const ChargeSpec.percent(10000))); // 100% (V15)
    final r = ItemizedCalculator.calculate(meal(const ChargeSpec.amount(9999))); // subtotal - 1 piaster
    expect(r.discountMinor, 9999);
    expect(r.totalMinor, 1);
    expect(ItemizedCalculator.calculate(meal(const ChargeSpec.percent(9999))).discountMinor, 9999);
  });

  test('a percent discount that rounds to zero piasters is rejected', () {
    // 1 bps of 10 piasters = 0.001 -> 0, which breaks 0 < discount (STANDALONE_SPEC 18.2 step 2).
    expectValidation(const ItemizedInput.charges(ab, [Item('Gum', 10, ['A'])], discount: ChargeSpec.percent(1)));
  });

  test('a discount can drop a member to zero (V14)', () {
    final r = ItemizedCalculator.calculate(meal(const ChargeSpec.amount(9999)));
    expect(r.members, [const MemberBreakdown('B', 5000, 0, 0, 0, 1, discountMinor: 4999)]);
  });

  test("a discount part never exceeds the member's items", () {
    final r = ItemizedCalculator.calculate(const ItemizedInput.charges(
        abc, [Item('Big', 99999, ['A']), Item('Tiny', 1, ['B']), Item('Mid', 3, ['C'])],
        discount: ChargeSpec.amount(100002)));
    for (final m in r.members) {
      expect(m.discountMinor, inInclusiveRange(0, m.itemsMinor));
    }
    expect(r.totalMinor, 1);
  });

  test('quantity boundaries', () {
    final one = ItemizedCalculator.calculate(const ItemizedInput.charges(ab, [Item.unit('Pepsi', 1, 1525, ['A'])]));
    expect(one.subtotalMinor, 1525);
    final max =
        ItemizedCalculator.calculate(const ItemizedInput.charges(ab, [Item.unit('Pepsi', 999, 1525, ['A', 'B'])]));
    expect(max.subtotalMinor, 999 * 1525);
    expectValidation(const ItemizedInput.charges(ab, [Item.unit('Pepsi', 0, 1525, ['A'])]));
    expectValidation(const ItemizedInput.charges(ab, [Item.unit('Pepsi', 1000, 1525, ['A'])]));
    expectValidation(const ItemizedInput.charges(ab, [Item.unit('Free', 2, 0, ['A'])]));
  });

  test('the line amount is capped and an overflow is a validation error', () {
    expectValidation(const ItemizedInput.charges(ab, [Item.unit('Yacht', 999, Limits.maxAmountMinor, ['A'])]));
    expectValidation(const ItemizedInput.charges(ab, [Item.unit('Overflow', 999, longMax, ['A'])]));
    final atCap =
        ItemizedCalculator.calculate(const ItemizedInput.charges(ab, [Item.unit('Cap', 1, Limits.maxAmountMinor, ['A'])]));
    expect(atCap.totalMinor, Limits.maxAmountMinor);
  });

  test('an item is either a legacy amount or a unit price with an optional quantity', () {
    expect(Item.of('X', ['A'], amountMinor: 500), const Item.unit('X', 1, 500, ['A']));
    expect(Item.of('X', ['A'], unitAmountMinor: 500), const Item.unit('X', 1, 500, ['A']));
    expect(Item.of('X', ['A'], unitAmountMinor: 500, quantity: 3).amountMinor, 1500);
    expectShape(() => Item.of('X', ['A'], amountMinor: 500, unitAmountMinor: 500)); // both (V16)
    expectShape(() => Item.of('X', ['A'])); // neither
    expectShape(() => Item.of('X', ['A'], amountMinor: 500, quantity: 2)); // quantity only goes with a unit price
  });

  test('a charge is either a percent or an amount', () {
    expect(ChargeSpec.of(1200, null), const ChargeSpec.percent(1200));
    expect(ChargeSpec.of(null, 5000), const ChargeSpec.amount(5000));
    expectShape(() => ChargeSpec.of(1200, 5000));
    expectShape(() => ChargeSpec.of(null, null));
  });

  test('charge amounts must be positive and within the cap', () {
    const items = [Item('X', 10000, ['A'])];
    expectValidation(const ItemizedInput.charges(ab, items, service: ChargeSpec.amount(0)));
    expectValidation(const ItemizedInput.charges(ab, items, tax: TaxSpec.amount(0, TaxBase.subtotal)));
    expectValidation(const ItemizedInput.charges(ab, items, service: ChargeSpec.amount(Limits.maxAmountMinor + 1)));
  });

  test('an amount-form tax on the subtotal is weighted by the net shares', () {
    final r = ItemizedCalculator.calculate(ItemizedInput.charges(abc, restaurant(),
        discount: const ChargeSpec.amount(5000),
        service: const ChargeSpec.percent(1200),
        tax: const TaxSpec.amount(5000, TaxBase.subtotal)));
    // Net 11523 / 11523 / 15954: the tax amount follows the discount allocation exactly (same weights' ratio).
    expect(r.members.map((m) => m.taxMinor), [1477, 1477, 2046]);
    expect(r.totalMinor, 44000 - 5000 + r.serviceMinor + 5000);
  });

  test('the adjustment is weighted by the net shares', () {
    // Net A 0, B 1 after the V14 discount: the whole adjustment goes to B.
    final r = ItemizedCalculator.calculate(const ItemizedInput.charges(ab, [Item('Meal', 10000, ['A', 'B'])],
        discount: ChargeSpec.amount(9999), adjustmentMinor: 100));
    expect(r.members, [const MemberBreakdown('B', 5000, 0, 0, 100, 101, discountMinor: 4999)]);
  });

  test('the legacy input is the same as percent charge specs', () {
    final legacy = ItemizedCalculator.calculate(
        ItemizedInput(abc, restaurant(), 1200, const TaxSpec(1400, TaxBase.subtotalPlusService), 0));
    final specs = ItemizedCalculator.calculate(ItemizedInput.charges(abc, restaurant(),
        service: const ChargeSpec.percent(1200),
        tax: TaxSpec.of(const ChargeSpec.percent(1400), TaxBase.subtotalPlusService)));
    expect(specs, legacy);
    expect(legacy.discountMinor, 0);
    expect(legacy.members.every((m) => m.discountMinor == 0), isTrue);
  });
}
