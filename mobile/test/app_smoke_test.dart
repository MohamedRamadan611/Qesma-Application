import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';

import 'support/auth_rig.dart';
import 'support/fake_groups_server.dart';

/// Boots the real app (router, guard, controller) on a fake backend with an empty store:
/// a first-time user must land on the welcome screen.
Future<ProviderContainer> _boot(WidgetTester tester, {Locale? locale, String? storedRefresh}) async {
  final backend = FakeGroupsServer();
  final container = ProviderContainer(
    overrides: [
      httpAdapterProvider.overrideWithValue(backend),
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore(storedRefresh)),
      googleIdTokenSourceProvider.overrideWithValue(FakeGoogleSource()),
    ],
  );
  addTearDown(container.dispose);
  if (locale != null) container.read(localeProvider.notifier).set(locale);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('first launch: Arabic and right-to-left by default, whatever the device language, ends on the welcome screen', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await _boot(tester);

    final context = tester.element(find.byType(Scaffold).first);
    final l10n = AppLocalizations.of(context);
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text(l10n.welcomeStart), findsOneWidget);
    expect(find.text(l10n.welcomeTitle), findsOneWidget);
  });

  testWidgets('English switches to left-to-right', (tester) async {
    await _boot(tester, locale: const Locale('en'));
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('start leads to the sign-in screen; signing in (debug fake) reaches the home screen', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();
    expect(find.text('المجموعات'), findsOneWidget, reason: 'the groups list is the signed-in home');
    expect(find.text('المتابعة باستخدام Google'), findsNothing);
  });

  testWidgets('a stored session restores straight to the home screen (no welcome, no sign-in)', (tester) async {
    final backend = FakeGroupsServer();
    final s = backend.issueSession();
    final container = ProviderContainer(
      overrides: [
        httpAdapterProvider.overrideWithValue(backend),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore(s.refresh)),
        googleIdTokenSourceProvider.overrideWithValue(FakeGoogleSource()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
    await tester.pumpAndSettle();
    expect(find.text('المجموعات'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsNothing);
  });

  testWidgets('signing out returns to the welcome screen', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });

  test('both ARB files define the supported locales', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), containsAll(['ar', 'en']));
  });
}
