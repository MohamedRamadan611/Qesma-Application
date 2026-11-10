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

/// Flutter's own accessibility guidelines (tap target size, labelled tap targets, text contrast)
/// run on the key screens in BOTH themes and both languages. Contrast is measured on the rendered
/// pixels, so it also catches colours the palette test cannot see.
void main() {
  setUpAll(loadAppFonts);

  final screens = <String, (FakeExpensesServer Function(), String Function(FakeExpensesServer))>{
    'groups list': (() => FakeBalancesServer(), (s) => Routes.home),
    'account hub': (() => FakeBalancesServer(), (s) => Routes.account),
    'balances tab': (() => FakeBalancesServer(), (s) => '${Routes.group(s.gid)}?tab=balances'),
    'expenses tab': (() => FakeExpensesServer()..seedAll(), (s) => Routes.group(s.gid)),
    'expense details': (() => FakeExpensesServer()..seedAll(), (s) => Routes.expense(s.gid, '7e3b3a23-d844-4889-99ae-5cba254d1173')),
    'add expense': (() => FakeExpensesServer(), (s) => Routes.addExpense(s.gid)),
  };

  for (final dark in [false, true]) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      screens.forEach((name, spec) {
        testWidgets('$name (${dark ? 'dark' : 'light'}, ${locale.languageCode}): tap targets, labels and text contrast', (tester) async {
          final handle = tester.ensureSemantics();
          final server = spec.$1();
          await pumpExpensesApp(tester, server, locale: locale, height: 2000, route: spec.$2(server), overrides: [
            preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({kThemeModePref: dark ? 'dark' : 'light'})),
          ]);
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      });
    }
  }
}

extension on FakeExpensesServer {
  void seedAll() => seedAllFixtures(this);
}
