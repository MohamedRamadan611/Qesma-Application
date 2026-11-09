import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/api/uuid_v4.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL5 against a REAL local backend (profile `local,fake-auth`): the requests the add/edit form
/// builds are accepted by the real server and return the numbers the UI relies on: the preview
/// (EQUAL among three, with and without payers, with the placeholder title), create with an
/// Idempotency-Key (and its replay), key reuse with another body, edit with If-Match and the
/// explicit participant list, and a stale edit. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('the add/edit form\'s requests against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl5-$stamp:fl5-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    // Setup through the generated client (the app's own members screen is FL3 and already verified).
    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL5 live'
            ..type = 'TRIP'
            ..currencyCode = 'EGP'),
        ))
        .data!;
    final gid = group.id;
    final you = group.yourMemberId;
    final asem = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'))).data!.id;
    final mohsen = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Mohsen'))).data!.id;
    final members = [you, asem, mohsen];
    final repo = container.read(expensesRepositoryProvider);

    // ---- preview: the server's numbers ----
    final equal = buildEqualPreview(title: '', date: Date(2026, 10, 18), totalMinor: 52000, participantIds: members);
    final preview = await repo.preview(gid, equal).result; // empty title -> the placeholder title is accepted
    expect(preview.members.map((m) => m.owedMinor).toList(), [17334, 17333, 17333]);
    expect(preview.payersTotalMatches, isFalse, reason: 'no payers yet');

    final withPayers = buildPayersCheck(title: 'x', date: Date(2026, 10, 18), totalMinor: 50000, memberIds: members, payers: {you: 30000, asem: 20000});
    expect((await repo.preview(gid, withPayers).result).payersTotalMatches, isTrue);
    final short = buildPayersCheck(title: 'x', date: Date(2026, 10, 18), totalMinor: 50000, memberIds: members, payers: {you: 30000, asem: 15000});
    expect((await repo.preview(gid, short).result).payersTotalMatches, isFalse);

    // "Split equally among the payers": 500.00 among three -> 166.67 / 166.67 / 166.66 (server numbers).
    final spread = await repo.preview(gid, buildEqualPreview(title: 'x', date: Date(2026, 10, 18), totalMinor: 50000, participantIds: members)).result;
    expect(spread.members.map((m) => m.owedMinor).toList(), [16667, 16667, 16666]);

    // ---- create from the form, with a key; the replay returns the stored expense ----
    ExpenseFormState form(String title) => ExpenseFormState(title: title, amountText: '520', date: Date(2026, 10, 18), singlePayerId: you);
    final command = buildExpenseCommand(form('Petrol'), edit: false, memberIds: members)!;
    expect(command.participantMemberIds, isNull, reason: 'a create lets the server resolve "all members"');

    final action = IdempotentAction();
    final first = await action.run(commandJson(command), (key) => repo.create(gid, command, key));
    expect(first.replayed, isFalse);
    expect(first.expense.totalMinor, 52000);
    expect(first.expense.shares.map((s) => s.owedMinor).toList(), [17334, 17333, 17333]);
    expect(first.expense.shares.map((s) => s.memberId).toSet(), members.toSet(), reason: 'omitted participants = everyone, stored explicitly (A28)');

    final key = newUuidV4();
    final stored = await repo.create(gid, buildExpenseCommand(form('Tea'), edit: false, memberIds: members)!, key);
    final replay = await repo.create(gid, buildExpenseCommand(form('Tea'), edit: false, memberIds: members)!, key);
    expect(replay.replayed, isTrue, reason: 'Idempotency-Replayed: true');
    expect(replay.expense.id, stored.expense.id);
    expect((await repo.list(gid)).items.where((e) => e.title == 'Tea'), hasLength(1), reason: 'no duplicate');

    Object? reused;
    try {
      await repo.create(gid, buildExpenseCommand(form('Coffee'), edit: false, memberIds: members)!, key);
    } catch (e) {
      reused = e;
    }
    expect(reused, isA<ApiHttpFailure>());
    expect((reused! as ApiHttpFailure).problem?.code, ApiErrorCode.idempotencyKeyReused);

    // ---- edit: read first, PUT with If-Match and the explicit participant list ----
    final expense = await repo.get(gid, first.expense.id);
    expect(repo.versionOf(expense.id), 1);
    final edited = buildExpenseCommand(form('Petrol and tea'), edit: true, memberIds: members)!;
    expect(edited.participantMemberIds!.toList(), members);
    final updated = await repo.update(gid, expense.id, edited);
    expect(updated.title, 'Petrol and tea');
    expect(updated.version, 2);
    expect(repo.versionOf(expense.id), 2, reason: 'the new version is remembered for the next edit');

    // ---- a stale edit is refused with 409 ----
    await api.getExpenseControllerApi().updateExpense(
          gid: gid,
          eid: expense.id,
          ifMatch: '"2"',
          expenseCommand: buildExpenseCommand(form('Someone else'), edit: true, memberIds: members)!,
        );
    Object? stale;
    try {
      await repo.update(gid, expense.id, buildExpenseCommand(form('Mine'), edit: true, memberIds: members)!);
    } catch (e) {
      stale = e;
    }
    expect((stale! as ApiHttpFailure).status, 409);
    expect((stale as ApiHttpFailure).problem?.code, ApiErrorCode.versionConflict);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
