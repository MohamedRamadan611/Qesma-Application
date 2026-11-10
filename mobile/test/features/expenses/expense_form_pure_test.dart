import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/fake_expenses_server.dart';

const List<String> _members = [kYou, kAsem, kMohsen];

Map<String, dynamic> _golden(String name) => (jsonDecode(File('test/fixtures/expense_commands/$name.json').readAsStringSync()) as Map).cast<String, dynamic>();

/// What goes over the wire, as plain JSON.
Map<String, dynamic> _wire(ExpenseCommand command) => (jsonDecode(jsonEncode(commandJson(command))) as Map).cast<String, dynamic>();

ExpenseFormState _form({
  String title = 'Petrol',
  String amount = '520',
  Date? date,
  SplitMode mode = SplitMode.all,
  Set<String> selected = const {},
  Map<String, String> exact = const {},
  PayerMode payerMode = PayerMode.single,
  String? payer = kYou,
  Map<String, String> payerTexts = const {},
}) =>
    ExpenseFormState(
      title: title,
      amountText: amount,
      date: date ?? Date(2026, 10, 18),
      splitMode: mode,
      selectedIds: selected,
      exactTexts: exact,
      payerMode: payerMode,
      singlePayerId: payer,
      payerTexts: payerTexts,
    );

void main() {
  group('the form becomes the exact JSON the backend takes (golden files)', () {
    test('EQUAL all, create: participantMemberIds is omitted (the server resolves the current members)', () {
      final command = buildExpenseCommand(_form(), edit: false, memberIds: _members)!;
      expect(_wire(command), _golden('equal_all_create'));
      expect(_wire(command).containsKey('participantMemberIds'), isFalse);
    });

    test('EQUAL all, edit: the explicit list of ALL current members (spec 7.9)', () {
      final command = buildExpenseCommand(_form(), edit: true, memberIds: _members)!;
      expect(_wire(command), _golden('equal_all_edit'));
    });

    test('EQUAL selected: exactly the selected members, in the group\'s order, on create too', () {
      final form = _form(mode: SplitMode.selected, selected: {kMohsen, kYou});
      expect(_wire(buildExpenseCommand(form, edit: false, memberIds: _members)!), _golden('equal_selected'));
      expect(_wire(buildExpenseCommand(form, edit: true, memberIds: _members)!), _golden('equal_selected'));
    });

    test('EXACT: shares are what the user typed; payer is a different member', () {
      final form = _form(
        title: 'Tickets',
        amount: '300',
        date: Date(2026, 10, 17),
        mode: SplitMode.exact,
        selected: {kYou, kAsem, kMohsen},
        exact: {kYou: '100', kAsem: '150', kMohsen: '50'},
        payer: kAsem,
      );
      expect(_wire(buildExpenseCommand(form, edit: false, memberIds: _members)!), _golden('exact'));
    });

    test('several payers: the typed amounts', () {
      final form = _form(title: 'Dinner', amount: '500', payerMode: PayerMode.multiple, payerTexts: {kYou: '300', kAsem: '200'});
      expect(_wire(buildExpenseCommand(form, edit: false, memberIds: _members)!), _golden('multi_payer'));
    });

    test('the restaurant bill (FL6) builds nothing here', () {
      expect(buildExpenseCommand(_form(mode: SplitMode.itemized), edit: false, memberIds: _members), isNull);
    });

    test('an incomplete or invalid form builds nothing', () {
      for (final form in [
        _form(title: ''),
        _form(title: '   '),
        _form(title: 'x' * 101),
        _form(amount: ''),
        _form(amount: '0'),
        _form(amount: 'abc'),
        _form(date: Date(1999, 12, 31)),
        _form(date: Date(2101, 1, 1)),
        _form(mode: SplitMode.selected),
        _form(payer: null),
        _form(payerMode: PayerMode.multiple, payerTexts: {kYou: '300'}), // 300 of 520
        _form(mode: SplitMode.exact, selected: {kYou, kAsem}, exact: {kYou: '100', kAsem: '100'}), // 200 of 520
      ]) {
        expect(buildExpenseCommand(form, edit: false, memberIds: _members), isNull);
      }
    });

    test('the title is trimmed and counted in code points', () {
      final form = _form(title: '  ${'\u{1F600}' * 100}  ');
      final command = buildExpenseCommand(form, edit: false, memberIds: _members)!;
      expect(command.title.runes.length, 100);
      expect(buildExpenseCommand(_form(title: '\u{1F600}' * 101), edit: false, memberIds: _members), isNull);
    });
  });

  group('previews', () {
    test('an EQUAL preview among given participants carries no payers and a placeholder title while the title is empty', () {
      final command = buildEqualPreview(title: '', date: Date(2026, 10, 18), totalMinor: 52000, participantIds: [kYou, kAsem]);
      expect(command.title, kPreviewTitle);
      expect(command.payers, isNull);
      expect(command.splitType, 'EQUAL');
      expect(command.participantMemberIds!.toList(), [kYou, kAsem]);
      expect(buildEqualPreview(title: ' Dinner ', date: Date(2026, 10, 18), totalMinor: 1, participantIds: [kYou]).title, 'Dinner');
    });

    test('the payers check is an EQUAL command with the payers being edited', () {
      final command = buildPayersCheck(title: 'x', date: Date(2026, 10, 18), totalMinor: 50000, memberIds: _members, payers: {kYou: 30000, kAsem: 20000});
      expect(command.payers!.map((p) => (p.memberId, p.amountMinor)).toList(), [(kYou, 30000), (kAsem, 20000)]);
      expect(command.participantMemberIds!.toList(), _members);
    });

    test('commandKey ignores the order of members, payers and shares, and changes when anything real changes', () {
      ExpenseCommand make(List<String> ids, List<(String, int)> payers) => ExpenseCommand((b) => b
        ..title = 'A'
        ..expenseDate = Date(2026, 10, 18)
        ..splitType = 'EQUAL'
        ..totalMinor = 100
        ..participantMemberIds.addAll(ids)
        ..payers.addAll([for (final p in payers) PayerInput((x) => x..memberId = p.$1..amountMinor = p.$2)]));
      final a = make([kYou, kAsem], [(kYou, 60), (kAsem, 40)]);
      final b = make([kAsem, kYou], [(kAsem, 40), (kYou, 60)]);
      final c = make([kYou, kAsem], [(kYou, 50), (kAsem, 50)]);
      expect(commandKey(a), commandKey(b));
      expect(commandKey(a), isNot(commandKey(c)));
    });
  });

  group('the typed numbers: only adding up what the user typed', () {
    test('the total parses like money: 0.5, 1,000.50, Arabic digits; rejects 0, 1,00, the cap, text', () {
      int? total(String text) => _form(amount: text).totalMinor;
      expect(total('0'), isNull);
      expect(total('0.5'), 50);
      expect(total('1,000.50'), 100050);
      expect(total('1,00'), isNull);
      expect(total('٥٠٠'), 50000);
      expect(total('٥٠٠٫٥٠'), 50050);
      expect(total('10000000000'), 1000000000000, reason: '10^10 EGP = 10^12 piasters is the cap');
      expect(total('10000000000.01'), isNull);
      expect(total('12a'), isNull);
      expect(total(''), isNull);
    });

    test('Exact: remaining is the total minus the typed amounts, and it is valid only at zero with a positive amount', () {
      final form = _form(mode: SplitMode.exact, selected: {kYou, kAsem, kMohsen}, exact: {kYou: '200', kAsem: '200', kMohsen: ''});
      expect(form.exactSum(_members), 40000);
      expect(form.exactRemaining(_members), 12000);
      expect(form.exactValid(_members), isFalse, reason: 'an empty box is not an amount');

      final done = form.copyWith(exactTexts: {kYou: '200', kAsem: '200', kMohsen: '120'});
      expect(done.exactRemaining(_members), 0);
      expect(done.exactValid(_members), isTrue);

      final over = form.copyWith(exactTexts: {kYou: '300', kAsem: '300', kMohsen: '0'});
      expect(over.exactRemaining(_members), -8000);
      expect(over.exactValid(_members), isFalse);

      final zeros = _form(amount: '0.01', mode: SplitMode.exact, selected: {kYou}, exact: {kYou: '0'});
      expect(zeros.exactValid(_members), isFalse, reason: 'at least one amount must be above zero');
      expect(_form(mode: SplitMode.exact, selected: {kYou}, exact: {kYou: '520'}).exactValid(_members), isTrue);
    });

    test('Exact: an unchecked member does not count and has no share', () {
      final form = _form(mode: SplitMode.exact, selected: {kYou, kAsem}, exact: {kYou: '300', kAsem: '220', kMohsen: '999'});
      expect(form.exactSum(_members), 52000);
      expect(form.participantIds(_members), [kYou, kAsem]);
    });

    test('payers: single pays the total; several must add up to it', () {
      expect(_form().payerMinors(), {kYou: 52000});
      expect(_form().payersValid, isTrue);
      final several = _form(payerMode: PayerMode.multiple, payerTexts: {kYou: '300', kAsem: '100'});
      expect(several.payerSum(), 40000);
      expect(several.payerRemaining(), 12000);
      expect(several.payersValid, isFalse);
      expect(several.copyWith(payerTexts: {kYou: '300', kAsem: '220'}).payersValid, isTrue);
      expect(several.copyWith(payerTexts: {kYou: '300', kAsem: '0'}).payersValid, isFalse, reason: 'a payer with 0 is not a payer');
      expect(_form(payerMode: PayerMode.multiple).payersValid, isFalse);
    });

    test('canSave needs a valid title, total, date, payers and split', () {
      expect(_form().canSave(_members), isTrue);
      expect(_form(title: '').canSave(_members), isFalse);
      expect(_form(amount: 'x').canSave(_members), isFalse);
      expect(_form(mode: SplitMode.selected).canSave(_members), isFalse);
      expect(_form(mode: SplitMode.selected, selected: {kAsem}).canSave(_members), isTrue);
      expect(_form(mode: SplitMode.itemized).canSave(_members), isFalse);
    });

    test('differsFrom spots any change (used to ask before discarding)', () {
      final base = _form();
      expect(base.differsFrom(_form()), isFalse);
      expect(base.differsFrom(base.copyWith(title: 'Other')), isTrue);
      expect(base.differsFrom(base.copyWith(selectedIds: {kYou})), isTrue);
      expect(base.differsFrom(base.copyWith(payerTexts: {kYou: '1'})), isTrue);
    });
  });

  group('opening an expense for edit', () {
    ExpenseFormState fill(String fixture, {List<String> members = _members}) => formFromExpense(expenseFixture(fixture), memberIds: members, fallbackPayerId: kYou);

    test('EQUAL for everyone: mode All, one payer, the saved numbers', () {
      final form = fill('expense_equal_v2');
      expect(form.splitMode, SplitMode.all);
      expect(form.title, 'Petrol (edited)');
      expect(form.amountText, '520');
      expect(form.payerMode, PayerMode.single);
      expect(form.singlePayerId, kYou);
      expect(form.date, Date(2026, 10, 18));
    });

    test('a member who joined after the expense stays unchecked (never added silently)', () {
      final form = fill('expense_equal_v2', members: [..._members, 'newcomer']);
      expect(form.splitMode, SplitMode.selected);
      expect(form.selectedIds, {kYou, kAsem, kMohsen});
      final command = buildExpenseCommand(form, edit: true, memberIds: [..._members, 'newcomer'])!;
      expect(command.participantMemberIds!.toList(), _members);
    });

    test('EQUAL for some: mode Selected with exactly those', () {
      final json = copyJson(fixtureMap('expense_equal_v2'));
      (json['shares'] as List).removeWhere((s) => s['memberId'] == kMohsen);
      final form = formFromExpense(expenseFrom(json), memberIds: _members, fallbackPayerId: kYou);
      expect(form.splitMode, SplitMode.selected);
      expect(form.selectedIds, {kYou, kAsem});
    });

    test('EXACT with two payers: Exact mode with the saved amounts and several payers', () {
      final form = fill('expense_exact');
      expect(form.splitMode, SplitMode.exact);
      expect(form.exactTexts, {kYou: '100', kAsem: '150', kMohsen: '50'});
      expect(form.payerMode, PayerMode.multiple);
      expect(form.payerTexts, {kYou: '100', kAsem: '200'});
      expect(form.canSave(_members), isTrue);
    });

    test('an itemized bill opens as a restaurant bill', () {
      expect(fill('expense_itemized_v5').splitMode, SplitMode.itemized);
    });

    test('the filled form rebuilds the same command the expense would be saved as', () {
      final form = fill('expense_equal_v2');
      expect(_wire(buildExpenseCommand(form, edit: true, memberIds: _members)!), {
        'title': 'Petrol (edited)',
        'expenseDate': '2026-10-18',
        'splitType': 'EQUAL',
        'totalMinor': 52000,
        'participantMemberIds': _members,
        'payers': [
          {'memberId': kYou, 'amountMinor': 52000},
        ],
      });
    });
  });
}
