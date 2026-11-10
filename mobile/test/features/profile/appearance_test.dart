import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/theme_mode_controller.dart';

import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

Brightness brightnessOf(WidgetTester tester) => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

Future<InMemoryPreferenceStore> openHub(WidgetTester tester, {Locale locale = const Locale('ar'), double textScale = 1.0, Brightness platform = Brightness.light, String? stored}) async {
  final prefs = InMemoryPreferenceStore({kThemeModePref: ?stored});
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await pumpExpensesApp(tester, FakeExpensesServer(), locale: locale, textScale: textScale, height: 2000, route: Routes.account, overrides: [preferenceStoreProvider.overrideWithValue(prefs)]);
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  setUpAll(loadAppFonts);

  group('theme mode controller', () {
    ProviderContainer containerWith(PreferenceStore store) {
      final c = ProviderContainer(overrides: [preferenceStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      return c;
    }

    test('defaults to following the phone', () async {
      final c = containerWith(InMemoryPreferenceStore());
      expect(c.read(themeModeProvider), ThemeMode.system);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(themeModeProvider), ThemeMode.system);
    });

    test('a choice applies at once, is stored, and a fresh start restores it', () async {
      final store = InMemoryPreferenceStore();
      final first = containerWith(store);
      await first.read(themeModeProvider.notifier).choose(ThemeMode.dark);
      expect(first.read(themeModeProvider), ThemeMode.dark);
      expect(store.values[kThemeModePref], 'dark');

      final second = containerWith(store);
      expect(second.read(themeModeProvider), ThemeMode.system, reason: 'until the stored value is read');
      await Future<void>.delayed(Duration.zero);
      expect(second.read(themeModeProvider), ThemeMode.dark);
    });

    test('a garbage stored value is ignored; a choice made first wins over the stored one', () async {
      final bad = containerWith(InMemoryPreferenceStore({kThemeModePref: 'purple'}));
      bad.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(bad.read(themeModeProvider), ThemeMode.system);

      final c = containerWith(InMemoryPreferenceStore({kThemeModePref: 'dark'}));
      await c.read(themeModeProvider.notifier).choose(ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('the app follows the mode', () {
    testWidgets('system mode follows the phone, both ways', (tester) async {
      await openHub(tester, platform: Brightness.dark);
      expect(brightnessOf(tester), Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(brightnessOf(tester), Brightness.light, reason: 'the phone changed while the app was open');
    });

    testWidgets('a stored Light choice ignores a dark phone; a stored Dark choice ignores a light one', (tester) async {
      await openHub(tester, platform: Brightness.dark, stored: 'light');
      expect(brightnessOf(tester), Brightness.light);
    });

    testWidgets('a stored Dark choice wins on a light phone', (tester) async {
      await openHub(tester, platform: Brightness.light, stored: 'dark');
      expect(brightnessOf(tester), Brightness.dark);
    });

    testWidgets('the Appearance row opens a sheet; choosing Dark applies at once and is remembered', (tester) async {
      final prefs = await openHub(tester);
      expect(find.text('زي الموبايل'), findsOneWidget);
      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();
      expect(find.text('اختار المظهر'), findsOneWidget);
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();
      expect(brightnessOf(tester), Brightness.dark);
      expect(prefs.values[kThemeModePref], 'dark');
      expect(find.text('داكن'), findsOneWidget, reason: 'the row shows the choice');
    });

    testWidgets('the sheet exposes the selected option to screen readers and has no overflow at 2.0x', (tester) async {
      final handle = tester.ensureSemantics();
      await openHub(tester, textScale: 2.0, stored: 'dark');
      await tester.scrollUntilVisible(find.text('المظهر'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.bySemanticsLabel('داكن').last).getSemanticsData();
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('English labels', (tester) async {
      await openHub(tester, locale: const Locale('en'));
      expect(find.text('Follow phone'), findsOneWidget);
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('Choose appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });
  });
}
