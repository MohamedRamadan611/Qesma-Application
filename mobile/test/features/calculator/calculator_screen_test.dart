import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/expenses/presentation/expense_form_screen.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/calculator/fuel_prices_repository.dart';

import '../../local/backend/support/local_http.dart';
import '../../support/test_app.dart' show allConfigs, loadAppFonts;

/// SA11 calculator on the real local backend, ar/en at text scale 1.0 and 2.0: the FAB menu, a fuel split with a
/// saved price and a comma decimal, "Create the expense" opening the add form filled in as EXACT (nothing saved),
/// and the ride tab rejecting a leg nobody rides (A141). Any layout overflow fails the test.
void main() {
  setUpAll(loadAppFonts);

  late LocalHttp http;
  late String gid;

  setUp(() async {
    http = await LocalHttp.open(profileName: 'Mona');
    gid = (await http.group(name: 'Sokhna'))['id'] as String;
    await http.member(gid, 'Asem');
    await http.member(gid, 'Mohsen');
    await FuelPricesRepository(http.db).save(FuelType.gasoline92, 1375);
  });
  tearDown(() => http.close());

  for (final config in allConfigs) {
    testWidgets('fuel split, create the expense, ride with an empty leg (${config.name})', (tester) async {
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
      String money(int minor) => moneyDisplay(l10n, minor);
      bool shows(String text) => find.textContaining(text, findRichText: true).evaluate().isNotEmpty;
      Finder field(String label) => find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(TextField));

      // The FAB offers the calculator next to a plain expense.
      router.go(Routes.group(gid));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.calcMenuAddExpenseHint), findsOneWidget);
      await tester.tap(find.text(l10n.calcMenuCalculator));
      await tester.pumpAndSettle();
      expect(find.text(l10n.calcTitle), findsOneWidget);

      // Fuel: 100 km x 8,1 L/100km (comma = decimal point, A168) x the saved 13.75 -> 111.375 -> 111.38, three ways.
      expect(find.text(l10n.calcFuel92), findsOneWidget);
      expect(shows(money(1375)), isTrue, reason: 'the saved price and its date are shown');
      await tester.enterText(field(l10n.calcDistance), '100');
      await tester.enterText(field(l10n.calcConsumption), '8,1');
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(find.text(l10n.calcResultTitle), find.byType(ListView), const Offset(0, -300));
      expect(find.text(money(11138)), findsWidgets);
      expect(find.text(money(3713)), findsNWidgets(2));
      expect(find.text(money(3712)), findsOneWidget);

      // Create -> the add form, filled in, nothing saved yet.
      await tester.tap(find.text(l10n.calcCreateExpense));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      expect(find.text(l10n.calcDraftFuelTitle('100')), findsOneWidget);
      expect(find.text('111.38'), findsOneWidget);
      expect(await http.db.expensesDao.select(http.db.expenses).get(), isEmpty);

      // Back to the calculator, ride tab: only Mona rides, and only to stop 2 of 3 -> leg 2-3 is empty.
      router.go(Routes.calculator(gid));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.calcTabRide));
      await tester.pumpAndSettle();
      await tester.enterText(field(l10n.calcFare), '150');
      await tester.enterText(field(l10n.calcLegDistance('1', '2')), '6');
      await tester.ensureVisible(find.text(l10n.calcStopAdd));
      await tester.tap(find.text(l10n.calcStopAdd));
      await tester.pumpAndSettle();
      await tester.enterText(field(l10n.calcLegDistance('2', '3')), '4');
      await tester.pumpAndSettle();
      for (final name in ['Asem', 'Mohsen']) {
        final chip = find.widgetWithText(AppChoiceChip, name).last;
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      final leave = find.text(l10n.calcStopName('3')).last;
      await tester.ensureVisible(leave);
      await tester.tap(leave);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.calcStopName('2')).last);
      await tester.pumpAndSettle();
      final error = find.text(l10n.calcErrorEmptyLeg('2', '3'));
      await tester.dragUntilVisible(error, find.byType(ListView), const Offset(0, -300));
      expect(error, findsOneWidget);
      final create = tester.widget<AppButton>(find.widgetWithText(AppButton, l10n.calcCreateExpense));
      expect(create.onPressed, isNull, reason: 'nothing to create while a leg has no riders');
    });
  }
}
