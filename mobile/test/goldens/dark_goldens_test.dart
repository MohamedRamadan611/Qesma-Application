import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/theme_mode_controller.dart';

import '../support/expenses_rig.dart';
import '../support/expenses_ui.dart';
import '../support/fake_balances_server.dart';
import '../support/fake_expenses_server.dart';
import '../support/test_app.dart';

/// Goldens of the DARK theme (Arabic, RTL, 360 wide) for the key screens. The light goldens elsewhere
/// must stay unchanged by the dark-mode work. Update with `flutter test --update-goldens test/goldens`
/// and review every PNG: text must be legible, nothing may glow or vanish.
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

Future<void> pumpDark(WidgetTester tester, FakeExpensesServer server, {required String route, double height = 1400}) async {
  await pumpExpensesApp(tester, server, height: height, route: route, overrides: [
    preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({kThemePrefKey: 'dark'})),
    themeModeAutoLoadProvider.overrideWithValue(true),
  ]);
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pumpAndSettle();
  expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);
}

const kThemePrefKey = kThemeModePref;

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('dark_goldens_test.dart'));
  });

  testWidgets('dark: account hub', (tester) async {
    await pumpDark(tester, FakeBalancesServer(), route: Routes.account, height: 1000);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_profile_hub_ar.png'));
  });

  testWidgets('dark: balances tab (V1 numbers) and its payment history', (tester) async {
    final server = FakeBalancesServer()..seedV2();
    server.balances = balancesMap('balances_v1');
    await pumpDark(tester, server, route: '${Routes.group(server.gid)}?tab=balances', height: 1700);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_balances_tab_ar.png'));
  });

  testWidgets('dark: record payment sheet', (tester) async {
    final server = FakeBalancesServer();
    await pumpDark(tester, server, route: '${Routes.group(server.gid)}?tab=balances', height: 1300);
    await tester.tap(find.text(lookupAppLocalizations(const Locale('ar')).balancesRecordPayment).first);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_record_payment_sheet_ar.png'));
  });

  testWidgets('dark: expense details (restaurant bill V5)', (tester) async {
    final server = FakeExpensesServer();
    seedAllFixtures(server);
    await pumpDark(tester, server, route: Routes.expense(server.gid, '7e3b3a23-d844-4889-99ae-5cba254d1173'), height: 1700);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_expense_details_v5_ar.png'));
  });

  testWidgets('dark: groups list', (tester) async {
    await pumpDark(tester, FakeBalancesServer(), route: Routes.home, height: 900);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_groups_list_ar.png'));
  });

  testWidgets('dark: restaurant bill editor with the V5 numbers', (tester) async {
    final server = FakeExpensesServer();
    seedAllFixtures(server);
    final v5 = fixtureMap('expense_itemized_v5');
    server.cannedPreviews[server.itemizedKey({
      'items': v5['items'],
      'service': {'bps': 1200},
      'tax': {'bps': 1400, 'base': 'SUBTOTAL_PLUS_SERVICE'},
    })] = fixtureMap('preview_v5');
    await pumpDark(tester, server, route: Routes.editExpense(server.gid, v5['id'] as String), height: 3500);
    await settleForm(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_itemized_editor_ar.png'));
  });

  testWidgets('dark: no internet state with the offline banner', (tester) async {
    final server = FakeExpensesServer()..offline = true;
    await pumpDark(tester, server, route: Routes.home, height: 900);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_offline_ar.png'));
  });
}
