import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/local_database.dart';

/// Saved fuel prices (SA11, A168): one row per type, upsert replaces, CHECKs refuse bad types and prices.
void main() {
  late LocalDatabase db;
  setUp(() => db = LocalDatabase.inMemory());
  tearDown(() => db.close());

  test('upsert inserts, then replaces the price and the date', () async {
    await db.fuelPricesDao.upsert(fuelType: 'GASOLINE_92', pricePerLitreMinor: 1375, updatedAt: 10);
    await db.fuelPricesDao.upsert(fuelType: 'GASOLINE_92', pricePerLitreMinor: 1500, updatedAt: 20);
    await db.fuelPricesDao.upsert(fuelType: 'DIESEL', pricePerLitreMinor: 1300, updatedAt: 30);
    final rows = {for (final r in await db.fuelPricesDao.watchAll().first) r.fuelType: r};
    expect(rows.keys, unorderedEquals(['GASOLINE_92', 'DIESEL']));
    expect(rows['GASOLINE_92']!.pricePerLitreMinor, 1500);
    expect(rows['GASOLINE_92']!.updatedAt, 20);
  });

  test('the schema refuses an unknown type and an out-of-range price', () async {
    await expectLater(db.fuelPricesDao.upsert(fuelType: 'GASOLINE_100', pricePerLitreMinor: 1, updatedAt: 1), throwsA(anything));
    await expectLater(db.fuelPricesDao.upsert(fuelType: 'DIESEL', pricePerLitreMinor: 0, updatedAt: 1), throwsA(anything));
    await expectLater(db.fuelPricesDao.upsert(fuelType: 'DIESEL', pricePerLitreMinor: 100001, updatedAt: 1), throwsA(anything));
  });
}
