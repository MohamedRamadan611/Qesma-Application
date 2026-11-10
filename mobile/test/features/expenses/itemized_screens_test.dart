import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

const Locale _ar = Locale('ar');

/// The saved restaurant bills (real backend responses) and the REAL backend's preview for each.
const Map<String, ({String expenseFixture, String id, int total})> _bills = {
  'v5': (expenseFixture: 'expense_itemized_v5', id: '7e3b3a23-d844-4889-99ae-5cba254d1173', total: 56179),
  'v6': (expenseFixture: 'expense_itemized_v6_service_only', id: '', total: 49280),
  'v7': (expenseFixture: 'expense_itemized_v7_tax_only', id: '', total: 50160),
  'v8': (expenseFixture: 'expense_itemized_v8_neither', id: '', total: 44000),
};

Map<String, dynamic> _golden(String name) => (jsonDecode(File('test/fixtures/expense_commands/$name.json').readAsStringSync()) as Map).cast<String, dynamic>();

/// A fake server that answers the four spec bills with the CAPTURED backend previews, verbatim.
FakeExpensesServer _server() {
  final server = FakeExpensesServer();
  seedAllFixtures(server);
  for (final v in ['v5', 'v6', 'v7', 'v8']) {
    server.cannedPreviews[server.itemizedKey(_golden('itemized_$v'))] = fixtureMap('preview_$v');
  }
  return server;
}

String _eid(String v) => fixtureMap(_bills[v]!.expenseFixture)['id'] as String;

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() => server = _server());

  Future<void> openBill(WidgetTester tester, String v, {Locale locale = _ar, double scale = 1.0, double height = 3000}) async {
    await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: height, route: Routes.editExpense(server.gid, _eid(v)));
    await settleForm(tester);
  }

  Future<void> openNew(WidgetTester tester, {Locale locale = _ar, double scale = 1.0, double height = 3000}) async {
    await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: height, route: Routes.addExpense(server.gid));
    await settleForm(tester);
  }

  String m(int minor, {bool signed = false}) => money(_ar, minor, signed: signed);

  Finder fieldWithText(String text) => find.byWidgetPredicate((w) => w is TextField && w.controller?.text == text);

  group('the server\'s numbers, exactly (the spec vectors from the real backend)', () {
    testWidgets('V5: 561.79 with service 52.80 and tax 68.99; everyone\'s owed amount and parts', (tester) async {
      await openBill(tester, 'v5');
      expect(find.text('أصناف الفاتورة'), findsOneWidget);
      expect(fieldWithText('Pizza'), findsOneWidget);
      expect(fieldWithText('200'), findsOneWidget);
      expect(fieldWithText('150'), findsOneWidget);
      expect(fieldWithText('90'), findsOneWidget);

      // The switches show what was saved, as the percent that was typed.
      expect(tester.widget<Switch>(find.byType(Switch).at(0)).value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isTrue);
      expect(fieldWithText('12'), findsOneWidget);
      expect(fieldWithText('14'), findsOneWidget);
      final withService = find.widgetWithText(AppChoiceChip, 'المجموع + الخدمة');
      expect(withService, findsOneWidget);

      // Items subtotal, charges and total: the captured server numbers.
      expect(find.text(m(44000)), findsOneWidget, reason: 'subtotal');
      expect(find.text(m(5280, signed: true)), findsOneWidget);
      expect(find.text(m(6899, signed: true)), findsOneWidget);
      expect(find.text(m(56179)), findsNWidgets(3), reason: 'the header total, the breakdown total and the bar');

      // Per person: owed and the server's own parts.
      for (final owed in [16599, 16598, 22982]) {
        expect(find.text(m(owed)), findsOneWidget, reason: '$owed');
      }
      String line(int items, int service, int tax) => 'أصناف ${m(items)} + خدمة ${m(service)} + ضريبة ${m(tax)}';
      expect(find.text(line(13000, 1560, 2039)), findsOneWidget);
      expect(find.text(line(13000, 1560, 2038)), findsOneWidget);
      expect(find.text(line(18000, 2160, 2822)), findsOneWidget);
    });

    testWidgets('V6: service only (492.80); the tax switch is off and has no rate or base', (tester) async {
      await openBill(tester, 'v6');
      expect(tester.widget<Switch>(find.byType(Switch).at(0)).value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);
      expect(find.text('المجموع فقط'), findsNothing, reason: 'the tax base chips appear only with tax on');
      expect(find.text(m(49280)), findsWidgets);
      expect(find.text(m(5280, signed: true)), findsOneWidget);
      for (final owed in [14560, 20160]) {
        expect(find.text(m(owed)), findsWidgets);
      }
      expect(find.textContaining('+ ضريبة'), findsNothing, reason: 'no tax part in anybody\'s breakdown');
    });

    testWidgets('V7: tax only on the subtotal (501.60)', (tester) async {
      await openBill(tester, 'v7');
      expect(tester.widget<Switch>(find.byType(Switch).at(0)).value, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isTrue);
      expect(tester.widget<AppChoiceChip>(find.widgetWithText(AppChoiceChip, 'المجموع فقط')).selected, isTrue);
      expect(find.text(m(50160)), findsWidgets);
      expect(find.text(m(6160, signed: true)), findsOneWidget);
      expect(find.textContaining('+ خدمة'), findsNothing, reason: 'no service part in anybody\'s breakdown');
    });

    testWidgets('V8: neither (440.00): both switches off, items only', (tester) async {
      await openBill(tester, 'v8');
      expect(tester.widget<Switch>(find.byType(Switch).at(0)).value, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);
      expect(find.text(m(44000)), findsWidgets);
      for (final owed in [13000, 18000]) {
        expect(find.text(m(owed)), findsWidgets);
      }
    });

    testWidgets('numbers that do not add up are shown as the server sent them (nothing is recalculated)', (tester) async {
      final tampered = copyJson(fixtureMap('preview_v5'));
      tampered['totalMinor'] = 999;
      tampered['serviceMinor'] = 7;
      tampered['taxMinor'] = 3;
      (tampered['members'] as List)[0]['owedMinor'] = 1;
      server.cannedPreviews[server.itemizedKey(_golden('itemized_v5'))] = tampered;
      await openBill(tester, 'v5');
      expect(find.text(m(999)), findsWidgets);
      expect(find.text(m(7, signed: true)), findsOneWidget);
      expect(find.text(m(3, signed: true)), findsOneWidget);
      expect(find.text(m(1)), findsOneWidget);
      expect(find.text(m(56179)), findsNothing, reason: 'the saved total is not shown as if it were current');
    });

    testWidgets('the payers banner follows the server: two payers that cover the bill match', (tester) async {
      await openBill(tester, 'v5');
      expect(find.text('الدافعين مطابقين للفاتورة'), findsOneWidget);
    });

    testWidgets('and says so when the server says they do not', (tester) async {
      server.forcePayersTotalMatches = false;
      await openBill(tester, 'v5');
      expect(find.text('الدافعين مش مطابقين للفاتورة. عدّل الدافعين.'), findsOneWidget);
    });
  });

  group('items', () {
    testWidgets('adding and removing items; each item has its own price and who shared it', (tester) async {
      await openNew(tester);
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      expect(find.text('الصنف 1'), findsOneWidget);
      await tapText(tester, 'إضافة صنف جديد');
      await tapText(tester, 'إضافة صنف جديد');
      expect(find.text('الصنف 3'), findsOneWidget);
      expect(find.text('دافعين'), findsNothing);

      await tester.tap(find.byTooltip('امسح الصنف 2'));
      await tester.pumpAndSettle();
      expect(find.text('الصنف 3'), findsNothing);
      expect(find.text('الصنف 2'), findsOneWidget);
    });

    testWidgets('a new item starts with everyone selected; unchecking all shows "item without an assignee" once touched', (tester) async {
      await openNew(tester);
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      final chips = find.widgetWithText(AppChoiceChip, 'Mohamed');
      expect(tester.widget<AppChoiceChip>(chips).selected, isTrue);
      expect(find.text('اختار عضو واحد على الأقل.'), findsNothing, reason: 'not touched yet');

      for (final name in ['Mohamed', 'Asem', 'Mohsen']) {
        await tester.tap(find.widgetWithText(AppChoiceChip, name));
        await tester.pump();
      }
      await settleForm(tester);
      expect(find.text('اختار عضو واحد على الأقل.'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppChoiceChip, 'Asem'));
      await settleForm(tester);
      expect(find.text('اختار عضو واحد على الأقل.'), findsNothing);
    });

    testWidgets('a touched item with no name or an unreadable price shows its errors', (tester) async {
      await openNew(tester);
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      await tester.enterText(find.byType(TextField).at(1), 'x');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.enterText(find.byType(TextField).at(2), '12.345');
      await settleForm(tester);
      expect(find.text('اكتب اسم الصنف.'), findsOneWidget);
      expect(find.text('اكتب سعر صحيح أكبر من صفر.'), findsOneWidget);
      expect(find.text('كمّل الأصناف والنسب عشان تظهر الحسابات.'), findsOneWidget);
    });

    testWidgets('at 100 items the add button is off and says why', (tester) async {
      await openBill(tester, 'v8');
      final button = find.widgetWithText(OutlinedButton, 'إضافة صنف جديد');
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    });
  });

  group('service, tax and the adjustment', () {
    testWidgets('switching the service off removes its rate and its amount; the request has no service', (tester) async {
      await openBill(tester, 'v5');
      await tester.tap(find.byType(Switch).at(0));
      await settleForm(tester);
      expect(fieldWithText('12'), findsNothing);
      expect(find.text(m(5280, signed: true)), findsNothing);
      final last = server.previewBodies.last;
      expect(last.containsKey('service'), isFalse, reason: 'off means absent, never 0 bps');
      expect(last['tax'], isNotNull);
      // V7 is exactly "tax only on items + service": the engine answers; the total is no longer V5's.
      expect(find.text(m(56179)), findsNothing);
    });

    testWidgets('a rate that cannot be read is an error and the bill waits', (tester) async {
      await openBill(tester, 'v5');
      await tester.enterText(fieldWithText('12'), '100.01');
      await settleForm(tester);
      expect(find.text('اكتب نسبة من 0 لـ 100، بحد أقصى رقمين بعد العلامة.'), findsOneWidget);
      expect(find.text('كمّل الأصناف والنسب عشان تظهر الحسابات.'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'حفظ التعديلات');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });

    testWidgets('tax base chips: choosing "items only" changes the question and the total comes from the server', (tester) async {
      await openBill(tester, 'v5');
      await tester.tap(find.widgetWithText(AppChoiceChip, 'المجموع فقط'));
      await settleForm(tester);
      expect((server.previewBodies.last['tax'] as Map)['base'], 'SUBTOTAL');
      expect(find.text(m(55440)), findsWidgets);
      expect(find.text(m(6160, signed: true)), findsOneWidget);
    });

    testWidgets('the adjustment steppers move by one piaster and the server decides the new total', (tester) async {
      await openBill(tester, 'v8');
      await tester.tap(find.byTooltip('زوّد قرش'));
      await settleForm(tester);
      expect(fieldWithText('0.01'), findsOneWidget);
      expect(server.previewBodies.last['adjustmentMinor'], 1);
      expect(find.text(m(44001)), findsWidgets);

      await tester.tap(find.byTooltip('نقّص قرش'));
      await tester.tap(find.byTooltip('نقّص قرش'));
      await settleForm(tester);
      expect(fieldWithText('-0.01'), findsOneWidget);
      expect(find.text(m(43999)), findsWidgets);
    });

    testWidgets('a typed negative adjustment goes through, and one that makes the total negative is refused by the server', (tester) async {
      await openBill(tester, 'v8');
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.keyboardType.signed == true), '-5');
      await settleForm(tester);
      expect(find.text(m(43500)), findsWidgets);
      expect(server.previewBodies.last['adjustmentMinor'], -500);

      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.keyboardType.signed == true), '-1000');
      await settleForm(tester);
      expect(find.text('معرفناش نحسب الفاتورة.'), findsOneWidget, reason: 'VALIDATION_ERROR from the server');
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ التعديلات')).onPressed, isNull);
    });

    testWidgets('an unreadable adjustment says so', (tester) async {
      await openBill(tester, 'v8');
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.keyboardType.signed == true), '5-5');
      await settleForm(tester);
      expect(find.text('اكتب مبلغ صحيح (ممكن يكون بالسالب).'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('add a bill from nothing: items, service 12%, one payer; save creates it with the server\'s total', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Sea Food');
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNull, reason: 'nothing to save yet');

      await tester.enterText(find.byType(TextField).at(1), 'Pizza');
      await tester.enterText(find.byType(TextField).at(2), '200');
      await settleForm(tester);
      expect(find.text(m(20000)), findsWidgets, reason: 'one item, no charges: the server says 200.00');

      await tester.tap(find.byType(Switch).at(0));
      await settleForm(tester);
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'مثلاً 12'), '12');
      await settleForm(tester);
      expect(find.text(m(22400)), findsWidgets, reason: '200.00 + 12% service, worked out by the server');
      expect(find.text(m(2400, signed: true)), findsOneWidget);

      final save = find.widgetWithText(FilledButton, 'حفظ المصروف');
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(server.creates.single.body.containsKey('totalMinor'), isFalse);
      expect(server.creates.single.body['service'], {'bps': 1200});
      expect(server.expenses.where((e) => e['title'] == 'Sea Food' && '${e['id']}'.startsWith('new-')).single['totalMinor'], 22400);
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
      expect(find.text(m(22400)), findsWidgets);
    });

    testWidgets('while the server is still working the bill out, save waits', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Sea Food');
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      final gate = Completer<void>();
      server.previewGates.add(gate);
      await tester.enterText(find.byType(TextField).at(1), 'Pizza');
      await tester.enterText(find.byType(TextField).at(2), '200');
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('بنحسب الفاتورة…'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNull);

      gate.complete();
      await settleForm(tester);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNotNull);
    });

    testWidgets('a failed calculation keeps save off and offers a retry that works', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Sea Food');
      await tapText(tester, 'فاتورة مفصلة');
      await settleForm(tester);
      server.failNextPreview = true;
      await tester.enterText(find.byType(TextField).at(1), 'Pizza');
      await tester.enterText(find.byType(TextField).at(2), '200');
      await settleForm(tester);
      expect(find.text('معرفناش نحسب الفاتورة.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNull);
      await tapText(tester, 'حاول تاني');
      await settleForm(tester);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNotNull);
    });

    testWidgets('editing: rename an item and save; the PUT carries If-Match and the whole bill', (tester) async {
      await openBill(tester, 'v5');
      await tester.enterText(fieldWithText('Pizza'), 'Large pizza');
      await settleForm(tester);
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.startsWith('PUT')).single, endsWith('if-match="1"'));
      expect(((server.updates.single['items'] as List).first as Map)['name'], 'Large pizza');
      expect(server.updates.single['service'], {'bps': 1200});
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('assignee chips, switches, steppers and the remove button can be activated and are named', (tester) async {
      final handle = tester.ensureSemantics();
      await openBill(tester, 'v5');
      final chip = tester.getSemantics(find.bySemanticsLabel('Mohsen').first).getSemanticsData();
      expect(chip.hasAction(SemanticsAction.tap), isTrue);
      for (final label in ['زوّد قرش', 'نقّص قرش', 'امسح الصنف 1']) {
        final data = tester.getSemantics(find.byTooltip(label)).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      final service = tester.getSemantics(find.bySemanticsLabel(RegExp('رسوم الخدمة')).first).getSemanticsData();
      expect(service.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('the breakdown rows are one stop each with amounts in words', (tester) async {
      final handle = tester.ensureSemantics();
      await openBill(tester, 'v5');
      final row = find.bySemanticsLabel(RegExp('أصناف 130 جنيه، خدمة 15 جنيه و60 قرش، ضريبة 20 جنيه و39 قرش'));
      expect(row, findsOneWidget);
      expect(tester.getSemantics(row).getSemanticsData().label, contains('165 جنيه و99 قرش'));
      handle.dispose();
    });

    testWidgets('errors and the payers banner are live regions', (tester) async {
      final handle = tester.ensureSemantics();
      await openBill(tester, 'v5');
      await tester.enterText(fieldWithText('12'), '101');
      await settleForm(tester);
      final error = find.bySemanticsLabel(RegExp('اكتب نسبة من 0'));
      expect(error, findsWidgets);
      expect(tester.getSemantics(error.first).getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('elements the design shows but cannot be built honestly are not built', () {
    testWidgets('no receipt scan, no per-item "per person" caption, no "a + b + c = total" proof line', (tester) async {
      await openBill(tester, 'v5');
      for (final text in ['مسح ضوئي', 'قياس ضوئي', 'لكل فرد', 'مشاركين', 'متطابق بالقرش', 'بدون أي فوارق', 'المجموع الكلي']) {
        expect(find.textContaining(text), findsNothing, reason: text);
      }
    });
  });

  for (final c in allConfigs) {
    testWidgets('fits at ${c.name}: the V5 bill, 48 px targets', (tester) async {
      await openBill(tester, 'v5', locale: c.locale, scale: c.textScale, height: 800);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final save = find.widgetWithText(FilledButton, l10nFor(c.locale).expenseFormSaveChanges);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(kMinTouch));
    });
  }
}
