import 'dart:convert';

import '../errors/api_failure.dart';
import 'uuid_v4.dart';

/// Canonical JSON (object keys sorted recursively) so the same logical body always
/// compares equal regardless of map insertion order.
String canonicalJson(Object? value) => jsonEncode(_sorted(value));

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

/// One user intention that creates something (an expense, a settlement).
///
/// SCREEN_MAP rule 6: the Idempotency-Key is generated once per user action and reused
/// for retries of the *same* request body; a changed body gets a new key. The key is
/// forgotten after success or after a definitive error, and kept after errors where the
/// outcome is unknown or repeating may work (timeout, no connection, 5xx).
class IdempotentAction {
  IdempotentAction({String Function()? newKey}) : _newKey = newKey ?? newUuidV4;

  final String Function() _newKey;
  String? _key;
  String? _body;

  /// The key currently held, if a send is awaiting a retry (for tests).
  String? get currentKey => _key;

  /// Runs [send] with the right key for [body] (the request body as a JSON-encodable
  /// value) and applies the lifecycle rules above. Throws the mapped [ApiFailure].
  Future<T> run<T>(Object? body, Future<T> Function(String key) send) async {
    final canonical = canonicalJson(body);
    if (_key == null || _body != canonical) {
      _key = _newKey();
      _body = canonical;
    }
    try {
      final result = await send(_key!);
      reset();
      return result;
    } catch (error) {
      final failure = mapApiError(error);
      if (!failure.retryable) reset();
      throw failure;
    }
  }

  /// Forget the key (the user left the screen, or the server reported
  /// IDEMPOTENCY_KEY_REUSED and a fresh key is wanted).
  void reset() {
    _key = null;
    _body = null;
  }
}
