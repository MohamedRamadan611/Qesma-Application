import '../engine_exception.dart';
import '../limits.dart';
import '../lrm.dart';
import '../values.dart';
import 'ride_common.dart';

/// The result of [FuelSplit.compute]: the fuel cost, the tolls, the total and one equal share per person who
/// shares the cost, in `sortOrder` order (ties by member id). The driver is always the payer.
final class FuelSplitResult {
  const FuelSplitResult({
    required this.fuelMinor,
    required this.tollsMinor,
    required this.totalMinor,
    required this.payerMemberId,
    required this.shares,
  });

  final int fuelMinor;
  final int tollsMinor;
  final int totalMinor;
  final String payerMemberId;
  final List<Share> shares;
}

/// Road-trip fuel + tolls split (STANDALONE_SPEC 11, A139). Pure integer / BigInt math.
abstract final class FuelSplit {
  /// 10,000.0 km.
  static const int maxDistanceTenthsKm = 100000;

  /// 1.0 L/100 km.
  static const int minConsumptionTenths = 10;

  /// 30.0 L/100 km.
  static const int maxConsumptionTenths = 300;

  /// 1,000 EGP per litre.
  static const int maxPricePerLitreMinor = 100000;

  static const int maxTolls = 20;

  static final BigInt _tenThousand = BigInt.from(10000);
  static final BigInt _half = BigInt.from(5000);

  /// `fuel = round_half_up(km_tenths x l100_tenths x price / 10000)`: km/10 x (l100/10)/100 litres x price.
  static int fuelMinor(int distanceTenthsKm, int consumptionTenths, int pricePerLitreMinor) {
    final product = BigInt.from(distanceTenthsKm) * BigInt.from(consumptionTenths) * BigInt.from(pricePerLitreMinor);
    return ((product + _half) ~/ _tenThousand).toInt(); // <= 3 x 10^8 within the limits
  }

  /// Splits fuel + tolls equally (LRM, ties by sortOrder) among [passengers] and, when [driverIncluded], the
  /// [driver]. Throws [EngineException] (`VALIDATION_ERROR`) on any out-of-range input or a total outside
  /// 1..[Limits.maxAmountMinor].
  static FuelSplitResult compute({
    required int distanceTenthsKm,
    required int consumptionTenths,
    required int pricePerLitreMinor,
    required List<int> tollsMinor,
    required MemberRef driver,
    required bool driverIncluded,
    required List<MemberRef> passengers,
  }) {
    if (distanceTenthsKm < 0 || distanceTenthsKm > maxDistanceTenthsKm) {
      throw EngineException.invalid('Distance is out of range');
    }
    if (consumptionTenths < minConsumptionTenths || consumptionTenths > maxConsumptionTenths) {
      throw EngineException.invalid('Consumption must be between 1.0 and 30.0 L/100 km');
    }
    if (pricePerLitreMinor < 0 || pricePerLitreMinor > maxPricePerLitreMinor) {
      throw EngineException.invalid('Price per litre is out of range');
    }
    if (tollsMinor.length > maxTolls) {
      throw EngineException.invalid('At most $maxTolls tolls are allowed');
    }
    var tolls = 0;
    for (final t in tollsMinor) {
      if (t < 1 || t > Limits.maxAmountMinor) {
        throw EngineException.invalid('Each toll must be between 1 and ${Limits.maxAmountMinor}');
      }
      tolls += t; // each <= 10^12 and at most 20 of them: no overflow
      if (tolls > Limits.maxAmountMinor) throw EngineException.invalid('Amount too large');
    }
    final ids = <String>{};
    for (final p in passengers) {
      if (p.id == driver.id) throw EngineException.invalid('The driver is not a passenger');
      if (!ids.add(p.id)) throw EngineException.invalid('Duplicate passenger');
    }
    final sharers = sortedMembers([...passengers, if (driverIncluded) driver]);
    if (sharers.isEmpty) throw EngineException.invalid('At least one person must share the cost');

    final fuel = fuelMinor(distanceTenthsKm, consumptionTenths, pricePerLitreMinor);
    final total = fuel + tolls;
    if (total < 1) throw EngineException.invalid('The total must be greater than zero');
    if (total > Limits.maxAmountMinor) throw EngineException.invalid('Amount too large');

    final parts = Lrm.allocate(
      total,
      List<int>.filled(sharers.length, 1),
      [for (final m in sharers) m.sortOrder],
    );
    return FuelSplitResult(
      fuelMinor: fuel,
      tollsMinor: tolls,
      totalMinor: total,
      payerMemberId: driver.id,
      shares: [for (var i = 0; i < sharers.length; i++) Share(sharers[i].id, parts[i])],
    );
  }
}
