import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/expenses/presentation/expense_filters.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

const String _asem = '98138ea2-62ee-4b5d-92d0-0ecccb012cfa';
const String _v5 = '7e3b3a23-d844-4889-99ae-5cba254d1173';
const Locale _ar = Locale('ar');
const Locale _en = Locale('en');

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() => server = FakeExpensesServer());

  Future<void> openExpense(WidgetTester tester, String title) async {
    final card = find.text(title).first;
    if (card.evaluate().isEmpty) await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  group('expenses tab', () {
    for (final locale in [_ar, _en]) {
      final l10n = l10nFor(locale);

      testWidgets('${locale.languageCode}: rows show title, split chip, who paid, how many share, your share and date headers', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server, locale: locale);

        for (final title in ['Petrol (edited)', 'Tickets', 'Sea Food', 'Service only', 'Tax only', 'Neither']) {
          expect(find.text(title), findsOneWidget, reason: title);
        }
        expect(find.text(l10n.expenseSplitEqual), findsOneWidget);
        expect(find.text(l10n.expenseSplitExact), findsOneWidget);
        expect(find.text(l10n.expenseSplitItemized), findsNWidgets(4));
        expect(find.text(l10n.expenseDayToday(isolated('2026-10-18'))), findsOneWidget, reason: 'one header for the five expenses of that day');
        expect(find.text(l10n.expenseDayYesterday(isolated('2026-10-17'))), findsOneWidget);

        // Totals and "your share" are the server numbers.
        expect(find.text(money(locale, 52000)), findsOneWidget);
        expect(find.text(l10n.expenseYourShare(money(locale, 17334))), findsOneWidget);
        expect(find.text(l10n.expenseYourShare(money(locale, 10000))), findsOneWidget);
        expect(find.text(l10n.expenseYourShare(money(locale, 16599))), findsOneWidget);

        // Who paid: one payer by name, several with their amounts.
        expect(find.text(l10n.expensePaidBy('Mohamed')), findsWidgets);
        expect(
          find.text(l10n.expensePaidBy('${fsIsolated("Mohamed (${isolated('300.00')})")}${l10n.expenseListSeparator}${fsIsolated("Asem (${isolated('261.79')})")}')),
          findsOneWidget,
        );
        expect(find.text(l10n.expenseSplitAmong('3')), findsWidgets);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text(l10n.expensesAdd), findsOneWidget);
      });
    }

    testWidgets('the Arabic copy reads as designed', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      expect(find.text('بالتساوي'), findsOneWidget);
      expect(find.text('فاتورة مفصلة'), findsNWidgets(4));
      expect(find.text('النهارده — ${isolated('2026-10-18')}'), findsOneWidget);
      expect(find.text('دفع: Mohamed'), findsWidgets);
      expect(find.text('مقسومة على 3 أفراد'), findsWidgets);
      expect(find.text('التاريخ: الكل'), findsOneWidget);
      expect(find.text('العضو: الكل'), findsOneWidget);
      expect(find.text('إضافة مصروف'), findsOneWidget);
    });

    testWidgets('your share is hidden when the server has no entry for you', (tester) async {
      final json = copyJson(fixtureMap('expense_itemized_v5'));
      (json['shares'] as List).removeWhere((s) => s['memberId'] == '77e31a5d-f072-4568-9115-0259fb131e9a');
      server.expenses.add(json);
      await pumpExpensesApp(tester, server);
      expect(find.textContaining('نصيبك'), findsNothing);
      expect(find.text('مقسومة على فردين'), findsOneWidget);
    });

    testWidgets('empty group: friendly empty state, no filters shown as active, the add button is there', (tester) async {
      await pumpExpensesApp(tester, server);
      expect(find.text('لسه مفيش مصاريف'), findsOneWidget);
      expect(find.text('ضيف أول مصروف وقسّمه على الشلة.'), findsOneWidget);
      expect(find.text('إضافة مصروف'), findsOneWidget);
      expect(find.text('امسح الفلاتر'), findsNothing);
    });

    testWidgets('while loading the skeleton shows; offline shows the no-internet state and retry recovers', (tester) async {
      seedAllFixtures(server);
      server.expensesOffline = true;
      await pumpExpensesApp(tester, server, settle: false);
      await tester.pump();
      expect(find.byType(SkeletonList), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('مفيش اتصال بالإنترنت'), findsOneWidget);
      server.expensesOffline = false;
      await tapText(tester, 'حاول تاني');
      expect(find.text('Sea Food'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads the next page once; the date header continues across pages', (tester) async {
      for (var i = 0; i < 25; i++) {
        server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'e$i', title: 'Expense $i', date: '2026-10-18'));
      }
      await pumpExpensesApp(tester, server, height: 800);
      expect(server.requests.where((r) => r.contains('/expenses?') && r.contains('page=1')), isEmpty);
      await tester.drag(find.byType(ListView).first, const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.contains('/expenses?') && r.contains('page=1')), hasLength(1));
      await tester.drag(find.byType(ListView).first, const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(find.text('Expense 24'), findsOneWidget);
      expect(find.textContaining('النهارده'), findsNothing, reason: 'the single header scrolled out of view; it was not repeated for page 2');
    });

    testWidgets('pull to refresh reloads from page 0', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'fresh', title: 'Fresh one', date: '2026-10-19'));
      final refreshing = tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
      await tester.pumpAndSettle();
      await refreshing;
      expect(find.text('Fresh one'), findsOneWidget);
    });

    group('filters', () {
      testWidgets('member filter: sheet lists members (you first), choosing one sends memberId, shows a removable chip', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await tapText(tester, 'العضو: الكل');
        expect(find.text('فلتر العضو'), findsOneWidget);
        expect(find.text('كل الأعضاء'), findsOneWidget);
        expect(find.text('Mohamed'), findsWidgets);
        expect(find.text('(أنت)'), findsWidgets);

        await tapText(tester, 'Asem');
        expect(server.requests.where((r) => r.contains('/expenses?')).last, contains('memberId=$_asem'));
        expect(find.text('العضو: Asem'), findsOneWidget);

        await tester.tap(find.byTooltip('شيل الفلتر: العضو: Asem'));
        await tester.pumpAndSettle();
        expect(server.requests.where((r) => r.contains('/expenses?')).last, isNot(contains('memberId')));
        expect(find.text('العضو: الكل'), findsOneWidget);
      });

      testWidgets('date filter: the Arabic date picker opens, a date is applied and the chip says so', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await tapText(tester, 'التاريخ: الكل');
        expect(find.text('فلتر التاريخ'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تطبيق')).onPressed, isNull, reason: 'nothing picked yet');

        await tapText(tester, 'من تاريخ: اختار التاريخ');
        final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
        await tester.tap(find.text(ok));
        await tester.pumpAndSettle();
        expect(find.textContaining('من تاريخ: '), findsOneWidget);
        expect(find.text('من تاريخ: اختار التاريخ'), findsNothing);

        await tapText(tester, 'تطبيق');
        final request = server.requests.where((r) => r.contains('/expenses?')).last;
        expect(request, matches(RegExp(r'fromDate=\d{4}-\d{2}-\d{2}')));
        expect(request, isNot(contains('toDate')));
        expect(find.textContaining('التاريخ: من '), findsOneWidget);
      });

      testWidgets('a backwards range shows the message and cannot be applied', (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDateFilterSheet(context, from: Date(2026, 10, 20), to: Date(2026, 10, 18)),
              child: const Text('open'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('تاريخ البداية لازم يكون قبل تاريخ النهاية.'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تطبيق')).onPressed, isNull);
      });

      testWidgets('clearing the date filter from its sheet removes it', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await tapText(tester, 'العضو: الكل');
        await tapText(tester, 'Asem');
        await tapText(tester, 'التاريخ: الكل');
        await tapText(tester, 'من تاريخ: اختار التاريخ');
        await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel));
        await tester.pumpAndSettle();
        await tapText(tester, 'تطبيق');
        expect(find.textContaining('التاريخ: من '), findsOneWidget);

        final dateLabel = tester.widget<Text>(find.textContaining('التاريخ: من ')).data!;
        await tester.tap(find.byTooltip('شيل الفلتر: $dateLabel'));
        await tester.pumpAndSettle();
        expect(find.text('التاريخ: الكل'), findsOneWidget);
        expect(find.text('العضو: Asem'), findsOneWidget, reason: 'the member filter stays');
      });

      testWidgets('no match: says so and one tap clears the filters; the true empty state is a different screen', (tester) async {
        await pumpExpensesApp(tester, server);
        await tapText(tester, 'العضو: الكل');
        await tapText(tester, 'Asem');
        expect(find.text('مفيش مصاريف مطابقة'), findsOneWidget);
        expect(find.text('لسه مفيش مصاريف'), findsNothing);

        server.expenses.add(copyJson(fixtureMap('expense_exact')));
        await tapText(tester, 'امسح الفلاتر');
        expect(find.text('Tickets'), findsOneWidget);
        expect(find.text('العضو: الكل'), findsOneWidget);
      });
    });

    testWidgets('the floating button opens the add-expense form', (tester) async {
      await pumpExpensesApp(tester, server);
      await tapText(tester, 'إضافة مصروف');
      expect(find.text('اسم المصروف'), findsOneWidget);
      expect(find.text('حفظ المصروف'), findsOneWidget);
    });

    testWidgets('a row is one spoken sentence for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      server.expenses.add(copyJson(fixtureMap('expense_exact')));
      await pumpExpensesApp(tester, server);
      // Amounts in words, no bare decimals, no invisible direction characters in what a voice reads.
      final row = find.bySemanticsLabel(RegExp(r'^Tickets، 300 جنيه، مبالغ محددة، دفع: Mohamed \(100 جنيه\)، Asem \(200 جنيه\)، مقسومة على 3 أفراد، نصيبك: 100 جنيه$'));
      expect(row, findsOneWidget);
      final data = tester.getSemantics(row).getSemanticsData();
      expect(data.label.runes.where((r) => r >= 0x2066 && r <= 0x2069), isEmpty);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: 'a screen reader must be able to activate the row');
      handle.dispose();
    });

    for (final c in allConfigs) {
      testWidgets('fits at ${c.name}: list with long titles and several payers, filter chips, 48 px targets', (tester) async {
        seedAllFixtures(server);
        final long = cloneExpense(fixtureMap('expense_itemized_v5'),
            id: 'long',
            title: t(c.locale, 'عشاء طويل جدًا في المطعم البحري الكبير على شاطئ دهب مع كل الأصحاب والعائلة', 'A very long dinner title at the big seafood place on the Dahab beach with everyone'));
        server.expenses.add(long);
        await pumpExpensesApp(tester, server, locale: c.locale, textScale: c.textScale, height: 800);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(FloatingActionButton)).height, greaterThanOrEqualTo(kMinTouch));
        await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('expense details', () {
    // (fixture title, section expectations)
    for (final locale in [_ar, _en]) {
      final l10n = l10nFor(locale);
      String m(int minor, {bool signed = false}) => money(locale, minor, signed: signed);

      testWidgets('${locale.languageCode}: V5 itemized with service 12% and tax 14%: every number is the fixture number', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server, locale: locale);
        await openExpense(tester, 'Sea Food');

        expect(find.text(l10n.expenseDetailsTitle), findsOneWidget);
        expect(find.text(m(56179)), findsWidgets, reason: 'header total and the charges total');
        expect(find.text(l10n.expenseSplitItemized), findsOneWidget);
        expect(find.textContaining(l10n.expenseEditedBadge('')), findsNothing, reason: 'version 1 has no edited badge');

        // Payers: two, with the payers' own sum.
        expect(find.text(l10n.expensePayersCountTwo), findsOneWidget);
        expect(find.text(m(30000)), findsOneWidget);
        expect(find.text(m(26179)), findsOneWidget);
        expect(find.text(l10n.expensePaidTotal(m(56179))), findsOneWidget);

        // Items with assignees.
        await reveal(tester, find.text('Pizza'));
        expect(find.text(m(20000)), findsOneWidget);
        expect(find.text('Pasta'), findsOneWidget);
        expect(find.text('Drinks'), findsOneWidget);

        // Charges: subtotal, service, tax, total; no adjustment row.
        await reveal(tester, find.text(l10n.expenseSubtotal));
        expect(find.text(m(44000)), findsOneWidget);
        expect(find.text(l10n.expenseServiceLabel), findsOneWidget);
        expect(find.text(l10n.expensePercent(isolated('12'))), findsOneWidget);
        expect(find.text(m(5280, signed: true)), findsOneWidget);
        expect(find.text(l10n.expenseTaxLabel), findsOneWidget);
        expect(find.text(l10n.expensePercent(isolated('14'))), findsOneWidget);
        expect(find.text(l10n.expenseTaxBaseSubtotalPlusService), findsOneWidget);
        expect(find.text(m(6899, signed: true)), findsOneWidget);
        expect(find.text(l10n.expenseAdjustmentLabel), findsNothing);
        expect(find.text(l10n.expenseBillTotal), findsOneWidget);

        // Per-person breakdown: owed amounts and the server's own parts.
        await reveal(tester, find.text(l10n.expenseBreakdownTitle));
        await reveal(tester, find.text(m(22982)));
        for (final owed in [16599, 16598, 22982]) {
          expect(find.text(m(owed)), findsOneWidget, reason: '$owed');
        }
        String line(int items, int service, int tax) =>
            '${l10n.expensePartItems(m(items))} + ${l10n.expensePartService(m(service))} + ${l10n.expensePartTax(m(tax))}';
        expect(find.text(line(13000, 1560, 2039)), findsOneWidget);
        expect(find.text(line(13000, 1560, 2038)), findsOneWidget);
        expect(find.text(line(18000, 2160, 2822)), findsOneWidget);
      });
    }

    testWidgets('V6 service only: no tax row and no tax part', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Service only');
      await reveal(tester, find.text('رسوم الخدمة'));
      expect(find.text('الضريبة'), findsNothing);
      expect(find.text('${isolated('12')}%'), findsOneWidget);
      await reveal(tester, find.text(money(_ar, 20160)));
      expect(find.textContaining('ضريبة'), findsNothing);
      expect(find.text('${_ar_('أصناف', money(_ar, 18000))} + ${_ar_('خدمة', money(_ar, 2160))}'), findsOneWidget);
    });

    testWidgets('V7 tax only on the subtotal: no service row', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Tax only');
      await reveal(tester, find.text('الضريبة'));
      expect(find.text('رسوم الخدمة'), findsNothing);
      expect(find.text('على مجموع الأصناف'), findsOneWidget);
      expect(find.text(money(_ar, 6160, signed: true)), findsOneWidget);
      await reveal(tester, find.text(money(_ar, 20520)));
      expect(find.textContaining('خدمة'), findsNothing);
    });

    testWidgets('V8 neither: subtotal and total, nothing else; the breakdown has items only', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Neither');
      await reveal(tester, find.text('مجموع الأصناف'));
      expect(find.text('رسوم الخدمة'), findsNothing);
      expect(find.text('الضريبة'), findsNothing);
      expect(find.text('تسوية'), findsNothing);
      await reveal(tester, find.text(money(_ar, 18000)));
      expect(find.text(_ar_('أصناف', money(_ar, 18000))), findsOneWidget);
    });

    testWidgets('a non-zero adjustment shows as a signed row and part', (tester) async {
      final json = copyJson(fixtureMap('expense_itemized_v8_neither'));
      (json['charges'] as Map)['adjustmentMinor'] = -500;
      (json['shares'] as List)[0]['adjustmentMinor'] = -500;
      server.expenses.add(json);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Neither');
      await reveal(tester, find.text('تسوية'));
      expect(find.text(money(_ar, -500, signed: true)), findsWidgets);
    });

    testWidgets('EQUAL (edited): payer, owed amounts only, "edited (version 2)", no items and no charges', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Petrol (edited)');
      expect(find.text('معدّل (النسخة 2)'), findsOneWidget);
      expect(find.text('بالتساوي'), findsOneWidget);
      expect(find.text('دافع واحد'), findsOneWidget);
      expect(find.text('الأصناف والإضافات'), findsNothing);
      await reveal(tester, find.text(money(_ar, 17334)));
      expect(find.text(money(_ar, 17333)), findsNWidgets(2));
      expect(find.textContaining('أصناف '), findsNothing, reason: 'no breakdown line for EQUAL');
      expect(find.text('تعديل المصروف'), findsOneWidget);
    });

    testWidgets('EXACT: two payers and the exact amounts, your row is tagged', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Tickets');
      expect(find.text(money(_ar, 10000)), findsWidgets);
      expect(find.text(money(_ar, 20000)), findsOneWidget);
      await reveal(tester, find.text(money(_ar, 5000)));
      expect(find.text('(أنت)'), findsWidgets);
      expect(find.text('الأصناف والإضافات'), findsNothing);
    });

    testWidgets('shown numbers are the server\'s even when they do not add up (nothing is recalculated)', (tester) async {
      final json = copyJson(fixtureMap('expense_itemized_v5'));
      json['totalMinor'] = 999;
      (json['shares'] as List)[0]['owedMinor'] = 1;
      (json['charges'] as Map)['subtotalMinor'] = 5;
      server.expenses.add(json);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Sea Food');
      expect(find.text(money(_ar, 999)), findsWidgets);
      await reveal(tester, find.text(money(_ar, 5)));
      await reveal(tester, find.text(money(_ar, 1)));
      expect(find.text(money(_ar, 56179)), findsNothing, reason: 'the payers sum line says "paid", not the total');
    });

    testWidgets('history sheet: newest first with version, kind of change, time, total and payers', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Petrol (edited)');
      await reveal(tester, find.text('سجل التعديلات'));
      await tapText(tester, 'سجل التعديلات');
      expect(find.text('النسخة 2'), findsOneWidget);
      expect(find.text('النسخة 1'), findsOneWidget);
      expect(find.text('تعديل'), findsOneWidget);
      expect(find.text('إنشاء'), findsOneWidget);
      expect(find.text('الإجمالي: ${money(_ar, 52000)}'), findsOneWidget);
      expect(find.text('الإجمالي: ${money(_ar, 50000)}'), findsOneWidget);
      expect(tester.getTopLeft(find.text('النسخة 2')).dy, lessThan(tester.getTopLeft(find.text('النسخة 1')).dy));
    });

    testWidgets('history failure shows a message and a retry that works', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Petrol (edited)');
      server.failNextRevisions = true;
      await reveal(tester, find.text('سجل التعديلات'));
      await tapText(tester, 'سجل التعديلات');
      expect(find.text('حاول تاني'), findsOneWidget);
      await tapText(tester, 'حاول تاني');
      expect(find.text('النسخة 2'), findsOneWidget);
    });

    testWidgets('edit on an itemized bill (its button says so) opens the bill editor', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Sea Food');
      await reveal(tester, find.text('تعديل الفاتورة والأصناف'));
      await tapText(tester, 'تعديل الفاتورة والأصناف');
      expect(find.text('أصناف الفاتورة'), findsOneWidget);
      expect(find.text('الشاشة دي لسه تحت الإنشاء.'), findsNothing);
    });

    testWidgets('the expense no longer exists: "no longer available" with a way back', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      final tap = find.text('Sea Food').first;
      server.expenses.removeWhere((e) => e['id'] == _v5);
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(find.text('المصروف ده مبقاش موجود'), findsOneWidget);
      await tapText(tester, 'رجوع للمصاريف');
      expect(find.text('Sea Food'), findsNothing, reason: 'the list was refreshed');
      expect(find.text('Tickets'), findsOneWidget);
    });

    testWidgets('offline when opening: no-internet state, retry shows the expense', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      server.expensesOffline = true;
      await tester.tap(find.text('Sea Food').first);
      await tester.pumpAndSettle();
      expect(find.text('مفيش اتصال بالإنترنت'), findsOneWidget);
      server.expensesOffline = false;
      await tapText(tester, 'حاول تاني');
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
      expect(find.text(money(_ar, 56179)), findsWidgets);
    });

    group('delete', () {
      Future<void> startDelete(WidgetTester tester) async {
        await reveal(tester, find.widgetWithText(FilledButton, 'حذف المصروف'));
        await tester.tap(find.widgetWithText(FilledButton, 'حذف المصروف'));
        await tester.pumpAndSettle();
      }

      Finder dialogButton(String text) => find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

      testWidgets('asks first, does not promise a history it cannot show, and cancel changes nothing', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        await startDelete(tester);
        expect(find.text('تحذف المصروف ده؟'), findsOneWidget);
        expect(find.textContaining('هيتشال'), findsOneWidget);
        expect(find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('سجل التعديلات')), findsNothing,
            reason: 'the history of a deleted expense cannot be opened, so the dialog does not promise it');
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();
        expect(server.requests.where((r) => r.startsWith('DELETE')), isEmpty);
        expect(find.text('تفاصيل المصروف'), findsOneWidget);
      });

      testWidgets('confirming deletes with If-Match, says so, returns to the refreshed list', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();

        expect(server.requests.where((r) => r.startsWith('DELETE')).single, endsWith('if-match="1"'));
        expect(find.text('اتحذف المصروف.'), findsOneWidget);
        expect(find.text('تفاصيل المصروف'), findsNothing);
        expect(find.text('Sea Food'), findsNothing);
        expect(find.text('Tickets'), findsOneWidget);
      });

      testWidgets('someone edited it meanwhile: conflict dialog, reload shows the newer version, then delete works', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        server.bumpVersion(_v5);
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        expect(find.text('حمّل آخر نسخة'), findsOneWidget);
        expect(server.expenses.any((e) => e['id'] == _v5), isTrue, reason: 'nothing was deleted');

        await tester.tap(find.text('حمّل آخر نسخة'));
        await tester.pumpAndSettle();
        expect(find.text('معدّل (النسخة 2)'), findsOneWidget);
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        expect(server.requests.where((r) => r.startsWith('DELETE')).last, endsWith('if-match="2"'));
        expect(find.text('اتحذف المصروف.'), findsOneWidget);
      });

      testWidgets('already deleted elsewhere: says so and goes back', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        server.expenses.removeWhere((e) => e['id'] == _v5);
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        expect(find.text('المصروف ده كان اتحذف خلاص.'), findsOneWidget);
        expect(find.text('تفاصيل المصروف'), findsNothing);
      });

      testWidgets('a lost reply: an error first, and the second try ends cleanly as "already deleted"', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        server.loseNextDeleteResponse = true;
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5)); // the error snackbar goes away
        await tester.pumpAndSettle();
        expect(find.text('تفاصيل المصروف'), findsOneWidget, reason: 'still here, the user may retry');
        expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حذف المصروف')).onPressed, isNotNull);

        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        expect(find.text('المصروف ده كان اتحذف خلاص.'), findsOneWidget);
        expect(find.text('Sea Food'), findsNothing);
      });

      testWidgets('offline: an error message and the screen stays', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server);
        await openExpense(tester, 'Sea Food');
        server.expensesOffline = true;
        await startDelete(tester);
        await tester.tap(dialogButton('حذف المصروف'));
        await tester.pumpAndSettle();
        expect(find.text('تفاصيل المصروف'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    for (final c in allConfigs) {
      testWidgets('fits at ${c.name}: the richest page (V5) scrolls end to end without overflow', (tester) async {
        seedAllFixtures(server);
        await pumpExpensesApp(tester, server, locale: c.locale, textScale: c.textScale);
        await openExpense(tester, 'Sea Food');
        expect(tester.takeException(), isNull);
        final l10n = l10nFor(c.locale);
        await reveal(tester, find.widgetWithText(FilledButton, l10n.expenseDelete));
        expect(tester.takeException(), isNull);
        for (final button in tester.widgetList<FilledButton>(find.byType(FilledButton))) {
          expect(button.onPressed, isNotNull);
        }
      });
    }
  });

  group('review fixes: accessibility and recovery', () {
    testWidgets('filter chips, day headers and tabs can be activated and read by a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      for (final label in ['التاريخ: الكل', 'العضو: الكل']) {
        final data = tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
        expect(data.flagsCollection.isButton, isTrue, reason: label);
      }
      final tab = tester.getSemantics(find.bySemanticsLabel('الأرصدة')).getSemanticsData();
      expect(tab.hasAction(SemanticsAction.tap), isTrue);

      // A day header is a header, and it is said as a date, not as "2026-10-18".
      final header = find.bySemanticsLabel(RegExp('^النهارده — '));
      expect(header, findsOneWidget);
      final said = tester.getSemantics(header).getSemanticsData();
      expect(said.flagsCollection.isHeader, isTrue);
      expect(said.label, isNot(contains('2026-10-18')));
      handle.dispose();
    });

    testWidgets('pull to refresh is also a named action for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      final labels = <String>[];
      void walk(SemanticsNode node) {
        for (final id in node.getSemanticsData().customSemanticsActionIds ?? const <int>[]) {
          labels.add(CustomSemanticsAction.getAction(id)!.label ?? '');
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(tester.getSemantics(find.byType(RefreshIndicator)));
      expect(labels, contains('تحديث القائمة'));
      handle.dispose();
    });

    testWidgets('a failed next page shows a "try again" row; scrolling does not hammer the server, the button retries', (tester) async {
      for (var i = 0; i < 25; i++) {
        server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'e$i', title: 'Expense $i', date: '2026-10-18'));
      }
      await pumpExpensesApp(tester, server, height: 800);
      server.expensesOffline = true;
      await tester.drag(find.byType(ListView).first, const Offset(0, -9000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000)); // the new row grew the list
      await tester.pumpAndSettle();
      expect(find.text('معرفناش نحمّل باقي المصاريف.'), findsOneWidget);
      final failedRequests = server.requests.where((r) => r.contains('page=1')).length;

      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.contains('page=1')).length, failedRequests, reason: 'only the button retries');

      server.expensesOffline = false;
      await tapText(tester, 'حاول تاني');
      expect(find.text('معرفناش نحمّل باقي المصاريف.'), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, -9000));
      await tester.pumpAndSettle();
      expect(find.text('Expense 24'), findsOneWidget);
    });

    testWidgets('delete conflict: its own wording, and a failed reload says so instead of staying silent', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Sea Food');
      server.bumpVersion(_v5);
      await reveal(tester, find.widgetWithText(FilledButton, 'حذف المصروف'));
      await tester.tap(find.widgetWithText(FilledButton, 'حذف المصروف'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('حذف المصروف')));
      await tester.pumpAndSettle();
      expect(find.text('المصروف اتعدّل'), findsOneWidget);
      expect(find.textContaining('راجعها قبل ما تحذفه'), findsOneWidget);
      expect(find.text('كمّل بتعديلي'), findsNothing, reason: 'there is no edit to continue with');

      server.expensesOffline = true;
      await tester.tap(find.text('حمّل آخر نسخة'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget, reason: 'the failed reload is reported');
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
    });

    testWidgets('history of an expense with no revisions says so instead of showing a blank sheet', (tester) async {
      server.expenses.add(copyJson(fixtureMap('expense_exact')));
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Tickets');
      await reveal(tester, find.text('سجل التعديلات'));
      await tapText(tester, 'سجل التعديلات');
      expect(find.text('مفيش سجل تعديلات للمصروف ده.'), findsOneWidget);
    });

    testWidgets('history rows read as one sentence each, with the total in words', (tester) async {
      final handle = tester.ensureSemantics();
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Petrol (edited)');
      await reveal(tester, find.text('سجل التعديلات'));
      await tapText(tester, 'سجل التعديلات');
      final row = find.bySemanticsLabel(RegExp('^النسخة 2'));
      expect(row, findsWidgets);
      final said = tester.getSemantics(row.first).getSemanticsData().label;
      expect(said, contains('الإجمالي: 520 جنيه'));
      expect(said, contains('دفع: Mohamed'));
      handle.dispose();
    });

    testWidgets('a person row on the details page is one stop: name, "you", amount in words, breakdown in words', (tester) async {
      final handle = tester.ensureSemantics();
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Sea Food');
      await reveal(tester, find.text('نصيب كل فرد'));
      final row = find.bySemanticsLabel(RegExp('أصناف 130 جنيه، خدمة 15 جنيه و60 قرش، ضريبة 20 جنيه و39 قرش'));
      expect(row, findsOneWidget);
      final said = tester.getSemantics(row).getSemanticsData().label;
      expect(said, contains('Mohamed'));
      expect(said, contains('165 جنيه و99 قرش'));
      handle.dispose();
    });

    testWidgets('item assignees are announced with context', (tester) async {
      final handle = tester.ensureSemantics();
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      await openExpense(tester, 'Sea Food');
      await reveal(tester, find.text('Pizza'));
      expect(find.bySemanticsLabel(RegExp('على: Mohamed، Asem')), findsWidgets);
      handle.dispose();
    });

    testWidgets('the Arabic counts agree: 2 is dual, 3-10 plural, 11+ singular accusative', (tester) async {
      final json = copyJson(fixtureMap('expense_exact'));
      // 12 participants: reuse the three members' shares under other ids.
      final shares = [for (var i = 0; i < 12; i++) {...(json['shares'] as List).first as Map, 'memberId': 'm$i'}];
      json['shares'] = shares;
      server.expenses.add(json);
      await pumpExpensesApp(tester, server);
      expect(find.text('مقسومة على 12 فردًا'), findsOneWidget);
    });
  });

  group('elements the design shows but the backend has no data for are not built', () {
    testWidgets('list and details contain none of them', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server);
      const omitted = ['نهائي', 'بطاقة', 'محفظة', 'دافع رئيسي', 'مشارك بالدفع', '100%', 'مستمتعين', 'سيناء', 'تسوية الحسابات', 'عمليات مسجلة', 'تقريب'];
      for (final text in omitted) {
        expect(find.textContaining(text), findsNothing, reason: 'list: $text');
      }
      await openExpense(tester, 'Sea Food');
      for (var i = 0; i < 6; i++) {
        for (final text in omitted) {
          expect(find.textContaining(text), findsNothing, reason: 'details: $text');
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
    });

    test('no expense string in either language promises permanence or shows something computed', () {
      for (final name in ['ar', 'en']) {
        final arb = jsonDecode(File('lib/core/l10n/app_$name.arb').readAsStringSync()) as Map<String, dynamic>;
        for (final entry in arb.entries.where((e) => e.key.startsWith('expense') && !e.key.startsWith('@'))) {
          final value = (entry.value as String).toLowerCase();
          for (final banned in ['نهائي', 'permanent', 'forever', '100%', 'card', 'wallet', 'بطاقة', 'محفظة']) {
            expect(value.contains(banned), isFalse, reason: '${entry.key} ($name) contains $banned');
          }
        }
      }
    });
  });
}

/// "items 130.00" in Arabic, built from the same two parts the app joins.
String _ar_(String word, String amount) => '$word $amount';
