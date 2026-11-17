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
}
