import 'dart:io';

import 'package:test/test.dart';

/// Guards the engine invariants (AGENTS.md 1 and 3, ADR-011): the package is pure Dart (no Flutter, no I/O)
/// and float-free. Port of EnginePurityTest.
void main() {
  final allowedImport = RegExp(r'''^(import|export)\s+'(dart:(core|collection|math)|package:qesma_engine/[^']+|[^:']+\.dart)'\s*(show|hide|as|;)''');
  final directive = RegExp(r'^(import|export|part)\b');
  // Floating point and its rounding helpers. `/` is float division in Dart; only `~/` is allowed.
  final forbidden = RegExp(r'\b(double|num|toDouble|round|floor|ceil|truncate|roundToDouble)\b|(?<![~/*])/(?![/*])');

  List<File> sources() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('engine sources import only dart:core, dart:collection, dart:math and their own files', () {
    final files = sources();
    expect(files, isNotEmpty);
    for (final f in files) {
      for (final raw in f.readAsLinesSync()) {
        final line = raw.trim();
        if (directive.hasMatch(line)) {
          expect(allowedImport.hasMatch(line), isTrue, reason: '${f.path}: $line');
        }
      }
    }
  });

  test('engine sources use no floating point and no rounding helpers', () {
    for (final f in sources()) {
      for (final raw in f.readAsLinesSync()) {
        var line = raw.trim();
        if (line.startsWith('//') || line.startsWith('*') || line.startsWith('/*')) continue;
        final comment = line.indexOf('//');
        if (comment >= 0) line = line.substring(0, comment);
        line = line.replaceAll(RegExp(r"'[^']*'"), "''"); // messages may contain any words
        expect(forbidden.hasMatch(line), isFalse, reason: '${f.path}: $raw');
      }
    }
  });
}
