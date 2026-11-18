import 'package:drift/drift.dart';

import '../local_database.dart';

part 'fuel_prices_dao.g.dart';

/// Saved fuel prices of the Khorouga calculator (SA11, A168): one row per fuel type, written only by the user.
@DriftAccessor(include: {'../schema.drift'})
class FuelPricesDao extends DatabaseAccessor<LocalDatabase> with _$FuelPricesDaoMixin {
  FuelPricesDao(super.db);

  Stream<List<FuelPriceRow>> watchAll() => select(fuelPrices).watch();

  /// Inserts or replaces the price of [fuelType] and stamps [updatedAt] (UTC epoch ms).
  Future<void> upsert({required String fuelType, required int pricePerLitreMinor, required int updatedAt}) =>
      into(fuelPrices).insertOnConflictUpdate(
        FuelPricesCompanion.insert(fuelType: fuelType, pricePerLitreMinor: pricePerLitreMinor, updatedAt: updatedAt),
      );
}
