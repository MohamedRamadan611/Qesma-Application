import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/fake_expenses_server.dart';

/// SA17 (A176): a scan's shop name fills the title only while it is empty, and its category guess fills the category
/// only while the user has not chosen one. A suggestion is announced only when it was applied.
ScanDraft _scan({String? merchant, String? category}) => ScanDraft(
      itemized: const ItemizedDraft(items: [ItemDraft(id: 'scan-0', name: 'Tea', amountText: '12')]),
      merchantName: merchant,
      category: category,
    );

void main() {
  group('formFromScan (the add form opened from the scan)', () {
    test('title and category come from the receipt and the note says so', () {
      final f = formFromScan(_scan(merchant: 'Zooba', category: 'FOOD'), date: Date(2026, 11, 20), payerId: 'me');
      expect((f.title, f.category, f.categoryTouched), ('Zooba', 'FOOD', false));
      expect(f.scanNotes, contains(ScanNote.titleCategorySuggested));
    });

    test('nothing suggested: empty title, OTHER, no note (the same as SA12)', () {
      final f = formFromScan(_scan(), date: Date(2026, 11, 20), payerId: 'me');
      expect((f.title, f.category), ('', 'OTHER'));
      expect(f.scanNotes, isEmpty);
    });
  });

  group('applyScan on a form that already exists', () {
    late FakeExpensesServer server;
    late ProviderContainer container;
    late ExpenseFormController form;

    setUp(() async {
      server = FakeExpensesServer();
      container = await formContainer(server);
      addTearDown(container.dispose);
      form = formController(container, server);
      form.startCreate();
    });

    ExpenseFormState data() => formView(container, server).form!;

    test('an empty title and an untouched category take the suggestion', () {
      form.applyScan(_scan(merchant: 'Zooba', category: 'FOOD'));
      expect((data().title, data().category, data().categoryTouched), ('Zooba', 'FOOD', false));
      expect(data().scanNotes, contains(ScanNote.titleCategorySuggested));
    });

    test('a typed title is kept (and a blank one counts as empty)', () {
      form.setTitle('Dinner with Asem');
      form.applyScan(_scan(merchant: 'Zooba'));
      expect(data().title, 'Dinner with Asem');
      expect(data().scanNotes, isNot(contains(ScanNote.titleCategorySuggested)), reason: 'nothing was applied');

      form.setTitle('   ');
      form.applyScan(_scan(merchant: 'Zooba'));
      expect(data().title, 'Zooba');
    });

    test('a category the user chose is kept, even when it is the default value', () {
      form.setCategory('OTHER');
      form.applyScan(_scan(category: 'FOOD'));
      expect((data().category, data().categoryTouched), ('OTHER', true));
      expect(data().scanNotes, isNot(contains(ScanNote.titleCategorySuggested)));
    });

    test('only the title applied: the note still shows; only the category applied likewise', () {
      form.setCategory('TRANSPORT');
      form.applyScan(_scan(merchant: 'Zooba', category: 'FOOD'));
      expect((data().title, data().category), ('Zooba', 'TRANSPORT'));
      expect(data().scanNotes, contains(ScanNote.titleCategorySuggested));
    });

    test('a scan that suggests nothing leaves the title and category alone', () {
      form.setTitle('Lunch');
      form.applyScan(_scan());
      expect((data().title, data().category), ('Lunch', 'OTHER'));
    });

    test('a second scan can replace a category the first scan set, never a user\'s', () {
      form.applyScan(_scan(category: 'FOOD'));
      form.applyScan(_scan(category: 'GROCERIES'));
      expect(data().category, 'GROCERIES');
      form.setCategory('BILLS');
      form.applyScan(_scan(category: 'FOOD'));
      expect(data().category, 'BILLS');
    });
  });
}
