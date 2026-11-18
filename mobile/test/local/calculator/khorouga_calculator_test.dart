import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/calculator/fuel_prices_repository.dart';
import 'package:qesma/local/calculator/khorouga_calculator.dart';
import 'package:qesma/local/db/local_database.dart';

const _a = CalcMember('A', 0);
const _b = CalcMember('B', 1);
const _c = CalcMember('C', 2);

FuelInputs _fuel({
  int distance = 1000,
  int price = 1375,
  List<int> tolls = const [],
  bool driverIncluded = true,
  List<CalcMember> passengers = const [_b, _c],
}) =>
    FuelInputs(
      distanceTenthsKm: distance,
      consumptionTenths: 81,
      pricePerLitreMinor: price,
      tollsMinor: tolls,
      driver: _a,
      driverIncluded: driverIncluded,
      passengers: passengers,
    );

void main() {
  const calc = KhorougaCalculator();

  group('fuel', () {
    test('returns the engine result with the driver as payer', () {
      final r = calc.fuel(_fuel()) as CalcResult;
      expect(r.fuelMinor, 11138);
      expect(r.totalMinor, 11138);
      expect(r.payerMemberId, 'A');
      expect(r.shares, {'A': 3713, 'B': 3713, 'C': 3712});
    });

    test('explains instead of throwing', () {
      expect((calc.fuel(_fuel(driverIncluded: false, passengers: [])) as CalcInvalid).reason, CalcInvalidReason.noSharers);
      expect((calc.fuel(_fuel(distance: 0)) as CalcInvalid).reason, CalcInvalidReason.zeroTotal);
      expect((calc.fuel(_fuel(tolls: [1000000000000])) as CalcInvalid).reason, CalcInvalidReason.totalTooLarge);
      expect((calc.fuel(_fuel(distance: -1)) as CalcInvalid).reason, CalcInvalidReason.outOfRange);
    });
  });

  group('ride', () {
    test('names every leg without riders (A141)', () {
      final out = calc.ride(const RideInputs(
        fareMinor: 5000,
        legDistancesTenthsKm: [10, 10, 10],
        riders: [CalcRider(_a, boardStop: 0, leaveStop: 1)],
      ));
      expect(out, isA<CalcInvalid>().having((i) => i.reason, 'reason', CalcInvalidReason.legsWithoutRiders).having((i) => i.legs, 'legs', [1, 2]));
    });

    test('returns leg fares and shares', () {
      final r = calc.ride(const RideInputs(
        fareMinor: 10000,
        legDistancesTenthsKm: [50, 30, 20],
        riders: [
          CalcRider(_a, boardStop: 0, leaveStop: 3),
          CalcRider(_b, boardStop: 0, leaveStop: 1),
          CalcRider(_c, boardStop: 1, leaveStop: 3),
        ],
      )) as CalcResult;
      expect(r.legFaresMinor, [5000, 3000, 2000]);
      expect(r.shares, {'A': 2500 + 1500 + 1000, 'B': 2500, 'C': 1500 + 1000});
      expect(r.payerMemberId, isNull);
    });

    test('no riders and a zero fare', () {
      expect((calc.ride(const RideInputs(fareMinor: 100, legDistancesTenthsKm: [1], riders: [])) as CalcInvalid).reason,
          CalcInvalidReason.noSharers);
      expect(
        (calc.ride(const RideInputs(fareMinor: 0, legDistancesTenthsKm: [1], riders: [CalcRider(_a, boardStop: 0, leaveStop: 1)]))
                as CalcInvalid)
            .reason,
        CalcInvalidReason.zeroTotal,
      );
    });
  });

  test('fuel prices repository saves with the clock and streams by type', () async {
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    final repo = FuelPricesRepository(db, clock: () => 1763510400000);
    await repo.save(FuelType.gasoline92, 1375);
    final prices = await repo.watch().first;
    expect(prices[FuelType.gasoline92]!.pricePerLitreMinor, 1375);
    expect(prices[FuelType.gasoline92]!.updatedAt, DateTime.utc(2025, 11, 19));
    expect(prices.containsKey(FuelType.diesel), isFalse);
  });
}
