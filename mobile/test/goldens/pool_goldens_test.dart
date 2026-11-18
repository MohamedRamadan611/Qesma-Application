import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/theme_mode_controller.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';

import '../local/backend/support/local_http.dart';
import '../support/test_app.dart';

/// SA10 goldens (Arabic, RTL, 360 wide) on the real local backend with fixed ids and clock: the pool card on the group
/// home, the pool screen with a negative meter, the deposit sheet, the expense form with "Paid from the pool" on, and
/// the pool screen in dark mode. Update with `flutter test --update-goldens test/goldens/pool_goldens_test.dart` and
/// review every PNG.
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
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('pool_goldens_test.dart'));
  });

  late LocalHttp http;
  late String gid; // 600.00 deposited, 450.00 spent: 150.00 left
  late String overdraftGid; // 100.00 deposited, 300.00 spent: the treasurer covered 200.00

  setUp(() async {
    var n = 0;
    http = await LocalHttp.open(profileName: 'منى', newId: () => '00000000-0000-4000-8000-${(++n).toString().padLeft(12, '0')}');
    Future<String> seed(String name, List<int> deposits, int spent) async {
      final g = await http.group(name: name);
      final id = g['id'] as String;
      final you = g['yourMemberId'] as String;
      final asem = await http.member(id, 'عاصم');
      final mohsen = await http.member(id, 'محسن');
      await http.patch('/groups/$id', {'treasurerMemberId': you}, ifMatch: '"1"');
      for (final (i, amount) in deposits.indexed) {
        await http.settlement(id, {
          'fromMemberId': i.isEven ? asem : mohsen,
          'toMemberId': you,
          'amountMinor': amount,
          'settledOn': '2026-11-1${i + 1}',
          'kind': 'POOL_DEPOSIT',
        });
      }
      await http.expense(id, {...equalBody(spent, [(id: you, amount: spent)], title: 'بنزين'), 'paidFromPool': true});
      return id;
    }

    gid = await seed('رحلة دهب', [30000, 30000], 45000);
    overdraftGid = await seed('سيوة', [10000], 30000);
  });
  tearDown(() => http.close());

  Future<void> pumpAt(WidgetTester tester, String route, {bool dark = false, double height = 800}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(360, height);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      ...localModeOverrides(http.db, clock: () => DateTime.utc(2026, 11, 17, 10).millisecondsSinceEpoch),
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 17, 12)),
      if (dark) ...[
        preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({kThemeModePref: 'dark'})),
        themeModeAutoLoadProvider.overrideWithValue(true),
      ],
    ]);
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).set(const Locale('ar'));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
    await tester.pumpAndSettle();
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  final l10n = lookupAppLocalizations(const Locale('ar'));

  testWidgets('pool card on the group home', (tester) async {
    await pumpAt(tester, Routes.group(gid));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('pool_card_ar.png'));
  });

  testWidgets('pool screen, negative meter said in words', (tester) async {
    await pumpAt(tester, Routes.pool(overdraftGid));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('pool_screen_negative_ar.png'));
  });

  testWidgets('deposit sheet', (tester) async {
    await pumpAt(tester, Routes.pool(gid));
    await tester.tap(find.text(l10n.poolAddDeposit));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('deposit_sheet_ar.png'));
  });

  testWidgets('expense form with "Paid from the pool" on', (tester) async {
    await pumpAt(tester, Routes.addExpense(gid), height: 1400);
    final poolSwitch = find.widgetWithText(SwitchListTile, l10n.expensePaidFromPool);
    await Scrollable.ensureVisible(tester.element(poolSwitch), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(poolSwitch);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('expense_form_pool_ar.png'));
  });

  testWidgets('dark: pool screen', (tester) async {
    await pumpAt(tester, Routes.pool(gid), dark: true);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('dark_pool_screen_ar.png'));
  });
}
