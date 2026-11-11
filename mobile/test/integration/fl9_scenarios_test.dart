import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/balances/data/balances_repository.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

import '../support/faulty_adapter.dart';

/// FL9 scenarios that need the REAL backend and the app's own session, repository and idempotency code, with faults
/// injected at the network edge ([FaultyAdapter]): (a) the seeded Dahab trip's documented balances, (e) a lost response
/// followed by a retry that reuses the key, (f) an expired access token refreshed exactly once, and the offline path.
/// Backend profiles `local,fake-auth,seed`. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend (profiles local,fake-auth,seed)' : null;

  setUpAll(() => HttpOverrides.global = null);

  ({ProviderContainer container, FaultyAdapter adapter}) boot() {
    final adapter = FaultyAdapter(IOHttpClientAdapter());
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
      httpAdapterProvider.overrideWithValue(adapter),
    ]);
    addTearDown(container.dispose);
    return (container: container, adapter: adapter);
  }

  Future<void> signIn(ProviderContainer c, String token) async {
    await c.read(authControllerProvider.notifier).signInWithIdToken(token);
    expect(c.read(authControllerProvider), isA<AuthSignedIn>(), reason: 'is the backend running with local,fake-auth(,seed)?');
  }

  test('(a) the seeded Dahab trip shows exactly the documented balances and its transfers', () async {
    final (:container, :adapter) = boot();
    await signIn(container, 'fake:dahab:mohamed@example.com:محمد');
    final api = container.read(qesmaApiProvider);

    final groups = (await api.getGroupControllerApi().listGroups()).data!;
    final dahab = groups.items.where((g) => g.name == 'رحلة دهب').toList();
    expect(dahab, hasLength(1), reason: 'the seed creates the trip once; is the seed profile on?');
    final gid = dahab.single.id;

    final group = (await api.getGroupControllerApi().getGroup(gid: gid)).data!;
    final nameOf = {for (final m in group.members) m.id: m.displayName};
    expect(group.members, hasLength(5));

    final view = await container.read(balancesRepositoryProvider).balances(gid);
    final nets = {for (final n in view.nets) nameOf[n.memberId]!: n.netMinor};
    expect(nets, {
      'محمد رمضان': 101401, // the docs say "محمد"; the seed names the owner member in full
      'عاصم': 111402,
      'محسن': -68803,
      'يوسف': -72000,
      'كريم': -72000,
    });
    expect(view.nets.fold<int>(0, (sum, n) => sum + n.netMinor), 0, reason: 'a ledger always sums to zero');
    // The server's own transfer list settles every debtor exactly: what each debtor pays out equals what they owe.
    final paidOut = <String, int>{};
    final received = <String, int>{};
    for (final t in view.transfers) {
      paidOut[nameOf[t.fromMemberId]!] = (paidOut[nameOf[t.fromMemberId]!] ?? 0) + t.amountMinor;
      received[nameOf[t.toMemberId]!] = (received[nameOf[t.toMemberId]!] ?? 0) + t.amountMinor;
    }
    expect(paidOut, {'محسن': 68803, 'يوسف': 72000, 'كريم': 72000});
    expect(received, {'محمد رمضان': 101401, 'عاصم': 111402});
    expect(view.transfers, hasLength(4), reason: 'the documented four transfers');
    expect(adapter.count((l) => l.startsWith('GET ')), greaterThan(0));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('(e) a lost response followed by a retry creates exactly one expense (same Idempotency-Key)', () async {
    final (:container, :adapter) = boot();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await signIn(container, 'fake:fl9-lost-$stamp:fl9-lost-$stamp@example.com:Tester');
    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL9 lost response'
            ..type = 'TRIP'
            ..currencyCode = 'EGP'),
        ))
        .data!;
    final gid = group.id;
    await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'));
    final me = group.yourMemberId;

    final command = ExpenseCommand((b) => b
      ..title = 'Lunch'
      ..expenseDate = Date(2026, 10, 20)
      ..splitType = 'EQUAL'
      ..totalMinor = 25050
      ..payers.add(PayerInput((x) => x
        ..memberId = me
        ..amountMinor = 25050)));
    final repo = container.read(expensesRepositoryProvider);
    final action = IdempotentAction(); // what the form's save button holds across taps

    // The first POST is processed by the server but its response is lost.
    var dropped = false;
    adapter.decide = (o) {
      if (!dropped && o.method == 'POST' && o.uri.path.endsWith('/expenses')) {
        dropped = true;
        return Fault.dropResponse;
      }
      return null;
    };
    Object? failure;
    try {
      await action.run(command.title, (key) => repo.create(gid, command, key));
    } catch (e) {
      failure = e;
    }
    expect(failure, isA<ApiFailure>());
    expect((failure! as ApiFailure).retryable, isTrue, reason: 'a lost response must keep the key for the retry');
    final firstKey = action.currentKey;
    expect(firstKey, isNotNull);

    // The user taps Save again: same key, the server answers with the stored expense.
    final created = await action.run(command.title, (key) => repo.create(gid, command, key));
    expect(adapter.idempotencyKeys.where((k) => k == firstKey), hasLength(2), reason: 'both attempts used the same key');
    expect(created.expense.totalMinor, 25050);

    final list = (await api.getExpenseControllerApi().listExpenses(gid: gid)).data!;
    expect(list.items, hasLength(1), reason: 'exactly one expense exists, not two');
    expect((await api.getGroupControllerApi().getGroup(gid: gid)).data!.totalSpentMinor, 25050, reason: 'and the group total counts it once');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('(f) an expired access token is refreshed exactly once and the call succeeds', () async {
    final (:container, :adapter) = boot();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await signIn(container, 'fake:fl9-exp-$stamp:fl9-exp-$stamp@example.com:Tester');
    final api = container.read(qesmaApiProvider);
    expect((await api.getMeControllerApi().getMe()).statusCode, 200);
    final refreshBefore = adapter.count((l) => l.contains('/auth/refresh'));

    var expired = false;
    adapter.decide = (o) {
      if (!expired && o.uri.path.endsWith('/me')) {
        expired = true;
        return Fault.expiredToken;
      }
      return null;
    };
    final me = await api.getMeControllerApi().getMe();
    expect(me.statusCode, 200, reason: 'the 401 is absorbed: refresh, then the same call is retried');
    expect(adapter.count((l) => l.contains('/auth/refresh')) - refreshBefore, 1, reason: 'one refresh, not a loop');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('offline: a failed call is reported as retryable, and the same call works once the network is back', () async {
    final (:container, :adapter) = boot();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await signIn(container, 'fake:fl9-off-$stamp:fl9-off-$stamp@example.com:Tester');
    final api = container.read(qesmaApiProvider);

    adapter.decide = (_) => Fault.offline;
    Object? failure;
    try {
      await api.getGroupControllerApi().listGroups();
    } catch (e) {
      failure = mapApiError(e);
    }
    expect(failure, isA<ApiFailure>());
    expect((failure! as ApiFailure).retryable, isTrue);

    adapter.decide = null;
    expect((await api.getGroupControllerApi().listGroups()).statusCode, 200);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
