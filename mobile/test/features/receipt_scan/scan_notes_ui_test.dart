import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/receipt_scan/application/receipt_draft_mapper.dart';
import 'package:qesma/features/receipt_scan/application/receipt_parser.dart';

import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

/// SA17: the notes a scan leaves above the items, and the title and category it fills, in Arabic and English and at
/// text scale 2.0 (no overflow). The draft is built by the real parser and mapper from a model answer.
const _everything = '{"items":[{"name":"Pepsi","amount":"90","quantity":"3","unitPrice":"30"},'
    '{"name":"Koshary","amount":"135","quantity":"3"},{"name":"Tea","amount":"9","quantity":"two","unitPrice":""}],'
    '"subtotal":"234","discountAmount":"20","discountPercent":"10","merchantName":"Zooba","category":"FOOD","total":"210"}';

const _droppedDiscount = '{"items":[{"name":"Tea","amount":"9"}],"subtotal":"9","discountAmount":"9","total":"9"}';

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() {
    server = FakeExpensesServer();
    seedAllFixtures(server);
  });

  for (final config in allConfigs) {
    group(config.name, () {
      final l10n = l10nFor(config.locale);

      Future<ProviderContainer> openWith(WidgetTester tester, String json) async {
        final container = await pumpExpensesApp(tester, server, locale: config.locale, textScale: config.textScale, height: 3000, route: Routes.addExpense(server.gid));
        await settleForm(tester);
        container.read(expenseFormControllerProvider((gid: server.gid, eid: null)).notifier).applyScan(scanDraftFrom(parseReceiptJson(json)));
        await settleForm(tester);
        return container;
      }

      ExpenseFormState formOf(ProviderContainer c) => c.read(expenseFormControllerProvider((gid: server.gid, eid: null))).form!;

      testWidgets('quantity, unit price, discount (percentage kept), title and category notes are shown', (tester) async {
        final container = await openWith(tester, _everything);
        for (final text in [
          l10n.scanQuantityCheck,
          l10n.scanUnitPriceCheck,
          l10n.scanDiscountFound,
          l10n.scanDiscountPercentKept,
          l10n.scanTitleCategorySuggested,
        ]) {
          if (find.text(text).evaluate().isEmpty) await reveal(tester, find.text(text));
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.text(l10n.scanDiscountDropped), findsNothing);
        expect(tester.takeException(), isNull);

        final form = formOf(container);
        expect((form.title, form.category), ('Zooba', 'FOOD'));
        expect(form.itemized.items.map((i) => (i.amountText, i.quantity)), [('30', 3), ('135', 1), ('9', 1)]);
        expect((form.itemized.discountOn, form.itemized.discountMode, form.itemized.discountPercentText), (true, ChargeMode.percent, '10'));
        expect(find.widgetWithText(TextField, 'Zooba'), findsOneWidget, reason: 'the title field shows the shop name');
      });

      testWidgets('a discount as large as the subtotal is left out with its own note', (tester) async {
        final container = await openWith(tester, _droppedDiscount);
        if (find.text(l10n.scanDiscountDropped).evaluate().isEmpty) await reveal(tester, find.text(l10n.scanDiscountDropped));
        expect(find.text(l10n.scanDiscountDropped), findsOneWidget);
        expect(find.text(l10n.scanDiscountFound), findsNothing);
        expect(tester.takeException(), isNull);
        expect(formOf(container).itemized.discountOn, isFalse);
        expect(formOf(container).scanNotes, {ScanNote.discountDropped});
      });
    });
  }
}
