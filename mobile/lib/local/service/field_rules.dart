import '../errors.dart';

/// Input rules shared by the local services: a port of Java `FieldRules` (and the text helpers it relies on).
/// Failures are 422 VALIDATION_ERROR. Lengths count Unicode code points, so an Arabic letter or an emoji counts once.
abstract final class FieldRules {
  static const int groupNameMax = 60;
  static const int memberNameMax = 40;
  static const int profileNameMax = 60;
  static const int pageSizeMax = 100;
  static const int pageSizeDefault = 20;
  static const String defaultCurrency = 'EGP';
  static const Set<String> groupTypes = {'TRIP', 'HOUSING', 'OUTING', 'OTHER'};

  /// Stripped, 1 to [max] code points (`FieldRules.name`).
  static String name(String? raw, int max, String field) {
    final name = javaStrip(raw ?? '');
    if (name.isEmpty) throw LocalApiException.validation('$field must not be blank');
    if (codePoints(name) > max) throw LocalApiException.validation('$field must be at most $max characters');
    return name;
  }

  static String groupType(String? raw) {
    final type = javaStrip(raw ?? '').toUpperCase();
    if (!groupTypes.contains(type)) {
      throw LocalApiException.validation('type must be one of TRIP, HOUSING, OUTING, OTHER');
    }
    return type;
  }

  /// Null or blank means EGP; otherwise an ISO 4217 currency usable for money (fraction digits >= 0).
  static String currency(String? raw) {
    if (raw == null || javaStrip(raw).isEmpty) return defaultCurrency;
    final code = javaStrip(raw).toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code) || !_iso4217.contains(code)) {
      throw LocalApiException.validation('currencyCode must be a valid ISO 4217 code');
    }
    return code;
  }

  static void page(int page, int size) {
    if (page < 0) throw LocalApiException.validation('page must be 0 or greater');
    if (size < 1 || size > pageSizeMax) throw LocalApiException.validation('size must be between 1 and $pageSizeMax');
  }

  /// [s] cut to at most [max] code points, then stripped again (the owner member name, `GroupService`).
  static String cutCodePoints(String s, int max) {
    final runes = s.runes.toList();
    if (runes.length <= max) return s;
    return javaStrip(String.fromCharCodes(runes.take(max)));
  }
}

int codePoints(String s) => s.runes.length;

/// Java `String.strip()`: removes leading and trailing `Character.isWhitespace` code points. Unlike Dart's `trim()`
/// it keeps the no-break spaces (U+00A0, U+2007, U+202F), so a name is accepted or rejected exactly as on the server.
String javaStrip(String s) {
  final runes = s.runes.toList();
  var start = 0;
  var end = runes.length;
  while (start < end && _isJavaWhitespace(runes[start])) {
    start++;
  }
  while (end > start && _isJavaWhitespace(runes[end - 1])) {
    end--;
  }
  return String.fromCharCodes(runes.sublist(start, end));
}

bool _isJavaWhitespace(int c) =>
    (c >= 0x09 && c <= 0x0D) ||
    (c >= 0x1C && c <= 0x20) ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200A && c != 0x2007) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x205F ||
    c == 0x3000;

/// Active ISO 4217 codes with a minor unit (Java rejects the pseudo-currencies XXX, XTS, XDR, metals and XB*).
const Set<String> _iso4217 = {
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', //
  'BMD', 'BND', 'BOB', 'BOV', 'BRL', 'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHE', 'CHF', 'CHW', 'CLF', //
  'CLP', 'CNY', 'COP', 'COU', 'CRC', 'CUC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP', 'DZD', 'EGP', 'ERN', 'ETB', //
  'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HRK', 'HTG', 'HUF', //
  'IDR', 'ILS', 'INR', 'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF', 'KPW', 'KRW', 'KWD', //
  'KYD', 'KZT', 'LAK', 'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRU', //
  'MUR', 'MVR', 'MWK', 'MXN', 'MXV', 'MYR', 'MZN', 'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', //
  'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF', 'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', //
  'SHP', 'SLE', 'SLL', 'SOS', 'SRD', 'SSP', 'STN', 'SVC', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP', 'TRY', //
  'TTD', 'TWD', 'TZS', 'UAH', 'UGX', 'USD', 'USN', 'UYI', 'UYU', 'UYW', 'UZS', 'VED', 'VES', 'VND', 'VUV', 'WST', //
  'XAF', 'XCD', 'XCG', 'XOF', 'XPF', 'YER', 'ZAR', 'ZMW', 'ZWG', 'ZWL',
};
