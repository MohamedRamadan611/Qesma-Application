import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the refresh token lives between launches. It is the ONLY thing persisted for a
/// session: the access token and the user stay in memory (SCREEN_MAP rule 9).
abstract interface class TokenStore {
  /// The stored refresh token, or null when there is none (or the storage was unreadable).
  Future<String?> readRefreshToken();

  /// Persists [token]. May throw when the platform storage fails; the caller decides what
  /// that means for the session.
  Future<void> writeRefreshToken(String token);

  /// Removes everything. Never throws.
  Future<void> clear();
}

/// Keystore-backed storage (flutter_secure_storage: RSA-OAEP wrapped AES-GCM on Android).
/// `resetOnError` (the package default) wipes unreadable data instead of crashing.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'qesma.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() async {
    try {
      final value = await _storage.read(key: _key);
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      // Unreadable storage (for example a Keystore key invalidated by the OS): treat as signed out.
      await clear();
      return null;
    }
  }

  @override
  Future<void> writeRefreshToken(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing more can be done; the next read will fail or return null and be handled.
    }
  }
}

/// Plain in-memory store for tests and previews. Never use it in the real app.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
