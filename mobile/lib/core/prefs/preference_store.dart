import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where non-secret device preferences live (the language, "coach marks seen"). Kept behind an
/// interface so the backing store can change in one class. Never throws.
abstract interface class PreferenceStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

/// Stored through the package that is already a dependency (`flutter_secure_storage`), so no
/// extra package is needed for two small values. Every failure reads as "nothing stored".
class SecurePreferenceStore implements PreferenceStore {
  SecurePreferenceStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: 'qesma.pref.$key');
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: 'qesma.pref.$key', value: value);
    } catch (_) {
      // The preference is simply not remembered; the app keeps working.
    }
  }
}

/// In-memory store for tests and previews.
class InMemoryPreferenceStore implements PreferenceStore {
  InMemoryPreferenceStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final preferenceStoreProvider = Provider<PreferenceStore>((ref) {
  // Widget and unit tests must never reach the platform channel: they override this.
  return SecurePreferenceStore();
});

/// Key of the stored language.
const String kLocalePref = 'locale';
