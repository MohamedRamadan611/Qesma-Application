import 'dart:math';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

RideRider _r(String id, int sortOrder, int board, int leave) =>
    RideRider(memberId: id, sortOrder: sortOrder, boardStop: board, leaveStop: leave);

Matcher get _invalid => throwsA(isA<EngineException>().having((e) => e.code, 'code', EngineErrorCode.validationError));

void main() {
  group('legs without riders (A141)', () {
    test('names every empty leg', () {
      expect(MultiStopSplit.legsWithoutRiders(4, [_r('A', 0, 0, 1), _r('B', 1, 3, 4)]), [1, 2]);
      expect(MultiStopSplit.legsWithoutRiders(2, [_r('A', 0, 0, 2)]), isEmpty);
    });

    test('compute rejects a trip with an empty leg', () {
      expect(
        () => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10, 10], riders: [_r('A', 0, 0, 1)]),
        _invalid,
      );
    });
  });

  group('limits', () {
    final one = [_r('A', 0, 0, 1)];
    test('fare 1..10^12', () {
      expect(() => MultiStopSplit.compute(fareMinor: 0, legDistancesTenthsKm: [10], riders: one), _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: Limits.maxAmountMinor + 1, legDistancesTenthsKm: [10], riders: one), _invalid);
      expect(MultiStopSplit.compute(fareMinor: Limits.maxAmountMinor, legDistancesTenthsKm: [10], riders: one).legFaresMinor,
          [Limits.maxAmountMinor]);
    });

    test('1..9 legs, each 0..10,000.0 km', () {
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [], riders: one), _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [-1], riders: one), _invalid);
      expect(
        () => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [MultiStopSplit.maxLegDistanceTenthsKm + 1], riders: one),
        _invalid,
      );
      final ten = List.filled(MultiStopSplit.maxLegs + 1, 10);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: ten, riders: [_r('A', 0, 0, ten.length)]), _invalid);
    });

    test('riders: at least one, unique, board before leave, within the stops', () {
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10], riders: []), _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10], riders: [_r('A', 0, 0, 1), _r('A', 1, 0, 1)]),
          _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10], riders: [_r('A', 0, 1, 1)]), _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10], riders: [_r('A', 0, -1, 1)]), _invalid);
      expect(() => MultiStopSplit.compute(fareMinor: 100, legDistancesTenthsKm: [10], riders: [_r('A', 0, 0, 2)]), _invalid);
    });
  });

  test('property: leg fares sum to the fare, shares sum to the fare, deterministic and order-independent', () {
    for (var seed = 0; seed < 2000; seed++) {
      final rnd = Random(seed);
      final legs = [for (var i = 0; i < 1 + rnd.nextInt(MultiStopSplit.maxLegs); i++) rnd.nextInt(4) == 0 ? 0 : rnd.nextInt(5000)];
      final fare = 1 + rnd.nextInt(10000000);
      final riders = <RideRider>[
        // one rider covers the whole trip so no leg is empty
        _r('R0', rnd.nextInt(4), 0, legs.length),
        for (var i = 1; i < 1 + rnd.nextInt(6); i++)
          () {
            final board = rnd.nextInt(legs.length);
            return _r('R$i', rnd.nextInt(4), board, board + 1 + rnd.nextInt(legs.length - board));
          }(),
      ];

      final r = MultiStopSplit.compute(fareMinor: fare, legDistancesTenthsKm: legs, riders: riders);
      final again = MultiStopSplit.compute(fareMinor: fare, legDistancesTenthsKm: legs, riders: riders.reversed.toList());

      expect(r.legFaresMinor.fold<int>(0, (s, x) => s + x), fare, reason: 'seed $seed');
      expect(r.shares.fold<int>(0, (s, x) => s + x.amountMinor), fare, reason: 'seed $seed');
      expect(again.legFaresMinor, r.legFaresMinor, reason: 'seed $seed');
      expect({for (final s in again.shares) s.memberId: s.amountMinor}, {for (final s in r.shares) s.memberId: s.amountMinor},
          reason: 'seed $seed');
    }
  });
}
