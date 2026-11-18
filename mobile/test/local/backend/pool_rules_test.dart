import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Pool validation in local mode, matching the Java BSA1 checks and codes (STANDALONE_SPEC 10, A135-A138).
void main() {
  late LocalHttp http;
  late String gid;
  late String you;
  late String ali;
  late String sara;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await http.member(gid, 'Ali');
    sara = await http.member(gid, 'Sara');
  });
  tearDown(() => http.close());

  Future<int> version() async => (await http.get('/groups/$gid')).data['version'] as int;

  Future<dynamic> setTreasurer(String? id) async =>
      http.patch('/groups/$gid', {'treasurerMemberId': id}, ifMatch: '"${await version()}"');

  Map<String, Object?> deposit(String from, String to, {int amount = 1000, String? kind = 'POOL_DEPOSIT'}) =>
      {'fromMemberId': from, 'toMemberId': to, 'amountMinor': amount, 'settledOn': '2026-11-12', 'kind': ?kind};

  Map<String, Object?> poolExpense(List<({String id, int amount})> payers, {int total = 3000}) =>
      {...equalBody(total, payers), 'paidFromPool': true};

  void expectProblem(dynamic r, int status, String code) =>
      expect((r.statusCode, r.data['code']), (status, code), reason: '${r.data}');

  group('without a treasurer', () {
    test('the meter is null and the treasurer is absent', () async {
      final g = (await http.get('/groups/$gid')).data as Map;
      expect(g.containsKey('poolBalanceMinor'), isFalse);
      expect(g.containsKey('treasurerMemberId'), isFalse);
    });

    test('a pool expense is 422 VALIDATION_ERROR', () async {
      expectProblem(await http.expense(gid, poolExpense([(id: you, amount: 3000)])), 422, 'VALIDATION_ERROR');
    });

    test('a deposit is 422 VALIDATION_ERROR', () async {
      expectProblem(await http.settlement(gid, deposit(ali, you)), 422, 'VALIDATION_ERROR');
    });

    test('a plain expense and a plain payment default to paidFromPool false and kind PAYMENT', () async {
      final e = await http.expense(gid, equalBody(3000, [(id: you, amount: 3000)]));
      expect((e.statusCode, e.data['paidFromPool']), (201, false));
      final s = await http.settlement(gid, deposit(ali, you, kind: null));
      expect((s.statusCode, s.data['kind']), (201, 'PAYMENT'));
    });

    test('an unknown kind is 422', () async {
      expectProblem(await http.settlement(gid, deposit(ali, you, kind: 'GIFT')), 422, 'VALIDATION_ERROR');
    });
  });

  group('with a treasurer', () {
    setUp(() async {
      final r = await setTreasurer(you);
      expect((r.statusCode, r.data['treasurerMemberId'], r.data['poolBalanceMinor']), (200, you, 0));
    });

    test('a pool expense paid by someone else is 422', () async {
      expectProblem(await http.expense(gid, poolExpense([(id: ali, amount: 3000)])), 422, 'VALIDATION_ERROR');
    });

    test('a pool expense with two payers (the treasurer one of them) is 422', () async {
      expectProblem(await http.expense(gid, poolExpense([(id: you, amount: 2000), (id: ali, amount: 1000)])), 422,
          'VALIDATION_ERROR');
    });

    test('editing an expense into a pool expense paid by someone else is 422 too', () async {
      final e = await http.expense(gid, equalBody(3000, [(id: ali, amount: 3000)]));
      final r = await http.put('/groups/$gid/expenses/${e.data['id']}', poolExpense([(id: ali, amount: 3000)]), ifMatch: '"1"');
      expectProblem(r, 422, 'VALIDATION_ERROR');
    });

    test('a deposit to anyone but the treasurer is 422', () async {
      expectProblem(await http.settlement(gid, deposit(sara, ali)), 422, 'VALIDATION_ERROR');
    });

    test('A138: the treasurer cannot deposit to themselves (from <> to)', () async {
      expectProblem(await http.settlement(gid, deposit(you, you)), 422, 'VALIDATION_ERROR');
    });

    test('the kind is part of the idempotent request: same key, other kind is IDEMPOTENCY_KEY_REUSED', () async {
      const key = '11111111-2222-4333-8444-555555555555';
      final first = await http.settlement(gid, deposit(ali, you), key: key);
      expect(first.statusCode, 201);
      final replay = await http.settlement(gid, deposit(ali, you), key: key);
      expect((replay.statusCode, replay.data['id']), (201, first.data['id']));
      expectProblem(await http.settlement(gid, deposit(ali, you, kind: 'PAYMENT'), key: key), 422, 'IDEMPOTENCY_KEY_REUSED');
      expect(await http.count('settlements'), 1);
    });

    test('setting the same treasurer again is a no-op (no version bump, no lock check)', () async {
      await http.settlement(gid, deposit(ali, you));
      final before = await version();
      final r = await setTreasurer(you);
      expect((r.statusCode, r.data['version']), (200, before));
    });

    test('the treasurer can change while the pool is untouched', () async {
      final r = await setTreasurer(ali);
      expect((r.statusCode, r.data['treasurerMemberId']), (200, ali));
    });

    test('A137: no change after the first deposit', () async {
      await http.settlement(gid, deposit(ali, you));
      expectProblem(await setTreasurer(ali), 409, 'INVALID_STATE_TRANSITION');
    });

    test('A137: no change after the first pool expense', () async {
      await http.expense(gid, poolExpense([(id: you, amount: 3000)]));
      expectProblem(await setTreasurer(ali), 409, 'INVALID_STATE_TRANSITION');
    });

    test('A137: a cancelled deposit still locks the treasurer', () async {
      final d = await http.settlement(gid, deposit(ali, you));
      await http.post('/groups/$gid/settlements/${d.data['id']}/cancel', null);
      expectProblem(await setTreasurer(ali), 409, 'INVALID_STATE_TRANSITION');
    });

    test('A137: a soft-deleted pool expense still locks the treasurer', () async {
      final e = await http.expense(gid, poolExpense([(id: you, amount: 3000)]));
      expect((await http.delete('/groups/$gid/expenses/${e.data['id']}', ifMatch: '"1"')).statusCode, 204);
      expect((await http.get('/groups/$gid')).data['poolBalanceMinor'], 0);
      expectProblem(await setTreasurer(ali), 409, 'INVALID_STATE_TRANSITION');
    });

    test('a plain payment to the treasurer does not lock it', () async {
      await http.settlement(gid, deposit(ali, you, kind: 'PAYMENT'));
      expect((await setTreasurer(ali)).statusCode, 200);
    });

    test('the treasurer must be a member of this group', () async {
      final other = await http.group(name: 'Other');
      final r = await setTreasurer(other['yourMemberId'] as String);
      expectProblem(r, 422, 'VALIDATION_ERROR');
    });

    test('a null treasurer is "no change" (the treasurer cannot be cleared, mirrors Java)', () async {
      final r = await setTreasurer(null);
      expect((r.statusCode, r.data['treasurerMemberId']), (200, you));
    });

    test('the treasurer, a ghost, cannot be removed from the group', () async {
      expect((await setTreasurer(ali)).statusCode, 200);
      expectProblem(await http.delete('/groups/$gid/members/$ali'), 409, 'MEMBER_HAS_TRANSACTIONS');
    });

    test('a group with a treasurer and no ledger can still be deleted', () async {
      expect((await setTreasurer(ali)).statusCode, 200);
      expect((await http.delete('/groups/$gid')).statusCode, 204);
    });

    test('the meter, the flag and the kind are visible in GET, list and revisions', () async {
      final e = await http.expense(gid, poolExpense([(id: you, amount: 3000)]));
      await http.settlement(gid, deposit(ali, you, amount: 5000));
      expect((await http.get('/groups/$gid')).data['poolBalanceMinor'], 2000);
      expect((await http.get('/groups/$gid/expenses/${e.data['id']}')).data['paidFromPool'], isTrue);
      expect(((await http.get('/groups/$gid/expenses')).data['items'] as List).single['paidFromPool'], isTrue);
      final revisions = (await http.get('/groups/$gid/expenses/${e.data['id']}/revisions')).data;
      expect(revisions.toString(), contains('paidFromPool: true'));
      expect(((await http.get('/groups/$gid/settlements')).data['items'] as List).single['kind'], 'POOL_DEPOSIT');
    });
  });
}
