import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/presentation/assignee_summary_chip.dart';
import 'package:qesma/features/expenses/presentation/expense_blocks.dart' show ShareRows;
import 'package:qesma/features/expenses/presentation/itemized_by_person.dart' show ByPersonView;
import 'package:qesma/features/expenses/presentation/itemized_items_card.dart' show ItemCard;

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
      testWidgets('5 members keep inline chips; the stepper changes the quantity and the request carries it (${c.name})', (tester) async {
        _addMembers(server, 5);
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale);
        expect(find.byType(AssigneeSummaryChip), findsNothing);
        expect(find.widgetWithText(AppChoiceChip, 'Member 5'), findsOneWidget);

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

    // The two measurements are separate tests (one app per test); the second compares with the first.
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

    testWidgets('measure: a card with 5 members (inline chips)', (tester) async {
      fiveMemberCard = await cardHeight(tester, 5);
      expect(find.byType(AssigneeSummaryChip), findsNothing);
    });

    testWidgets('the 15-member card is not taller than the 5-member card by more than the summary chip', (tester) async {
      final five = fiveMemberCard ?? await cardHeight(tester, 5);
      server = FakeExpensesServer();
      seedAllFixtures(server);
      final fifteen = await cardHeight(tester, 15);
      expect(find.byType(AssigneeSummaryChip), findsOneWidget);
      expect(fifteen, lessThanOrEqualTo(five + kMinTouch), reason: 'five: $five, fifteen: $fifteen');
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
      await tapText(tester, l10nFor(_ar).expenseFormEditPayers);
      await settleForm(tester);
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(TextField)), findsWidgets);
    });
  });

  group('by person', () {
    for (final c in allConfigs) {
      testWidgets('choose a person, tick their items; an item nobody has is flagged (${c.name})', (tester) async {
        final l10n = l10nFor(c.locale);
        final container = await openNewBill(tester, locale: c.locale, scale: c.textScale, height: 2000);
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

        // By item the empty item is flagged too.
        expect(find.text(l10n.expenseItemizedNoAssignee), findsOneWidget);

        await tapVisible(tester, find.text(l10n.expenseItzModeByPerson));
        await settleForm(tester);
        expect(find.text(l10n.expenseItzPersonUnassigned('Pasta')), findsOneWidget);
        expect(find.byType(Checkbox), findsNWidgets(2), reason: 'one row per item');

        // The first person (you) has Pizza; tick Pasta for them.
        await tapVisible(tester, find.text('Pasta'));
        await settleForm(tester);
        expect(formOf(container).itemized.items.last.assigneeIds, {kYou});
        expect(find.text(l10n.expenseItzPersonUnassigned('Pasta')), findsNothing);

        // Another person through the picker (rows are single choice, no Done button).
        await tapVisible(tester, find.descendant(of: find.byType(ByPersonView), matching: find.byIcon(Icons.arrow_drop_down)));
        await tester.tap(find.descendant(of: find.byType(AppBottomSheet), matching: find.text('Asem')));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomSheet), findsNothing);
        await tapVisible(tester, find.text(l10n.expenseItzPersonAllItems));
        await settleForm(tester);
        expect(formOf(container).itemized.items.every((i) => i.assigneeIds.contains(kAsem)), isTrue);
        await tapVisible(tester, find.text(l10n.expenseItzPersonNoItems));
        await settleForm(tester);
        expect(formOf(container).itemized.items.any((i) => i.assigneeIds.contains(kAsem)), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
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
      await tester.ensureVisible(find.byType(Switch).at(2));
      await tester.tap(find.byType(Switch).at(2));
      await settleForm(tester);
      expect(find.widgetWithText(AppChoiceChip, 'المجموع فقط'), findsOneWidget);
      expect(container, isNotNull);
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
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
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
        await reveal(tester, find.byKey(ValueKey(formOf(container).itemized.items.last.id)));
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
      await reveal(tester, find.byKey(ValueKey(formOf(container).itemized.items.last.id)));
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

  group('split the units between people', () {
    testWidgets('"Mohamed got 2, Asem got 1" becomes two items', (tester) async {
      final container = await openNewBill(tester, height: 2400);
      final l10n = l10nFor(_ar);
      final id = formOf(container).itemized.items.single.id;
      controllerOf(container)
        ..setItemName(id, 'Pepsi')
        ..setItemAmount(id, '15.25')
        ..setItemQuantity(id, 3);
      await settleForm(tester);
      await tester.ensureVisible(find.byTooltip(l10n.expenseItzItemMenuSpoken('1')));
      await tester.tap(find.byTooltip(l10n.expenseItzItemMenuSpoken('1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.expenseItzSplitUnits));
      await tester.pumpAndSettle();
      final sheet = find.byType(AppBottomSheet);
      expect(sheet, findsOneWidget);
      expect(find.text(l10n.expenseItzSplitRemaining('3')), findsOneWidget);
      final plus = find.descendant(of: sheet, matching: find.byTooltip(l10n.expenseItzQuantityPlus));
      await tester.tap(plus.at(0));
      await tester.tap(plus.at(0));
      await tester.tap(plus.at(1));
      await tester.pumpAndSettle();
      expect(find.text(l10n.expenseItzSplitMatches), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, l10n.expenseItzSplitConfirm));
      await tester.pumpAndSettle();
      final items = formOf(container).itemized.items;
      expect(items.map((i) => (i.quantity, i.assigneeIds.single)), [(2, kYou), (1, kAsem)]);
      expect(find.byType(ItemCard), findsNWidgets(2));
    });
  });

  group('the read-only details (P7-01)', () {
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
