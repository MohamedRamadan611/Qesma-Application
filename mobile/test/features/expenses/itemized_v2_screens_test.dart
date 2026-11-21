import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/presentation/assignee_summary_chip.dart';
import 'package:qesma/features/expenses/presentation/expense_blocks.dart' show ShareRows;
import 'package:qesma/features/expenses/presentation/itemized_by_person.dart' show ByPersonView;
import 'package:qesma/features/expenses/presentation/itemized_items_card.dart' show ItemCard, ItemSummaryRow;
import 'package:qesma/features/expenses/presentation/validation_summary_card.dart';

import '../../support/expense_form_rig.dart';
import '../../support/expenses_rig.dart';
import '../../support/expenses_ui.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/fake_groups_server.dart';
import '../../support/test_app.dart';

/// SA16 widget tests: the compact item card, the member picker, by-person mode, charges, the breakdown, the
/// validation summary with scroll-to-first-error, the printed-total note, split units and the read-only details, in
/// Arabic and English and at text scale 2.0 (the cases that depend on layout run over [allConfigs]).
const Locale _ar = Locale('ar');

/// Adds members to the captured group (3) until it has [total]: "Member 4" ... with ids "member-3" ...
void _addMembers(FakeExpensesServer server, int total) {
  for (var i = server.group.members.length; i < total; i++) {
    server.group.members.add(FakeMember(id: 'member-$i', name: 'Member ${i + 1}', sortOrder: 10 + i));
  }
}

void main() {
  setUpAll(loadAppFonts);

  late FakeExpensesServer server;
  setUp(() {
    server = FakeExpensesServer();
    seedAllFixtures(server);
  });

  ExpenseFormState formOf(ProviderContainer container) => container.read(expenseFormControllerProvider((gid: server.gid, eid: null))).form!;
  ExpenseFormController controllerOf(ProviderContainer container) => container.read(expenseFormControllerProvider((gid: server.gid, eid: null)).notifier);

  /// Scrolls the page until [finder] is built and on screen, then taps it (the list builds lazily; at 2.0x it is long).
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) await reveal(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> openNewBill(WidgetTester tester, {Locale locale = _ar, double scale = 1.0, double height = 2400}) async {
    final container = await pumpExpensesApp(tester, server, locale: locale, textScale: scale, height: height, route: Routes.addExpense(server.gid));
    await settleForm(tester);
    controllerOf(container).setSplitMode(SplitMode.itemized);
    await settleForm(tester);
    return container;
  }

  group('the compact item card', () {
    for (final c in allConfigs) {
      testWidgets('the members button is always one summary chip; the stepper changes the quantity and the request carries it (${c.name})', (tester) async {
        _addMembers(server, 5);
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale);
        expect(find.byType(AssigneeSummaryChip), findsOneWidget, reason: 'no inline chips any more, whatever the group size');
        expect(find.widgetWithText(AppChoiceChip, 'Member 5'), findsNothing);

        final name = formOf(container).itemized.items.single.id;
        controllerOf(container)
          ..setItemName(name, 'Pepsi')
          ..setItemAmount(name, '15.25');
        await settleForm(tester);
        for (var i = 0; i < 2; i++) {
          await tester.ensureVisible(find.byTooltip(l10n.expenseItzQuantityPlus).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(l10n.expenseItzQuantityPlus).first);
          await tester.pumpAndSettle();
        }
        await settleForm(tester);
        expect(formOf(container).itemized.items.single.quantity, 3);
        final item = (server.previewBodies.last['items'] as List).single as Map;
        expect((item['unitAmountMinor'], item['quantity']), (1525, 3));
        expect(item.containsKey('amountMinor'), isFalse);
        expect(find.textContaining('×'), findsWidgets, reason: 'the line is shown as typed: 3 x 15.25');
        expect(tester.takeException(), isNull);
      });
    }

    // The open card is the same size for any group (the members button is one chip).
    double? fiveMemberCard;

    Future<double> cardHeight(WidgetTester tester, int members) async {
      _addMembers(server, members);
      final container = await openNewBill(tester);
      final id = formOf(container).itemized.items.single.id;
      controllerOf(container)
        ..setItemName(id, 'Pizza')
        ..setItemAmount(id, '200');
      await settleForm(tester);
      return tester.getSize(find.byType(ItemCard).first).height;
    }

    testWidgets('measure: the open card with 5 members', (tester) async {
      fiveMemberCard = await cardHeight(tester, 5);
      expect(find.byType(AssigneeSummaryChip), findsOneWidget);
    });

    testWidgets('the open card with 15 members is the same height', (tester) async {
      final five = fiveMemberCard ?? await cardHeight(tester, 5);
      server = FakeExpensesServer();
      seedAllFixtures(server);
      final fifteen = await cardHeight(tester, 15);
      expect(find.byType(AssigneeSummaryChip), findsOneWidget);
      expect(fifteen, closeTo(five, 1), reason: 'five: $five, fifteen: $fifteen');
    });
  });

  group('the member picker', () {
    for (final c in allConfigs) {
      testWidgets('search above 8 members, all/none, a sticky "Done (n)" button (${c.name})', (tester) async {
        _addMembers(server, 15);
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale, height: 1600);
        final id = formOf(container).itemized.items.single.id;
        expect(find.byType(AppChoiceChip).evaluate().where((e) => (e.widget as AppChoiceChip).label.startsWith('Member')), isEmpty, reason: 'no inline chips');

        await tapVisible(tester, find.byType(AssigneeSummaryChip));
        expect(find.byType(AppBottomSheet), findsOneWidget);
        expect(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('15')), findsOneWidget, reason: 'everyone is in by default');

        // Search.
        await tester.enterText(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), 'Member 1');
        await tester.pumpAndSettle();
        expect(find.text('Member 12'), findsOneWidget);
        expect(find.text('Member 5'), findsNothing);
        await tester.enterText(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), 'zzz');
        await tester.pumpAndSettle();
        expect(find.text(l10n.expenseItzPickerNoResults), findsOneWidget);
        await tester.enterText(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), '');
        await tester.pumpAndSettle();

        // None, then two people.
        await tester.tap(find.widgetWithText(AppChoiceChip, l10n.expenseItzPickerNone));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('0')), findsOneWidget);
        await tester.tap(find.text('Member 4'));
        await tester.tap(find.text('Member 5'));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('2')), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('2')));
        await tester.pumpAndSettle();
        expect(formOf(container).itemized.items.single.assigneeIds, {'member-3', 'member-4'});
        expect(find.byType(AppBottomSheet), findsNothing);

        // All again: the summary says "everyone".
        await tapVisible(tester, find.byType(AssigneeSummaryChip));
        await tester.tap(find.descendant(of: find.byType(AppBottomSheet), matching: find.widgetWithText(AppChoiceChip, l10n.expenseItzPickerAll)));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('15')));
        await tester.pumpAndSettle();
        expect(formOf(container).itemized.items.single.assigneeIds, hasLength(15));
        expect(find.descendant(of: find.byType(AssigneeSummaryChip), matching: find.text(l10n.expenseItzSummaryAll)), findsOneWidget);
        expect(id, isNotEmpty);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('6 members use the summary chip, but the sheet has no search (it appears above 8)', (tester) async {
      _addMembers(server, 6);
      await openNewBill(tester);
      await tester.tap(find.byType(AssigneeSummaryChip).first);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), findsNothing);
      expect(find.text('Member 6'), findsOneWidget);
    });

    testWidgets('the paid-by sheet also gets the search with many members', (tester) async {
      _addMembers(server, 12);
      await openNewBill(tester);
      await tapText(tester, l10nFor(_ar).expenseFormChange);
      await settleForm(tester);
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), findsWidgets);
    });
  });

  group('by person', () {
    for (final c in allConfigs) {
      testWidgets('person cards: copy an item, remove one, add one for them; an item nobody has is flagged (${c.name})', (tester) async {
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale, height: 2400);
        final ctl = controllerOf(container);
        final first = formOf(container).itemized.items.single.id;
        ctl
          ..setItemName(first, 'Pizza')
          ..setItemAmount(first, '200')
          ..addItem();
        final second = formOf(container).itemized.items.last.id;
        ctl
          ..setItemName(second, 'Pasta')
          ..setItemAmount(second, '150')
          ..setAllAssignees(second, all: false);
        await settleForm(tester);

        // By item the empty item is a closed row that says nobody was chosen.
        expect(find.textContaining(l10n.expenseItzSummaryNone), findsWidgets);

        await tapVisible(tester, find.text(l10n.expenseItzModeByPerson));
        await settleForm(tester);
        expect(find.text(l10n.expenseItzPersonUnassigned('Pasta')), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing, reason: 'person cards, not a checklist');

        // The first person (you) has Pizza; "copy an existing item" puts Pasta on them.
        await tapVisible(tester, find.bySemanticsLabel(l10n.expenseItzCopyItemSpoken('Pasta', 'Mohamed')));
        await settleForm(tester);
        expect(formOf(container).itemized.items.last.assigneeIds, {kYou});
        expect(find.text(l10n.expenseItzPersonUnassigned('Pasta')), findsNothing);

        // Another person: open their card, take Pizza off them, then add an item for them with the inline form.
        await tapVisible(tester, find.descendant(of: find.byType(ByPersonView), matching: find.text('Asem')).first);
        await settleForm(tester);
        await tapVisible(tester, find.byTooltip(l10n.expenseItzPersonRemoveItem('Pizza', 'Asem')));
        await settleForm(tester);
        expect(formOf(container).itemized.items.first.assigneeIds.contains(kAsem), isFalse, reason: 'removed from this person');
        final fields = find.descendant(of: find.byType(ByPersonView), matching: find.byType(TextField));
        await tester.ensureVisible(fields.first);
        await tester.enterText(fields.first, 'Fries');
        await tester.enterText(fields.at(1), '40');
        await tapVisible(tester, find.text(l10n.expenseItzAddItemFor('Asem')));
        await settleForm(tester);
        final added = formOf(container).itemized.items.last;
        expect((added.name, added.amountText), ('Fries', '40'));
        expect(added.assigneeIds, {kAsem});
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the add-an-item form shows its errors and adds nothing while a field is missing', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      final before = formOf(container).itemized.items.length;
      await tapVisible(tester, find.text(l10n.expenseItzModeByPerson));
      await settleForm(tester);
      await tapVisible(tester, find.text(l10n.expenseItzAddItemFor('Mohamed')));
      await settleForm(tester);
      expect(find.text(l10n.expenseItemizedNameRequired), findsWidgets);
      expect(find.text(l10n.expenseItemizedAmountInvalid), findsWidgets);
      expect(formOf(container).itemized.items.length, before);
    });
  });

  group('charges: discount, service and tax', () {
    testWidgets('the discount row: switch, % | EGP toggle, the server\'s amount; the tax base chips only with service and tax on', (tester) async {
      final container = await pumpExpensesApp(tester, server, height: 3000, route: Routes.editExpense(server.gid, fixtureMap('expense_itemized_v6_service_only')['id'] as String));
      await settleForm(tester);
      final l10n = l10nFor(_ar);
      expect(find.widgetWithText(AppChoiceChip, 'المجموع فقط'), findsNothing, reason: 'service only: no base to choose');

      // Discount on: an empty rate is an error (icon and words), 10% makes the server's total 392.00... for 440 - 44 + 12% service.
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await settleForm(tester);
      expect(find.text(l10n.expenseItzDiscountPercentInvalid), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsWidgets);
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == l10n.expenseItemizedPercentHint).first, '10');
      await settleForm(tester);
      expect(server.previewBodies.last['discount'], {'bps': 1000});
      expect(find.textContaining('−'), findsWidgets, reason: 'the discount amount is shown with a minus, as the server sent it');

      // Amount mode.
      await tester.tap(find.text(l10n.expenseItzModeAmount).first);
      await settleForm(tester);
      expect(find.text(l10n.expenseItzDiscountNeedsAmount), findsOneWidget);
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == l10n.expenseItzAmountHint).first, '50');
      await settleForm(tester);
      expect(server.previewBodies.last['discount'], {'amountMinor': 5000});

      // Tax on with the service already on: the base chips appear.
      await tester.ensureVisible(find.byType(Switch).at(3));
      await tester.tap(find.byType(Switch).at(3));
      await settleForm(tester);
      expect(find.widgetWithText(AppChoiceChip, 'المجموع فقط'), findsOneWidget);
      expect(container, isNotNull);
    });
  });

  group('delivery (A180): an amount only, outside discount, service and tax', () {
    testWidgets('switch on, amount only (no % toggle), the request carries it and the server\'s per-person part is the hint', (tester) async {
      await pumpExpensesApp(tester, server, height: 3000, route: Routes.editExpense(server.gid, fixtureMap('expense_itemized_v8_neither')['id'] as String));
      await settleForm(tester);
      final l10n = l10nFor(_ar);
      expect(tester.widget<Switch>(find.byType(Switch).at(2)).value, isFalse, reason: 'saved without delivery');
      expect(server.previewBodies.every((b) => !b.containsKey('deliveryMinor')), isTrue);

      await tester.ensureVisible(find.byType(Switch).at(2));
      await tester.tap(find.byType(Switch).at(2));
      await settleForm(tester);
      expect(find.text(l10n.expenseItzChargeAmountInvalid), findsOneWidget, reason: 'on and empty: an error with icon and words');
      // Delivery has no % | EGP toggle (the other charges are off here, so there is none on screen at all).
      expect(find.byType(SegmentedButton<ChargeMode>), findsNothing);

      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == l10n.expenseItzAmountHint).last, '10');
      await settleForm(tester);
      expect(server.previewBodies.last['deliveryMinor'], 1000);
      expect(find.textContaining(l10n.expenseItzDeliveryLabel), findsWidgets);
    });

    testWidgets('the breakdown folds the delivery part the server sent', (tester) async {
      final container = await openNewBill(tester);
      final c = controllerOf(container);
      final id = formOf(container).itemized.items.first.id;
      c.setItemName(id, 'Pizza');
      c.setItemAmount(id, '300');
      c.setDeliveryOn(true);
      c.setDeliveryAmount('30');
      await settleForm(tester);
      expect(server.previewBodies.last['deliveryMinor'], 3000);
      final l10n = l10nFor(_ar);
      final more = find.descendant(of: find.byType(ShareRows), matching: find.byIcon(Icons.expand_more));
      await tester.ensureVisible(more.first);
      await tester.pumpAndSettle();
      await tester.tap(more.first);
      await tester.pumpAndSettle();
      expect(find.textContaining(l10n.expensePartDelivery('').trim()), findsWidgets);
    });
  });

  group('the breakdown folds each person\'s parts', () {
    testWidgets('one row per person, opened by a tap; the discount part is the server\'s', (tester) async {
      final v8 = fixtureMap('expense_itemized_v8_neither')['id'] as String;
      await pumpExpensesApp(tester, server, height: 3000, route: Routes.editExpense(server.gid, v8));
      await settleForm(tester);
      final l10n = l10nFor(_ar);
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await settleForm(tester);
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == l10n.expenseItemizedPercentHint).first, '10');
      await settleForm(tester);

      final rows = find.byType(ShareRows);
      expect(rows, findsOneWidget);
      expect(find.textContaining('خصم −'), findsNothing, reason: 'folded until the row is opened');
      final more = find.descendant(of: rows, matching: find.byIcon(Icons.expand_more));
      expect(more, findsWidgets);
      await tester.ensureVisible(more.first);
      await tester.pumpAndSettle();
      await tester.tap(more.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('خصم −'), findsOneWidget);
      expect(find.descendant(of: rows, matching: find.byIcon(Icons.expand_less)), findsOneWidget);
    });
  });

  group('validation: Save stays enabled, counts what is missing and goes to the first problem', () {
    for (final c in allConfigs) {
      testWidgets('count, icon and words, and the page scrolls to the first item (${c.name})', (tester) async {
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale, height: 800);
        final ctl = controllerOf(container);
        ctl.setTitle('Sea Food');
        for (var i = 0; i < 9; i++) {
          ctl.addItem();
        }
        await settleForm(tester);
        await reveal(tester, find.text(l10n.expenseItemizedAdd));
        final firstItem = find.byKey(ValueKey(formOf(container).itemized.items.first.id));
        if (firstItem.evaluate().isNotEmpty) expect(tester.getRect(firstItem).top, lessThan(0), reason: 'the first item is scrolled away');

        final save = find.widgetWithText(FilledButton, l10n.expenseItzSave);
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull, reason: 'Save stays enabled on a restaurant bill');
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(server.creates, isEmpty);
        // Ten items with no name and no price: twenty fields.
        expect(find.text(l10n.expenseItzMissingCount(20)), findsOneWidget);
        expect(find.descendant(of: find.byType(Scaffold), matching: find.byIcon(Icons.error_outline)), findsWidgets, reason: 'an icon, never colour alone');
        expect(firstItem, findsOneWidget, reason: 'scrolled back to the first section with a problem');
        // The section is brought to the top, so the first item is on screen (at 2.0x the section header takes much of it).
        final rect = tester.getRect(firstItem);
        expect(rect.bottom, greaterThan(0));
        expect(rect.top, lessThan(800));
        expect(find.text(l10n.expenseItemizedNameRequired), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('with the title missing the page goes to the title first', (tester) async {
      final container = await openNewBill(tester, height: 800);
      for (var i = 0; i < 5; i++) {
        controllerOf(container).addItem();
      }
      await settleForm(tester);
      await reveal(tester, find.text(l10nFor(_ar).expenseItemizedAdd));
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ الفاتورة'));
      await tester.pumpAndSettle();
      expect(find.text(l10nFor(_ar).expenseFormTitleRequired), findsOneWidget);
      expect(tester.getRect(find.text(l10nFor(_ar).expenseFormTitleRequired)).top, inInclusiveRange(0, 800));
    });

    testWidgets('the other tabs keep a Save that waits until the form is valid', (tester) async {
      await pumpExpensesApp(tester, server, route: Routes.addExpense(server.gid));
      await settleForm(tester);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ المصروف')).onPressed, isNull);
    });
  });

  group('the item accordion and the validation summary (redesign)', () {
    testWidgets('one item is open at a time: tapping a closed row opens it and closes the other', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final ctl = controllerOf(container);
      final first = formOf(container).itemized.items.single.id;
      ctl
        ..setItemName(first, 'Pizza')
        ..setItemAmount(first, '200')
        ..addItem();
      final second = formOf(container).itemized.items.last.id;
      ctl
        ..setItemName(second, 'Pasta')
        ..setItemAmount(second, '150');
      await settleForm(tester);

      expect(find.byType(ItemCard), findsOneWidget);
      expect(find.widgetWithText(ItemSummaryRow, 'Pasta'), findsOneWidget, reason: 'the second item is a one-line row');
      await tapVisible(tester, find.widgetWithText(ItemSummaryRow, 'Pasta'));
      await settleForm(tester);
      expect(find.byType(ItemCard), findsOneWidget);
      expect(find.widgetWithText(ItemSummaryRow, 'Pizza'), findsOneWidget, reason: 'the first one closed');
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Pasta'), findsOneWidget);
    });

    testWidgets('Save lists every problem; a tap on one opens that item', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      final ctl = controllerOf(container)..setTitle('Sea Food');
      final first = formOf(container).itemized.items.single.id;
      ctl
        ..setItemName(first, 'Pizza')
        ..setItemAmount(first, '200')
        ..addItem();
      final second = formOf(container).itemized.items.last.id;
      ctl.setItemName(second, 'Pasta'); // no price
      await settleForm(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, l10n.expenseItzSave));
      await tester.drag(find.byType(ListView).first, const Offset(0, 4000)); // back to the top, where the summary is
      await tester.pumpAndSettle();
      expect(find.byType(ValidationSummaryCard), findsOneWidget);
      expect(find.text(l10n.expenseItzSummaryTitle(1)), findsOneWidget);
      expect(find.text(l10n.expenseItzIssueItemPrice('Pasta')), findsOneWidget);
      expect(find.descendant(of: find.byType(ValidationSummaryCard), matching: find.byIcon(Icons.error_outline)), findsWidgets, reason: 'an icon, never colour alone');

      await tester.tap(find.text(l10n.expenseItzIssueItemPrice('Pasta')));
      await settleForm(tester);
      expect(find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Pasta'), findsOneWidget, reason: 'the item with the problem is open');
      expect(find.text(l10n.expenseItemizedAmountInvalid), findsWidgets);
    });

    testWidgets('a scan notice can be closed', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      controllerOf(container).applyScan(ScanDraft(
        itemized: const ItemizedDraft(items: [ItemDraft(id: 'a', name: 'Pizza', amountText: '200', touched: true)]),
        notes: {ScanNote.discountFound},
      ));
      await settleForm(tester);
      expect(find.text(l10n.scanDiscountFound), findsOneWidget);
      await tapVisible(tester, find.byTooltip(l10n.commonClose));
      expect(find.text(l10n.scanDiscountFound), findsNothing);
      expect(formOf(container).scanNotes.contains(ScanNote.discountFound), isFalse);
    });
  });

  group('the printed total of a scanned receipt (A174)', () {
    ItemizedDraft bill() => const ItemizedDraft(items: [
          ItemDraft(id: 'a', name: 'Pizza', amountText: '200', assigneeIds: {kYou, kAsem}, touched: true),
          ItemDraft(id: 'b', name: 'Pasta', amountText: '150', assigneeIds: {kMohsen}, touched: true),
          ItemDraft(id: 'c', name: 'Drinks', amountText: '90', assigneeIds: {kYou, kAsem, kMohsen}, touched: true),
        ]);

    testWidgets('within 1 EGP: the adjustment is set, the match and the note are shown', (tester) async {
      final container = await pumpExpensesApp(tester, server, height: 3000, route: Routes.addExpense(server.gid));
      await settleForm(tester);
      controllerOf(container).applyScan(ScanDraft(itemized: bill(), printedTotalMinor: 44050));
      await settleForm(tester);
      expect(find.textContaining('تم ضبط فرق'), findsOneWidget);
      expect(find.textContaining('قرش تلقائيًا لمطابقة إجمالي الإيصال'), findsOneWidget);
      expect(find.textContaining('الإجمالي زي إجمالي الإيصال'), findsOneWidget);
      expect(find.textContaining('الإجمالي مش زي'), findsNothing);

      // Typing the adjustment by hand takes the note away.
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.keyboardType.signed == true), '2');
      await settleForm(tester);
      expect(find.textContaining('تم ضبط فرق'), findsNothing);
    });

    testWidgets('more than 1 EGP away: the mismatch banner stays and nothing is adjusted', (tester) async {
      final container = await pumpExpensesApp(tester, server, height: 3000, route: Routes.addExpense(server.gid));
      await settleForm(tester);
      controllerOf(container).applyScan(ScanDraft(itemized: bill(), printedTotalMinor: 44101));
      await settleForm(tester);
      expect(find.textContaining('الإجمالي مش زي إجمالي الإيصال'), findsOneWidget);
      expect(find.textContaining('تم ضبط فرق'), findsNothing);
    });

    testWidgets('the engine refuses the adjustment: the mismatch banner stays', (tester) async {
      server.rejectAdjustments = true;
      final container = await pumpExpensesApp(tester, server, height: 3000, route: Routes.addExpense(server.gid));
      await settleForm(tester);
      controllerOf(container).applyScan(ScanDraft(itemized: bill(), printedTotalMinor: 44050));
      await settleForm(tester);
      expect(find.textContaining('الإجمالي مش زي إجمالي الإيصال'), findsOneWidget);
      expect(find.textContaining('تم ضبط فرق'), findsNothing);
    });
  });

  group('split the units between people (the picker\'s "by quantity" mode)', () {
    testWidgets('"Mohamed got 2, Asem got 1" becomes two items', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      final id = formOf(container).itemized.items.single.id;
      controllerOf(container)
        ..setItemName(id, 'Pepsi')
        ..setItemAmount(id, '15.25')
        ..setItemQuantity(id, 3);
      await settleForm(tester);
      await tapVisible(tester, find.byType(AssigneeSummaryChip));
      final sheet = find.byType(AppBottomSheet);
      expect(sheet, findsOneWidget);
      // Equal is the default; "by quantity" shows how many units are given out.
      await tester.tap(find.text(l10n.expenseItzPickerModeQuantity));
      await tester.pumpAndSettle();
      expect(find.text(l10n.expenseItzPickerDistributed('0', '3')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('0'))).onPressed, isNull, reason: 'the units must add up to the quantity');
      final plus = find.descendant(of: sheet, matching: find.byTooltip(l10n.expenseItzQuantityPlus));
      await tester.tap(plus.at(0));
      await tester.tap(plus.at(0));
      await tester.tap(plus.at(1));
      await tester.pumpAndSettle();
      expect(find.text(l10n.expenseItzSplitMatches), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, l10n.expenseItzPickerDone('2')));
      await tester.pumpAndSettle();
      final items = formOf(container).itemized.items;
      expect(items.map((i) => (i.quantity, i.assigneeIds.single)), [(2, kYou), (1, kAsem)]);
      expect(find.byType(ItemCard).evaluate().length + find.byType(ItemSummaryRow).evaluate().length, 2);
    });

    testWidgets('an item with quantity 1 has no mode toggle', (tester) async {
      await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      await tapVisible(tester, find.byType(AssigneeSummaryChip));
      expect(find.text(l10n.expenseItzPickerModeQuantity), findsNothing);
    });
  });

  group('the read-only details (P7-01)', () {
    testWidgets('delivery is a line of the charges box only when the server sent one (A180)', (tester) async {
      final json = copyJson(fixtureMap('expense_itemized_v8_neither'));
      json['id'] = 'with-delivery';
      (json['charges'] as Map<String, dynamic>)['deliveryMinor'] = 3000;
      server.expenses.add(json);
      await pumpExpensesApp(tester, server, height: 3000, route: Routes.expense(server.gid, 'with-delivery'));
      await settleForm(tester);
      expect(find.text(l10nFor(_ar).expenseItzDeliveryLabel), findsOneWidget);
    });

    testWidgets('a bill without delivery (the captured V8) has no delivery line', (tester) async {
      await pumpExpensesApp(tester, server, height: 3000, route: Routes.expense(server.gid, fixtureMap('expense_itemized_v8_neither')['id'] as String));
      await settleForm(tester);
      expect(find.text(l10nFor(_ar).expenseItzDeliveryLabel), findsNothing);
    });

    testWidgets('quantity, the discount line and "names +N" that expands', (tester) async {
      _addMembers(server, 6);
      final json = copyJson(fixtureMap('expense_itemized_v5'));
      json['id'] = 'v2-bill';
      final items = (json['items'] as List).cast<Map<String, dynamic>>();
      items.first
        ..['quantity'] = 2
        ..['unitAmountMinor'] = 10000
        ..['amountMinor'] = 20000
        ..['assigneeMemberIds'] = [kYou, kAsem, kMohsen, 'member-3', 'member-4'];
      (json['charges'] as Map<String, dynamic>)['discount'] = {'bps': 1000, 'amountMinor': 4400};
      server.expenses.add(json);
      await pumpExpensesApp(tester, server, height: 3000, route: Routes.expense(server.gid, 'v2-bill'));
      await settleForm(tester);
      final l10n = l10nFor(_ar);

      expect(find.textContaining('×'), findsOneWidget, reason: 'only the item with a quantity above 1');
      expect(find.text(l10n.expenseItzDetailsDiscount), findsOneWidget);
      expect(find.textContaining('−'), findsWidgets);
      expect(find.text('+2'), findsOneWidget);
      await tester.ensureVisible(find.text('+2'));
      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.expenseItzAssigneesCollapseSpoken), findsOneWidget);
      expect(find.text('+2'), findsNothing);
    });
  });
}
