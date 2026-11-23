/// The calendar day in Africa/Cairo: the daily scan cap (A145) and the trip budget's "today" (A191). No timezone
/// package: Egypt is UTC+2, and UTC+3 in summer time, which runs from the last Friday of April (00:00) to the last Thursday of October (24:00).
/// If Egyptian law changes this rule, the cap day is off by at most one hour around midnight: harmless for a cap.
String cairoDay(DateTime nowUtc) {
  final utc = nowUtc.toUtc();
  final local = utc.add(Duration(hours: _isSummerTime(utc) ? 3 : 2));
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-$m-$d';
}

bool _isSummerTime(DateTime utc) {
  final start = _lastWeekday(utc.year, DateTime.april, DateTime.friday).subtract(const Duration(hours: 2));
  final end = _lastWeekday(utc.year, DateTime.october, DateTime.thursday).add(const Duration(hours: 21));
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Midnight UTC of the last [weekday] of [month].
DateTime _lastWeekday(int year, int month, int weekday) {
  var day = DateTime.utc(year, month + 1, 0); // last day of the month
  while (day.weekday != weekday) {
    day = day.subtract(const Duration(days: 1));
  }
  return day;
}
