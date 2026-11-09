import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/expense_form_rig.dart';
import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

const Locale _ar = Locale('ar');
const Locale _en = Locale('en');
const String _eqId = '91d890aa-7d46-458e-ad4e-e99710109445';

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() => server = FakeExpensesServer());

  Future<void> openAdd(WidgetTester tester, {Locale locale = _ar, double scale = 1.0, double height = 2400}) async {
    await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: height, route: Routes.addExpense(server.gid));
    await settleForm(tester);
  }

  Finder field(int index) => find.byType(TextField).at(index);

  Future<void> typeTitleAndAmount(WidgetTester tester, {String title = 'Petrol', String amount = '520'}) async {
    await tester.enterText(field(0), title);
    await tester.enterText(field(1), amount);
    await settleForm(tester);
  }

  Finder saveButton(Locale locale) => find.widgetWithText(FilledButton, l10nFor(locale).expenseFormSave);

  group('the add form', () {
    for (final locale in [_ar, _en]) {
      final l10n = l10nFor(locale);

      testWidgets('${locale.languageCode}: shows the fields, the paid-by summary, the four split tabs and a disabled save', (tester) async {
        await openAdd(tester, locale: locale);
        expect(find.text(l10n.expenseFormTitleLabel), findsOneWidget);
        expect(find.text(l10n.expenseFormAmountLabel), findsOneWidget);
        expect(find.text(l10n.expenseFormCurrencyNote), findsOneWidget);
        expect(find.text('${l10n.expenseFormDateLabel}: ${isolated('2026-10-18')}'), findsOneWidget, reason: 'today, as a Western-digit date');
        expect(find.text(l10n.expensePaidBy('Mohamed')), findsOneWidget, reason: 'you pay by default');
        expect(find.text(l10n.expenseFormEditPayers), findsOneWidget);
        for (final tab in [l10n.expenseFormSplitAll, l10n.expenseFormSplitSelected, l10n.expenseSplitExact, l10n.expenseSplitItemized]) {
          expect(find.text(tab), findsOneWidget, reason: tab);
        }
        expect(tester.widget<FilledButton>(saveButton(locale)).onPressed, isNull);
        expect(find.text(l10n.expenseFormShareNeedAmount), findsOneWidget);
      });
    }

    testWidgets('the Arabic copy reads as designed', (tester) async {
      await openAdd(tester);
      expect(find.text('اسم المصروف'), findsOneWidget);
      expect(find.text('المبلغ الإجمالي'), findsOneWidget);
      expect(find.text('مين اللي دفع؟'), findsOneWidget);
      expect(find.text('طريقة التقسيم'), findsOneWidget);
      expect(find.text('حفظ المصروف'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('محددين'), findsOneWidget);
    });

    testWidgets('typing a name and an amount shows the SERVER\'s shares for everyone and enables save', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      expect(find.text(money(_ar, 17334)), findsOneWidget);
      expect(find.text(money(_ar, 17333)), findsNWidgets(2));
      expect(tester.widget<FilledButton>(saveButton(_ar)).onPressed, isNotNull);
      expect(server.previewBodies.last['splitType'], 'EQUAL');
    });

    testWidgets('an unreadable amount says so and shows no shares', (tester) async {
      await openAdd(tester);
      await tester.enterText(field(0), 'Petrol');
      await tester.enterText(field(1), '12.345');
      await settleForm(tester);
      expect(find.text('اكتب مبلغ صحيح أكبر من صفر.'), findsOneWidget);
      expect(find.text(money(_ar, 17334)), findsNothing);
      expect(tester.widget<FilledButton>(saveButton(_ar)).onPressed, isNull);
    });

    testWidgets('the amount box only takes digits and separators', (tester) async {
      await openAdd(tester);
      await tester.enterText(field(1), 'ab1c2,5d0.5٠');
      await tester.pump();
      expect(tester.widget<TextField>(field(1)).controller!.text, '12,50.5٠');
    });

    testWidgets('Selected: unchecking a member changes the split and the server amounts follow', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'محددين');
      await settleForm(tester);
      expect(find.byType(Checkbox), findsNWidgets(3));
      await tester.tap(find.byType(Checkbox).last);
      await settleForm(tester);
      expect(find.text(money(_ar, 26000)), findsNWidgets(2));
      expect(find.text('—'), findsOneWidget);
      expect(server.previewBodies.last['participantMemberIds'], [kYou, kAsem]);
    });

    testWidgets('while a preview is out the shares are not shown as if they were current', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      expect(find.text(money(_ar, 17334)), findsOneWidget);
      // A new total: the old shares disappear at once; the new ones come with the new answer.
      await tester.enterText(field(1), '600');
      await tester.pump();
      expect(find.text(money(_ar, 17334)), findsNothing);
      expect(find.byType(SkeletonBlock), findsWidgets);
      await settleForm(tester);
      expect(find.text(money(_ar, 20000)), findsNWidgets(3));
    });

    testWidgets('a failed preview shows a message and retry brings the shares back', (tester) async {
      await openAdd(tester);
      server.failNextPreview = true;
      await typeTitleAndAmount(tester);
      expect(find.text('معرفناش نحسب الأنصبة.'), findsOneWidget);
      await tapText(tester, 'حاول تاني');
      await settleForm(tester);
      expect(find.text(money(_ar, 17334)), findsOneWidget);
    });

    testWidgets('Exact: prefilled from the server, "matches the total", editing shows what is left and blocks save, spread equally restores', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'مبالغ محددة');
      await settleForm(tester);

      String boxText(int i) => tester.widget<TextField>(find.byType(TextField).at(2 + i)).controller!.text;
      expect([boxText(0), boxText(1), boxText(2)], ['173.34', '173.33', '173.33']);
      expect(find.text('مطابق للإجمالي'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton(_ar)).onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).at(2), '200');
      await settleForm(tester);
      expect(find.text('مجموع التقسيم: ${money(_ar, 54666)} من ${money(_ar, 52000)}'), findsOneWidget);
      expect(find.text('زيادة ${money(_ar, 2666)} عن الإجمالي'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton(_ar)).onPressed, isNull);

      await tapText(tester, 'وزّع بالتساوي');
      await settleForm(tester);
      expect(boxText(0), '173.34');
      expect(find.text('مطابق للإجمالي'), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton(_ar)).onPressed, isNotNull);
    });

    testWidgets('Exact: something left to split is said in words', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'مبالغ محددة');
      await settleForm(tester);
      await tester.enterText(find.byType(TextField).at(2), '100');
      await settleForm(tester);
      expect(find.text('لسه باقي ${money(_ar, 7334)}'), findsOneWidget);
    });

    testWidgets('the Restaurant bill tab opens the marked FL6 screen and the form is unchanged when you come back', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'فاتورة مفصلة');
      expect(find.text('الشاشة دي لسه تحت الإنشاء.'), findsOneWidget);
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(find.text('حفظ المصروف'), findsOneWidget);
      expect(tester.widget<TextField>(field(0)).controller!.text, 'Petrol');
    });

    testWidgets('the date picker opens in Arabic and a picked date is shown', (tester) async {
      await openAdd(tester);
      await tapText(tester, 'التاريخ: ${isolated('2026-10-18')}');
      final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(find.text('التاريخ: ${isolated('2026-10-18')}'), findsOneWidget);
    });
  });

  group('who paid (the payers sheet)', () {
    Future<void> openSheet(WidgetTester tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester, title: 'Dinner', amount: '500');
      await tapText(tester, 'تعديل الدافعين');
      await settleForm(tester);
    }

    Finder amountBoxes() => find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));

    testWidgets('opens with you paying the whole total, nothing left to assign and the server confirming the match', (tester) async {
      await openSheet(tester);
      expect(find.text('مين دفع الفاتورة؟'), findsOneWidget);
      expect(find.text('المجموع مظبوط ومطابق للفاتورة'), findsOneWidget);
      expect(find.text('تأكيد الدافعين (${money(_ar, 50000)})'), findsOneWidget);
    });

    testWidgets('two payers: what is left is shown from the typed amounts, confirm waits for zero and the server agrees', (tester) async {
      await openSheet(tester);
      await tester.tap(find.byType(Checkbox).at(1)); // Asem pays too
      await settleForm(tester);
      expect(find.text('المتبقي للتوزيع: ${money(_ar, 0)}'), findsNothing);
      await tester.enterText(amountBoxes().at(0), '300');
      await tester.enterText(amountBoxes().at(1), '150');
      await settleForm(tester);
      expect(find.text('المتبقي للتوزيع: ${money(_ar, 5000)}'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تأكيد الدافعين (${money(_ar, 50000)})')).onPressed, isNull);

      await tester.enterText(amountBoxes().at(1), '250');
      await settleForm(tester);
      expect(find.text('زيادة ${money(_ar, 5000)} عن الفاتورة'), findsOneWidget);

      await tester.enterText(amountBoxes().at(1), '200');
      await settleForm(tester);
      expect(find.text('المجموع مظبوط ومطابق للفاتورة'), findsOneWidget, reason: 'typed sum is the total AND the server says so');
      expect(server.previewBodies.last['payers'], hasLength(2));
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد الدافعين (${money(_ar, 50000)})'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mohamed (${isolated('300.00')})'), findsOneWidget);
      expect(find.textContaining('Asem (${isolated('200.00')})'), findsOneWidget);
      expect(find.text('دافعين'), findsOneWidget);
    });

    testWidgets('"split equally among the payers" copies the server\'s numbers (no client division)', (tester) async {
      await openSheet(tester);
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.tap(find.byType(Checkbox).at(2));
      await settleForm(tester);
      await tapText(tester, 'قسّم بالتساوي على الدافعين');
      await settleForm(tester);
      final texts = [for (var i = 0; i < 3; i++) tester.widget<TextField>(amountBoxes().at(i)).controller!.text];
      expect(texts, ['166.67', '166.67', '166.66']);
      expect(find.text('المجموع مظبوط ومطابق للفاتورة'), findsOneWidget);
    });

    testWidgets('clear amounts empties the boxes and the remaining is the whole bill', (tester) async {
      await openSheet(tester);
      await tapText(tester, 'امسح المبالغ');
      await settleForm(tester);
      expect(tester.widget<TextField>(amountBoxes().first).controller!.text, '');
      expect(find.text('المتبقي للتوزيع: ${money(_ar, 50000)}'), findsOneWidget);
    });

    testWidgets('one payer other than you: confirm turns it into a single payer', (tester) async {
      await openSheet(tester);
      await tester.tap(find.byType(Checkbox).first); // uncheck Mohamed
      await tester.tap(find.byType(Checkbox).at(1)); // check Asem
      await settleForm(tester);
      await tester.enterText(amountBoxes().at(1), '500');
      await settleForm(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'تأكيد الدافعين (${money(_ar, 50000)})'));
      await tester.pumpAndSettle();
      expect(find.text('دفع: Asem'), findsOneWidget);
    });

    testWidgets('a server that disagrees with the typed sum blocks confirm and says so', (tester) async {
      await openSheet(tester);
      server.forcePayersTotalMatches = false; // the server's word is final, whatever was typed
      await tester.tap(find.byType(Checkbox).at(1));
      await settleForm(tester);
      await tester.enterText(amountBoxes().at(0), '300');
      await tester.enterText(amountBoxes().at(1), '200');
      await settleForm(tester);
      expect(find.text('الخادم شايف إن المجموع مش مطابق. راجع المبالغ.'), findsOneWidget);
      expect(find.text('المجموع مظبوط ومطابق للفاتورة'), findsNothing);
      final confirm = find.widgetWithText(FilledButton, 'تأكيد الدافعين (${money(_ar, 50000)})');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    });
  });

  group('saving', () {
    Future<void> fillAndSave(WidgetTester tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
    }

    testWidgets('create opens the new expense\'s details, says it was saved, and the list has it', (tester) async {
      await fillAndSave(tester);
      expect(server.creates, hasLength(1));
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
      expect(find.text('اتحفظ المصروف.'), findsOneWidget);
      expect(find.text('Petrol'), findsWidgets);
      expect(find.text(money(_ar, 52000)), findsWidgets);
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(find.text('Petrol'), findsOneWidget, reason: 'back on the refreshed expenses list');
    });

    testWidgets('a lost reply: an error with "save again", the same request, and exactly one expense', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      server.loseNextCreateResponse = true;
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
      expect(find.text('مش متأكدين إن المصروف اتحفظ. لو حفظت تاني مش هيتكرر.'), findsOneWidget);
      expect(find.text('احفظ تاني'), findsOneWidget);
      expect(find.text('حفظ المصروف'), findsOneWidget, reason: 'the form is still there');

      await tester.tap(find.text('احفظ تاني'));
      await tester.pumpAndSettle();
      expect(server.expenses, hasLength(1));
      expect(server.creates.map((c) => c.key).toSet(), hasLength(1), reason: 'one key for both attempts');
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
    });

    testWidgets('offline keeps the form and offers to try again', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      server.expensesOffline = true;
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(tester.widget<TextField>(field(0)).controller!.text, 'Petrol');
      server.expensesOffline = false;
      await tester.tap(find.text('احفظ تاني'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
    });

    testWidgets('PAYERS_TOTAL_MISMATCH from the server is a banner on the paid-by card', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      server.forceNextCreateCode = 'PAYERS_TOTAL_MISMATCH';
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
      expect(find.text('مجموع اللي دفعوه لازم يساوي إجمالي المصروف.'), findsOneWidget);
      expect(find.text('احفظ تاني'), findsNothing, reason: 'a definitive refusal is not a "try again"');
    });

    testWidgets('SPLIT_TOTAL_MISMATCH from the server is a banner under the split', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      server.forceNextCreateCode = 'SPLIT_TOTAL_MISMATCH';
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
      expect(find.text('مجموع الأنصبة لازم يساوي إجمالي المصروف.'), findsOneWidget);
    });

    testWidgets('MEMBER_NOT_IN_GROUP reloads the members and the form shows the new list', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'محددين');
      await settleForm(tester);
      server.group.members.removeWhere((m) => m.id == kMohsen);
      await tester.tap(saveButton(_ar));
      await tester.pumpAndSettle();
      expect(find.text('Mohsen'), findsNothing, reason: 'the member list was read again');
      expect(find.text('Asem'), findsWidgets);
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('an untouched form closes without asking', (tester) async {
      await openAdd(tester);
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(find.text('تخرج من غير ما تحفظ؟'), findsNothing);
      expect(find.text('اسم المصروف'), findsNothing);
    });

    testWidgets('a typed form asks first; "keep editing" stays, "leave" goes', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(find.text('تخرج من غير ما تحفظ؟'), findsOneWidget);
      await tester.tap(find.text('كمّل كتابة'));
      await tester.pumpAndSettle();
      expect(find.text('اسم المصروف'), findsOneWidget);
      expect(tester.widget<TextField>(field(0)).controller!.text, 'Petrol');

      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اخرج'));
      await tester.pumpAndSettle();
      expect(find.text('اسم المصروف'), findsNothing);
    });
  });

  group('editing an expense', () {
    Future<void> openEdit(WidgetTester tester, {Locale locale = _ar, double scale = 1.0, double height = 2400}) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: height, route: Routes.expense(server.gid, _eqId));
      await settleForm(tester);
    }

    testWidgets('Edit on the details page opens the form filled with the saved values', (tester) async {
      await openEdit(tester);
      await tapText(tester, 'تعديل المصروف');
      await settleForm(tester);
      expect(tester.widget<TextField>(field(0)).controller!.text, 'Petrol (edited)');
      expect(tester.widget<TextField>(field(1)).controller!.text, '520');
      expect(find.text('حفظ التعديلات'), findsOneWidget);
      expect(find.text(money(_ar, 17334)), findsOneWidget);
    });

    testWidgets('saving sends If-Match and the full participant list, returns to the details and shows the new title', (tester) async {
      await openEdit(tester);
      await tapText(tester, 'تعديل المصروف');
      await settleForm(tester);
      await tester.enterText(field(0), 'Petrol and tea');
      await settleForm(tester);
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.startsWith('PUT')).single, endsWith('if-match="2"'));
      expect(server.updates.single['participantMemberIds'], [kYou, kAsem, kMohsen]);
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
      expect(find.text('Petrol and tea'), findsWidgets);
      expect(find.text('معدّل (النسخة 3)'), findsOneWidget);
    });

    testWidgets('a conflict: its dialog, your input stays, a note says so, saving again works', (tester) async {
      await openEdit(tester);
      await tapText(tester, 'تعديل المصروف');
      await settleForm(tester);
      await tester.enterText(field(0), 'My edit');
      await settleForm(tester);
      server.bumpVersion(_eqId);
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      expect(find.text('المصروف اتعدّل'), findsOneWidget);
      expect(find.textContaining('اللي كتبته هيفضل زي ما هو'), findsOneWidget);

      await tester.tap(find.text('حمّل آخر نسخة'));
      await tester.pumpAndSettle();
      expect(find.text('حد عدّل المصروف ده. تعديلاتك لسه موجودة، والحفظ هيبدّل نسخته.'), findsOneWidget);
      expect(tester.widget<TextField>(field(0)).controller!.text, 'My edit');

      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.startsWith('PUT')).last, endsWith('if-match="3"'));
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
    });

    testWidgets('a lost reply to the edit: saving again ends on the details, not in an error', (tester) async {
      await openEdit(tester);
      await tapText(tester, 'تعديل المصروف');
      await settleForm(tester);
      await tester.enterText(field(0), 'My edit');
      await settleForm(tester);
      server.loseNextUpdateResponse = true;
      await tester.tap(find.text('حفظ التعديلات'));
      await tester.pumpAndSettle();
      expect(find.text('احفظ تاني'), findsOneWidget);
      await tester.tap(find.text('احفظ تاني'));
      await tester.pumpAndSettle();
      expect(find.text('المصروف اتعدّل'), findsOneWidget);
      await tester.tap(find.text('حمّل آخر نسخة'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل المصروف'), findsOneWidget);
      expect(find.text('My edit'), findsWidgets);
      expect(server.updates, hasLength(2));
    });

    testWidgets('editing an itemized bill shows the marked FL6 screen', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server, route: Routes.editExpense(server.gid, '7e3b3a23-d844-4889-99ae-5cba254d1173'));
      await settleForm(tester);
      expect(find.text('الشاشة دي لسه تحت الإنشاء.'), findsOneWidget);
      expect(find.text('اسم المصروف'), findsNothing);
    });

    testWidgets('an expense that no longer exists: the "no longer available" state', (tester) async {
      seedAllFixtures(server);
      await pumpExpensesApp(tester, server, route: Routes.editExpense(server.gid, 'gone'));
      await settleForm(tester);
      expect(find.text('المصروف ده مبقاش موجود'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('member rows are one stop with a check state and a tap action; amounts are said in words', (tester) async {
      final handle = tester.ensureSemantics();
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'محددين');
      await settleForm(tester);
      final row = find.bySemanticsLabel(RegExp('Mohamed، نصيبه 173 جنيه و34 قرش'));
      expect(row, findsOneWidget);
      final data = tester.getSemantics(row).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);

      await tester.tap(find.byType(Checkbox).last);
      await settleForm(tester);
      expect(find.bySemanticsLabel(RegExp('Mohsen، مش مشارك')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('split chips and the save button can be activated by a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      for (final label in ['الكل', 'محددين', 'مبالغ محددة']) {
        final data = tester.getSemantics(find.bySemanticsLabel(label).first).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      final save = tester.getSemantics(find.bySemanticsLabel('حفظ المصروف')).getSemanticsData();
      expect(save.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('the Exact amount boxes are labelled with whose share they are, and the remaining line is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'مبالغ محددة');
      await settleForm(tester);
      expect(find.bySemanticsLabel(RegExp('نصيب Mohamed')), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(2), '100');
      await settleForm(tester);
      final line = find.bySemanticsLabel(RegExp('لسه باقي'));
      expect(line, findsWidgets);
      expect(tester.getSemantics(line.first).getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('the payers sheet announces the remaining amount as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await openAdd(tester);
      await typeTitleAndAmount(tester, amount: '500');
      await tapText(tester, 'تعديل الدافعين');
      await settleForm(tester);
      await tapText(tester, 'امسح المبالغ');
      await settleForm(tester);
      final banner = find.bySemanticsLabel(RegExp('المتبقي للتوزيع'));
      expect(banner, findsWidgets);
      expect(tester.getSemantics(banner.first).getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('elements the design shows but the backend has no data for are not built', () {
    testWidgets('no receipt photo, no emoji in the title, no per-member captions, no payer roles', (tester) async {
      await openAdd(tester);
      await typeTitleAndAmount(tester);
      await tapText(tester, 'تعديل الدافعين');
      await settleForm(tester);
      for (final text in ['صورة', 'دافع أساسي', 'مشارك بالدفع', 'مشارك في الرحلة', 'قعدة الساحل', 'الإيصال']) {
        expect(find.textContaining(text), findsNothing, reason: text);
      }
    });
  });

  for (final c in allConfigs) {
    testWidgets('fits at ${c.name}: the form in Exact mode with a long title, 48 px targets', (tester) async {
      await openAdd(tester, locale: c.locale, scale: c.textScale, height: 800);
      await tester.enterText(field(0), t(c.locale, 'عشاء طويل جدًا في المطعم البحري الكبير على شاطئ دهب مع كل الأصحاب والعائلة', 'A very long dinner title at the big seafood place on the Dahab beach with everyone'));
      await tester.enterText(field(1), '1234567.89');
      await settleForm(tester);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text(l10nFor(c.locale).expenseSplitExact));
      await tester.tap(find.text(l10nFor(c.locale).expenseSplitExact));
      await settleForm(tester);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final save = find.widgetWithText(FilledButton, l10nFor(c.locale).expenseFormSave);
      expect(tester.getSize(save).height, greaterThanOrEqualTo(kMinTouch));
      for (final box in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(box.onChanged, isNotNull);
      }
    });

    testWidgets('fits at ${c.name}: the payers sheet with three payers', (tester) async {
      await openAdd(tester, locale: c.locale, scale: c.textScale, height: 800);
      await tester.enterText(field(0), 'Dinner');
      await tester.enterText(field(1), '500');
      await settleForm(tester);
      await tester.ensureVisible(find.text(l10nFor(c.locale).expenseFormEditPayers));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nFor(c.locale).expenseFormEditPayers));
      await settleForm(tester);
      expect(tester.takeException(), isNull);
      for (final i in [1, 2]) {
        await tester.ensureVisible(find.byType(Checkbox).at(i));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).at(i));
        await tester.pump();
      }
      await settleForm(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
