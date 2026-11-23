import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/insights/budget_summary_provider.dart';
import 'package:qesma/local/insights/budget_summary_repository.dart';

import '../local/backend/support/local_http.dart';
import '../support/test_app.dart';

/// SA20 goldens (Arabic, RTL, 360 wide): the budget card on the group home under and over budget, and the budget
/// screen with trip dates. The figures are fixed literals (the engine is tested elsewhere). Update with
/// `flutter test --update-goldens test/goldens/budget_goldens_test.dart` and review every PNG.
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

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('budget_goldens_test.dart'));
  });

  late LocalHttp http;
  late String underGid;
  late String overGid;

  setUp(() async {
    var n = 0;
    http = await LocalHttp.open(profileName: 'منى', newId: () => '00000000-0000-4000-8000-${(++n).toString().padLeft(12, '0')}');
    Future<String> seed(String name) async {
      final id = (await http.group(name: name))['id'] as String;
      await http.member(id, 'عاصم');
      await http.patch('/groups/$id', {'budgetMinor': 500000}, ifMatch: '"1"');
      return id;
    }

    underGid = await seed('رحلة دهب');
    overGid = await seed('سيوة');
  });
  tearDown(() => http.close());

  Future<void> pumpAt(WidgetTester tester, String route, BudgetSummary summary, String gid, {double height = 800}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(360, height);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      ...localModeOverrides(http.db, clock: () => DateTime.utc(2026, 11, 17, 10).millisecondsSinceEpoch),
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 17, 12)),
      budgetSummaryProvider(gid).overrideWith((ref) => Stream.value(summary)),
    ]);
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).set(const Locale('ar'));
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
    await tester.pumpAndSettle();
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets('budget card, under budget', (tester) async {
    await pumpAt(tester, Routes.group(underGid), _under, underGid);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('budget_card_under_ar.png'));
  });

  testWidgets('budget card, over budget said in words', (tester) async {
    await pumpAt(tester, Routes.group(overGid), _over, overGid);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('budget_card_over_ar.png'));
  });

  testWidgets('budget screen with trip dates', (tester) async {
    await pumpAt(tester, Routes.budget(underGid), _under, underGid);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('budget_screen_ar.png'));
  });
}
