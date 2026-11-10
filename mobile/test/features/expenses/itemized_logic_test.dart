import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/core/money/money.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/application/expense_preview_controller.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/expenses_rig.dart';
import '../../support/fake_expenses_server.dart';

const List<String> _members = [kYou, kAsem, kMohsen];

Map<String, dynamic> _golden(String name) => (jsonDecode(File('test/fixtures/expense_commands/$name.json').readAsStringSync()) as Map).cast<String, dynamic>();

Map<String, dynamic> _wire(ExpenseCommand command) => (jsonDecode(jsonEncode(commandJson(command))) as Map).cast<String, dynamic>();

/// The spec's bill (section 10, V5-V8): Pizza 200.00 {Mohamed, Asem}, Pasta 150.00 {Mohsen}, Drinks 90.00 {everyone}.
List<ItemDraft> _items() => const [
      ItemDraft(id: 'a', name: 'Pizza', amountText: '200', assigneeIds: {kYou, kAsem}, touched: true),
      ItemDraft(id: 'b', name: 'Pasta', amountText: '150', assigneeIds: {kMohsen}, touched: true),
      ItemDraft(id: 'c', name: 'Drinks', amountText: '90', assigneeIds: {kYou, kAsem, kMohsen}, touched: true),
    ];

ExpenseFormState _bill({
  String title = 'Sea Food',
  List<ItemDraft>? items,
  bool service = false,
  String servicePercent = '',
  bool tax = false,
  String taxPercent = '',
  TaxBase base = TaxBase.subtotalPlusService,
  String adjustment = '',
  int? serverTotal,
  PayerMode payerMode = PayerMode.single,
  Map<String, String> payerTexts = const {},
}) =>
    ExpenseFormState(
      title: title,
      amountText: '',
      date: Date(2026, 10, 18),
      singlePayerId: kYou,
      splitMode: SplitMode.itemized,
      payerMode: payerMode,
      payerTexts: payerTexts,
      serverTotalMinor: serverTotal,
      itemized: ItemizedDraft(
        items: items ?? _items(),
        serviceOn: service,
        servicePercentText: servicePercent,
        taxOn: tax,
        taxPercentText: taxPercent,
        taxBase: base,
        adjustmentText: adjustment,
      ),
    );

/// The four vectors: name, the bill, the server's total for it.
final Map<String, ({ExpenseFormState form, int total})> _vectors = {
  'v5': (form: _bill(service: true, servicePercent: '12', tax: true, taxPercent: '14', serverTotal: 56179), total: 56179),
  'v6': (form: _bill(service: true, servicePercent: '12', serverTotal: 49280), total: 49280),
  'v7': (form: _bill(tax: true, taxPercent: '14', base: TaxBase.subtotal, serverTotal: 50160), total: 50160),
  'v8': (form: _bill(serverTotal: 44000), total: 44000),
};

/// An [ExpenseCommand] written out of a saved expense's JSON (the way the backend would read it back).
ExpenseCommand _commandOf(Map<String, dynamic> e) {
  final charges = e['charges'] as Map<String, dynamic>?;
  return ExpenseCommand((b) {
    b
      ..title = e['title'] as String
      ..expenseDate = _dateOf(e['expenseDate'] as String)
      ..splitType = 'ITEMIZED';
    b.items.addAll([
      for (final i in (e['items'] as List).cast<Map<String, dynamic>>())
        ItemInput((x) => x
          ..name = i['name'] as String
          ..amountMinor = i['amountMinor'] as int
          ..assigneeMemberIds.addAll((i['assigneeMemberIds'] as List).cast<String>())),
    ]);
    final service = charges?['service'] as Map<String, dynamic>?;
    if (service != null) b.service = ServiceInput((s) => s..bps = service['bps'] as int).toBuilder();
    final tax = charges?['tax'] as Map<String, dynamic>?;
    if (tax != null) {
      b.tax = TaxInput((t) => t
        ..bps = tax['bps'] as int
        ..base_ = tax['base'] as String).toBuilder();
    }
    final adjustment = (charges?['adjustmentMinor'] as int?) ?? 0;
    if (adjustment != 0) b.adjustmentMinor = adjustment;
    b.payers.addAll([
      for (final p in (e['payers'] as List).cast<Map<String, dynamic>>())
        PayerInput((x) => x
          ..memberId = p['memberId'] as String
          ..amountMinor = p['amountMinor'] as int),
    ]);
  });
}

Date _dateOf(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return Date(p[0], p[1], p[2]);
}

void main() {
  group('the bill becomes the exact request (golden JSON for the spec vectors)', () {
    for (final name in ['v5', 'v6', 'v7', 'v8']) {
      test('$name: the editor state builds exactly the expected body, with no total', () {
        final vector = _vectors[name]!;
        final command = buildExpenseCommand(vector.form, edit: false, memberIds: _members)!;
        expect(_wire(command), _golden('itemized_$name'));
        expect(_wire(command).containsKey('totalMinor'), isFalse, reason: 'the server computes the total of a restaurant bill');
        expect(_wire(buildExpenseCommand(vector.form, edit: true, memberIds: _members)!), _golden('itemized_$name'), reason: 'an edit sends the same body');
      });
    }

    test('a switch that is off removes the field (never 0 bps), whatever is left in its box', () {
      final form = _bill(service: false, servicePercent: '12', tax: false, taxPercent: '14', serverTotal: 44000);
      final body = _wire(buildExpenseCommand(form, edit: false, memberIds: _members)!);
      expect(body.containsKey('service'), isFalse);
      expect(body.containsKey('tax'), isFalse);
      expect(body.containsKey('adjustmentMinor'), isFalse);
    });

    test('service and tax are independent: each alone works', () {
      final serviceOnly = _wire(buildExpenseCommand(_bill(service: true, servicePercent: '12', serverTotal: 1), edit: false, memberIds: _members)!);
      expect(serviceOnly['service'], {'bps': 1200});
      expect(serviceOnly.containsKey('tax'), isFalse);
      final taxOnly = _wire(buildExpenseCommand(_bill(tax: true, taxPercent: '14', serverTotal: 1), edit: false, memberIds: _members)!);
      expect(taxOnly['tax'], {'bps': 1400, 'base': 'SUBTOTAL_PLUS_SERVICE'});
      expect(taxOnly.containsKey('service'), isFalse);
    });

    test('a charge switched on at 0% is sent as bps 0 ("enabled with 0"), not left out', () {
      final body = _wire(buildExpenseCommand(_bill(service: true, servicePercent: '0', tax: true, taxPercent: '0', serverTotal: 1), edit: false, memberIds: _members)!);
      expect(body['service'], {'bps': 0});
      expect((body['tax'] as Map)['bps'], 0);
    });

    test('the adjustment is sent only when it is not zero, with its sign', () {
      Map<String, dynamic> body(String text) => _wire(buildExpenseCommand(_bill(adjustment: text, serverTotal: 1), edit: false, memberIds: _members)!);
      expect(body('').containsKey('adjustmentMinor'), isFalse);
      expect(body('0').containsKey('adjustmentMinor'), isFalse);
      expect(body('0.05')['adjustmentMinor'], 5);
      expect(body('-5')['adjustmentMinor'], -500);
    });

    test('without the server\'s total there is nothing to save, but the question for the preview can be asked', () {
      final form = _bill(service: true, servicePercent: '12'); // no serverTotal yet
      expect(buildExpenseCommand(form, edit: false, memberIds: _members), isNull);
      expect(form.canSave(_members), isFalse);

      final question = buildItemizedPreview(form, memberIds: _members)!;
      final wire = _wire(question);
      expect(wire['title'], kPreviewTitle, reason: 'the preview does not depend on the title');
      expect(wire.containsKey('payers'), isFalse);
      expect(wire.containsKey('totalMinor'), isFalse);
      expect(wire['service'], {'bps': 1200});
    });

    test('the preview question ignores the title and the payers, so typing a name never re-asks the server', () {
      final a = commandKey(buildItemizedPreview(_bill(title: 'A', serverTotal: 44000), memberIds: _members)!);
      final b = commandKey(buildItemizedPreview(_bill(title: 'Another', serverTotal: 44000), memberIds: _members)!);
      expect(a, b);
      final withPayers = buildItemizedPreview(_bill(serverTotal: 44000), memberIds: _members, withPayers: true)!;
      expect(withPayers.payers!.map((p) => (p.memberId, p.amountMinor)).toList(), [(kYou, 44000)]);
    });

    test('assignees who are no longer members are dropped, and an item left with nobody blocks the bill', () {
      final gone = _bill(items: [const ItemDraft(id: 'x', name: 'Tea', amountText: '10', assigneeIds: {kYou, 'ghost'})], serverTotal: 1000);
      final body = _wire(buildExpenseCommand(gone, edit: false, memberIds: _members)!);
      expect(((body['items'] as List).single as Map)['assigneeMemberIds'], [kYou]);

      final nobody = _bill(items: [const ItemDraft(id: 'x', name: 'Tea', amountText: '10', assigneeIds: {'ghost'})], serverTotal: 1000);
      expect(buildExpenseCommand(nobody, edit: false, memberIds: _members), isNull);
    });
  });

  group('percentages are parsed as text (no floating point)', () {
    int? bps(String text) => ItemizedDraft(serviceOn: true, servicePercentText: text).serviceBps;

    test('"12", "12.5", "100", "0" and Arabic digits are read; the cap and bad text are not', () {
      expect(bps('12'), 1200);
      expect(bps('12.5'), 1250);
      expect(bps('12.05'), 1205);
      expect(bps('100'), 10000);
      expect(bps('0'), 0);
      expect(bps('١٢'), 1200);
      expect(bps('100.01'), isNull);
      expect(bps('101'), isNull);
      expect(bps('-1'), isNull);
      expect(bps('12.345'), isNull);
      expect(bps(''), isNull);
      expect(bps('abc'), isNull);
    });

    test('a switch that is off has no rate, and is valid whatever its box says', () {
      const off = ItemizedDraft(serviceOn: false, servicePercentText: 'abc');
      expect(off.serviceBps, isNull);
      expect(off.serviceValid, isTrue);
      expect(const ItemizedDraft(serviceOn: true, servicePercentText: 'abc').serviceValid, isFalse);
    });

    test('a saved rate is shown back as a percentage: 1200 -> "12", 1250 -> "12.5"', () {
      expect(Bps.format(1200), '12');
      expect(Bps.format(1250), '12.5');
      expect(Bps.format(1400), '14');
    });
  });

  group('items: validation', () {
    bool valid(List<ItemDraft> items) => ItemizedDraft(items: items).itemsValid(_members);
    ItemDraft item({String name = 'Tea', String amount = '10', Set<String> who = const {kYou}}) => ItemDraft(id: 'i', name: name, amountText: amount, assigneeIds: who);

    test('a valid item', () => expect(valid([item()]), isTrue));

    test('each way an item can be wrong', () {
      expect(valid([item(name: '')]), isFalse);
      expect(valid([item(name: '   ')]), isFalse);
      expect(valid([item(name: 'x' * 101)]), isFalse);
      expect(valid([item(name: 'x' * 100)]), isTrue);
      expect(valid([item(amount: '')]), isFalse);
      expect(valid([item(amount: '0')]), isFalse);
      expect(valid([item(amount: 'abc')]), isFalse);
      expect(valid([item(amount: '10000000000.01')]), isFalse);
      expect(valid([item(who: const {})]), isFalse);
      expect(valid([item(who: const {'ghost'})]), isFalse, reason: 'not a member');
    });

    test('1 to 100 items; none or 101 is not a bill', () {
      expect(valid(const []), isFalse);
      expect(valid([for (var i = 0; i < 100; i++) item()]), isTrue);
      expect(valid([for (var i = 0; i < 101; i++) item()]), isFalse);
    });

    test('item names are counted in code points', () {
      expect(valid([item(name: '\u{1F355}' * 100)]), isTrue);
      expect(valid([item(name: '\u{1F355}' * 101)]), isFalse);
    });

    test('adjustment: empty is none; signed amounts are read; text is not', () {
      expect(const ItemizedDraft().adjustmentMinor, 0);
      expect(const ItemizedDraft(adjustmentText: '0.05').adjustmentMinor, 5);
      expect(const ItemizedDraft(adjustmentText: '-5').adjustmentMinor, -500);
      expect(const ItemizedDraft(adjustmentText: 'abc').adjustmentValid, isFalse);
      expect(const ItemizedDraft(adjustmentText: '10000000000.01').adjustmentValid, isFalse);
    });
  });

  group('the total of a bill is the server\'s', () {
    test('totalMinor of a restaurant bill is the server\'s copy; the typed amount is ignored', () {
      final form = _bill(serverTotal: 56179).copyWith(amountText: '999');
      expect(form.totalMinor, 56179);
      expect(_bill().totalMinor, isNull);
    });

    test('a single payer pays the server\'s total (a copy); several payers are compared with it', () {
      expect(_bill(serverTotal: 56179).payerMinors(), {kYou: 56179});
      final several = _bill(serverTotal: 56179, payerMode: PayerMode.multiple, payerTexts: {kYou: '300', kAsem: '261.79'});
      expect(several.payerRemaining(), 0);
      expect(several.payersValid, isTrue);
      expect(several.copyWith(payerTexts: {kYou: '300', kAsem: '200'}).payersValid, isFalse);
    });

    test('save needs a title, a valid bill, valid payers AND the server\'s total', () {
      expect(_vectors['v5']!.form.canSave(_members), isTrue);
      expect(_vectors['v5']!.form.copyWith(clearServerTotal: true).canSave(_members), isFalse);
      expect(_vectors['v5']!.form.copyWith(title: '').canSave(_members), isFalse);
      expect(_vectors['v5']!.form.copyWith(itemized: _vectors['v5']!.form.itemized.copyWith(servicePercentText: 'x')).canSave(_members), isFalse);
    });
  });

  group('opening a saved restaurant bill (edit round trip)', () {
    for (final entry in {
      'expense_itemized_v5': 56179,
      'expense_itemized_v6_service_only': 49280,
      'expense_itemized_v7_tax_only': 50160,
      'expense_itemized_v8_neither': 44000,
    }.entries) {
      test('${entry.key}: GET -> form -> PUT body is the saved expense as a request, with its total known', () {
        final json = fixtureMap(entry.key);
        final form = formFromExpense(expenseFrom(json), memberIds: _members, fallbackPayerId: kYou);
        expect(form.splitMode, SplitMode.itemized);
        expect(form.serverTotalMinor, entry.value);
        expect(form.canSave(_members), isTrue);
        final rebuilt = buildExpenseCommand(form, edit: true, memberIds: _members)!;
        expect(commandKey(rebuilt), commandKey(_commandOf(json)));
      });
    }

    test('V5 is shown the way it was entered: 12 and 14 percent, the base, the amounts as text', () {
      final form = formFromExpense(expenseFixture('expense_itemized_v5'), memberIds: _members, fallbackPayerId: kYou);
      final d = form.itemized;
      expect((d.serviceOn, d.servicePercentText, d.taxOn, d.taxPercentText, d.taxBase), (true, '12', true, '14', TaxBase.subtotalPlusService));
      expect(d.items.map((i) => (i.name, i.amountText)).toList(), [('Pizza', '200'), ('Pasta', '150'), ('Drinks', '90')]);
      expect(d.adjustmentText, '');
      expect(form.payerMode, PayerMode.multiple, reason: 'two payers: 300.00 and 261.79');
      expect(form.payerTexts, {kYou: '300', kAsem: '261.79'});
    });

    test('V6 and V7 open with only their own charge on; V8 with neither', () {
      ItemizedDraft draft(String f) => formFromExpense(expenseFixture(f), memberIds: _members, fallbackPayerId: kYou).itemized;
      expect((draft('expense_itemized_v6_service_only').serviceOn, draft('expense_itemized_v6_service_only').taxOn), (true, false));
      expect((draft('expense_itemized_v7_tax_only').serviceOn, draft('expense_itemized_v7_tax_only').taxOn, draft('expense_itemized_v7_tax_only').taxBase), (false, true, TaxBase.subtotal));
      expect((draft('expense_itemized_v8_neither').serviceOn, draft('expense_itemized_v8_neither').taxOn), (false, false));
    });

    test('a saved non-zero adjustment comes back as signed text', () {
      final json = copyJson(fixtureMap('expense_itemized_v8_neither'));
      (json['charges'] as Map)['adjustmentMinor'] = -500;
      final form = formFromExpense(expenseFrom(json), memberIds: _members, fallbackPayerId: kYou);
      expect(form.itemized.adjustmentText, '-5');
      expect(_wire(buildExpenseCommand(form, edit: true, memberIds: _members)!)['adjustmentMinor'], -500);
    });

    test('a change to the saved bill changes exactly that part of the request', () {
      final form = formFromExpense(expenseFixture('expense_itemized_v5'), memberIds: _members, fallbackPayerId: kYou);
      final renamed = form.copyWith(itemized: form.itemized.copyWith(items: [form.itemized.items.first.copyWith(name: 'Large pizza'), ...form.itemized.items.skip(1)]));
      final body = _wire(buildExpenseCommand(renamed, edit: true, memberIds: _members)!);
      final original = _wire(_commandOf(fixtureMap('expense_itemized_v5')));
      expect(((body['items'] as List).first as Map)['name'], 'Large pizza');
      expect(body['tax'], original['tax']);
      expect(body['service'], original['service']);

      final switched = form.copyWith(itemized: form.itemized.copyWith(taxBase: TaxBase.subtotal));
      expect((_wire(buildExpenseCommand(switched, edit: true, memberIds: _members)!)['tax'] as Map)['base'], 'SUBTOTAL');
    });
  });

  group('the fake server\'s engine reproduces the REAL backend\'s numbers (so the widget tests are realistic)', () {
    for (final name in ['v5', 'v6', 'v7', 'v8']) {
      test('$name: the numbers equal the captured server response', () async {
        final server = FakeExpensesServer();
        final container = await formContainer(server);
        addTearDown(container.dispose);
        final command = buildItemizedPreview(_vectors[name]!.form, memberIds: _members)!;
        final preview = await container.read(expensesRepositoryProvider).preview(server.gid, command).result;

        final real = fixtureMap('preview_$name');
        final captured = standardSerializers.deserializeWith(ExpensePreview.serializer, real)!;
        expect(preview.totalMinor, captured.totalMinor);
        expect((preview.subtotalMinor, preview.serviceMinor, preview.taxMinor, preview.adjustmentMinor), (captured.subtotalMinor, captured.serviceMinor, captured.taxMinor, captured.adjustmentMinor));
        List<(String, int, int?, int?, int?, int?)> shares(ExpensePreview p) =>
            [for (final m in p.members) (m.memberId, m.owedMinor, m.itemsMinor, m.serviceMinor, m.taxMinor, m.adjustmentMinor)];
        expect(shares(preview), shares(captured));
      });
    }

    test('the spec totals: 561.79, 492.80, 501.60, 440.00', () {
      final captured = {for (final n in ['v5', 'v6', 'v7', 'v8']) n: standardSerializers.deserializeWith(ExpensePreview.serializer, fixtureMap('preview_$n'))!.totalMinor};
      expect(captured, {'v5': 56179, 'v6': 49280, 'v7': 50160, 'v8': 44000});
      expect(Money.formatPlain(captured['v5']!), '561.79');
    });
  });

  group('the form controller drives a bill', () {
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

    /// Types the spec's bill (V5 inputs) through the controller, one action at a time.
    Future<void> typeSpecBill({bool service = true, bool tax = true, TaxBase base = TaxBase.subtotalPlusService}) async {
      form.startCreate();
      form.setTitle('Sea Food');
      form.setSplitMode(SplitMode.itemized);
      form.setItemName(data().itemized.items.single.id, 'Pizza');
      form.setItemAmount(data().itemized.items.single.id, '200');
      form.toggleAssignee(data().itemized.items.single.id, kMohsen);
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
      if (service) {
        form.setServiceOn(true);
        form.setServicePercent('12');
      }
      if (tax) {
        form.setTaxOn(true);
        form.setTaxPercent('14');
        form.setTaxBase(base);
      }
    }

    test('switching service or tax on offers 12 and 14, keeps what the user typed, and stays editable', () {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      expect((data().itemized.servicePercentText, data().itemized.taxPercentText), ('', ''));
      form.setServiceOn(true);
      form.setTaxOn(true);
      expect((data().itemized.servicePercentText, data().itemized.taxPercentText), ('12', '14'));
      form.setServicePercent('10');
      form.setServiceOn(false);
      form.setServiceOn(true);
      expect(data().itemized.servicePercentText, '10', reason: 'a typed rate is never overwritten');
      form.setTaxPercent('');
      form.setTaxOn(false);
      form.setTaxOn(true);
      expect(data().itemized.taxPercentText, '14', reason: 'an emptied field gets the offer again');
    });

    test('entering the mode adds one empty item with everyone as assignee, and asks the server nothing yet', () async {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      expect(data().itemized.items, hasLength(1));
      expect(data().itemized.items.single.assigneeIds, {kYou, kAsem, kMohsen});
      expect(data().totalMinor, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(server.previewBodies, isEmpty, reason: 'an empty bill is not a question');
    });

    test('a complete bill is previewed, and the server\'s total is copied in: 561.79', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 56179);
      expect(data().canSave(form.memberIds), isTrue);
      expect(server.previewBodies.last['splitType'], 'ITEMIZED');
      expect(server.previewBodies.last.containsKey('totalMinor'), isFalse);
    });

    test('ANY change to the bill forgets the total at once and the new total arrives with its preview', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);

      form.setTaxBase(TaxBase.subtotal);
      expect(data().serverTotalMinor, isNull, reason: 'the old total belongs to the old bill');
      expect(data().canSave(form.memberIds), isFalse);
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 55440, reason: '440.00 + 52.80 service + 61.60 tax on the subtotal');

      form.setServiceOn(false);
      expect(data().serverTotalMinor, isNull);
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 50160, reason: 'V7: tax only, on the subtotal');
    });

    test('typing the title does not make the server recalculate the bill, and does not forget its total', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final asked = server.previewBodies.length;
      form.setTitle('Sea Food and tea');
      expect(data().serverTotalMinor, 56179, reason: 'the title is not part of the question');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(server.previewBodies.length, asked);
    });

    test('an incomplete bill forgets the total and cannot be saved', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);
      form.setItemAmount(data().itemized.items.first.id, '');
      expect(data().serverTotalMinor, isNull);
      expect(data().canSave(form.memberIds), isFalse);
    });

    test('a failed preview leaves no total: nothing can be saved until it works', () async {
      server.failNextPreview = true;
      await typeSpecBill();
      await waitUntil(() => container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.split))).status == PreviewStatus.failed);
      expect(data().serverTotalMinor, isNull);
      expect(await form.save(), SaveOutcome.invalid);
      expect(server.creates, isEmpty);

      container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.split)).notifier).retry();
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 56179);
    });

    test('a slow reply for an older bill never becomes the total of the new one', () async {
      await typeSpecBill(service: false, tax: false);
      await waitUntil(() => data().serverTotalMinor == 44000);
      final gate = Completer<void>();
      server.previewGates.add(gate);
      form.setServiceOn(true);
      form.setServicePercent('12'); // asked, held
      await Future<void>.delayed(const Duration(milliseconds: 40));
      form.setServicePercent('10'); // a newer question
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 48400, reason: '440.00 + 10% service');
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(data().serverTotalMinor, 48400, reason: 'the late answer for 12% was ignored');
    });

    test('the payers match question is asked with the payers once the total is known', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);
      await waitUntil(() => server.previewBodies.any((b) => b['payers'] != null));
      final withPayers = server.previewBodies.lastWhere((b) => b['payers'] != null);
      expect((withPayers['payers'] as List).single, {'memberId': kYou, 'amountMinor': 56179});
      final match = container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.match)));
      await waitUntil(() => container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.match))).status == PreviewStatus.ready);
      expect(match.status, anyOf(PreviewStatus.loading, PreviewStatus.ready));
      expect(container.read(expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.match))).preview!.payersTotalMatches, isTrue);
    });

    test('create: the body is the V5 golden (the title aside) and the server stores 561.79 with its parts', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);
      expect(await form.save(), SaveOutcome.saved);
      final body = Map<String, dynamic>.of(server.creates.single.body)..['title'] = 'Sea Food';
      expect(body, _golden('itemized_v5'));
      final stored = server.expenses.single;
      expect(stored['totalMinor'], 56179);
      expect((stored['shares'] as List).map((s) => s['owedMinor']).toList(), [16599, 16598, 22982]);
      expect((stored['charges'] as Map)['subtotalMinor'], 44000);
    });

    test('create keeps the idempotency rules: a lost reply is retried with the same key, an edit gets a new one', () async {
      await typeSpecBill();
      await waitUntil(() => data().serverTotalMinor == 56179);
      server.loseNextCreateResponse = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(await form.save(), SaveOutcome.saved);
      expect(server.creates.map((c) => c.key).toSet(), hasLength(1));
      expect(server.expenses, hasLength(1));

      form.setItemName(data().itemized.items.first.id, 'Large pizza');
      await waitUntil(() => data().serverTotalMinor != null);
      expect(await form.save(), SaveOutcome.saved);
      expect(server.creates.map((c) => c.key).toSet(), hasLength(2));
    });

    test('the server\'s refusal of a negative total is a form-level VALIDATION_ERROR', () async {
      await typeSpecBill(service: false, tax: false);
      await waitUntil(() => data().serverTotalMinor == 44000);
      form.setAdjustment('-500'); // more than the whole bill
      final failure = await _previewFailure(container, server);
      expect(failure.problem!.code, ApiErrorCode.validationError);
      expect(data().serverTotalMinor, isNull);
    });

    test('the adjustment steppers move by one piaster and show zero as an empty box', () async {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      form.stepAdjustment(1);
      expect(data().itemized.adjustmentText, '0.01');
      form.stepAdjustment(1);
      expect(data().itemized.adjustmentText, '0.02');
      form.setAdjustment('0.05');
      form.stepAdjustment(1);
      expect(data().itemized.adjustmentText, '0.06');
      form.setAdjustment('0');
      form.stepAdjustment(-1);
      expect(data().itemized.adjustmentText, '-0.01');
      form.stepAdjustment(1);
      expect(data().itemized.adjustmentText, '');
      form.setAdjustment('abc');
      form.stepAdjustment(1);
      expect(data().itemized.adjustmentText, 'abc', reason: 'unreadable text: nothing to step from');
    });

    test('items: add up to 100, remove, and the order is kept', () async {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      for (var i = 0; i < 120; i++) {
        form.addItem();
      }
      expect(data().itemized.items, hasLength(kMaxItems));
      final second = data().itemized.items[1].id;
      form.removeItem(second);
      expect(data().itemized.items, hasLength(99));
      expect(data().itemized.items.any((i) => i.id == second), isFalse);
    });

    test('an item edited by the user counts as touched (its errors may be shown)', () {
      form.startCreate();
      form.setSplitMode(SplitMode.itemized);
      expect(data().itemized.items.single.touched, isFalse);
      form.setItemName(data().itemized.items.single.id, 'x');
      expect(data().itemized.items.single.touched, isTrue);
    });
  });

  group('editing a saved bill', () {
    const v5 = '7e3b3a23-d844-4889-99ae-5cba254d1173';
    late FakeExpensesServer server;
    late ProviderContainer container;
    late ExpenseFormController form;

    setUp(() async {
      server = FakeExpensesServer();
      seedAllFixtures(server);
      container = await formContainer(server);
      addTearDown(container.dispose);
      form = formController(container, server, eid: v5);
    });

    ExpenseFormState data() => formView(container, server, eid: v5).form!;

    test('opens as a bill with its total known, and saving it unchanged sends the same request with If-Match "1"', () async {
      await form.startEdit();
      expect(formView(container, server, eid: v5).phase, FormPhase.ready);
      expect(data().splitMode, SplitMode.itemized);
      expect(data().serverTotalMinor, 56179);
      expect(form.dirty, isFalse);
      expect(await form.save(), SaveOutcome.saved);
      expect(server.requests.where((r) => r.startsWith('PUT')).single, endsWith('if-match="1"'));
      final sent = server.updates.single;
      expect(sent.containsKey('totalMinor'), isFalse);
      expect((sent['items'] as List), hasLength(3));
      expect(server.expenses.firstWhere((e) => e['id'] == v5)['totalMinor'], 56179);
    });

    test('renaming an item keeps the total (no new question needed for the payers) and saves the new name', () async {
      await form.startEdit();
      form.setItemName(data().itemized.items.first.id, 'Large pizza');
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 56179);
      expect(await form.save(), SaveOutcome.saved);
      expect(((server.updates.single['items'] as List).first as Map)['name'], 'Large pizza');
    });

    test('switching the tax base changes the total, so the two saved payers no longer cover it: save waits', () async {
      await form.startEdit();
      form.setTaxBase(TaxBase.subtotal);
      await waitUntil(() => data().serverTotalMinor != null);
      expect(data().serverTotalMinor, 55440);
      expect(data().payerMode, PayerMode.multiple);
      expect(data().payersValid, isFalse, reason: '300.00 + 261.79 is not 554.40');
      expect(data().canSave(form.memberIds), isFalse);
      expect(await form.save(), SaveOutcome.invalid);
    });

    test('a conflict keeps the user\'s input and a later save carries the new version', () async {
      await form.startEdit();
      form.setItemName(data().itemized.items.first.id, 'Mine');
      await waitUntil(() => data().serverTotalMinor != null);
      server.bumpVersion(v5);
      expect(await form.save(), SaveOutcome.failed);
      expect((formView(container, server, eid: v5).failure! as ApiHttpFailure).problem!.code, ApiErrorCode.versionConflict);
      expect(await form.reloadLatest(), ReloadOutcome.reloaded);
      expect(data().itemized.items.first.name, 'Mine');
      expect(await form.save(), SaveOutcome.saved);
      expect(server.requests.where((r) => r.startsWith('PUT')).last, endsWith('if-match="2"'));
    });

    test('a lost reply to the edit is recognised as our own save on the next conflict', () async {
      await form.startEdit();
      form.setItemName(data().itemized.items.first.id, 'Mine');
      await waitUntil(() => data().serverTotalMinor != null);
      server.loseNextUpdateResponse = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(await form.save(), SaveOutcome.failed, reason: 'the old version now conflicts');
      expect(await form.reloadLatest(), ReloadOutcome.alreadyApplied);
      expect(formView(container, server, eid: v5).savedId, v5);
    });
  });
}

/// Waits for the split preview to fail and returns why.
Future<ApiHttpFailure> _previewFailure(ProviderContainer container, FakeExpensesServer server) async {
  final provider = expensePreviewControllerProvider((gid: server.gid, slot: PreviewSlot.split));
  await waitUntil(() => container.read(provider).status == PreviewStatus.failed);
  return container.read(provider).failure! as ApiHttpFailure;
}
