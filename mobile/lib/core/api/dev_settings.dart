import 'package:flutter/foundation.dart';

/// Developer conveniences that exist ONLY in debug builds. In release builds every
/// member folds to a constant empty value and the literals below are tree-shaken.
/// A guard test makes sure no other file mentions the fake token format.
abstract final class DevSettings {
  /// Android emulator alias for the host machine (backend default port 8080).
  /// Cleartext to this host is allowed only by the debug manifest.
  static String get defaultBaseUrl => kDebugMode ? 'http://10.0.2.2:8080' : '';

  /// Runtime override of the base URL (set by a debug settings screen in a later
  /// milestone); null means "use the build-time value".
  static String? baseUrlOverride;

  /// Token accepted by the backend's `fake-auth` profile: `fake:<sub>:<email>:<name>`.
  /// Used by the debug-only sign-in shortcut (FL2); empty in release builds.
  static String get fakeToken => kDebugMode ? 'fake:dahab:mohamed@example.com:محمد' : '';
}
