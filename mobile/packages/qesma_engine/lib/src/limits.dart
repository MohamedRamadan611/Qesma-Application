/// Bounds on stored money (port of the Java `Limits`). Every amount (expense total, payer, share, item,
/// settlement) is at most [maxAmountMinor] piasters (10 billion EGP), so ledger sums cannot overflow 64 bits
/// in any realistic group.
abstract final class Limits {
  static const int maxAmountMinor = 1000000000000;

  static bool withinAmountLimit(int amountMinor) => amountMinor <= maxAmountMinor;
}
