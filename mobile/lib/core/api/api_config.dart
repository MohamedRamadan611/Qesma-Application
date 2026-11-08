import 'package:flutter/foundation.dart';

import 'dev_settings.dart';

/// Where the backend lives. The generated client already includes `/api/v1` in every
/// path, so this is the server ORIGIN only (no path).
///
/// Set at build time: `--dart-define=API_BASE_URL=https://api.example.com`.
/// Debug builds fall back to the Android emulator's alias for the host machine.
/// Release builds must be given an https URL; there is deliberately no default.
abstract final class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => resolveBaseUrl(
        defined: _definedBaseUrl,
        debugOverride: DevSettings.baseUrlOverride,
        isDebug: kDebugMode,
      );

  /// Pure so it can be tested for both build modes.
  static String resolveBaseUrl({
    required String defined,
    required String? debugOverride,
    required bool isDebug,
  }) {
    final chosen = isDebug && debugOverride != null && debugOverride.isNotEmpty ? debugOverride : defined;
    if (chosen.isEmpty) {
      if (isDebug) return DevSettings.defaultBaseUrl;
      throw StateError('API_BASE_URL must be set (https) for non-debug builds.');
    }
    if (!isDebug && !chosen.startsWith('https://')) {
      throw StateError('API_BASE_URL must use https outside debug builds.');
    }
    return chosen.endsWith('/') ? chosen.substring(0, chosen.length - 1) : chosen;
  }
}
