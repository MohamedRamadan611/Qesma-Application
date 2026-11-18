import 'dart:math';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

const _a = MemberRef('A', 0);
const _b = MemberRef('B', 1);
const _c = MemberRef('C', 2);

FuelSplitResult _fuel({
  int distance = 1000,
  int consumption = 80,
  int price = 1375,
  List<int> tolls = const [],
  MemberRef driver = _a,
  bool driverIncluded = true,
  List<MemberRef> passengers = const [_b, _c],
}) =>
    FuelSplit.compute(
      distanceTenthsKm: distance,
      consumptionTenths: consumption,
      pricePerLitreMinor: price,
      tollsMinor: tolls,
      driver: driver,
      driverIncluded: driverIncluded,
      passengers: passengers,
    );

Matcher get _invalid => throwsA(isA<EngineException>().having((e) => e.code, 'code', EngineErrorCode.validationError));

void main() {
  group('fuel rounding', () {
    test('just below half a piaster rounds down', () {
      // 0.1 km x 1.0 L/100km x 44.99 EGP: 1 x 10 x 4499 = 44990 / 10000 = 4.499 piasters -> 4.
      expect(_fuel(distance: 1, consumption: 10, price: 4499, passengers: []).fuelMinor, 4);
    });

    test('exactly half a piaster rounds up', () {
      expect(_fuel(distance: 1, consumption: 10, price: 4500, passengers: []).fuelMinor, 5);
    });

    test('zero distance means zero fuel', () {
      expect(_fuel(distance: 0, tolls: [100]).fuelMinor, 0);
    });
  });

  group('limits', () {
    test('consumption must be 1.0 to 30.0 L/100 km', () {
      expect(() => _fuel(consumption: 9), _invalid);
      expect(() => _fuel(consumption: 301), _invalid);
      expect(_fuel(consumption: 10).fuelMinor, greaterThan(0));
      expect(_fuel(consumption: 300).fuelMinor, greaterThan(0));
    });

    test('distance is 0 to 10,000.0 km', () {
      expect(() => _fuel(distance: -1), _invalid);
      expect(() => _fuel(distance: FuelSplit.maxDistanceTenthsKm + 1), _invalid);
    });

    test('price per litre is 0 to 1,000 EGP', () {
      expect(() => _fuel(price: -1), _invalid);
      expect(() => _fuel(price: FuelSplit.maxPricePerLitreMinor + 1), _invalid);
    });

    test('tolls: positive, capped each, at most 20', () {
      expect(() => _fuel(tolls: [0]), _invalid);
      expect(() => _fuel(tolls: [-5]), _invalid);
      expect(() => _fuel(tolls: [Limits.maxAmountMinor + 1]), _invalid);
      expect(() => _fuel(tolls: List.filled(FuelSplit.maxTolls + 1, 100)), _invalid);
      expect(_fuel(tolls: List.filled(FuelSplit.maxTolls, 100)).tollsMinor, 2000);
    });

    test('the sum of tolls cannot overflow past the limit', () {
      expect(() => _fuel(tolls: [Limits.maxAmountMinor, Limits.maxAmountMinor]), _invalid);
    });

    test('a zero total is rejected (an expense needs at least one piaster)', () {
      expect(() => _fuel(distance: 0), _invalid);
      expect(() => _fuel(price: 0), _invalid);
    });

    test('at least one person shares the cost', () {
      expect(() => _fuel(driverIncluded: false, passengers: []), _invalid);
    });

    test('the driver cannot also be a passenger; ids are unique', () {
      expect(() => _fuel(passengers: [_a, _b]), _invalid);
      expect(() => _fuel(passengers: [_b, _b]), _invalid);
    });
  });

  test('the driver is always the payer, shares are in sortOrder order', () {
    final r = _fuel(driver: _c, passengers: [_b, _a]);
    expect(r.payerMemberId, 'C');
    expect([for (final s in r.shares) s.memberId], ['A', 'B', 'C']);
  });

  test('property: shares sum to the total, are within one piaster, and are deterministic', () {
    for (var seed = 0; seed < 2000; seed++) {
      final rnd = Random(seed);
      final n = rnd.nextInt(8);
      // Unique sortOrders, as in a real group (A9).
      final orders = List<int>.generate(n + 1, (i) => i)..shuffle(rnd);
      final passengers = [for (var i = 0; i < n; i++) MemberRef('P$i', orders[i])];
      final driver = MemberRef('D', orders[n]);
      final included = n == 0 || rnd.nextBool();
      final distance = 1 + rnd.nextInt(FuelSplit.maxDistanceTenthsKm);
      final consumption = 10 + rnd.nextInt(291);
      final price = 1 + rnd.nextInt(FuelSplit.maxPricePerLitreMinor);
      final tolls = [for (var i = 0; i < rnd.nextInt(4); i++) 1 + rnd.nextInt(100000)];
      FuelSplitResult run(List<MemberRef> ps) => FuelSplit.compute(
            distanceTenthsKm: distance,
            consumptionTenths: consumption,
            pricePerLitreMinor: price,
            tollsMinor: tolls,
            driver: driver,
            driverIncluded: included,
            passengers: ps,
          );

      final first = run(passengers);
      final again = run(passengers.reversed.toList());

      expect(first.fuelMinor + first.tollsMinor, first.totalMinor, reason: 'seed $seed');
      expect(first.shares.fold<int>(0, (s, x) => s + x.amountMinor), first.totalMinor, reason: 'seed $seed');
      final amounts = first.shares.map((s) => s.amountMinor);
      expect(amounts.reduce(max) - amounts.reduce(min), lessThanOrEqualTo(1), reason: 'seed $seed');
      expect(again.shares, first.shares, reason: 'seed $seed: input order must not matter');
      expect(run(passengers).shares, first.shares, reason: 'seed $seed: deterministic');
    }
  });
}
