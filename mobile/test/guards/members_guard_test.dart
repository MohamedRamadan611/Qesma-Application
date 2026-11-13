import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FL12 guard: the members feature never does balance or money arithmetic. It only shows and sends what the server
/// says (SCREEN_MAP rule 2). Roles are never computed from data either: `Permissions` is the only role switch.
void main() {
  test('lib/features/members has no money arithmetic and no number types', () {
    final hits = <String>[];
    final files = Directory('lib/features/members').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        final arithmetic = RegExp(r'Minor\w*\s*[-+*/%]|[-+*/%]\s*\w*Minor\b|\b(double|num)\b|Decimal|BigInt|netMinor|balance');
        if (arithmetic.hasMatch(line)) hits.add('${file.path}:${i + 1}: $line');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
