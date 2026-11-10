import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/auth/presentation/auth_widgets.dart';

import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_balances_server.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

const _ar = Locale('ar');
const _en = Locale('en');

Future<InMemoryPreferenceStore> openHub(
  WidgetTester tester,
  FakeExpensesServer server, {
  Locale locale = _ar,
  double textScale = 1.0,
  double height = 2400,
  String route = Routes.account,
  List<Uri>? opened,
}) async {
  final prefs = InMemoryPreferenceStore();
  await pumpExpensesApp(tester, server, locale: locale, textScale: textScale, height: height, route: route, overrides: [
    preferenceStoreProvider.overrideWithValue(prefs),
    urlOpenerProvider.overrideWithValue((uri) async {
      opened?.add(uri);
      return true;
    }),
  ]);
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  late FakeExpensesServer server;

  setUpAll(loadAppFonts);
  setUp(() => server = FakeExpensesServer());

  for (final locale in [_ar, _en]) {
    final l10n = l10nFor(locale);
    final name = locale.languageCode;

    group('Profile hub ($name)', () {
      testWidgets('shows who you are, the group count, the language, the legal rows and the version', (tester) async {
        final opened = <Uri>[];
        await openHub(tester, server, locale: locale, opened: opened);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text(l10n.accountGoogleTitle), findsOneWidget);
        expect(find.text(l10n.profileGroupsOne), findsOneWidget, reason: 'one group in the list');
        expect(find.text(locale == _ar ? l10n.languageArabic : l10n.languageEnglish), findsOneWidget);
        expect(find.text(ltrIsolate('0.1.0 (1)')), findsOneWidget);

        await tester.tap(find.text(l10n.legalTerms));
        await tester.tap(find.text(l10n.legalPrivacy));
        expect(opened.map((u) => u.toString()), ['https://qesma.app/terms', 'https://qesma.app/privacy']);
      });

      testWidgets('omitted: role badge, avatar photo, notifications, currency, payment handles, export, devices, delete account, phone', (tester) async {
        await openHub(tester, server, locale: locale);
        final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join('\n');
        for (final banned in [
          'مسؤول المجموعة', 'Group admin', 'التنبيهات', 'Notifications', 'العملة الافتراضية', 'Default currency', 'InstaPay', 'إنستا', 'تصدير', 'Export',
          'الأجهزة النشطة', 'Active devices', 'حذف الحساب', 'Delete account', 'الخروج من كل الأجهزة', 'everywhere', 'رقم الموبايل', 'Phone',
        ]) {
          expect(all.contains(banned), isFalse, reason: 'found "$banned"');
        }
        expect(find.byIcon(Icons.camera_alt), findsNothing);
      });

      testWidgets('semantics: rows are read as title, value and button; the sign-out button is reachable', (tester) async {
        final handle = tester.ensureSemantics();
        await openHub(tester, server, locale: locale);
        final value = locale == _ar ? l10n.languageArabic : l10n.languageEnglish;
        final node = tester.getSemantics(find.bySemanticsLabel('${l10n.profileLanguage}، $value'));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(find.bySemanticsLabel(l10n.homeSignOut), findsWidgets);
        handle.dispose();
      });

      testWidgets('no overflow at text scale 2.0', (tester) async {
        await openHub(tester, server, locale: locale, textScale: 2.0, height: 4000);
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.profileTitle), findsWidgets);
      });

      testWidgets('sign out asks first, then returns to the welcome screen', (tester) async {
        await openHub(tester, server, locale: locale);
        await tester.scrollUntilVisible(find.text(l10n.homeSignOut), 200, scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text(l10n.homeSignOut));
        await tester.pumpAndSettle();
        expect(find.text(l10n.profileSignOutTitle), findsOneWidget);
        await tester.tap(find.text(l10n.commonCancel));
        await tester.pumpAndSettle();
        expect(find.text(l10n.profileTitle), findsWidgets, reason: 'cancelled: still signed in');

        await tester.tap(find.text(l10n.homeSignOut));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.homeSignOut).last);
        await tester.pumpAndSettle();
        expect(find.text(l10n.welcomeStart), findsOneWidget);
      });
    });

    group('Edit profile ($name)', () {
      Future<void> openEdit(WidgetTester tester) async {
        await openHub(tester, server, locale: locale);
        await tester.tap(find.text(l10n.profileEdit));
        await tester.pumpAndSettle();
      }

      Finder nameField() => find.byType(TextField).first;

      testWidgets('prefilled, save is off until the name changes, then saves the trimmed name and shows it on the hub', (tester) async {
        await openEdit(tester);
        expect(tester.widget<TextField>(nameField()).controller!.text, 'Test User');
        expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.profileSave)).onPressed, isNull);
        expect(find.text('test@example.com'), findsOneWidget, reason: 'the email is shown, read only');

        await tester.enterText(nameField(), '  Mohamed Ramadan ');
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.profileSave));
        await tester.pumpAndSettle();
        expect(server.meUpdates, [
          {'displayName': 'Mohamed Ramadan'}
        ]);
        expect(find.text(l10n.profileSaved), findsOneWidget);
        expect(find.text('Mohamed Ramadan'), findsOneWidget, reason: 'the hub shows the new name at once');
      });

      testWidgets('empty and too long names are explained and cannot be saved', (tester) async {
        await openEdit(tester);
        await tester.enterText(nameField(), '');
        await tester.pumpAndSettle();
        expect(find.text(l10n.profileNameRequired), findsOneWidget);
        expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.profileSave)).onPressed, isNull);
        await tester.enterText(nameField(), 'x' * 70);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(nameField()).controller!.text.length, 60, reason: 'the field stops at 60');
        expect(server.meUpdates, isEmpty);
      });

      testWidgets('leaving with a changed name asks first; unchanged leaves without asking', (tester) async {
        await openEdit(tester);
        await tester.tap(find.byTooltip(l10n.commonBack));
        await tester.pumpAndSettle();
        expect(find.text(l10n.profileTitle), findsWidgets);
        expect(find.text(l10n.profileDiscardTitle), findsNothing);

        await tester.tap(find.text(l10n.profileEdit));
        await tester.pumpAndSettle();
        await tester.enterText(nameField(), 'Other');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(l10n.commonBack));
        await tester.pumpAndSettle();
        expect(find.text(l10n.profileDiscardTitle), findsOneWidget);
        await tester.tap(find.text(l10n.profileDiscardConfirm));
        await tester.pumpAndSettle();
        expect(find.text('Test User'), findsOneWidget);
        expect(server.meUpdates, isEmpty);
      });

      testWidgets('offline: the form is kept, the failure is shown, and the offline banner appears; saving works again later', (tester) async {
        await openEdit(tester);
        await tester.enterText(nameField(), 'Mohamed');
        await tester.pumpAndSettle();
        server.offline = true;
        await tester.tap(find.text(l10n.profileSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.errorNoConnection), findsOneWidget);
        expect(find.text(l10n.stateOfflineBanner), findsOneWidget, reason: 'the shared offline banner');
        expect(tester.widget<TextField>(nameField()).controller!.text, 'Mohamed');
        server.offline = false;
        await tester.tap(find.text(l10n.profileSave));
        await tester.pumpAndSettle();
        expect(find.text(l10n.stateOfflineBanner), findsNothing, reason: 'the next answer clears it');
        expect(server.meName, 'Mohamed');
      });

      testWidgets('no overflow at text scale 2.0', (tester) async {
        await openHub(tester, server, locale: locale, textScale: 2.0, height: 4000);
        await tester.tap(find.text(l10n.profileEdit));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Account settings ($name)', () {
      testWidgets('only the connected Google account and sign out', (tester) async {
        await openHub(tester, server, locale: locale);
        await tester.tap(find.text(l10n.profileAccountSettings));
        await tester.pumpAndSettle();
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text(l10n.accountConnected), findsOneWidget);
        expect(find.text(l10n.homeSignOut), findsOneWidget);
        expect(find.text(l10n.profileLanguage), findsNothing);
      });
    });

    group('Shared offline and error states ($name)', () {
      // Every feature that reads the server, opened while the connection is down.
      final screens = <String, String Function(FakeExpensesServer)>{
        'groups list': (s) => Routes.home,
        'group home (expenses tab)': (s) => Routes.group(s.gid),
        'balances tab': (s) => '${Routes.group(s.gid)}?tab=balances',
        'expense details': (s) => Routes.expense(s.gid, s.expenses.first['id'] as String),
        'edit expense': (s) => Routes.editExpense(s.gid, s.expenses.first['id'] as String),
      };
      screens.forEach((label, routeOf) {
        testWidgets('$label: no connection shows the offline state and the shared banner, with a retry', (tester) async {
          final balances = label == 'balances tab' ? FakeBalancesServer() : FakeExpensesServer();
          seedAllFixtures(balances);
          balances.offline = true;
          await openHub(tester, balances, locale: locale, route: routeOf(balances));
          final offlineState = find.text(l10n.stateNoInternetTitle);
          expect(offlineState, findsWidgets, reason: label);
          expect(find.text(l10n.stateOfflineBanner), findsOneWidget, reason: '$label: the banner');
          expect(find.text(l10n.commonRetry), findsWidgets);

          balances.offline = false;
          await tester.tap(find.text(l10n.commonRetry).first);
          await tester.pumpAndSettle();
          expect(find.text(l10n.stateOfflineBanner), findsNothing, reason: '$label: back online after an answer');
        });
      });

      testWidgets('a server error shows the generic error with the request id and a retry', (tester) async {
        final balances = FakeBalancesServer()..failNextBalances = true;
        await openHub(tester, balances, locale: locale, route: '${Routes.group(balances.gid)}?tab=balances');
        expect(find.textContaining('req-500', findRichText: true), findsOneWidget);
        expect(find.text(l10n.commonRetry), findsOneWidget);
        expect(find.text(l10n.stateOfflineBanner), findsNothing, reason: 'the server answered: we are online');
      });
    });
  }

  group('language switch (ar -> en)', () {
    testWidgets('applies at once, flips to left-to-right, and is remembered', (tester) async {
      final prefs = await openHub(tester, server);
      expect(Directionality.of(tester.element(find.text('حسابي').first)), TextDirection.rtl);
      await tester.tap(find.text(l10nFor(_ar).profileLanguage));
      await tester.pumpAndSettle();
      expect(find.text(l10nFor(_ar).languageSheetTitle), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsWidgets);
      expect(Directionality.of(tester.element(find.text('Account').first)), TextDirection.ltr);
      expect(prefs.values[kLocalePref], 'en');
    });
  });

  group('bottom navigation', () {
    testWidgets('only Groups and Account; screens pushed from them cover the bar', (tester) async {
      await openHub(tester, server, route: Routes.home);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination)), findsNWidgets(2));
      await tester.tap(find.text('Dahab'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing, reason: 'the group screen covers the bar');
    });
  });
}
