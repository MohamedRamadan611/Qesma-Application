import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/recap/presentation/trip_recap_card.dart';
import 'package:qesma/local/insights/trip_recap_repository.dart';

import '../support/test_app.dart';

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

TripRecapResult _goldenRecap() {
  return const TripRecapResult(
    totalSpentMinor: 125000,
    expenseCount: 5,
    dateRangeStart: '2026-11-01',
    dateRangeEnd: '2026-11-06',
    topPayer: TripRecapTopPayer(
      memberId: 'm1',
      displayName: 'أحمد',
      amountPaidMinor: 75000,
    ),
    biggestExpense: TripRecapBiggestExpense(
      expenseId: 'e1',
      title: 'عشاء المأكولات البحرية',
      totalMinor: 50000,
      expenseDate: '2026-11-02',
    ),
    categoryBreakdown: [
      TripRecapCategoryBreakdown(category: 'FOOD', totalMinor: 50000, percentageBps: 4000),
      TripRecapCategoryBreakdown(category: 'TRANSPORT', totalMinor: 35000, percentageBps: 2800),
      TripRecapCategoryBreakdown(category: 'FUEL', totalMinor: 25000, percentageBps: 2000),
      TripRecapCategoryBreakdown(category: 'ACCOMMODATION', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'GROCERIES', totalMinor: 15000, percentageBps: 1200),
      TripRecapCategoryBreakdown(category: 'SHOPPING', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'ENTERTAINMENT', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'BILLS', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'OTHER', totalMinor: 0, percentageBps: 0),
    ],
    memberPaidTotals: [
      TripRecapMemberPaidTotal(memberId: 'm1', displayName: 'أحمد', sortOrder: 0, amountPaidMinor: 75000),
      TripRecapMemberPaidTotal(memberId: 'm2', displayName: 'منى', sortOrder: 1, amountPaidMinor: 50000),
    ],
  );
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator =
        _TolerantComparator(current.basedir.resolve('trip_recap_goldens_test.dart'));
  });

  Future<void> pumpCard(WidgetTester tester, Locale locale, {GlobalKey? boundaryKey}) async {
    await pumpApp(
      tester,
      Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: TripRecapCard(
            groupName: locale.languageCode == 'ar' ? 'رحلة دهب' : 'Dahab Trip',
            recap: _goldenRecap(),
          ),
        ),
      ),
      locale: locale,
      size: const Size(360, 450),
      scaffold: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('recap image card golden (ar)', (tester) async {
    await pumpCard(tester, const Locale('ar'));
    await expectLater(find.byType(TripRecapCard), matchesGoldenFile('trip_recap_ar.png'));
  });

  testWidgets('recap image card golden (en)', (tester) async {
    await pumpCard(tester, const Locale('en'));
    await expectLater(find.byType(TripRecapCard), matchesGoldenFile('trip_recap_en.png'));
  });

  testWidgets('rendering service produces a non-empty PNG of 1080x1350 px', (tester) async {
    final key = GlobalKey();
    await pumpCard(tester, const Locale('ar'), boundaryKey: key);

    Uint8List? pngBytes;
    await tester.runAsync(() async {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      expect(boundary, isNotNull);

      final image = await boundary!.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);

      pngBytes = byteData!.buffer.asUint8List();

      final codec = await ui.instantiateImageCodec(pngBytes!);
      final frame = await codec.getNextFrame();

      expect(frame.image.width, equals(1080), reason: 'Rendered PNG must be 1080 px wide');
      expect(frame.image.height, equals(1350), reason: 'Rendered PNG must be 1350 px high');
    });

    expect(pngBytes, isNotNull);
    expect(pngBytes!.isNotEmpty, isTrue);
  });
}
