/// `2026-10-18` in the device's local time zone: Western digits, no locale formatting
/// (DESIGN.md numeral rules). Dates are never built with `intl`, which would use Arabic-Indic digits.
String isoDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}
