import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/budget/presentation/budget_screen.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/insights/budget_summary_provider.dart';
import 'package:qesma/local/insights/budget_summary_repository.dart';

import '../../local/backend/support/local_http.dart';
import '../../support/test_app.dart' show allConfigs, loadAppFonts;

/// SA20 UI (STANDALONE_SPEC 20) in ar/en at text scale 1.0 and 2.0 on the real local backend: the Budget section of
/// Edit group (save sends only what changed, clear, invalid amount, an end date that cannot precede the start) and
/// the card and screen with fixed `BudgetSummary` literals (under budget, exactly at it, over it, with and without
/// trip dates, no expenses). Any layout overflow fails the test. The server-mode absence is the mode guard's.
const _under = BudgetSummary(
  budgetMinor: 500000,
  spentMinor: 120000,
  remainingMinor: 380000,
  overBudget: false,
  overByMinor: null,
  progressBps: 2400,
  barFillBps: 2400,
  perDay: [BudgetDay(date: '2026-11-13', totalMinor: 70000), BudgetDay(date: '2026-11-12', totalMinor: 50000)],
  elapsedDays: 3,
  dailyAverageMinor: 40000,
  daysLeft: 4,
  perDayLeftMinor: 95000,
  costPerHeadMinor: 125000,
);
const _exactly = BudgetSummary(
  budgetMinor: 500000,
  spentMinor: 500000,
  remainingMinor: 0,
  overBudget: false,
  overByMinor: null,
  progressBps: 10000,
  barFillBps: 10000,
  perDay: [BudgetDay(date: '2026-11-13', totalMinor: 500000)],
  elapsedDays: null,
  dailyAverageMinor: null,
  daysLeft: null,
  perDayLeftMinor: null,
  costPerHeadMinor: null,
);
const _over = BudgetSummary(
  budgetMinor: 500000,
  spentMinor: 600000,
  remainingMinor: -100000,
  overBudget: true,
  overByMinor: 100000,
  progressBps: 12000,
  barFillBps: 10000,
  perDay: [BudgetDay(date: '2026-11-13', totalMinor: 600000)],
  elapsedDays: 2,
  dailyAverageMinor: 300000,
  daysLeft: null,
  perDayLeftMinor: null,
  costPerHeadMinor: 125000,
);
const _empty = BudgetSummary(
  budgetMinor: 500000,
  spentMinor: 0,
  remainingMinor: 500000,
  overBudget: false,
  overByMinor: null,
  progressBps: 0,
  barFillBps: 0,
  perDay: [],
  elapsedDays: null,
  dailyAverageMinor: null,
  daysLeft: null,
  perDayLeftMinor: null,
  costPerHeadMinor: null,
);

void main() {
  setUpAll(loadAppFonts);

  late LocalHttp http;
  late String gid; // no budget
  late String budgetGid; // budget 5,000.00
  // Real database I/O never completes inside testWidgets (fake async): every group is made here, and reads in a test
  // go through tester.runAsync.
  late String siwaGid, exactlyGid, overGid, emptyGid;

  Future<String> newGroup(String name, [Map<String, dynamic> patch = const {}]) async {
    final id = (await http.group(name: name))['id'] as String;
    await http.member(id, 'Asem');
    if (patch.isNotEmpty) expect((await http.patch('/groups/$id', patch, ifMatch: '"1"')).statusCode, 200);
    return id;
  }

  Future<Map<String, dynamic>> read(String id) async => (await http.get('/groups/$id')).data as Map<String, dynamic>;

  setUp(() async {
    http = await LocalHttp.open(profileName: 'Mona');
    gid = await newGroup('Flat');
    budgetGid = await newGroup('Dahab', {'budgetMinor': 500000});
    siwaGid = await newGroup('Siwa', {'budgetMinor': 500000, 'tripStartDate': '2099-05-10'});
    exactlyGid = await newGroup('Exact', {'budgetMinor': 500000});
    overGid = await newGroup('Over', {'budgetMinor': 500000});
    emptyGid = await newGroup('Empty', {'budgetMinor': 500000});
  });
  tearDown(() => http.close());

  for (final config in allConfigs) {
    Future<(AppLocalizations, void Function(String), Future<void> Function(String))> pump(
      WidgetTester tester, {
      Map<String, BudgetSummary> summaries = const {},
    }) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 900);
      tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = ProviderContainer(overrides: [
        ...localModeOverrides(http.db),
        for (final e in summaries.entries) budgetSummaryProvider(e.key).overrideWith((ref) => Stream.value(e.value)),
      ]);
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

      return (l10n, (_) {}, go);
    }

    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.dragUntilVisible(finder, find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
    }

    final amountField = find.descendant(of: find.byType(AmountBox), matching: find.byType(TextField));

    testWidgets('edit group: enter an amount and save sends only the budget (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.editGroup(gid));
      await reveal(tester, find.text(l10n.budgetSectionTitle));
      expect(find.text(l10n.budgetSectionHint), findsOneWidget);
      expect(find.text(l10n.budgetClear), findsNothing, reason: 'nothing to remove yet');
      await reveal(tester, amountField);
      await tester.enterText(amountField, '1500');
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupSaveChanges));
      await tester.tap(find.text(l10n.groupSaveChanges));
      await tester.pumpAndSettle();
      final saved = (await tester.runAsync(() => read(gid)))!;
      expect(saved['budgetMinor'], 150000);
      expect(saved['name'], 'Flat');
      expect(saved['tripStartDate'], isNull);
    });

    testWidgets('create group: pool and budget are one radio choice; budget saves with the group (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.newGroup);
      await reveal(tester, find.text(l10n.groupBudgetToggle));
      expect(find.text(l10n.groupMoneyModeLocked), findsOneWidget);
      expect(amountField, findsNothing, reason: 'nothing extra is the default');
      await tester.tap(find.text(l10n.groupPoolToggle));
      await tester.pumpAndSettle();
      expect(find.text(l10n.groupPoolWho), findsOneWidget);
      expect(amountField, findsNothing, reason: 'a pool group has no budget form');
      await tester.tap(find.text(l10n.groupBudgetToggle));
      await tester.pumpAndSettle();
      expect(find.text(l10n.groupPoolWho), findsNothing, reason: 'a budget group has no treasurer');
      await reveal(tester, amountField);
      await tester.enterText(find.byType(TextField).first, 'Siwa trip');
      await tester.enterText(amountField, '2500');
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupCreateButton));
      await tester.tap(find.text(l10n.groupCreateButton));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      final groups = (await tester.runAsync(() => http.get('/groups')))!.data;
      final listed = (groups['items'] as List).cast<Map<String, dynamic>>().firstWhere((g) => g['name'] == 'Siwa trip');
      final created = (await tester.runAsync(() => read(listed['id'] as String)))!;
      expect(created['budgetMinor'], 250000);
      expect(created.containsKey('treasurerMemberId'), isFalse);
    });

    testWidgets('edit group: add to the budget raises it by the typed amount (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.editGroup(budgetGid));
      final topUp = find.descendant(of: find.byType(AmountBox).at(1), matching: find.byType(TextField));
      await reveal(tester, topUp);
      await tester.enterText(topUp, '1000');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, l10n.budgetTopUpAction));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(amountField.first).controller!.text, '6000');
      await reveal(tester, find.text(l10n.groupSaveChanges));
      await tester.tap(find.text(l10n.groupSaveChanges));
      await tester.pumpAndSettle();
      expect(((await tester.runAsync(() => read(budgetGid)))!)['budgetMinor'], 600000);
    });

    testWidgets('groups list: long press opens archive and delete; delete removes the group (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.home);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      await reveal(tester, find.text('Over'));
      await tester.longPress(find.text('Over'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.archiveAction), findsOneWidget);
      expect(find.text(l10n.groupDelete), findsOneWidget);
      await tester.tap(find.text(l10n.groupDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, l10n.commonDelete).last);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      final status = (await tester.runAsync(() => http.get('/groups/$overGid')))!.statusCode;
      expect(status, 404);
    });

    testWidgets('edit group: an invalid amount shows the error and disables save (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.editGroup(gid));
      await reveal(tester, amountField);
      await tester.enterText(amountField, '0');
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupSaveChanges));
      expect(find.text(l10n.budgetAmountError), findsOneWidget);
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.groupSaveChanges)).onPressed, isNull);
    });

    testWidgets('edit group: remove budget clears it (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester);
      await go(Routes.editGroup(budgetGid));
      await reveal(tester, find.text(l10n.budgetClear));
      await tester.tap(find.text(l10n.budgetClear));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupSaveChanges));
      await tester.tap(find.text(l10n.groupSaveChanges));
      await tester.pumpAndSettle();
      expect(((await tester.runAsync(() => read(budgetGid)))!)['budgetMinor'], isNull);
    });

    testWidgets('edit group: the end date cannot precede the start and can be cleared (${config.name})', (tester) async {
      final id = siwaGid;
      final (l10n, _, go) = await pump(tester);
      await go(Routes.editGroup(id));
      await reveal(tester, find.text(l10n.budgetEndLabel));
      await tester.tap(find.text(l10n.budgetEndLabel));
      await tester.pumpAndSettle();
      expect(tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker)).firstDate, DateTime(2099, 5, 10));
      await tester.tap(find.text('20'));
      await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(CalendarDatePicker))).okButtonLabel));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupSaveChanges));
      await tester.tap(find.text(l10n.groupSaveChanges));
      await tester.pumpAndSettle();
      final saved = (await tester.runAsync(() => read(id)))!;
      expect(saved['tripEndDate'], '2099-05-20');
      expect(saved['tripStartDate'], '2099-05-10');

      // Clear the start date: the group keeps its end date only.
      await go(Routes.editGroup(id));
      await reveal(tester, find.byTooltip(l10n.budgetDateClear).first);
      await tester.tap(find.byTooltip(l10n.budgetDateClear).first);
      await tester.pumpAndSettle();
      await reveal(tester, find.text(l10n.groupSaveChanges));
      await tester.tap(find.text(l10n.groupSaveChanges));
      await tester.pumpAndSettle();
      final cleared = (await tester.runAsync(() => read(id)))!;
      expect(cleared['tripStartDate'], isNull);
      expect(cleared['tripEndDate'], '2099-05-20');
    });

    testWidgets('card: under budget, exactly at it, over it; hidden without a budget (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester, summaries: {budgetGid: _under, exactlyGid: _exactly, overGid: _over});
      String money(int minor) => moneyDisplay(l10n, minor);

      await go(Routes.group(budgetGid));
      expect(find.text(l10n.budgetCardTitle), findsOneWidget);
      expect(find.text(money(380000)), findsOneWidget);
      expect(find.text(l10n.budgetSpentOf(money(120000), money(500000))), findsOneWidget);
      expect(find.text(l10n.budgetProgress(ltrIsolate('24%'))), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      await go(Routes.group(exactlyGid));
      expect(find.text(money(0)), findsWidgets);
      expect(find.text(l10n.budgetProgress(ltrIsolate('100%'))), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing, reason: 'exactly at the budget is not over it');

      await go(Routes.group(overGid));
      expect(find.text(l10n.budgetOverBy(money(100000))), findsOneWidget, reason: 'over budget is said in words');
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text(l10n.budgetProgress(ltrIsolate('120%'))), findsOneWidget, reason: 'the bar is capped, the text is not');

      await go(Routes.group(gid));
      expect(find.text(l10n.budgetCardTitle), findsNothing);

      // The card opens the screen.
      await go(Routes.group(budgetGid));
      await tester.tap(find.text(l10n.budgetCardTitle));
      await tester.pumpAndSettle();
      expect(find.byType(BudgetScreen), findsOneWidget);
    });

    testWidgets('screen: with trip dates, without them, over budget and with no expenses (${config.name})', (tester) async {
      final (l10n, _, go) = await pump(tester, summaries: {budgetGid: _under, overGid: _over, emptyGid: _empty});
      String money(int minor) => moneyDisplay(l10n, minor);

      await go(Routes.budget(budgetGid));
      expect(find.text(l10n.budgetDailyAverage), findsOneWidget);
      expect(find.text(l10n.budgetOverDays(3)), findsOneWidget);
      expect(find.text(l10n.budgetPerDayLeft), findsOneWidget);
      expect(find.text(l10n.budgetDaysLeft(4)), findsOneWidget);
      expect(find.text(money(95000)), findsOneWidget);
      expect(find.text(l10n.budgetCostPerHead), findsOneWidget);
      expect(find.text(l10n.budgetCostPerHeadHint), findsOneWidget);
      await reveal(tester, find.text(ltrIsolate('2026-11-12')));
      expect(find.text(ltrIsolate('2026-11-13')), findsOneWidget);
      final newest = tester.getTopLeft(find.text(ltrIsolate('2026-11-13'))).dy;
      expect(newest, lessThan(tester.getTopLeft(find.text(ltrIsolate('2026-11-12'))).dy), reason: 'newest first');

      await go(Routes.budget(overGid));
      expect(find.text(l10n.budgetOverBy(money(100000))), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text(l10n.budgetPerDayLeft), findsNothing, reason: 'no trip dates, no per-day-left row');
      expect(find.text(l10n.budgetDaysLeft(4)), findsNothing);
      expect(find.text(l10n.budgetDailyAverage), findsOneWidget);

      await go(Routes.budget(emptyGid));
      await reveal(tester, find.text(l10n.budgetNoExpenses));
      expect(find.text(l10n.budgetDailyAverage), findsNothing);
      expect(find.text(l10n.budgetCostPerHead), findsNothing);
    });
  }
}
