import '../db/local_database.dart';

/// Pump grades offered by the calculator (A168). The wire value is the `fuel_prices.fuel_type` CHECK value.
enum FuelType {
  gasoline80('GASOLINE_80'),
  gasoline92('GASOLINE_92'),
  gasoline95('GASOLINE_95'),
  diesel('DIESEL');

  const FuelType(this.wire);

  final String wire;

  static FuelType? fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// A price the user typed, with when they typed it (A142: never an official or fetched price).
final class SavedFuelPrice {
  const SavedFuelPrice({required this.pricePerLitreMinor, required this.updatedAt});

  final int pricePerLitreMinor;

  /// UTC.
  final DateTime updatedAt;
}

/// The user's saved fuel prices (drift, A148), live.
final class FuelPricesRepository {
  FuelPricesRepository(this._db, {this._clock = utcNowMillis});

  final LocalDatabase _db;
  final int Function() _clock;

  Stream<Map<FuelType, SavedFuelPrice>> watch() => _db.fuelPricesDao.watchAll().map(
        (rows) => {
          for (final r in rows)
            ?FuelType.fromWire(r.fuelType): SavedFuelPrice(
              pricePerLitreMinor: r.pricePerLitreMinor,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
            ),
        },
      );

  Future<void> save(FuelType type, int pricePerLitreMinor) =>
      _db.fuelPricesDao.upsert(fuelType: type.wire, pricePerLitreMinor: pricePerLitreMinor, updatedAt: _clock());
}
