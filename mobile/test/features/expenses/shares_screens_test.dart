import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/core/widgets/widgets.dart' show fsIsolate;
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/shares_fixture.dart';
import '../../support/test_app.dart';

const Locale _ar = Locale('ar');
const Locale _en = Locale('en');
const int _unit = FakeExpensesServer.sharesPiastersPerUnit; // the fake server's own amount per unit, not the engine's

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() => server = FakeExpensesServer());

  Future<ProviderContainer> openAdd(WidgetTester tester, {Locale locale = _ar, double scale = 1.0}) async {
    final container = await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: 3200, route: Routes.addExpense(server.gid));
    await settleForm(tester);
    return container;
  }

  Future<void> openShares(WidgetTester tester, Locale locale, {String title = 'Rent', String amount = '9000'}) async {
    await tester.enterText(find.byType(TextField).at(0), title);
    await tester.enterText(find.byType(TextField).at(1), amount);
    await settleForm(tester);
    await chooseSplit(tester, l10nFor(locale).expenseSplitShares);
    await settleForm(tester);
  }

  ExpenseFormController controllerOf(ProviderContainer c) => c.read(expenseFormControllerProvider((gid: server.gid, eid: null)).notifier);

  Finder minusButtons() => find.widgetWithIcon(IconButton, Icons.remove);
  Finder plusButtons() => find.widgetWithIcon(IconButton, Icons.add);

  Map<String, dynamic> lastParticipant(String memberId) =>
      ((server.previewBodies.last['shareParticipants'] as List).cast<Map<String, dynamic>>()).firstWhere((p) => p['memberId'] == memberId);

  for (final locale in [_ar, _en]) {
    final l10n = l10nFor(locale);
    final lang = locale.languageCode;

    group('the shares editor ($lang)', () {
      testWidgets('is the fifth split method; it lists everyone with one share and shows only the server\'s amounts', (tester) async {
        await openAdd(tester, locale: locale);
        await tester.enterText(find.byType(TextField).at(0), 'Rent');
        await tester.enterText(find.byType(TextField).at(1), '9000');
        await settleForm(tester);
        await chooseSplit(tester, l10n.expenseSplitShares);
        await settleForm(tester);

        expect(find.text(l10n.expenseSplitShares), findsWidgets);
        expect(find.text(l10n.sharesHint), findsOneWidget);
        expect(find.text('Mohamed'), findsWidgets);
        // Three people, 1 unit each: the fake server owes each 1 x its unit amount (not 3,000 each).
        expect(find.text(money(locale, _unit)), findsNWidgets(3));
        expect(find.text(money(locale, 300000)), findsNothing, reason: 'the app never divides the total itself');
        expect(server.previewBodies.last['splitType'], 'SHARES');
        expect((server.previewBodies.last['shareParticipants'] as List).length, 3);
        expect(server.previewBodies.last.containsKey('periodFrom'), isFalse);
        expect(find.text(l10n.sharesUnitsOne), findsNWidgets(3), reason: 'the units the server took, per person');
      });

      testWidgets('the stepper changes one person; the amounts follow the new preview and never show old numbers meanwhile', (tester) async {
        await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        await tester.tap(plusButtons().first);
        await tester.pump();
        expect(find.text(money(locale, _unit)), findsNothing, reason: 'amounts of an older question are not shown');
        await settleForm(tester);
        expect(find.text(money(locale, 2 * _unit)), findsOneWidget);
        expect(find.text(money(locale, _unit)), findsNWidgets(2));
        expect(lastParticipant(kYou)['shareUnits'], 2);
        expect(find.text(l10n.sharesUnitsTwo), findsOneWidget);
      });

      testWidgets('units stay between 1 and 100: minus is off at 1 and plus is off at 100', (tester) async {
        final container = await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        expect(tester.widget<IconButton>(minusButtons().first).onPressed, isNull);
        expect(tester.widget<IconButton>(plusButtons().first).onPressed, isNotNull);
        controllerOf(container).stepShareUnits(kYou, 99);
        await settleForm(tester);
        expect(tester.widget<IconButton>(plusButtons().first).onPressed, isNull);
        expect(tester.widget<IconButton>(minusButtons().first).onPressed, isNotNull);
        expect(find.text(money(locale, 100 * _unit)), findsOneWidget);
        // Beyond the range the controller itself clamps (a spoken "increase" cannot pass 100 either).
        controllerOf(container).stepShareUnits(kYou, 1);
        expect(container.read(expenseFormControllerProvider((gid: server.gid, eid: null))).form!.shares.rowOf(kYou)!.units, 100);
      });

      testWidgets('the billing period is off by default; turning it on opens the range picker and cancelling keeps it off', (tester) async {
        await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        expect(find.text(l10n.sharesFullPeriod), findsNothing, reason: 'no presence controls without a period');
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.byType(DateRangePickerDialog), findsOneWidget);
        await tester.tap(find.descendant(of: find.byType(DateRangePickerDialog), matching: find.byIcon(Icons.close)));
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(find.text(l10n.sharesFullPeriod), findsNothing);
      });

      testWidgets('with a period each person has "full period"; a presence range is picked inside the period and reset', (tester) async {
        final container = await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        controllerOf(container).setPeriod(Date(2026, 11, 1), Date(2026, 11, 30));
        await settleForm(tester);

        expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
        expect(find.text(l10n.sharesFullPeriod), findsNWidgets(3));
        expect(server.previewBodies.last['periodFrom'], '2026-11-01');
        expect(server.previewBodies.last['periodTo'], '2026-11-30');
        // The range the server used is shown as the server stored it, and no day count is shown anywhere.
        final period = l10n.sharesDaysPresentLine(l10n.sharesRange(isolated('2026-11-01'), isolated('2026-11-30')));
        expect(find.textContaining(period), findsNWidgets(3));
        expect(find.textContaining(RegExp(r'\b30 (يوم|days)')), findsNothing);

        // Third person: pick 12..30 Nov in a picker bounded to the period.
        await tester.ensureVisible(find.text(l10n.sharesFullPeriod).last);
        await tester.tap(find.text(l10n.sharesFullPeriod).last);
        await tester.pumpAndSettle();
        expect(find.byType(DateRangePickerDialog), findsOneWidget);
        await tester.tap(find.descendant(of: find.byType(DateRangePickerDialog), matching: find.text('12')).first);
        await tester.pump();
        await tester.tap(find.descendant(of: find.byType(DateRangePickerDialog), matching: find.text('30')).first);
        await tester.pump();
        await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(DateRangePickerDialog))).saveButtonLabel));
        await tester.pumpAndSettle();
        await settleForm(tester);

        expect(lastParticipant(kMohsen)['presentFrom'], '2026-11-12');
        expect(lastParticipant(kMohsen)['presentTo'], '2026-11-30');
        expect(lastParticipant(kYou).containsKey('presentFrom'), isFalse, reason: 'the full period is sent as absent bounds');
        expect(find.byTooltip(l10n.sharesPresenceReset), findsOneWidget);

        await tester.tap(find.byTooltip(l10n.sharesPresenceReset));
        await settleForm(tester);
        expect(lastParticipant(kMohsen).containsKey('presentFrom'), isFalse);
        expect(find.byTooltip(l10n.sharesPresenceReset), findsNothing);
      });

      testWidgets('changing the period resets a presence range that is no longer inside it, and turning it off clears them all', (tester) async {
        final container = await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        final c = controllerOf(container);
        c.setPeriod(Date(2026, 11, 1), Date(2026, 11, 30));
        c.setPresence(kMohsen, Date(2026, 11, 12), Date(2026, 11, 30));
        c.setPresence(kAsem, Date(2026, 11, 5), Date(2026, 11, 10));
        c.setPeriod(Date(2026, 11, 8), Date(2026, 11, 30));
        final rows = container.read(expenseFormControllerProvider((gid: server.gid, eid: null))).form!.shares;
        expect(rows.rowOf(kAsem)!.hasPresence, isFalse, reason: 'it started before the new period');
        expect(rows.rowOf(kMohsen)!.hasPresence, isTrue, reason: 'it is still inside');
        c.clearPeriod();
        final off = container.read(expenseFormControllerProvider((gid: server.gid, eid: null))).form!.shares;
        expect(off.periodOn, isFalse);
        expect(off.rows.every((r) => !r.hasPresence), isTrue);
        await settleForm(tester);
        expect(server.previewBodies.last.containsKey('periodFrom'), isFalse);
      });

      testWidgets('Edit people: the picker drops and adds people; a new person starts with the default share', (tester) async {
        server.group.members.firstWhere((m) => m.id == kAsem).defaultShareUnits = 4;
        await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        expect(lastParticipant(kAsem)['shareUnits'], 4);
        await tester.tap(find.text(l10n.sharesEditPeople));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Asem')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.expenseItzPickerDone('2')));
        await tester.pumpAndSettle();
        await settleForm(tester);
        expect((server.previewBodies.last['shareParticipants'] as List).map((p) => (p as Map)['memberId']), [kYou, kMohsen]);
        expect(lastParticipant(kMohsen)['shareUnits'], 1);
        await tester.tap(find.text(l10n.sharesEditPeople));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Asem')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.expenseItzPickerDone('3')));
        await tester.pumpAndSettle();
        await settleForm(tester);
        expect((server.previewBodies.last['shareParticipants'] as List).length, 3);
      });

      testWidgets('a member\'s default share is the starting units when switching to shares', (tester) async {
        server.group.members.firstWhere((m) => m.id == kAsem).defaultShareUnits = 3;
        await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        expect(lastParticipant(kAsem)['shareUnits'], 3);
        expect(lastParticipant(kYou)['shareUnits'], 1);
        expect(find.text(money(locale, 3 * _unit)), findsOneWidget);
      });

      testWidgets('a 422 naming shareParticipants[1].shareUnits is shown under the second person, in our words', (tester) async {
        await openAdd(tester, locale: locale);
        server.sharesProblemTitle = 'shareParticipants[1].shareUnits must be between 1 and 100';
        await openShares(tester, locale);
        expect(find.text(l10n.sharesErrUnits), findsOneWidget);
        expect(find.textContaining('must be between'), findsNothing, reason: 'the server\'s English text is never shown');
        final second = tester.getTopLeft(find.text('Asem')).dy;
        final error = tester.getTopLeft(find.text(l10n.sharesErrUnits)).dy;
        final third = tester.getTopLeft(find.text('Mohsen')).dy;
        expect(error, greaterThan(second));
        expect(error, lessThan(third));
      });

      testWidgets('a 422 naming periodTo is shown under the billing period', (tester) async {
        final container = await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        server.sharesProblemTitle = 'periodTo must not be before periodFrom';
        controllerOf(container).setPeriod(Date(2026, 11, 1), Date(2026, 11, 30));
        await settleForm(tester);
        expect(find.text(l10n.sharesErrPeriod), findsOneWidget);
        expect(find.text(l10n.sharesErrUnits), findsNothing);
        expect(tester.getTopLeft(find.text(l10n.sharesErrPeriod)).dy, greaterThan(tester.getTopLeft(find.text(l10n.sharesPeriodTitle)).dy));
      });

      testWidgets('saving sends the SHARES body (idempotent create) and opens the new expense', (tester) async {
        final container = await openAdd(tester, locale: locale);
        await openShares(tester, locale);
        controllerOf(container).stepShareUnits(kYou, 1);
        await settleForm(tester);
        final save = find.widgetWithText(FilledButton, l10n.expenseFormSave);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(server.creates, hasLength(1));
        final body = server.creates.single.body;
        expect(body['splitType'], 'SHARES');
        expect(body['totalMinor'], 900000);
        expect((body['shareParticipants'] as List).map((p) => (p as Map)['shareUnits']), [2, 1, 1]);
        for (final key in ['participantMemberIds', 'shares', 'items', 'periodFrom']) {
          expect(body.containsKey(key), isFalse, reason: key);
        }
        expect(server.creates.single.key, isNotNull);
      });
    });
  }

  testWidgets('at text scale 2.0 the editor with a period and a presence range lays out without overflow (ar and en)', (tester) async {
    for (final locale in [_ar, _en]) {
      final container = await openAdd(tester, locale: locale, scale: 2.0);
      await openShares(tester, locale);
      final c = controllerOf(container);
      c.setPeriod(Date(2026, 11, 1), Date(2026, 11, 30));
      c.setPresence(kMohsen, Date(2026, 11, 12), Date(2026, 11, 30));
      await settleForm(tester);
      expect(tester.takeException(), isNull);
      for (final button in tester.widgetList<IconButton>(find.byType(IconButton))) {
        expect(button.constraints?.minHeight ?? 48, greaterThanOrEqualTo(44));
      }
      expect(find.text(l10nFor(locale).sharesPeriodTitle), findsOneWidget);
      container.dispose();
    }
  });

  group('a saved shares expense', () {
    Future<void> seed() async {
      final json = sharesExpenseJson();
      server.expenses.add(json);
      server.revisions['shares-1'] = [
        {'version': 1, 'changeType': 'CREATE', 'changedAt': '2026-11-09T10:00:00Z', 'changedByUserId': 'u1', 'snapshot': json},
      ];
    }

    for (final locale in [_ar, _en]) {
      final l10n = l10nFor(locale);
      testWidgets('${locale.languageCode}: details show the period, each person\'s units and presence range as the server stored them, and Edit is enabled', (tester) async {
        await seed();
        await pumpExpensesApp(tester, server, locale: locale, route: Routes.expense(server.gid, 'shares-1'), textScale: 2.0);
        expect(find.text(l10n.expenseSplitShares), findsWidgets);
        final range = l10n.sharesRange(isolated('2026-11-01'), isolated('2026-11-30'));
        expect(find.text(l10n.sharesPeriodLine(range)), findsOneWidget);
        await reveal(tester, find.textContaining(l10n.sharesUnitsTwo));
        expect(find.textContaining(l10n.sharesUnitsTwo), findsOneWidget);
        expect(find.textContaining(l10n.sharesDaysPresentLine(l10n.sharesRange(isolated('2026-11-12'), isolated('2026-11-30')))), findsOneWidget);
        expect(find.text(money(locale, 495413)), findsWidgets);
        final edit = find.widgetWithText(FilledButton, l10n.expenseEdit);
        await reveal(tester, edit);
        expect(tester.widget<FilledButton>(edit).onPressed, isNotNull);
      });

      testWidgets('${locale.languageCode}: the history sheet lists the period and one compact line per person', (tester) async {
        await seed();
        await pumpExpensesApp(tester, server, locale: locale, route: Routes.expense(server.gid, 'shares-1'));
        await reveal(tester, find.text(l10n.expenseHistory));
        await tapText(tester, l10n.expenseHistory);
        expect(find.text(l10n.sharesPeriodLine(l10n.sharesRange(isolated('2026-11-01'), isolated('2026-11-30')))), findsWidgets);
        expect(
          find.text(l10n.sharesHistoryRow(fsIsolate('Mohsen'), l10n.sharesUnitsOne, l10n.sharesRange(isolated('2026-11-12'), isolated('2026-11-30')))),
          findsOneWidget,
        );
        expect(find.textContaining(l10n.sharesUnitsTwo), findsWidgets);
      });
    }

    testWidgets('Edit opens the shares form with the saved units, period and presence; saving sends a PUT with the same SHARES shape', (tester) async {
      await seed();
      await pumpExpensesApp(tester, server, route: Routes.editExpense(server.gid, 'shares-1'), height: 3200);
      await settleForm(tester);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(l10nFor(_ar).sharesFullPeriod), findsNWidgets(2));
      expect(find.textContaining(l10nFor(_ar).sharesUnitsTwo), findsWidgets);
      final save = find.widgetWithText(FilledButton, l10nFor(_ar).expenseFormSaveChanges);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(server.updates, hasLength(1));
      final body = server.updates.single;
      expect(body['splitType'], 'SHARES');
      expect(body['periodFrom'], '2026-11-01');
      final people = (body['shareParticipants'] as List).cast<Map<String, dynamic>>();
      expect(people.map((p) => p['shareUnits']), [2, 1, 1]);
      expect(people[2]['presentFrom'], '2026-11-12');
      expect(people[0].containsKey('presentFrom'), isFalse);
    });
  });
}
