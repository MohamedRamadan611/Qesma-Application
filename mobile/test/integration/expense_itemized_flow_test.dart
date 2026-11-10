import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL6 against a REAL local backend (profile `local,fake-auth`): the restaurant-bill requests the
/// editor builds are accepted by the real server and answered with the spec's numbers (V5-V8), a
/// bill is created (and replayed), read back into the form, edited with `If-Match`, and a stale
/// edit is refused. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('the restaurant-bill editor\'s requests against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl6-$stamp:fl6-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL6 live'
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

    // The spec's bill: Pizza 200.00 {you, Asem}, Pasta 150.00 {Mohsen}, Drinks 90.00 {everyone}.
    final items = [
      ItemDraft(id: 'a', name: 'Pizza', amountText: '200', assigneeIds: {you, asem}),
      ItemDraft(id: 'b', name: 'Pasta', amountText: '150', assigneeIds: {mohsen}),
      ItemDraft(id: 'c', name: 'Drinks', amountText: '90', assigneeIds: {you, asem, mohsen}),
    ];
    ExpenseFormState bill({bool service = false, bool tax = false, TaxBase base = TaxBase.subtotalPlusService, int? total, String title = 'Sea Food'}) => ExpenseFormState(
          title: title,
          amountText: '',
          date: Date(2026, 10, 18),
          singlePayerId: you,
          splitMode: SplitMode.itemized,
          serverTotalMinor: total,
          itemized: ItemizedDraft(items: items, serviceOn: service, servicePercentText: '12', taxOn: tax, taxPercentText: '14', taxBase: base),
        );

    // ---- the four spec vectors through the app's own builder ----
    Future<ExpensePreview> preview(ExpenseFormState form) async => repo.preview(gid, buildItemizedPreview(form, memberIds: members)!).result;

    final v5 = await preview(bill(service: true, tax: true));
    expect(v5.totalMinor, 56179);
    expect((v5.subtotalMinor, v5.serviceMinor, v5.taxMinor), (44000, 5280, 6899));
    expect(v5.members.map((m) => m.owedMinor).toList(), [16599, 16598, 22982]);
    expect(v5.members.map((m) => (m.itemsMinor, m.serviceMinor, m.taxMinor)).toList(), [(13000, 1560, 2039), (13000, 1560, 2038), (18000, 2160, 2822)]);

    expect((await preview(bill(service: true))).totalMinor, 49280);
    expect((await preview(bill(tax: true, base: TaxBase.subtotal))).totalMinor, 50160);
    final v8 = await preview(bill());
    expect(v8.totalMinor, 44000);
    expect(v8.members.map((m) => m.owedMinor).toList(), [13000, 13000, 18000]);

    // A 0% charge that is switched on is accepted ("enabled with 0"); the request carries bps 0.
    final zero = bill(service: true).copyWith(itemized: bill(service: true).itemized.copyWith(servicePercentText: '0'));
    expect(commandJson(buildItemizedPreview(zero, memberIds: members)!), containsPair('service', {'bps': 0}));
    expect((await preview(zero)).totalMinor, 44000);

    // The editor's "payers match" question: the payers with the server's total match.
    final withPayers = bill(service: true, tax: true, total: 56179);
    final matches = await repo.preview(gid, buildItemizedPreview(withPayers, memberIds: members, withPayers: true)!).result;
    expect(matches.payersTotalMatches, isTrue);

    // A negative total is refused by the server as VALIDATION_ERROR (the editor shows it as a failed calculation).
    final negative = bill().copyWith(itemized: bill().itemized.copyWith(adjustmentText: '-1000'));
    Object? refused;
    try {
      await repo.preview(gid, buildItemizedPreview(negative, memberIds: members)!).result;
    } catch (e) {
      refused = e;
    }
    expect((refused! as ApiHttpFailure).problem?.code, ApiErrorCode.validationError);

    // ---- create (key), replay, read back into the form, edit, stale edit ----
    final form = bill(service: true, tax: true, total: 56179);
    final command = buildExpenseCommand(form, edit: false, memberIds: members)!;
    expect(commandJson(command), isNot(contains('totalMinor')));
    final action = IdempotentAction();
    final created = await action.run(commandJson(command), (key) => repo.create(gid, command, key));
    expect(created.expense.totalMinor, 56179);
    expect(created.expense.shares.map((s) => s.owedMinor).toList(), [16599, 16598, 22982]);

    final expense = await repo.get(gid, created.expense.id);
    final reopened = formFromExpense(expense, memberIds: members, fallbackPayerId: you);
    expect(reopened.splitMode, SplitMode.itemized);
    expect((reopened.itemized.servicePercentText, reopened.itemized.taxPercentText, reopened.itemized.taxBase), ('12', '14', TaxBase.subtotalPlusService));
    expect(commandKey(buildExpenseCommand(reopened, edit: true, memberIds: members)!), commandKey(command), reason: 'GET -> form -> request is the same bill');

    final renamed = reopened.copyWith(itemized: reopened.itemized.copyWith(items: [reopened.itemized.items.first.copyWith(name: 'Large pizza'), ...reopened.itemized.items.skip(1)]));
    final updated = await repo.update(gid, expense.id, buildExpenseCommand(renamed, edit: true, memberIds: members)!);
    expect(updated.version, 2);
    expect(updated.items!.first.name, 'Large pizza');
    expect(updated.totalMinor, 56179);

    await api.getExpenseControllerApi().updateExpense(
          gid: gid,
          eid: expense.id,
          ifMatch: '"2"',
          expenseCommand: buildExpenseCommand(renamed.copyWith(title: 'Someone else'), edit: true, memberIds: members)!,
        );
    Object? stale;
    try {
      await repo.update(gid, expense.id, buildExpenseCommand(renamed.copyWith(title: 'Mine'), edit: true, memberIds: members)!);
    } catch (e) {
      stale = e;
    }
    expect((stale! as ApiHttpFailure).problem?.code, ApiErrorCode.versionConflict);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
