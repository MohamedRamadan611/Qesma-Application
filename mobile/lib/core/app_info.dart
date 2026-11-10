/// What the About row shows. The build can pass `--dart-define=APP_VERSION=1.2.3+4`; the default is
/// kept equal to `pubspec.yaml` (a test fails when they differ), so no package is needed to read it.
abstract final class AppInfo {
  static const String defaultVersion = '0.1.0+1';

  static const String raw = String.fromEnvironment('APP_VERSION', defaultValue: defaultVersion);

  /// "0.1.0 (1)": the version and the build number.
  static String get display {
    final parts = raw.split('+');
    return parts.length == 2 ? '${parts[0]} (${parts[1]})' : raw;
  }
}
