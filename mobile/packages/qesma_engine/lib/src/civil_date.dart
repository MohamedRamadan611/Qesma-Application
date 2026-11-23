import 'engine_exception.dart';

/// Calendar dates as `YYYY-MM-DD` text (the wire and storage form), turned into day numbers with integer
/// arithmetic only. No `DateTime`, so no local time zone or daylight-saving step can shift a day (A186).
abstract final class CivilDate {
  static final RegExp _shape = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Days since 1970-01-01 of a real calendar date (2026-02-30 is rejected), Gregorian calendar.
  static int epochDay(String date) {
    final m = _shape.firstMatch(date);
    if (m == null) throw EngineException.invalid('Dates must be YYYY-MM-DD');
    final y = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    if (month < 1 || month > 12 || d < 1 || d > _daysInMonth(y, month)) {
      throw EngineException.invalid('Not a calendar date: $date');
    }
    // Days from civil (H. Hinnant): March-based years, so the leap day is the last day of the year. y >= 0 here.
    final yy = month <= 2 ? y - 1 : y;
    final era = yy ~/ 400;
    final yoe = yy - era * 400;
    final mp = (month + 9) % 12;
    final doy = (153 * mp + 2) ~/ 5 + d - 1;
    final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  static bool _leap(int y) => y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);

  static int _daysInMonth(int y, int month) => switch (month) {
        2 => _leap(y) ? 29 : 28,
        4 || 6 || 9 || 11 => 30,
        _ => 31,
      };
}
