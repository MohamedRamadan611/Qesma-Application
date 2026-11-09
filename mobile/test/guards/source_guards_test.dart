import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source guards (SCREEN_MAP rules 2, 3, 8, 9). They scan `lib/` and fail the build with
/// the offending file:line, so a violation cannot be merged by accident.
///
/// Excluded from every guard: generated code (`lib/core/l10n/generated`).
/// `core/money` is the only place allowed to do money arithmetic.
/// `core/theme` and `core/widgets` may use `double` (pixel sizes) but nothing money-related.

List<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !_rel(f).startsWith('lib/core/l10n/generated/'))
    .toList();

String _rel(File f) => f.path.replaceAll('\\', '/');

/// Source lines without comments and string contents' effect on the patterns below.
Iterable<MapEntry<int, String>> _codeLines(File file) sync* {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('//') || line.startsWith('///') || line.startsWith('*')) continue;
    yield MapEntry(i + 1, line);
  }
}

List<String> _scan(
  RegExp pattern, {
  bool Function(String path)? skip,
}) {
  final hits = <String>[];
  for (final file in _dartFiles()) {
    final path = _rel(file);
    if (skip != null && skip(path)) continue;
    for (final line in _codeLines(file)) {
      if (pattern.hasMatch(line.value)) hits.add('$path:${line.key}: ${line.value}');
    }
  }
  return hits;
}

void main() {
  test('no money arithmetic or floating point outside core/money', () {
    final hits = <String>[
      // Floating point types and conversions: allowed only for pixel sizes in theme/widgets.
      ..._scan(
        RegExp(r'\b(double|num)\b|\.toDouble\(|double\.parse|double\.tryParse'),
        skip: (p) => p.startsWith('lib/core/money/') || p.startsWith('lib/core/theme/') || p.startsWith('lib/core/widgets/'),
      ),
      // The classic piaster/EGP conversions and rounding, allowed nowhere but core/money.
      ..._scan(
        RegExp(r'[/*]\s*100\b|~/\s*100\b|\.round\(\)|\.floor\(\)|\.ceil\(\)|\.truncate\(\)|\.toStringAsFixed\('),
        skip: (p) => p.startsWith('lib/core/money/'),
      ),
    ];
    expect(hits, isEmpty, reason: 'Money is int piasters; use core/money (parse/format) or ask the backend.\n${hits.join('\n')}');
  });

  test('no hard-coded user-visible strings (everything comes from the ARB files)', () {
    // Text('literal'), SelectableText('literal') and the usual named text parameters with a letter inside.
    final letters = r'[A-Za-z؀-ۿ]';
    final pattern = RegExp(
      "\\b(?:Text|SelectableText)\\(\\s*(?:const\\s+)?r?['\"][^'\"\$]*$letters"
      "|\\b(?:title|label|labelText|hintText|helperText|errorText|tooltip|semanticsLabel|semanticLabel|content)\\s*:\\s*(?:const\\s+)?(?:Text\\()?r?['\"][^'\"\$]*$letters",
    );
    // Only the debug-only catalogue (sample data for design reviews) may hold literal text.
    final hits = _scan(pattern, skip: (p) => p.startsWith('lib/core/widgets/catalogue/'));
    expect(hits, isEmpty, reason: 'Add the string to lib/core/l10n/app_ar.arb and app_en.arb instead.\n${hits.join('\n')}');
  });

  test('the debug-only fake token format appears only in dev_settings.dart', () {
    final hits = _scan(
      RegExp('''['"]fake:'''),
      skip: (p) => p == 'lib/core/api/dev_settings.dart',
    );
    expect(hits, isEmpty, reason: hits.join('\n'));

    final source = File('lib/core/api/dev_settings.dart').readAsStringSync();
    final tokenLine = source.split('\n').firstWhere((l) => l.contains("'fake:"));
    expect(tokenLine, contains('kDebugMode ?'), reason: 'the fake token must be guarded by kDebugMode');
  });

  test('nothing in lib/ logs or prints (use the request logger, which never logs tokens)', () {
    final hits = _scan(
      RegExp(r'\bprint\(|\bdebugPrint\(|\bdeveloper\.log\('),
      skip: (p) => p == 'lib/core/api/dio_factory.dart' || p == 'lib/core/auth/auth_log.dart', // the two debug-only sinks: enums and status codes only
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('no raw colours outside core/theme (use QesmaColors / the ColorScheme)', () {
    final hits = _scan(
      RegExp(r'\bColor\(\s*0x|\bColors\.(?!transparent\b)|\bColor\.fromARGB|\bColor\.fromRGBO'),
      skip: (p) => p.startsWith('lib/core/theme/'),
    );
    expect(
      hits,
      isEmpty,
      reason: 'Define the colour in lib/core/theme/tokens.dart and check its contrast.\n${hits.join('\n')}',
    );
  });

  test('layout is direction-aware: no physical left/right (RTL must mirror automatically)', () {
    final hits = _scan(
      RegExp(
        r'EdgeInsets\.only\([^)]*\b(left|right)\s*:'
        r'|EdgeInsets\.fromLTRB'
        r'|\bAlignment\.(top|center|bottom)?(Left|Right)\b'
        r'|TextAlign\.(left|right)\b'
        r'|Positioned\([^)]*\b(left|right)\s*:'
        r'|BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight)\b'
        r'|MainAxisAlignment\.(left|right)',
      ),
      skip: (p) => p.startsWith('lib/core/l10n/generated/'),
    );
    expect(
      hits,
      isEmpty,
      reason: 'Use EdgeInsetsDirectional / AlignmentDirectional / TextAlign.start|end.\n${hits.join('\n')}',
    );
  });

  test('the component catalogue exists only in debug builds and is imported by nothing else', () {
    final lines = File('lib/core/router/app_router.dart').readAsLinesSync();
    final routeLine = lines.firstWhere((l) => l.contains('Routes.catalogue') && l.contains('GoRoute('));
    expect(routeLine, contains('if (kDebugMode)'), reason: 'the /_catalog route must be declared under kDebugMode');
    final initialLine = lines.firstWhere((l) => l.contains('_initialRouteDefine.isNotEmpty'));
    expect(initialLine, contains('kDebugMode'), reason: 'INITIAL_ROUTE must be ignored outside debug builds');

    final importers = _scan(
      RegExp(r"import\s+'[^']*catalogue/"),
      skip: (p) => p == 'lib/core/router/app_router.dart',
    );
    expect(importers, isEmpty, reason: importers.join('\n'));
  });

  test('token identifiers stay inside the session code (never in widgets, routes or other features)', () {
    final hits = _scan(
      RegExp(r'\b(accessToken|refreshToken|idToken)\b'),
      skip: (p) => p.startsWith('lib/core/auth/') || p.startsWith('lib/features/auth/application/'),
    );
    expect(hits, isEmpty, reason: 'Only lib/core/auth and lib/features/auth/application may touch tokens.\n${hits.join('\n')}');
  });
  test('the generated API is used only by repositories and core wiring (widgets and notifiers never touch it)', () {
    final hits = _scan(
      RegExp(r'qesmaApiProvider|authlessApiProvider|get\w+ControllerApi\(\)'),
      skip: (p) => p.startsWith('lib/core/') || p.contains('/data/') || p.startsWith('lib/features/auth/application/'),
    );
    expect(hits, isEmpty, reason: 'Go through a repository in features/*/data.\n${hits.join('\n')}');
  });

  test('the body of an expense is built in ONE place (the command builder), never in widgets or notifiers', () {
    final hits = _scan(
      RegExp(r'\bExpenseCommand\('),
      skip: (p) => p == 'lib/features/expenses/application/expense_command_builder.dart',
    );
    expect(hits, isEmpty, reason: 'Build the request with buildExpenseCommand / buildEqualPreview / buildPayersCheck.\n${hits.join('\n')}');
  });

  test('the manifest disables Android backup (restored backups cannot unwrap the Keystore-wrapped token)', () {
    final main = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(main, contains('android:allowBackup="false"'));
  });

  test('the Android release manifest has no cleartext, no emulator host and no fake token', () {
    final main = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(main, isNot(contains('usesCleartextTraffic')));
    expect(main, isNot(contains('networkSecurityConfig')));
    expect(main, isNot(contains('10.0.2.2')));
    expect(main, contains('android.permission.INTERNET'));

    final debug = File('android/app/src/debug/res/xml/network_security_config.xml').readAsStringSync();
    expect(debug, contains('10.0.2.2'));
    expect(Directory('android/app/src/main/res/xml').existsSync(), isFalse,
        reason: 'a network security config in main would apply to release builds');
  });
}
