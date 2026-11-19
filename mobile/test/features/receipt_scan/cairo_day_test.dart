import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/receipt_scan/application/cairo_day.dart';

/// The daily cap counts Africa/Cairo calendar days (A145). Egypt: UTC+2, UTC+3 from the last Friday of April to the
/// last Thursday of October (2026: 24 April 00:00 local to 29 October 24:00 local).
void main() {
  test('winter: UTC+2, the day changes at 22:00 UTC', () {
    expect(cairoDay(DateTime.utc(2026, 1, 15, 21, 59)), '2026-01-15');
    expect(cairoDay(DateTime.utc(2026, 1, 15, 22, 0)), '2026-01-16');
  });

  test('summer: UTC+3, the day changes at 21:00 UTC', () {
    expect(cairoDay(DateTime.utc(2026, 7, 1, 20, 59)), '2026-07-01');
    expect(cairoDay(DateTime.utc(2026, 7, 1, 21, 0)), '2026-07-02');
  });

  test('summer time starts on the last Friday of April 2026 (24th) at 00:00 local', () {
    expect(cairoDay(DateTime.utc(2026, 4, 23, 21, 59)), '2026-04-23'); // 23:59 local, still winter time
    expect(cairoDay(DateTime.utc(2026, 4, 23, 22, 0)), '2026-04-24'); // 00:00 local, first moment of summer time
    expect(cairoDay(DateTime.utc(2026, 4, 24, 20, 59)), '2026-04-24'); // 23:59 local summer
    expect(cairoDay(DateTime.utc(2026, 4, 24, 21, 0)), '2026-04-25');
  });

  test('summer time ends on the last Thursday of October 2026 (29th) at 24:00 local', () {
    expect(cairoDay(DateTime.utc(2026, 10, 29, 20, 59)), '2026-10-29'); // 23:59 local summer
    expect(cairoDay(DateTime.utc(2026, 10, 29, 21, 0)), '2026-10-29'); // clocks back: 23:00 local, still the 29th
    expect(cairoDay(DateTime.utc(2026, 10, 29, 22, 0)), '2026-10-30'); // 00:00 local winter
  });

  test('year end and a local (non-UTC) input are handled', () {
    expect(cairoDay(DateTime.utc(2026, 12, 31, 22, 0)), '2027-01-01');
    expect(cairoDay(DateTime.parse('2026-12-31T23:30:00+02:00')), '2026-12-31');
  });
}
