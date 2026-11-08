/// Money in integer piasters (1 EGP = 100). Pure string/`int` logic: no floating point,
/// ever (SCREEN_MAP rules 2-3). The only place in `lib/` allowed to do `/ 100`-style
/// arithmetic; a guard test enforces that.
abstract final class Money {
  /// Upper bound of every amount the backend accepts: 10^12 piasters.
  static const int maxMinor = 1000000000000;

  static const String currencySuffix = 'ج.م';

  /// Minus sign used for display (U+2212, not a hyphen).
  static const String minus = '−';

  /// Parses what a user typed into piasters, or null if it is not a valid amount.
  ///
  /// Accepts Western and Arabic-Indic digits, `.`/`٫` as decimal separator and `,`/`٬`
  /// as thousands grouping (only in correct 3-digit groups, so "1,00" is rejected
  /// instead of silently becoming 100). At most 2 decimals. Range 1..[maxMinor], or
  /// 0..[maxMinor] with [allowZero]; [allowNegative] mirrors the range for adjustments.
  static int? parse(String input, {bool allowNegative = false, bool allowZero = false}) {
    var text = _normalize(input.trim());
    var negative = false;
    if (text.startsWith('-')) {
      if (!allowNegative) return null;
      negative = true;
      text = text.substring(1);
    }
    final match = _amount.firstMatch(text);
    if (match == null) return null;
    final integerDigits = match.group(1)!.replaceAll(',', '');
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    if (integerDigits.length > 13) return null; // beyond 10^12 piasters; avoids int overflow
    final minor = int.parse(integerDigits) * 100 + int.parse(fraction);
    if (minor > maxMinor) return null;
    if (minor == 0 && !allowZero) return null;
    return negative ? -minor : minor;
  }

  /// The number without the currency: "1,061.79", "−5.25"; with [signed] also "+1,061.79".
  /// Widgets add the (localized) currency and isolate this part for right-to-left layouts.
  static String formatNumber(int minor, {bool signed = false}) {
    final sign = minor < 0 ? minus : (signed && minor > 0 ? '+' : '');
    return '$sign${_grouped(minor.abs())}';
  }

  /// "1,061.79 ج.م". Negative values get a leading minus; use [formatSigned] for balances.
  static String format(int minor) {
    final sign = minor < 0 ? minus : '';
    return '$sign${_grouped(minor.abs())} $currencySuffix';
  }

  /// Amount with an explicit sign: "+1,061.79 ج.م", "−1,061.79 ج.م", "0.00 ج.م".
  /// Sign and text carry the meaning; colour is only a hint.
  static String formatSigned(int minor) {
    if (minor == 0) return format(0);
    return '${minor > 0 ? '+' : minus}${_grouped(minor.abs())} $currencySuffix';
  }

  /// Digits only, for pre-filling an edit field: 106179 -> "1061.79", 106100 -> "1061".
  static String formatPlain(int minor) {
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;
    if (frac == 0) return '$sign$whole';
    return '$sign$whole.${frac.toString().padLeft(2, '0')}';
  }

  /// Splits an amount into whole pounds and piasters (both non-negative) for spoken text
  /// and screen readers: -8050 -> (80, 50). The sign is the caller's business.
  static ({int pounds, int piasters}) parts(int minor) {
    final abs = minor.abs();
    return (pounds: abs ~/ 100, piasters: abs % 100);
  }

  static String _grouped(int absMinor) {
    final whole = (absMinor ~/ 100).toString();
    final frac = (absMinor % 100).toString().padLeft(2, '0');
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '$buffer.$frac';
  }

  static final RegExp _amount = RegExp(r'^(\d{1,3}(,\d{3})+|\d+)(?:\.(\d{1,2}))?$');
}

/// Percentages as integer basis points (1200 bps = 12.00%).
abstract final class Bps {
  static const int max = 10000;

  /// "12" -> 1200, "12.5" -> 1250, "12.05" -> 1205. 0..100.00, at most 2 decimals.
  static int? parse(String input) {
    final text = _normalize(input.trim());
    final match = _percent.firstMatch(text);
    if (match == null) return null;
    final bps = int.parse(match.group(1)!) * 100 + int.parse((match.group(2) ?? '').padRight(2, '0'));
    return bps > max ? null : bps;
  }

  /// 1200 -> "12", 1250 -> "12.5", 1205 -> "12.05" (Western digits, no % sign).
  static String format(int bps) {
    final whole = bps ~/ 100;
    final frac = bps % 100;
    if (frac == 0) return '$whole';
    final digits = frac.toString().padLeft(2, '0');
    return '$whole.${digits.endsWith('0') ? digits.substring(0, 1) : digits}';
  }

  static final RegExp _percent = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$');
}

/// Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits to ASCII; Arabic decimal and
/// thousands separators to `.` and `,`; the Unicode minus sign to `-`.
String _normalize(String input) {
  final buffer = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(0x30 + unit - 0x0660);
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.writeCharCode(0x30 + unit - 0x06F0);
    } else if (unit == 0x066B) {
      buffer.write('.');
    } else if (unit == 0x066C) {
      buffer.write(',');
    } else if (unit == 0x2212) {
      buffer.write('-');
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}
