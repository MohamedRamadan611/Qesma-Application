import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/my_share/presentation/category_drilldown_sheet.dart';
import 'package:qesma/features/my_share/presentation/my_share_screen.dart';
import 'package:qesma/local/insights/my_share_provider.dart';
import 'package:qesma/local/insights/my_share_repository.dart';

import '../../support/test_app.dart';

MyShareResult _sampleData() {
  return const MyShareResult(
    sections: [
      MyShareCurrencySection(
        currencyCode: 'EGP',
        months: [
          MyShareMonth(
            month: '2026-11',
            totalConsumedMinor: 30000,
            totalPaidUpFrontMinor: 40000,
            categories: [
              MyShareCategoryBreakdown(
                category: 'FOOD',
                consumedMinor: 15000,
                paidUpFrontMinor: 30000,
                percentageBps: 5000,
                expenses: [
                  MyShareExpenseDetail(
                    expenseId: 'e1',
                    groupId: 'g1',
                    expenseTitle: 'Seafood Feast',
                    groupName: 'Dahab Trip',
                    expenseDate: '2026-11-10',
                    owedMinor: 15000,
                    paidMinor: 30000,
                  ),
                ],
              ),
              MyShareCategoryBreakdown(
                category: 'FUEL',
                consumedMinor: 15000,
                paidUpFrontMinor: 10000,
                percentageBps: 5000,
                expenses: [
                  MyShareExpenseDetail(
                    expenseId: 'e2',
                    groupId: 'g1',
                    expenseTitle: 'Highway Gas',
                    groupName: 'Dahab Trip',
                    expenseDate: '2026-11-12',
                    owedMinor: 15000,
                    paidMinor: 10000,
                  ),
                ],
              ),
            ],
          ),
          MyShareMonth(
            month: '2026-10',
            totalConsumedMinor: 20000,
            totalPaidUpFrontMinor: 20000,
            categories: [
              MyShareCategoryBreakdown(
                category: 'BILLS',
                consumedMinor: 20000,
                paidUpFrontMinor: 20000,
                percentageBps: 10000,
                expenses: [
                  MyShareExpenseDetail(
                    expenseId: 'e3',
                    groupId: 'g2',
                    expenseTitle: 'Electricity',
                    groupName: 'Flat Mates',
                    expenseDate: '2026-10-05',
                    owedMinor: 20000,
                    paidMinor: 20000,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('MyShareScreen', () {
    testWidgets('empty state renders in Arabic and English across text scales', (tester) async {
      for (final config in allConfigs) {
        await pumpApp(
          tester,
          ProviderScope(
            overrides: [
              myShareStreamProvider.overrideWith((ref) => Stream.value(const MyShareResult(sections: []))),
            ],
            child: const MyShareScreen(),
          ),
          locale: config.locale,
          textScale: config.textScale,
          scaffold: false,
        );
        await tester.pumpAndSettle();

        final l10n = l10nOf(tester);
        expect(find.text(l10n.myShareTitle), findsOneWidget);
        expect(find.text(l10n.myShareEmptyTitle), findsOneWidget);
        expect(find.text(l10n.myShareEmptyBody), findsOneWidget);
        expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
      }
    });

    testWidgets('renders month selector, overview cards and category breakdowns with data', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            myShareStreamProvider.overrideWith((ref) => Stream.value(_sampleData())),
          ],
          child: const MyShareScreen(),
        ),
        locale: const Locale('ar'),
        textScale: 1.0,
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);
      expect(find.text(l10n.myShareTitle), findsOneWidget);

      // Months present in ChoiceChips
      expect(find.text(isolated('2026-11')), findsOneWidget);
      expect(find.text(isolated('2026-10')), findsOneWidget);

      // Totals
      expect(find.text(l10n.myShareConsumed), findsWidgets);
      expect(find.text(l10n.mySharePaidUpFront), findsWidgets);

      // Categories
      expect(find.text(l10n.categoryFood), findsOneWidget);
      expect(find.text(l10n.categoryFuel), findsOneWidget);
      expect(find.text('50%'), findsNWidgets(2)); // both FOOD and FUEL are 50%
    });

    testWidgets('tapping a category opens the drill-down bottom sheet and shows expenses', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            myShareStreamProvider.overrideWith((ref) => Stream.value(_sampleData())),
          ],
          child: const MyShareScreen(),
        ),
        locale: const Locale('ar'),
        textScale: 1.0,
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);

      // Tap on FOOD category card
      await tester.tap(find.text(l10n.categoryFood));
      await tester.pumpAndSettle();

      // Drill-down sheet should be visible
      expect(find.byType(CategoryDrilldownSheet), findsOneWidget);
      expect(find.text('Seafood Feast'), findsOneWidget);
      expect(find.text('Dahab Trip • ${isolated('2026-11-10')}'), findsOneWidget);

      // Close the sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryDrilldownSheet), findsNothing);
    });

    testWidgets('survives text scale 2.0 without overflow', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            myShareStreamProvider.overrideWith((ref) => Stream.value(_sampleData())),
          ],
          child: const MyShareScreen(),
        ),
        locale: const Locale('en'),
        textScale: 2.0,
        scaffold: false,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
