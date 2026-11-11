import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/theme_mode_controller.dart';

import '../support/expenses_rig.dart';
import '../support/expenses_ui.dart';
import '../support/fake_balances_server.dart';
import '../support/fake_expenses_server.dart';
import '../support/test_app.dart';

/// FL9: every screen that is reachable by a route, in light and dark, Arabic and English:
///  - Flutter's accessibility guidelines (tap target size, labelled tap targets, text contrast), and
///  - at 2.0x text scale: no overflow or any other exception while the screen builds and settles.
/// (The sheets, dialogs and the auth screens are covered where they are opened: test/features/*, guidelines_test.dart and
/// auth/username_auth_test.dart, which run the same guidelines and 2.0x checks.)
void main() {
  setUpAll(loadAppFonts);

  const equalId = '7e3b3a23-d844-4889-99ae-5cba254d1173';
  final screens = <String, (FakeExpensesServer Function(), String Function(FakeExpensesServer))>{
    'new group': (() => FakeBalancesServer(), (s) => Routes.newGroup),
    'edit group': (() => FakeBalancesServer(), (s) => Routes.editGroup(s.gid)),
    'members tab': (() => FakeBalancesServer(), (s) => '${Routes.group(s.gid)}?tab=members'),
    'edit profile': (() => FakeBalancesServer(), (s) => Routes.editProfile),
    'account settings': (() => FakeBalancesServer(), (s) => Routes.accountSettings),
    'edit expense': (() => FakeExpensesServer()..seedAll(), (s) => Routes.editExpense(s.gid, equalId)),
    // the screens of guidelines_test.dart, here at 2.0x text for the overflow check
    'groups list': (() => FakeBalancesServer(), (s) => Routes.home),
    'account hub': (() => FakeBalancesServer(), (s) => Routes.account),
    'balances tab': (() => FakeBalancesServer(), (s) => '${Routes.group(s.gid)}?tab=balances'),
    'expenses tab': (() => FakeExpensesServer()..seedAll(), (s) => Routes.group(s.gid)),
    'expense details': (() => FakeExpensesServer()..seedAll(), (s) => Routes.expense(s.gid, equalId)),
    'add expense': (() => FakeExpensesServer(), (s) => Routes.addExpense(s.gid)),
  };

  // Screens that must contain a text field: proves the route really shows the form and not a redirect or an error page.
  const formScreens = {'new group', 'edit group', 'edit profile', 'edit expense', 'add expense'};

  // Screens whose pixel-contrast check is skipped, with the reason (the sampler is unreliable on very short words/icons).
  const skipContrast = <String, String>{};

  for (final dark in [false, true]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      screens.forEach((name, spec) {
        final label = '$name (${dark ? 'dark' : 'light'}, ${locale.languageCode})';
        testWidgets('$label: guidelines at 1.0x', (tester) async {
          final handle = tester.ensureSemantics();
          final server = spec.$1();
          await pumpExpensesApp(tester, server, locale: locale, height: 2000, route: spec.$2(server), overrides: [
            preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({kThemeModePref: dark ? 'dark' : 'light'})),
          ]);
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pumpAndSettle();
          expect(find.byType(Text), findsWidgets, reason: 'the screen rendered');
          if (formScreens.contains(name)) expect(find.byType(TextField), findsWidgets, reason: 'the form is on screen');
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          if (!skipContrast.containsKey(name)) await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });

        testWidgets('$label: builds at 2.0x text without overflow', (tester) async {
          final server = spec.$1();
          await pumpExpensesApp(tester, server, locale: locale, textScale: 2.0, height: 2000, route: spec.$2(server), overrides: [
            preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({kThemeModePref: dark ? 'dark' : 'light'})),
          ]);
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'overflow or another error at 2.0x text');
          // the screen must still be scrollable to its end without errors
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            await tester.drag(scrollable.first, const Offset(0, -3000));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'error while scrolling at 2.0x text');
          }
        });
      });
    }
  }
}

extension on FakeExpensesServer {
  void seedAll() => seedAllFixtures(this);
}
