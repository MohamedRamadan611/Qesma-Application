import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/balances/application/record_payment_state.dart';
import 'package:qesma/features/balances/data/balances_repository.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma/features/groups/data/groups_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// SA10 pool & treasurer through the app's own repositories and request builders (BSA1 contract): set the
/// treasurer, record deposits (POOL_DEPOSIT, built by `buildSettlementCommand`), a pool expense (built by
/// `buildExpenseCommand` with "Paid from the pool"), read the meter from `GroupDto.poolBalanceMinor`, and the A137
/// lock by code. Shared shape with the other flows; run by the local-mode conformance suite.
Future<void> runPoolFlow(ProviderContainer container) async {
  final api = container.read(qesmaApiProvider);
  final groups = container.read(groupsRepositoryProvider);
  final balances = container.read(balancesRepositoryProvider);
  final expenses = container.read(expensesRepositoryProvider);

  final created = (await api.getGroupControllerApi().createGroup(
        createGroupRequest: CreateGroupRequest((b) => b
          ..name = 'SA10 pool'
          ..type = 'TRIP'
          ..currencyCode = 'EGP'),
      ))
      .data!;
  final gid = created.id;
  final t = created.yourMemberId;
  final a = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'))).data!.id;
  final s = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Mohsen'))).data!.id;

  // No treasurer: no meter.
  var group = await groups.get(gid);
  expect((group.treasurerMemberId, group.poolBalanceMinor), (null, null));

  group = await groups.update(gid, name: group.name, type: group.type, treasurerMemberId: t);
  expect((group.treasurerMemberId, group.poolBalanceMinor), (t, 0));

  // Two deposits as the deposit sheet sends them.
  for (final (from, amount) in [(a, '300'), (s, '300')]) {
    final command = buildSettlementCommand(
      PaymentForm(fromId: from, toId: t, amountText: amount, date: Date(2026, 11, 12), poolDeposit: true),
    )!;
    expect(command.kind, kPoolDepositKind);
    final recorded = await IdempotentAction().run(settlementBodyJson(command), (key) => balances.record(gid, command, key));
    expect(recorded.kind, kPoolDepositKind);
  }

  // A pool expense of 450.00 split by all three, as the form builds it with the switch on.
  final form = ExpenseFormState(
    title: 'Fuel',
    amountText: '450',
    date: Date(2026, 11, 13),
    singlePayerId: t,
    paidFromPool: true,
  );
  final command = buildExpenseCommand(form, edit: false, memberIds: [t, a, s])!;
  expect(command.paidFromPool, isTrue);
  final expense = await IdempotentAction().run(command.title, (key) => expenses.create(gid, command, key));
  expect(expense.expense.paidFromPool, isTrue);

  group = await groups.get(gid);
  expect(group.poolBalanceMinor, 15000, reason: '600.00 deposited - 450.00 spent');
  final v = await balances.balances(gid);
  expect(v.nets.map((n) => n.netMinor).toList(), [-30000, 15000, 15000],
      reason: 'each depositor gets back 150.00: the treasurer holds the 150.00 left and owes their own 150.00 share');

  // A137: locked now; the server's code is INVALID_STATE_TRANSITION.
  await expectLater(
    groups.update(gid, name: group.name, type: group.type, treasurerMemberId: a),
    throwsA(isA<ApiHttpFailure>().having((f) => f.problem?.code, 'code', ApiErrorCode.invalidStateTransition)),
  );
}
