/// When the "back up your data" banner shows (SA5, owner decision: 10 expenses or 14 days). Pure, so the rule is a table
/// in the tests. All times are UTC epoch milliseconds (A151); a day is 24 hours (no calendar arithmetic).
abstract final class BackupReminder {
  static const int expenseThreshold = 10;
  static const int dayThreshold = 14;
  static const int snoozeDays = 7;
  static const int _dayMillis = 86400000;

  /// How long a dismissal hides the banner.
  static int snoozeUntil(int now) => now + snoozeDays * _dayMillis;

  /// Shown when there is data worth saving, the banner is not snoozed, and either [expensesSinceExport] reached the
  /// threshold or the last export (or the install, when never exported) is old enough.
  static bool shouldShow({
    required int now,
    required int liveExpenseCount,
    required int expensesSinceExport,
    required int? lastExportAt,
    required int installedAt,
    required int? snoozedUntil,
  }) {
    if (liveExpenseCount < 1) return false;
    if (snoozedUntil != null && now < snoozedUntil) return false;
    if (expensesSinceExport >= expenseThreshold) return true;
    final since = lastExportAt ?? installedAt;
    return now - since >= dayThreshold * _dayMillis;
  }
}
