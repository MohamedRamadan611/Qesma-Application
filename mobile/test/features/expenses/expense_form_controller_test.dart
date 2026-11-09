import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_controller.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/application/expense_preview_controller.dart';
import 'package:qesma/features/expenses/application/expenses_list_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/expenses_rig.dart';
import '../../support/fake_expenses_server.dart';

final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

ExpenseCommand _command(String title, {int total = 52000, List<String>? participants}) => ExpenseCommand((b) => b
  ..title = title
  ..expenseDate = Date(2026, 10, 18)
  ..splitType = 'EQUAL'
  ..totalMinor = total
  ..participantMemberIds.addAll(participants ?? [kYou, kAsem, kMohsen]));

void main() {
  late FakeExpensesServer server;
  late ProviderContainer container;

  setUp(() async {
    server = FakeExpensesServer();
    container = await formContainer(server);
    addTearDown(container.dispose);
  });

  group('preview: debounced, cancellable, never stale (fake async)', () {
    PreviewKey slot() => (gid: server.gid, slot: PreviewSlot.split);
    ExpensePreviewController preview() => container.read(expensePreviewControllerProvider(slot()).notifier);
    PreviewState state() => container.read(expensePreviewControllerProvider(slot()));

    setUp(() async {
      // The long, real debounce (300 ms) is what these tests are about.
      container.dispose();
      container = await formContainer(server, debounce: const Duration(milliseconds: 300));
      keepAlive(container, expensePreviewControllerProvider(slot()));
    });

    testWidgets('rapid edits send ONE request, 300 ms after the last one', (tester) async {
      preview().request(_command('a'));
      await tester.pump(const Duration(milliseconds: 100));
      preview().request(_command('ab'));
      await tester.pump(const Duration(milliseconds: 100));
      preview().request(_command('abc'));
      await tester.pump(const Duration(milliseconds: 299));
      expect(server.previewBodies, isEmpty, reason: 'still inside the debounce');
      expect(state().status, PreviewStatus.loading);

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump(const Duration(milliseconds: 1));
      expect(server.previewBodies, hasLength(1));
      expect(server.previewBodies.single['title'], 'abc');
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.ready));
      expect(state().status, PreviewStatus.ready);
    });

    testWidgets('the numbers are the server\'s: 520.00 among three is 173.34 / 173.33 / 173.33', (tester) async {
      final command = _command('a');
      preview().request(command);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.ready));
      expect(state().isCurrentFor(commandKey(command)), isTrue);
      expect(state().preview!.members.map((m) => m.owedMinor).toList(), [17334, 17333, 17333]);
    });

    testWidgets('after an edit the old numbers are not current any more (loading, not stale)', (tester) async {
      final a = _command('a');
      preview().request(a);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.ready));
      expect(state().isCurrentFor(commandKey(a)), isTrue);

      preview().request(_command('a', total: 60000));
      expect(state().status, PreviewStatus.loading);
      expect(state().preview, isNull, reason: 'the old preview is dropped at once');
      expect(state().isCurrentFor(commandKey(a)), isFalse);
      await tester.pump(const Duration(milliseconds: 301));
    });

    testWidgets('asking for the command already loading or shown sends nothing more', (tester) async {
      final a = _command('a');
      preview().request(a);
      preview().request(a);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.ready));
      preview().request(a);
      await tester.pump(const Duration(milliseconds: 301));
      expect(server.previewBodies, hasLength(1));
    });

    testWidgets('nothing to preview (null) cancels the pending request', (tester) async {
      preview().request(_command('a'));
      await tester.pump(const Duration(milliseconds: 100));
      preview().request(null);
      await tester.pump(const Duration(milliseconds: 500));
      expect(server.previewBodies, isEmpty);
      expect(state().status, PreviewStatus.idle);
    });

    testWidgets('a failed preview says so and retry asks again', (tester) async {
      final a = _command('a');
      server.failNextPreview = true;
      preview().request(a);
      await tester.pump(const Duration(milliseconds: 301));
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.failed));
      expect(state().status, PreviewStatus.failed);
      expect(state().isCurrentFor(commandKey(a)), isFalse);

      preview().retry();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(() => waitUntil(() => state().status == PreviewStatus.ready));
      expect(state().isCurrentFor(commandKey(a)), isTrue);
    });
  });

  group('preview races (real timers)', () {
    PreviewKey slot() => (gid: server.gid, slot: PreviewSlot.split);
    ExpensePreviewController preview() => container.read(expensePreviewControllerProvider(slot()).notifier);
    PreviewState state() => container.read(expensePreviewControllerProvider(slot()));

    test('a reply that comes back late for older input is ignored (out-of-order replies)', () async {
      keepAlive(container, expensePreviewControllerProvider(slot()));
      final first = Completer<void>();
      final second = Completer<void>();
      server.previewGates.addAll([first, second]);
      final a = _command('a', total: 30000);
      final b = _command('b', total: 52000);

      preview().request(a);
      await waitUntil(() => server.previewBodies.length == 1);
      preview().request(b);
      await waitUntil(() => server.previewBodies.length == 2);

      second.complete(); // the newer answer arrives first
      await waitUntil(() => state().status == PreviewStatus.ready);
      expect(state().isCurrentFor(commandKey(b)), isTrue);

      first.complete(); // then the old one
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(state().isCurrentFor(commandKey(b)), isTrue, reason: 'still the newer answer');
      expect(state().isCurrentFor(commandKey(a)), isFalse);
      expect(state().preview!.totalMinor, 52000);
      expect(server.previewsCancelled, greaterThanOrEqualTo(1), reason: 'the older HTTP call was cancelled');
    });
  });

  group('the add form', () {
    late ExpenseFormController form;

    setUp(() => form = formController(container, server));

    ExpenseFormState data() => formView(container, server).form!;

    test('opens with today\'s date, you as the payer, everyone in the split and nothing typed', () {
      form.startCreate();
      expect(formView(container, server).phase, FormPhase.ready);
      expect(data().date, Date(2026, 10, 18));
      expect(data().singlePayerId, kYou);
      expect(data().splitMode, SplitMode.all);
      expect(data().title, '');
      expect(form.dirty, isFalse);
      expect(form.memberIds, [kYou, kAsem, kMohsen]);
    });

    test('typing makes it dirty and valid in steps', () {
      form.startCreate();
      form.setTitle('Petrol');
      expect(data().canSave(form.memberIds), isFalse);
      form.setAmount('520');
      expect(data().canSave(form.memberIds), isTrue);
      expect(form.dirty, isTrue);
      form.setAmount('abc');
      expect(data().canSave(form.memberIds), isFalse);
    });

    test('Selected starts with everyone checked; toggling changes only that member', () {
      form.startCreate();
      form.setSplitMode(SplitMode.selected);
      expect(data().selectedIds, {kYou, kAsem, kMohsen});
      form.toggleMember(kAsem);
      expect(data().selectedIds, {kYou, kMohsen});
      form.toggleMember(kAsem);
      expect(data().selectedIds, {kYou, kAsem, kMohsen});
    });

    test('Exact is prefilled with the SERVER\'s equal split, then the user edits and only the typed remaining changes', () async {
      form.startCreate();
      form.setTitle('Petrol');
      form.setAmount('520');
      form.setSplitMode(SplitMode.exact);
      await waitUntil(() => data().exactTexts.isNotEmpty);

      expect(data().exactTexts, {kYou: '173.34', kAsem: '173.33', kMohsen: '173.33'});
      expect(server.previewBodies.last['splitType'], 'EQUAL');
      expect(data().exactRemaining(form.memberIds), 0);
      expect(data().canSave(form.memberIds), isTrue);

      form.setExactText(kYou, '200');
      expect(data().exactRemaining(form.memberIds), -2666, reason: 'typed sums only: 520.00 - (200 + 173.33 + 173.33)');
      expect(data().canSave(form.memberIds), isFalse);
      form.setExactText(kMohsen, '146.67');
      expect(data().exactRemaining(form.memberIds), 0);
      expect(data().canSave(form.memberIds), isTrue);
    });

    test('Exact prefills as soon as a usable total is typed (nothing to prefill before)', () async {
      form.startCreate();
      form.setSplitMode(SplitMode.exact);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(data().exactTexts, isEmpty);
      expect(server.previewBodies, isEmpty, reason: 'no total yet, so no question for the server');

      form.setAmount('300');
      await waitUntil(() => data().exactTexts.isNotEmpty);
      expect(data().exactTexts.values.toList(), ['100', '100', '100']);
    });

    test('"Spread equally" asks the server again for the current total and selection', () async {
      form.startCreate();
      form.setTitle('Tickets');
      form.setAmount('300');
      form.setSplitMode(SplitMode.exact);
      await waitUntil(() => data().exactTexts.length == 3);
      form.toggleMember(kMohsen); // unchecked: its box goes away
      expect(data().exactTexts.containsKey(kMohsen), isFalse);
      await form.prefillExact();
      expect(data().exactTexts, {kYou: '150', kAsem: '150'});
    });

    test('a prefill that answers after the user changed the total is not applied', () async {
      form.startCreate();
      form.setTitle('Tickets');
      form.setAmount('300');
      final gate = Completer<void>();
      server.previewGates.add(gate);
      form.setSplitMode(SplitMode.exact); // the first question (for 300) is held
      await Future<void>.delayed(const Duration(milliseconds: 20));
      form.setAmount('600');
      gate.complete();
      await waitUntil(() => data().exactTexts.isNotEmpty);
      // Whatever arrived is for 600: the old 300 answer must not have been written.
      expect(data().exactTexts.values.toList(), ['200', '200', '200']);
    });

    test('a failed prefill is flagged (and nothing is invented)', () async {
      form.startCreate();
      form.setTitle('Tickets');
      form.setAmount('300');
      server.failNextPreview = true;
      form.setSplitMode(SplitMode.exact);
      await waitUntil(() => formView(container, server).prefillFailed);
      expect(formView(container, server).prefillFailed, isTrue);
      expect(data().exactTexts, isEmpty);
    });

    test('"split equally among the payers" returns the server\'s numbers, no client division', () async {
      form.startCreate();
      form.setTitle('Dinner');
      form.setAmount('500');
      final texts = await form.equalAmongPayers([kYou, kAsem, kMohsen, ]);
      expect(texts, {kYou: '166.67', kAsem: '166.67', kMohsen: '166.66'});
      final two = await form.equalAmongPayers([kYou, kAsem]);
      expect(two, {kYou: '250', kAsem: '250'});
    });

    test('applyPayers: one payer is stored as single; several keep their typed amounts', () {
      form.startCreate();
      form.setAmount('500');
      form.applyPayers(mode: PayerMode.multiple, texts: {kYou: '300', kAsem: '200'});
      expect(data().payerMode, PayerMode.multiple);
      expect(data().payersValid, isTrue);
      form.applyPayers(mode: PayerMode.single, singlePayerId: kAsem);
      expect(data().payerMode, PayerMode.single);
      expect(data().singlePayerId, kAsem);
      expect(data().payerMinors(), {kAsem: 50000});
    });
  });

  group('saving a new expense: the idempotency key lifecycle', () {
    late ExpenseFormController form;

    Future<void> fill() async {
      form = formController(container, server);
      form.startCreate();
      form.setTitle('Petrol');
      form.setAmount('520');
    }

    List<String?> keys() => [for (final c in server.creates) c.key];

    test('create sends the golden body with a UUID key, opens the new expense and refreshes the list', () async {
      await fill();
      keepAlive(container, expensesListControllerProvider(server.gid));
      await container.read(expensesListControllerProvider(server.gid).notifier).load();

      expect(await form.save(), SaveOutcome.saved);
      expect(server.creates, hasLength(1));
      expect(server.creates.single.key, matches(_uuid));
      expect(server.creates.single.body.containsKey('participantMemberIds'), isFalse);
      expect(server.expenses.single['title'], 'Petrol');
      expect(server.expenses.single['shares'].map((dynamic s) => s['owedMinor']).toList(), [17334, 17333, 17333]);
      expect(formView(container, server).savedId, server.expenses.single['id']);
      await waitUntil(() => container.read(expensesListControllerProvider(server.gid)).items.length == 1);
      expect(container.read(expensesListControllerProvider(server.gid)).items.single.title, 'Petrol');
    });

    test('a lost reply: the retry reuses the SAME key and no duplicate exists', () async {
      await fill();
      server.loseNextCreateResponse = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(formView(container, server).failure, isA<ApiTimeout>());
      expect(formView(container, server).submitting, isFalse);
      expect(server.expenses, hasLength(1), reason: 'the server did store it');

      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], keys()[1], reason: 'same body, same key');
      expect(server.expenses, hasLength(1), reason: 'the replay returned the stored expense');
      expect(formView(container, server).savedId, server.expenses.single['id']);
    });

    test('a server error before anything was stored also keeps the key', () async {
      await fill();
      server.failNextCreate = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], keys()[1]);
      expect(server.expenses, hasLength(1));
    });

    test('editing the form after a failed attempt gets a NEW key', () async {
      await fill();
      server.loseNextCreateResponse = true;
      await form.save();
      form.setTitle('Petrol and tea');
      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], isNot(keys()[1]));
      expect(server.expenses, hasLength(2), reason: 'a different body is a different expense; the user changed it on purpose');
    });

    test('success clears the key: the next create (after the form changes) uses a fresh one', () async {
      await fill();
      expect(await form.save(), SaveOutcome.saved);
      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], isNot(keys()[1]), reason: 'a second save is a second action');
    });

    test('a definitive error (a member removed meanwhile) is not retried with the old key', () async {
      await fill();
      form.setSplitMode(SplitMode.selected);
      server.group.members.removeWhere((m) => m.id == kMohsen); // someone else removed Mohsen; the form still lists him
      final outcome = await form.save();
      expect(outcome, SaveOutcome.failed);
      final failure = formView(container, server).failure! as ApiHttpFailure;
      expect(failure.problem!.code, ApiErrorCode.memberNotInGroup);

      await form.reloadMembers();
      expect(form.memberIds, [kYou, kAsem]);
      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], isNot(keys()[1]), reason: 'the body changed AND the error was definitive');
      expect(server.expenses.single['shares'].map((dynamic s) => s['memberId']).toList(), [kYou, kAsem]);
    });

    test('invalid form: nothing is sent', () async {
      form = formController(container, server);
      form.startCreate();
      expect(await form.save(), SaveOutcome.invalid);
      expect(server.creates, isEmpty);
    });

    test('only one save runs at a time', () async {
      await fill();
      final a = form.save();
      final b = form.save();
      expect(await b, SaveOutcome.busy);
      expect(await a, SaveOutcome.saved);
      expect(server.creates, hasLength(1));
    });

    test('offline keeps the form exactly as typed', () async {
      await fill();
      server.expensesOffline = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(formView(container, server).failure, isA<ApiNoConnection>());
      expect(formView(container, server).form!.title, 'Petrol');
      expect(formView(container, server).form!.amountText, '520');
      server.expensesOffline = false;
      expect(await form.save(), SaveOutcome.saved);
      expect(server.createAttemptKeys, hasLength(2));
      expect(server.createAttemptKeys[0], server.createAttemptKeys[1], reason: 'the same key for the retry');
    });

    test('a server 422 PAYERS_TOTAL_MISMATCH keeps the form, is a definitive error, and the retry gets a fresh key', () async {
      await fill();
      server.forceNextCreateCode = 'PAYERS_TOTAL_MISMATCH';
      expect(await form.save(), SaveOutcome.failed);
      final failure = formView(container, server).failure! as ApiHttpFailure;
      expect(failure.problem!.code, ApiErrorCode.payersTotalMismatch);
      expect(failure.retryable, isFalse);
      expect(formView(container, server).form!.title, 'Petrol');

      expect(await form.save(), SaveOutcome.saved);
      expect(keys()[0], isNot(keys()[1]), reason: 'a definitive refusal forgets the key');
    });

    test('SPLIT_TOTAL_MISMATCH is surfaced as its own code', () async {
      await fill();
      server.forceNextCreateCode = 'SPLIT_TOTAL_MISMATCH';
      await form.save();
      expect((formView(container, server).failure! as ApiHttpFailure).problem!.code, ApiErrorCode.splitTotalMismatch);
    });

    test('an Exact expense is sent with the typed shares', () async {
      await fill();
      form.setSplitMode(SplitMode.exact);
      await waitUntil(() => formView(container, server).form!.exactTexts.length == 3);
      form.setExactText(kYou, '200');
      form.setExactText(kAsem, '160');
      form.setExactText(kMohsen, '160');
      expect(await form.save(), SaveOutcome.saved);
      expect(server.creates.single.body['splitType'], 'EXACT');
      expect(server.expenses.single['shares'].map((dynamic s) => s['owedMinor']).toList(), [20000, 16000, 16000]);
    });
  });

  group('editing: PUT, If-Match and the explicit participant list', () {
    const eqId = '91d890aa-7d46-458e-ad4e-e99710109445';
    late ExpenseFormController form;

    setUp(() async {
      seedAllFixtures(server);
      form = formController(container, server, eid: eqId);
    });

    ExpenseFormState data() => formView(container, server, eid: eqId).form!;
    ExpenseFormView view() => formView(container, server, eid: eqId);

    test('opens with the saved values and is not dirty', () async {
      await form.startEdit();
      expect(view().phase, FormPhase.ready);
      expect(data().title, 'Petrol (edited)');
      expect(data().amountText, '520');
      expect(data().splitMode, SplitMode.all);
      expect(form.dirty, isFalse);
    });

    test('save sends If-Match "2" and the explicit participant list of everyone', () async {
      await form.startEdit();
      form.setTitle('Petrol again');
      expect(await form.save(), SaveOutcome.saved);
      expect(server.requests.where((r) => r.startsWith('PUT')).single, endsWith('if-match="2"'));
      expect(server.updates.single['participantMemberIds'], [kYou, kAsem, kMohsen]);
      expect(server.updates.single['title'], 'Petrol again');
      expect(server.creates, isEmpty, reason: 'an edit never goes through the create endpoint');
      expect(view().savedId, eqId);
      expect(server.expenses.firstWhere((e) => e['id'] == eqId)['version'], 3);
    });

    test('a member who joined later is not added: the PUT lists exactly the original participants', () async {
      final json = server.expenses.firstWhere((e) => e['id'] == eqId);
      (json['shares'] as List).removeWhere((s) => s['memberId'] == kMohsen); // Mohsen was not part of it
      await form.startEdit();
      expect(data().splitMode, SplitMode.selected);
      expect(data().selectedIds, {kYou, kAsem});
      form.setTitle('x');
      await form.save();
      expect(server.updates.single['participantMemberIds'], [kYou, kAsem]);
    });

    test('an exact expense with two payers opens in Exact mode with several payers and saves', () async {
      const exactId = '9cf70c24-3d33-41ee-aa07-38a5f1a47cc0';
      final exact = formController(container, server, eid: exactId);
      await exact.startEdit();
      final f = formView(container, server, eid: exactId).form!;
      expect(f.splitMode, SplitMode.exact);
      expect(f.payerMode, PayerMode.multiple);
      exact.setExactText(kYou, '110');
      exact.setExactText(kMohsen, '40');
      expect(await exact.save(), SaveOutcome.saved);
      expect(server.updates.single['splitType'], 'EXACT');
      expect(server.updates.single['shares'], hasLength(3));
    });

    test('an itemized bill opens the FL6 stub phase, not a form', () async {
      const itemizedId = '7e3b3a23-d844-4889-99ae-5cba254d1173';
      final itemized = formController(container, server, eid: itemizedId);
      await itemized.startEdit();
      expect(formView(container, server, eid: itemizedId).phase, FormPhase.itemized);
      expect(formView(container, server, eid: itemizedId).form, isNull);
    });

    test('an expense that is gone: the gone phase', () async {
      final missing = formController(container, server, eid: 'nope');
      await missing.startEdit();
      expect(formView(container, server, eid: 'nope').phase, FormPhase.gone);
    });

    test('offline when opening: failed phase with a retry that works', () async {
      server.expensesOffline = true;
      await form.startEdit();
      expect(view().phase, FormPhase.failed);
      server.expensesOffline = false;
      await form.retryLoad();
      expect(view().phase, FormPhase.ready);
    });

    test('409: the user\'s input is kept; reloading records the new version; saving again then works', () async {
      await form.startEdit();
      form.setTitle('My edit');
      server.bumpVersion(eqId); // someone else saved first: version 3
      expect(await form.save(), SaveOutcome.failed);
      expect((view().failure! as ApiHttpFailure).problem!.code, ApiErrorCode.versionConflict);
      expect(data().title, 'My edit');

      expect(await form.reloadLatest(), ReloadOutcome.reloaded);
      expect(view().latestReloaded, isTrue);
      expect(data().title, 'My edit', reason: 'what the user typed stays');
      expect(view().failure, isNull);

      expect(await form.save(), SaveOutcome.saved);
      expect(server.requests.where((r) => r.startsWith('PUT')).last, endsWith('if-match="3"'));
      expect(server.expenses.firstWhere((e) => e['id'] == eqId)['title'], 'My edit');
    });

    test('a lost PUT reply: the next 409 is recognised as our own save and ends cleanly', () async {
      await form.startEdit();
      form.setTitle('My edit');
      server.loseNextUpdateResponse = true;
      expect(await form.save(), SaveOutcome.failed);
      expect(view().failure, isA<ApiTimeout>());
      expect(server.expenses.firstWhere((e) => e['id'] == eqId)['title'], 'My edit', reason: 'the server applied it');

      expect(await form.save(), SaveOutcome.failed, reason: 'the old version now conflicts');
      expect((view().failure! as ApiHttpFailure).problem!.code, ApiErrorCode.versionConflict);

      expect(await form.reloadLatest(), ReloadOutcome.alreadyApplied);
      expect(view().savedId, eqId);
      expect(server.updates, hasLength(2));
    });

    test('a real conflict after an unknown outcome is NOT mistaken for our save', () async {
      await form.startEdit();
      form.setTitle('My edit');
      server.loseNextUpdateResponse = true;
      await form.save(); // applied, reply lost
      // Then somebody else changed it again.
      final stored = server.expenses.firstWhere((e) => e['id'] == eqId);
      stored['title'] = 'Their edit';
      stored['version'] = (stored['version'] as int) + 1;
      await form.save(); // 409
      expect(await form.reloadLatest(), ReloadOutcome.reloaded);
      expect(view().savedId, isNull);
    });
  });
}
