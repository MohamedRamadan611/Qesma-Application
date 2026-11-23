import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';

import '../../local/backend/support/local_http.dart';
import '../../support/test_app.dart' show allConfigs, loadAppFonts;

/// SA10 UI on the real local backend, in ar/en at text scale 1.0 and 2.0: the pool card on the group home, the pool
/// screen (breakdown, deposits, a negative meter said in words), the deposit sheet, the expense-form switch (the
/// treasurer becomes the only payer and the payer editor is off), the locked treasurer in Edit group and the
/// balances note. Any layout overflow fails the test.
void main() {
  setUpAll(loadAppFonts);

  late LocalHttp http;
  late String gid; // positive meter: 600 deposited, 450 spent
  late String overdraftGid; // negative meter: 100 deposited, 300 spent
  late String plainGid; // no treasurer

  Future<String> poolGroup(String name, List<int> deposits, int spent) async {
    final g = await http.group(name: name);
    final id = g['id'] as String;
    final you = g['yourMemberId'] as String;
    final asem = await http.member(id, 'Asem');
    await http.member(id, 'Mohsen');
    expect((await http.patch('/groups/$id', {'treasurerMemberId': you}, ifMatch: '"1"')).statusCode, 200);
    for (final amount in deposits) {
      final r = await http.settlement(id, {'fromMemberId': asem, 'toMemberId': you, 'amountMinor': amount, 'settledOn': '2026-11-12', 'kind': 'POOL_DEPOSIT'});
      expect(r.statusCode, 201, reason: '${r.data}');
    }
    final e = await http.expense(id, {...equalBody(spent, [(id: you, amount: spent)], title: 'Fuel'), 'paidFromPool': true});
    expect(e.statusCode, 201, reason: '${e.data}');
    return id;
  }

  setUp(() async {
    http = await LocalHttp.open(profileName: 'Mona');
    gid = await poolGroup('Dahab', [30000, 30000], 45000);
    overdraftGid = await poolGroup('Siwa', [10000], 30000);
    plainGid = (await http.group(name: 'Flat'))['id'] as String;
  });
  tearDown(() => http.close());

  for (final config in allConfigs) {
    testWidgets('pool card, pool screen, deposit sheet, expense switch, edit group (${config.name})', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 900);
      tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = ProviderContainer(overrides: localModeOverrides(http.db));
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).set(config.locale);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      final router = container.read(routerProvider);
      Future<void> go(String location) async {
        router.go(location);
        await tester.pumpAndSettle();
      }

      String money(int minor) => moneyDisplay(l10n, minor);
      bool shows(String text) => find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

      // Group home: the compact card with the meter as the backend sent it (150.00 left).
      await go(Routes.group(gid));
      expect(find.text(l10n.poolBalanceLabel), findsOneWidget);
      expect(find.text(l10n.poolRemaining), findsOneWidget);
      expect(find.text(money(15000)), findsOneWidget);
      expect(find.text(l10n.poolAddDeposit), findsOneWidget);

      // No treasurer: no card.
      await go(Routes.group(plainGid));
      expect(find.text(l10n.poolBalanceLabel), findsNothing);

      // Pool screen: deposited, spent, left, and the deposits.
      await go(Routes.pool(gid));
      expect(find.text(l10n.poolDeposited), findsOneWidget);
      expect(find.text(money(60000)), findsOneWidget);
      expect(find.text(l10n.poolSpent), findsOneWidget);
      expect(find.text(money(45000)), findsOneWidget);
      expect(find.text(money(15000)), findsOneWidget);
      expect(find.text(money(30000)), findsNWidgets(2), reason: 'two deposits of 300.00');

      // Overdraft: said in words with a warning icon, never a bare red number.
      await go(Routes.pool(overdraftGid));
      expect(shows(l10n.poolCovered(money(20000))), isTrue);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text(l10n.poolCoveredHint), findsOneWidget);

      // The deposit sheet: fixed receiver in the subtitle, the depositor is not the treasurer.
      await go(Routes.pool(gid));
      await tester.tap(find.text(l10n.poolAddDeposit));
      await tester.pumpAndSettle();
      expect(find.text(l10n.poolDepositSheetTitle), findsOneWidget);
      expect(find.text(l10n.poolDepositFrom), findsOneWidget);
      expect(find.text(l10n.paymentTo), findsNothing, reason: 'the receiver is fixed to the treasurer');
      expect(find.text(l10n.poolDepositSave), findsOneWidget);
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      // Expense form: the switch makes the treasurer the only payer and turns the payer editor off.
      await go(Routes.addExpense(gid));
      final poolSwitch = find.widgetWithText(SwitchListTile, l10n.expensePaidFromPool);
      await tester.dragUntilVisible(poolSwitch, find.byType(ListView).first, const Offset(0, -200));
      await Scrollable.ensureVisible(tester.element(poolSwitch), alignment: 0.5); // clear of the sticky Save bar
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(poolSwitch).value, isFalse);
      await tester.tap(poolSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(poolSwitch).value, isTrue);
      expect(find.textContaining(l10n.expensePaidFromPool), findsWidgets);
      final editPayers = find.widgetWithText(AppButton, l10n.expenseFormChange);
      expect(tester.widget<AppButton>(editPayers).onPressed, isNull);

      // A group without a treasurer has no switch.
      await go(Routes.addExpense(plainGid));
      expect(find.widgetWithText(SwitchListTile, l10n.expensePaidFromPool), findsNothing);

      // Edit group: the treasurer is locked after the first deposit, with the reason in words.
      await go(Routes.editGroup(gid));
      expect(find.text(l10n.poolTreasurerLabel), findsOneWidget);
      expect(find.text(l10n.poolTreasurerLocked), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Edit group without a treasurer: pickable, not locked.
      await go(Routes.editGroup(plainGid));
      expect(find.text(l10n.poolTreasurerNone), findsOneWidget);
      expect(find.text(l10n.poolTreasurerLocked), findsNothing);

      // Balances: the one explanatory line, only with a pool.
      await go(Routes.home); // leave the group page under Edit, so the tab comes from the query
      await go('${Routes.group(gid)}?tab=balances');
      expect(find.text(l10n.balancesPoolNote), findsOneWidget);
      await go(Routes.home);
      await go('${Routes.group(plainGid)}?tab=balances');
      expect(find.text(l10n.balancesPoolNote), findsNothing);
    });
  }
}
