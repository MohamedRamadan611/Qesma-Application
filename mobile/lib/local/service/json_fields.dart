import 'dart:convert';

import '../errors.dart';

/// Typed reading of a request body, mirroring what Jackson does on the server: a value of the wrong JSON type, a
/// malformed UUID or date, or a number that is not an integer is `400 VALIDATION_ERROR`; a missing (or JSON null)
/// field is `null` and left to the service validator, which answers 422.
final class JsonFields {
  JsonFields(this._map);

  final Map<String, Object?> _map;

  /// Parses a request body that must be a JSON object. An empty or malformed body is a 400.
  static JsonFields body(String? text) {
    if (text == null || text.trim().isEmpty) throw LocalApiException.unreadable('Request body is required');
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw LocalApiException.unreadable('Malformed JSON request body');
    }
    return object(decoded) ?? (throw LocalApiException.unreadable('Request body must be a JSON object'));
  }

  /// [value] as an object, null for JSON null; anything else is a 400.
  static JsonFields? object(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return JsonFields(value);
    if (value is Map) return JsonFields(value.cast<String, Object?>());
    throw LocalApiException.unreadable('Expected a JSON object');
  }

  String? str(String key) {
    final v = _map[key];
    if (v == null || v is String) return v as String?;
    throw LocalApiException.unreadable('$key must be a string');
  }

  int? integer(String key) => integerValue(_map[key], key);

  /// A JSON boolean (Jackson does not coerce strings or numbers to a `Boolean` here either).
  bool? boolean(String key) {
    final v = _map[key];
    if (v == null || v is bool) return v as bool?;
    throw LocalApiException.unreadable('$key must be a boolean');
  }

  String? uuid(String key) => uuidValue(_map[key], key);

  /// A `YYYY-MM-DD` calendar date, returned in that canonical text form.
  String? date(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is String && isIsoDate(v)) return v;
    throw LocalApiException.unreadable('$key must be a date (YYYY-MM-DD)');
  }

  List<Object?>? list(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is List) return v.cast<Object?>();
    throw LocalApiException.unreadable('$key must be an array');
  }

  JsonFields? obj(String key) => object(_map[key]);

  /// A list of UUID strings; JSON null elements stay null (the validator rejects them with a 422, as Java does).
  List<String?>? uuidList(String key) => list(key)?.map((e) => uuidValue(e, key)).toList();

  static int? integerValue(Object? v, String key) {
    if (v == null) return null;
    if (v is int) return v;
    throw LocalApiException.unreadable('$key must be an integer');
  }

  static String? uuidValue(Object? v, String key) {
    if (v == null) return null;
    if (v is String && isUuid(v)) return v.toLowerCase();
    throw LocalApiException.unreadable('$key must be a UUID');
  }
}

final RegExp _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

bool isUuid(String s) => _uuid.hasMatch(s);

/// A real calendar date in `YYYY-MM-DD` form (2025-02-30 is not).
bool isIsoDate(String s) {
  final m = _isoDate.firstMatch(s);
  if (m == null) return false;
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final dt = DateTime.utc(y, mo, d);
  return dt.year == y && dt.month == mo && dt.day == d;
}
