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
import 'package:qesma/features/balances/application/record_payment_state.dart';
import 'package:qesma/features/balances/data/balances_repository.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL7 against a REAL local backend (profile `local,fake-auth`): the spec's V1 and V2 through the
/// app's own repository and request builder: nets 100.00 / -80.00 / -20.00 and two transfers; after
/// "Asem pays Mohamed 80.00" 20.00 / 0 / -20.00 and one transfer; the idempotent replay, partial and
/// larger-than-suggested payments, delete (and the second delete), and the refusals by code.
/// Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

String _key(int n) => 'c0ffee00-0000-4000-8000-${DateTime.now().microsecondsSinceEpoch % 100000000}${n.toString().padLeft(4, '0')}';

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('balances, suggested transfers, payments and their history against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl7-$stamp:fl7-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL7 live'
            ..type = 'TRIP'
            ..currencyCode = 'EGP'),
        ))
        .data!;
    final gid = group.id;
    final m = group.yourMemberId;
    final a = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'))).data!.id;
    final s = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Mohsen'))).data!.id;
    final expenses = container.read(expensesRepositoryProvider);
    final repo = container.read(balancesRepositoryProvider);

    // V1: Mohamed pays 100.00 for Asem and Mohsen (50.00 each); Mohsen pays 30.00 for Asem.
    ExpenseCommand exact(String title, int total, Map<String, int> shares, String payer) => ExpenseCommand((b) => b
      ..title = title
      ..expenseDate = Date(2026, 10, 17)
      ..splitType = 'EXACT'
      ..totalMinor = total
      ..shares.addAll([for (final e in shares.entries) ShareInput((x) => x..memberId = e.key..amountMinor = e.value)])
      ..payers.add(PayerInput((x) => x..memberId = payer..amountMinor = total)));
    var n = 0;
    for (final command in [exact('Hotel', 10000, {a: 5000, s: 5000}, m), exact('Dinner', 3000, {a: 3000}, s)]) {
      await IdempotentAction().run(command.title, (key) => expenses.create(gid, command, key));
      n++;
    }

    List<int> nets(BalanceView v) => v.nets.map((x) => x.netMinor).toList();
    final v1 = await repo.balances(gid);
    expect(v1.nets.map((x) => x.memberId).toList(), [m, a, s], reason: 'every member, in sort order');
    expect(nets(v1), [10000, -8000, -2000]);
    expect(v1.transfers.map((t) => (t.fromMemberId, t.toMemberId, t.amountMinor)).toList(), [(a, m, 8000), (s, m, 2000)]);
    expect((await repo.settlements(gid)).items, isEmpty);

    // Record 80.00 from Asem to Mohamed, as the Record payment sheet would send it.
    PaymentForm form(String from, String to, String amount, {String note = ''}) =>
        PaymentForm(fromId: from, toId: to, amountText: amount, date: Date(2026, 10, 18), note: note);
    final command = buildSettlementCommand(form(a, m, '80', note: ' cash on the road '))!;
    expect(command.note, 'cash on the road');
    final recorded = await IdempotentAction().run(settlementBodyJson(command), (key) => repo.record(gid, command, key));
    expect(recorded.amountMinor, 8000);
    expect(recorded.note, 'cash on the road');

    // A replay with the same key and body answers with the stored payment and records nothing twice.
    final replayKey = _key(++n);
    final first = await repo.record(gid, buildSettlementCommand(form(s, m, '1'))!, replayKey);
    final replay = await repo.record(gid, buildSettlementCommand(form(s, m, '1'))!, replayKey);
    expect(replay.id, first.id);
    expect((await repo.settlements(gid)).total, 2, reason: '80.00 and the 1.00, once each');
    await repo.delete(gid, first.id);

    final v2 = await repo.balances(gid);
    expect(nets(v2), [2000, 0, -2000], reason: 'V2');
    expect(v2.transfers.map((t) => (t.fromMemberId, t.toMemberId, t.amountMinor)).toList(), [(s, m, 2000)]);
    expect((await api.getGroupControllerApi().getGroup(gid: gid)).data!.yourNetMinor, 2000, reason: 'the group header agrees');

    // Partial, then larger than suggested (the excess flips the balance).
    final partial = await repo.record(gid, buildSettlementCommand(form(s, m, '5'))!, _key(++n));
    expect(nets(await repo.balances(gid)), [1500, 0, -1500]);
    final larger = await repo.record(gid, buildSettlementCommand(form(s, m, '30'))!, _key(++n));
    expect(nets(await repo.balances(gid)), [-1500, 0, 1500], reason: 'paid more than was owed: now Mohsen is owed');

    // History: the server counts and pages it.
    final page = await repo.settlements(gid);
    expect(page.total, 3);
    expect(page.items.map((p) => p.amountMinor).toSet(), {8000, 500, 3000});

    // Deleting reverses the effect; a second delete is a plain 404.
    await repo.delete(gid, larger.id);
    await repo.delete(gid, partial.id);
    expect(nets(await repo.balances(gid)), [2000, 0, -2000]);
    Object? gone;
    try {
      await repo.delete(gid, larger.id);
    } catch (e) {
      gone = e;
    }
    expect((gone! as ApiHttpFailure).problem?.code, ApiErrorCode.notFound);

    // Refusals by code.
    Future<ApiErrorCode?> refused(SettlementCommand c) async {
      try {
        await repo.record(gid, c, _key(++n));
      } catch (e) {
        return (e as ApiHttpFailure).problem?.code;
      }
      return null;
    }

    final sameMember = SettlementCommand((b) => b
      ..fromMemberId = m
      ..toMemberId = m
      ..amountMinor = 100
      ..settledOn = Date(2026, 10, 18));
    expect(await refused(sameMember), ApiErrorCode.validationError);
    final stranger = SettlementCommand((b) => b
      ..fromMemberId = m
      ..toMemberId = '11111111-2222-4333-8444-555555555555'
      ..amountMinor = 100
      ..settledOn = Date(2026, 10, 18));
    expect(await refused(stranger), ApiErrorCode.memberNotInGroup);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
