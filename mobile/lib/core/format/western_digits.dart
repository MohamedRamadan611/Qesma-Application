/// Maps Arabic-Indic (U+0660..0669) and Extended Arabic-Indic (U+06F0..06F9) digits to ASCII digits.
/// Pure string logic, no arithmetic; every other character is kept as it is.
library;

const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const String _easternArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

String westernDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final a = _arabicIndic.indexOf(char);
    final e = _easternArabicIndic.indexOf(char);
    out.write(a >= 0 ? '$a' : e >= 0 ? '$e' : char);
  }
  return out.toString();
}
