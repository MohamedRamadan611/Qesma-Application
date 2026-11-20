import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/money/money.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/application/expense_preview_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/fake_expenses_server.dart';

/// SA16: the itemized editor's state, controller and request builder for the v2 fields (quantity, discount, charges as
/// amounts, by-person edits, split units, the validation summary and the printed-total tolerance, A174).
const List<String> _members = [kYou, kAsem, kMohsen];

Map<String, dynamic> _wire(ExpenseCommand command) => (jsonDecode(jsonEncode(commandJson(command))) as Map).cast<String, dynamic>();

/// The spec's V5 items: Pizza 200.00 {you, Asem}, Pasta 150.00 {Mohsen}, Drinks 90.00 {everyone}.
List<ItemDraft> _items() => const [
      ItemDraft(id: 'a', name: 'Pizza', amountText: '200', assigneeIds: {kYou, kAsem}, touched: true),
      ItemDraft(id: 'b', name: 'Pasta', amountText: '150', assigneeIds: {kMohsen}, touched: true),
      ItemDraft(id: 'c', name: 'Drinks', amountText: '90', assigneeIds: {kYou, kAsem, kMohsen}, touched: true),
    ];

ExpenseFormState _bill({List<ItemDraft>? items, ItemizedDraft? draft, int? printed}) => ExpenseFormState(
      title: 'Sea Food',
      amountText: '',
      date: Date(2026, 10, 18),
      singlePayerId: kYou,
      splitMode: SplitMode.itemized,
      serverTotalMinor: 44000,
      printedTotalMinor: printed,
      itemized: (draft ?? const ItemizedDraft()).copyWith(items: items ?? _items()),
    );

void main() {
  group('the request carries the v2 fields (A171-A173) and keeps the old shape when they are not used', () {
    test('quantity 1 stays the legacy shape; quantity above 1 sends unitAmountMinor and quantity, never amountMinor', () {
      final plain = _wire(buildItemizedCommand(_bill(), memberIds: _members)!);
      for (final item in (plain['items'] as List).cast<Map<String, dynamic>>()) {
        expect(item.containsKey('amountMinor'), isTrue);
        expect(item.containsKey('quantity'), isFalse);
        expect(item.containsKey('unitAmountMinor'), isFalse);
      }
      expect(plain.containsKey('discount'), isFalse);

      final pepsi = _bill(items: const [ItemDraft(id: 'p', name: 'Pepsi', amountText: '15.25', quantity: 3, assigneeIds: {kYou, kAsem}, touched: true)]);
      final item = ((_wire(buildItemizedCommand(pepsi, memberIds: _members)!)['items'] as List).single as Map).cast<String, dynamic>();
      expect(item['unitAmountMinor'], 1525);
      expect(item['quantity'], 3);
      expect(item.containsKey('amountMinor'), isFalse, reason: 'the client never multiplies (A172)');
    });

    test('discount as a percentage or an amount, never both', () {
      final percent = _wire(buildItemizedCommand(_bill(draft: const ItemizedDraft(discountOn: true, discountPercentText: '10')), memberIds: _members)!);
      expect(percent['discount'], {'bps': 1000});
      final amount = _wire(buildItemizedCommand(
        _bill(draft: const ItemizedDraft(discountOn: true, discountMode: ChargeMode.amount, discountPercentText: '10', discountAmountText: '50')),
        memberIds: _members,
      )!);
      expect(amount['discount'], {'amountMinor': 5000}, reason: 'the text of the other mode is kept but not sent');
      final off = _wire(buildItemizedCommand(_bill(draft: const ItemizedDraft(discountPercentText: '10')), memberIds: _members)!);
      expect(off.containsKey('discount'), isFalse);
    });

    test('service and tax as amounts; the tax base is still sent with an amount', () {
      final command = _wire(buildItemizedCommand(
        _bill(
          draft: const ItemizedDraft(
            serviceOn: true,
            serviceMode: ChargeMode.amount,
            serviceAmountText: '50',
            taxOn: true,
            taxMode: ChargeMode.amount,
            taxAmountText: '60',
            taxBase: TaxBase.subtotal,
          ),
        ),
        memberIds: _members,
      )!);
      expect(command['service'], {'amountMinor': 5000});
      expect(command['tax'], {'amountMinor': 6000, 'base': 'SUBTOTAL'});
    });

    test('an unreadable discount makes the bill incomplete (no request)', () {
      for (final text in ['', '0', '100', '100.00', 'abc']) {
        final bill = _bill(draft: ItemizedDraft(discountOn: true, discountPercentText: text));
        expect(buildItemizedCommand(bill, memberIds: _members), isNull, reason: 'discount "$text"');
      }
      expect(buildItemizedCommand(_bill(draft: const ItemizedDraft(discountOn: true, discountPercentText: '99.99')), memberIds: _members), isNotNull);
      expect(buildItemizedCommand(_bill(draft: const ItemizedDraft(discountOn: true, discountMode: ChargeMode.amount, discountAmountText: '0')), memberIds: _members), isNull);
    });

    test('a saved v2 bill opens with its quantity, unit price and the charge modes it was saved with', () {
      final saved = ExpenseView((b) => b
        ..id = 'e1'
        ..groupId = 'g1'
        ..title = 'Seafood'
        ..splitType = 'ITEMIZED'
        ..category = 'OTHER'
        ..paidFromPool = false
        ..totalMinor = 13075
        ..expenseDate = Date(2026, 10, 18)
        ..version = 1
        ..createdAt = DateTime.utc(2026, 10, 18)
        ..items.add(ItemView((i) => i
          ..id = 'i1'
          ..name = 'Pepsi'
          ..quantity = 3
          ..unitAmountMinor = 1525
          ..amountMinor = 4575
          ..assigneeMemberIds.addAll([kYou, kAsem])))
        ..charges.replace(Charges((c) => c
          ..subtotalMinor = 4575
          ..adjustmentMinor = 0
          ..discount.replace(DiscountCharge((d) => d..amountMinor = 500))
          ..service.replace(ServiceCharge((s) => s
            ..bps = 1200
            ..amountMinor = 489)))));
      final form = formFromExpense(saved, memberIds: _members, fallbackPayerId: kYou);
      final item = form.itemized.items.single;
      expect((item.amountText, item.quantity), ('15.25', 3));
      expect(form.itemized.discountOn, isTrue);
      expect((form.itemized.discountMode, form.itemized.discountAmountText), (ChargeMode.amount, '5'));
      expect((form.itemized.serviceMode, form.itemized.servicePercentText), (ChargeMode.percent, '12'));
      expect(form.itemized.taxOn, isFalse);
    });
  });

  group('the controller edits the v2 bill', () {
    late FakeExpensesServer server;
    late ProviderContainer container;
    late ExpenseFormController form;

    setUp(() async {
      server = FakeExpensesServer();
      container = await formContainer(server);
      addTearDown(container.dispose);
      form = formController(container, server);
    });

    ExpenseFormState data() => formView(container, server).form!;
    PreviewState split() => container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.split)));

    /// Starts an itemized bill with the V5 items typed through the controller.
    void typeBill() {
      form.startCreate();
      form.setTitle('Sea Food');
      form.setSplitMode(SplitMode.itemized);
      final first = data().itemized.items.single.id;
      form.setItemName(first, 'Pizza');
      form.setItemAmount(first, '200');
      form.toggleAssignee(first, kMohsen);
      form.addItem();
      var id = data().itemized.items.last.id;
      form.setItemName(id, 'Pasta');
      form.setItemAmount(id, '150');
      form.toggleAssignee(id, kYou);
      form.toggleAssignee(id, kAsem);
      form.addItem();
      id = data().itemized.items.last.id;
      form.setItemName(id, 'Drinks');
      form.setItemAmount(id, '90');
    }

    test('quantity is clamped to 1..999 and stepped by one', () {
      typeBill();
      final id = data().itemized.items.first.id;
      form.setItemQuantity(id, 0);
      expect(data().itemized.items.first.quantity, 1);
      form.setItemQuantity(id, 1000);
      expect(data().itemized.items.first.quantity, 999);
      form.stepItemQuantity(id, 1);
      expect(data().itemized.items.first.quantity, 999, reason: 'cannot pass 999');
      form.setItemQuantity(id, 2);
      form.stepItemQuantity(id, -1);
      form.stepItemQuantity(id, -1);
      expect(data().itemized.items.first.quantity, 1);
    });

    test('the discount, with the spec\'s V9 numbers from the server (10% discount, 12% service, 14% tax on items + service)', () async {
      typeBill();
      form.setDiscountOn(true);
      form.setChargeText(ChargeKind.discount, '10');
      form.setServiceOn(true);
      form.setTaxOn(true);
      await waitUntil(() => split().status == PreviewStatus.ready && data().serverTotalMinor == 50561);
      expect(data().serverTotalMinor, 50561);
      final owed = {for (final s in split().preview!.members) s.memberId: s.owedMinor};
      expect(owed, {kYou: 14939, kAsem: 14938, kMohsen: 20684});
      expect(split().preview!.discountMinor, 4400);
      expect(server.previewBodies.last['discount'], {'bps': 1000});
    });

    test('the discount as an amount (V10) and the mode switch keeps what was typed in each mode', () async {
      typeBill();
      form.setDiscountOn(true);
      form.setChargeText(ChargeKind.discount, '10');
      form.setChargeMode(ChargeKind.discount, ChargeMode.amount);
      form.setChargeText(ChargeKind.discount, '50');
      expect((data().itemized.discountPercentText, data().itemized.discountAmountText), ('10', '50'));
      await waitUntil(() => data().serverTotalMinor == 39000);
      expect(data().serverTotalMinor, 39000);
      expect(server.previewBodies.last['discount'], {'amountMinor': 5000});
      form.setChargeMode(ChargeKind.discount, ChargeMode.percent);
      expect(data().itemized.discountBps, 1000, reason: 'the percentage typed earlier is back');
    });

    test('service and tax as amounts (V13: service 12%, tax 60.00 on items + service)', () async {
      typeBill();
      form.setServiceOn(true);
      form.setTaxOn(true);
      form.setChargeMode(ChargeKind.tax, ChargeMode.amount);
      form.setChargeText(ChargeKind.tax, '60');
      await waitUntil(() => data().serverTotalMinor == 55280);
      expect(data().serverTotalMinor, 55280);
      expect(server.previewBodies.last['tax'], {'amountMinor': 6000, 'base': 'SUBTOTAL_PLUS_SERVICE'});
    });

    test('a quantity (V11: 3 x 15.25 shared by two, plus a shawarma for one)', () async {
      form.startCreate();
      form.setTitle('Lunch');
      form.setSplitMode(SplitMode.itemized);
      var id = data().itemized.items.single.id;
      form.setItemName(id, 'Pepsi');
      form.setItemAmount(id, '15.25');
      form.setItemQuantity(id, 3);
      form.toggleAssignee(id, kMohsen);
      form.addItem();
      id = data().itemized.items.last.id;
      form.setItemName(id, 'Shawarma');
      form.setItemAmount(id, '85');
      form.toggleAssignee(id, kAsem);
      form.toggleAssignee(id, kMohsen);
      await waitUntil(() => data().serverTotalMinor == 13075);
      expect(data().serverTotalMinor, 13075);
      expect({for (final s in split().preview!.members) s.memberId: s.owedMinor}, {kYou: 10788, kAsem: 2287});
    });

    test('by person: tick one item, all items, none; an item nobody has is reported', () {
      typeBill();
      String idOf(int i) => data().itemized.items[i].id;
      form.toggleAssigneeForPerson(kAsem, idOf(0));
      expect(data().itemized.items.first.assigneeIds, {kYou});
      form.setPersonOnAllItems(kAsem, on: true);
      expect(data().itemized.items.every((i) => i.assigneeIds.contains(kAsem)), isTrue);
      form.setPersonOnAllItems(kAsem, on: false);
      expect(data().itemized.items.any((i) => i.assigneeIds.contains(kAsem)), isFalse);
      form.setAllAssignees(idOf(1), all: false);
      expect(data().itemized.items[1].assigneesAmong(_members), isEmpty);
      expect(data().itemized.itemsMissing(_members), 1, reason: 'one item with nobody');
      form.setAllAssignees(idOf(1), all: true);
      expect(data().itemized.items[1].assigneeIds, {...kAllMembers});
    });

    test('duplicate puts a copy right after; delete returns what is needed to undo it, at the same place', () {
      typeBill();
      form.duplicateItem(data().itemized.items[0].id);
      var items = data().itemized.items;
      expect(items.map((i) => i.name), ['Pizza', 'Pizza', 'Pasta', 'Drinks']);
      expect(items[0].id == items[1].id, isFalse);
      expect(items[1].assigneeIds, items[0].assigneeIds);
      final removed = form.removeItem(data().itemized.items[2].id)!;
      expect(data().itemized.items.map((i) => i.name), ['Pizza', 'Pizza', 'Drinks']);
      form.restoreItem(removed.item, removed.index);
      items = data().itemized.items;
      expect(items.map((i) => i.name), ['Pizza', 'Pizza', 'Pasta', 'Drinks']);
      form.restoreItem(removed.item, removed.index);
      expect(data().itemized.items, hasLength(4), reason: 'restoring twice does not duplicate');
    });

    test('split units: "you got 2, Asem got 1" becomes one item per person with the same unit price', () {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      final id = data().itemized.items.single.id;
      form.setItemName(id, 'Pepsi');
      form.setItemAmount(id, '15.25');
      form.setItemQuantity(id, 3);
      expect(form.splitItemUnits(id, {kAsem: 1, kYou: 2}), isTrue);
      final items = data().itemized.items;
      expect(items, hasLength(2));
      expect(items.map((i) => (i.name, i.amountText, i.quantity, i.assigneeIds.single)), [('Pepsi', '15.25', 2, kYou), ('Pepsi', '15.25', 1, kAsem)], reason: 'members\' order, one person each');
      expect(form.splitItemUnits('nope', {kYou: 1}), isFalse);
      expect(form.splitItemUnits(items.first.id, const {}), isFalse);
    });

    test('validation: the missing fields are counted and the first section is named', () {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      expect(data().itemizedErrorCount(_members), 3, reason: 'title, item name, item price');
      expect(data().firstErrorSection(_members), ErrorSection.title);
      form.setTitle('Sea Food');
      expect(data().firstErrorSection(_members), ErrorSection.items);
      form.setAllAssignees(data().itemized.items.first.id, all: false);
      expect(data().itemizedErrorCount(_members), 3, reason: 'name, price, assignees');
      form.setItemName(data().itemized.items.first.id, 'Pizza');
      form.setItemAmount(data().itemized.items.first.id, '10');
      form.setAllAssignees(data().itemized.items.first.id, all: true);
      expect(data().itemizedErrorCount(_members), 0);
      form.setDiscountOn(true);
      expect(data().itemizedErrorCount(_members), 1);
      expect(data().firstErrorSection(_members), ErrorSection.charges);
    });

    test('revealErrors marks every item touched and sets the flag', () {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      expect(data().itemized.items.single.touched, isFalse);
      form.revealErrors();
      expect(data().itemized.items.single.touched, isTrue);
      expect(data().showAllErrors, isTrue);
    });
  });

  group('the printed-total tolerance (A174, STANDALONE_SPEC 18.3)', () {
    late FakeExpensesServer server;
    late ProviderContainer container;
    late ExpenseFormController form;

    setUp(() async {
      server = FakeExpensesServer();
      container = await formContainer(server);
      addTearDown(container.dispose);
      form = formController(container, server);
    });

    ExpenseFormState data() => formView(container, server).form!;

    /// The V8 bill (440.00, no charges) as a scan proposes it: items assigned, the printed total from the receipt.
    void scanned(int printed) {
      form.startCreate();
      form.setTitle('Receipt');
      form.applyScan(ScanDraft(itemized: ItemizedDraft(items: _items()), printedTotalMinor: printed));
    }

    Future<void> settle() async {
      await waitUntil(() => data().serverTotalMinor != null);
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    test('the constant lives in core/money and the gap is limited to 1..100 piasters either way', () {
      expect(kPrintedTotalTolerance, 100);
      expect(toleratedGap(44099, 44000), 99);
      expect(toleratedGap(44100, 44000), 100);
      expect(toleratedGap(44101, 44000), isNull);
      expect(toleratedGap(43950, 44000), -50);
      expect(toleratedGap(43899, 44000), isNull);
      expect(toleratedGap(44000, 44000), isNull, reason: 'nothing to adjust');
    });

    test('99 piasters: the adjustment is set, the bill is previewed again and the total now matches the receipt', () async {
      scanned(44099);
      await settle();
      expect(data().itemized.adjustmentText, '0.99');
      expect(data().itemized.adjustmentAuto, isTrue);
      expect(data().autoAdjustedPiasters, 99);
      expect(data().serverTotalMinor, 44099, reason: 'the server\'s total for the adjusted bill equals the printed total');
      expect(server.previewBodies.any((b) => b['adjustmentMinor'] == 99), isTrue);
    });

    test('100 piasters is still accepted; a negative gap sets a negative adjustment', () async {
      scanned(44100);
      await settle();
      expect((data().itemized.adjustmentText, data().serverTotalMinor), ('1', 44100));
      form.applyScan(ScanDraft(itemized: ItemizedDraft(items: _items()), printedTotalMinor: 43950));
      await waitUntil(() => data().serverTotalMinor == 43950);
      expect((data().itemized.adjustmentText, data().autoAdjustedPiasters), ('-0.50', 50));
    });

    test('101 piasters keeps the mismatch: no adjustment is set', () async {
      scanned(44101);
      await settle();
      expect(data().itemized.adjustmentText, isEmpty);
      expect(data().itemized.adjustmentAuto, isFalse);
      expect(data().serverTotalMinor, 44000);
      expect(server.previewBodies.every((b) => b['adjustmentMinor'] == null), isTrue);
    });

    test('a manual edit clears the auto flag and the tolerance never overrides it again', () async {
      scanned(44050);
      await settle();
      expect(data().itemized.adjustmentAuto, isTrue);
      form.setAdjustment('2');
      expect(data().itemized.adjustmentAuto, isFalse);
      expect(data().autoAdjustedPiasters, isNull);
      expect(data().itemized.adjustmentText, '2');
      await settle();
      expect(data().itemized.adjustmentText, '2', reason: 'the user\'s own number stays');
      form.setAdjustment('');
      await settle();
      expect(data().itemized.adjustmentText, isEmpty, reason: 'clearing it by hand is also a manual choice');
    });

    test('any other edit drops the automatic adjustment and the next preview measures the bill again', () async {
      scanned(44050);
      await settle();
      expect(data().itemized.adjustmentAuto, isTrue);
      form.setItemName('a', 'Large pizza');
      expect((data().itemized.adjustmentText, data().itemized.adjustmentAuto), ('', false), reason: 'dropped at once, before any answer');
      await settle();
      expect((data().itemized.adjustmentText, data().itemized.adjustmentAuto), ('0.50', true));
    });

    test('the engine refuses the adjustment: it is taken back, the mismatch stays and nothing loops', () async {
      server.rejectAdjustments = true;
      scanned(44050);
      await waitUntil(() => data().serverTotalMinor == 44000 && !data().itemized.adjustmentAuto);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(data().itemized.adjustmentText, isEmpty);
      expect(data().itemized.adjustmentAuto, isFalse);
      expect(data().autoAdjustedPiasters, isNull);
      expect(data().serverTotalMinor, 44000);
      final adjusted = server.previewBodies.where((b) => b['adjustmentMinor'] == 50).length;
      expect(adjusted, lessThanOrEqualTo(2), reason: 'one try (the numbers and the payers check), not a loop');
    });

    test('a bill without a printed total is never adjusted', () async {
      form.startCreate();
      form.applyScan(ScanDraft(itemized: ItemizedDraft(items: _items())));
      await settle();
      expect(data().itemized.adjustmentText, isEmpty);
    });
  });
}

const List<String> kAllMembers = _members;
