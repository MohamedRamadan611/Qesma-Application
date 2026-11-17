import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which app this build is (STANDALONE_SPEC 2, ADR-011): `local` keeps everything on the phone (no accounts,
/// no server); `server` is the multi-user app that talks to the Java backend.
enum AppMode {
  local,
  server;

  /// `--dart-define=QESMA_MODE=local|server`. Empty: release builds are local, debug builds and tests are server.
  static const String _defined = String.fromEnvironment('QESMA_MODE');

  static AppMode fromEnvironment() => resolve(_defined, isRelease: kReleaseMode);

  /// Pure so it can be tested as a table. An unknown value fails fast: it must never silently pick a mode.
  static AppMode resolve(String defined, {required bool isRelease}) {
    switch (defined) {
      case 'local':
        return AppMode.local;
      case 'server':
        return AppMode.server;
      case '':
        return isRelease ? AppMode.local : AppMode.server;
      default:
        throw StateError('QESMA_MODE must be "local" or "server".');
    }
  }
}

/// The mode of the running app. `main.dart` and tests override it; the default is the build-time value.
final appModeProvider = Provider<AppMode>((ref) => AppMode.fromEnvironment());
