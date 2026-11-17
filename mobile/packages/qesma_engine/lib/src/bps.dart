import 'engine_exception.dart';

/// Percentage-of-amount computation with integer basis points (spec 7.1, last bullet). Port of the Java `Bps`.
abstract final class Bps {
  /// 100.00%. Service and tax rates above this are rejected as input errors.
  static const int maxBps = 10000;

  static final BigInt _tenThousand = BigInt.from(10000);
  static final BigInt _half = BigInt.from(5000);

  /// `round_half_up(amount x bps / 10000)` in minor units. [amount] must be non-negative.
  static int percentOf(int amount, int bps) {
    if (amount < 0) {
      throw EngineException.invalid('Amount must not be negative');
    }
    if (bps < 0 || bps > maxBps) {
      throw EngineException.invalid('Basis points must be between 0 and $maxBps');
    }
    // The result is <= amount, so it always fits in 64 bits.
    return ((BigInt.from(amount) * BigInt.from(bps) + _half) ~/ _tenThousand).toInt();
  }
}
