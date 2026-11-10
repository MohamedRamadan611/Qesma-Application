import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';

import '../support/expenses_ui.dart';
import '../support/fake_balances_server.dart';
import '../support/test_app.dart';

/// Golden of the Account tab (Arabic, RTL, 360 wide) with the real V1 group numbers.
/// Update with `flutter test --update-goldens test/goldens` and review the PNG.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('profile_goldens_test.dart'));
  });

  testWidgets('profile hub (ar)', (tester) async {
    final server = FakeBalancesServer();
    await pumpExpensesApp(tester, server, height: 1000, route: Routes.account, overrides: [preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore())]);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('profile_hub_ar.png'));
  });
}
