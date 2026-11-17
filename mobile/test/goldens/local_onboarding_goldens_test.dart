import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/auth/presentation/local_name_screen.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/db/local_database.dart';

import '../support/test_app.dart';

/// Goldens of the local onboarding screen "what's your name?" (SA4): Arabic and English, empty and with a validation
/// error. Update with `flutter test --update-goldens test/goldens/local_onboarding_goldens_test.dart`.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('local_onboarding_goldens_test.dart'));
  });

  Future<void> pump(WidgetTester tester, Locale locale) async {
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    await pumpApp(
      tester,
      ProviderScope(overrides: localModeOverrides(db), child: const LocalNameScreen()),
      locale: locale,
      scaffold: false,
    );
    await tester.pump();
  }

  testWidgets('empty (ar)', (tester) async {
    await pump(tester, const Locale('ar'));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('local_name_ar.png'));
  });

  testWidgets('empty (en)', (tester) async {
    await pump(tester, const Locale('en'));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('local_name_en.png'));
  });

  testWidgets('blank name shows the error (ar)', (tester) async {
    await pump(tester, const Locale('ar'));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('local_name_error_ar.png'));
  });
}
