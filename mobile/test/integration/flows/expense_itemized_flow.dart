import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL6 against a REAL local backend (profile `local,fake-auth`): the restaurant-bill requests the
/// editor builds are accepted by the real server and answered with the spec's numbers (V5-V8), a
/// bill is created (and replayed), read back into the form, edited with `If-Match`, and a stale
/// edit is refused. Skipped unless `API_BASE_URL` is given.
///
/// Shared by the server run (`../expense_itemized_flow_test.dart`, after a fake sign-in) and the local-mode conformance
/// run (`test/local/conformance/`), which plugs `LocalBackend` into `httpAdapterProvider` (SA3).
Future<void> runExpenseItemizedFlow(ProviderContainer container) async {

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

  // ---- SA16: the editor's v2 fields through the app's own builder (discount, quantity, charges as amounts) ----
  ExpenseFormState v2(ItemizedDraft Function(ItemizedDraft) change, {List<ItemDraft>? withItems}) {
    final base = bill();
    return base.copyWith(itemized: change(base.itemized.copyWith(items: withItems ?? items)));
  }

  // V9: discount 10%, service 12%, tax 14% on items + service.
  final v9 = await preview(v2((d) => d.copyWith(discountOn: true, discountPercentText: '10', serviceOn: true, servicePercentText: '12', taxOn: true, taxPercentText: '14')));
  expect(v9.totalMinor, 50561);
  expect(v9.discountMinor, 4400);
  expect(v9.members.map((m) => m.owedMinor).toList(), [14939, 14938, 20684]);
  expect(v9.members.map((m) => m.discountMinor).toList(), [1300, 1300, 1800]);

  // V10: the discount as an amount (50.00), no service or tax.
  final v10 = await preview(v2((d) => d.copyWith(discountOn: true, discountMode: ChargeMode.amount, discountAmountText: '50')));
  expect(v10.totalMinor, 39000);
  expect(v10.members.map((m) => m.owedMinor).toList(), [11523, 11523, 15954]);

  // V12 and V13: service and tax given as amounts.
  expect((await preview(v2((d) => d.copyWith(serviceOn: true, serviceMode: ChargeMode.amount, serviceAmountText: '50')))).totalMinor, 49000);
  final v13 = await preview(v2((d) => d.copyWith(serviceOn: true, servicePercentText: '12', taxOn: true, taxMode: ChargeMode.amount, taxAmountText: '60')));
  expect(v13.totalMinor, 55280);
  expect(v13.members.map((m) => m.owedMinor).toList(), [16333, 16333, 22614]);

  // V11: a quantity. Pepsi 3 x 15.25 {you, Asem}, Shawarma 85.00 {you}: the client sends the unit price and the quantity,
  // the server multiplies.
  final lunch = [
    ItemDraft(id: 'p', name: 'Pepsi', amountText: '15.25', quantity: 3, assigneeIds: {you, asem}),
    ItemDraft(id: 's', name: 'Shawarma', amountText: '85', assigneeIds: {you}),
  ];
  final v11 = await preview(v2((d) => d, withItems: lunch));
  expect(v11.totalMinor, 13075);
  expect(v11.members.map((m) => m.owedMinor).toList(), [10788, 2287]);

  // The refusals the engine gives (V15): a discount of the whole subtotal (440.00), or more.
  for (final text in ['440', '500']) {
    Object? tooBig;
    try {
      await repo.preview(gid, buildItemizedPreview(v2((d) => d.copyWith(discountOn: true, discountMode: ChargeMode.amount, discountAmountText: text)), memberIds: members)!).result;
    } catch (e) {
      tooBig = e;
    }
    expect((tooBig! as ApiHttpFailure).problem?.code, ApiErrorCode.validationError, reason: 'discount equal to the subtotal ($text)');
  }

  // Create a v2 bill, read it back into the form and send the same request again (quantity, unit price and charge modes survive).
  final v2Form = v2((d) => d.copyWith(discountOn: true, discountPercentText: '10', serviceOn: true, serviceMode: ChargeMode.amount, serviceAmountText: '50'), withItems: [
    ...lunch,
    ItemDraft(id: 'd', name: 'Drinks', amountText: '90', assigneeIds: {you, asem, mohsen}),
  ]);
  final v2Preview = await preview(v2Form);
  final v2Command = buildExpenseCommand(v2Form.copyWith(serverTotalMinor: v2Preview.totalMinor), edit: false, memberIds: members)!;
  final v2Created = await IdempotentAction().run(commandJson(v2Command), (key) => repo.create(gid, v2Command, key));
  expect(v2Created.expense.totalMinor, v2Preview.totalMinor);
  expect(v2Created.expense.items!.first.quantity, 3);
  expect(v2Created.expense.items!.first.unitAmountMinor, 1525);
  expect(v2Created.expense.charges!.discount?.bps, 1000);
  final v2Back = formFromExpense(await repo.get(gid, v2Created.expense.id), memberIds: members, fallbackPayerId: you);
  expect(v2Back.itemized.items.first.quantity, 3);
  expect((v2Back.itemized.discountMode, v2Back.itemized.discountPercentText), (ChargeMode.percent, '10'));
  expect((v2Back.itemized.serviceMode, v2Back.itemized.serviceAmountText), (ChargeMode.amount, '50'));
  expect(commandKey(buildExpenseCommand(v2Back, edit: true, memberIds: members)!), commandKey(v2Command), reason: 'GET -> form -> request is the same v2 bill');
}
