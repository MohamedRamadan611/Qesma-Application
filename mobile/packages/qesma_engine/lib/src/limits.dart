/// Bounds on stored money (port of the Java `Limits`). Every amount (expense total, payer, share, item,
/// settlement) is at most [maxAmountMinor] piasters (10 billion EGP), so ledger sums cannot overflow 64 bits
/// in any realistic group.
abstract final class Limits {
  static const int maxAmountMinor = 1000000000000;

  /// SHARES (A185, A194): integer units per participant and the longest period, inclusive.
  static const int minShareUnits = 1;
  static const int maxShareUnits = 100;
  static const int maxPeriodDays = 366;

  static bool withinAmountLimit(int amountMinor) => amountMinor <= maxAmountMinor;
}
