import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Payments in local mode (STANDALONE_SPEC 3.5, A125): CONFIRMED at once and counted in balances (A83); cancel is
/// the undo and is idempotent; the list keeps every status.
void main() {
  late LocalHttp http;
  late String gid;
  late String you;
  late String ali;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await http.member(gid, 'Ali');
    await http.expense(gid, equalBody(10000, [(id: you, amount: 10000)]));
  });
  tearDown(() => http.close());

  Future<List<int>> nets() async => [for (final n in (await http.get('/groups/$gid/balances')).data['nets'] as List) n['netMinor'] as int];

  test('a payment is CONFIRMED immediately and moves the balances; cancel reverts them; a second cancel is a no-op',
      () async {
    expect(await nets(), [5000, -5000]);
    final r = await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 5000, 'settledOn': '2026-11-12', 'note': '  cash  '});
    expect(r.statusCode, 201);
    expect(r.headers.value('location'), '/api/v1/groups/$gid/settlements/${r.data['id']}');
    expect((r.data['status'], r.data['note'], r.data['recordedByAdmin'], r.data['createdByMemberId']), ('CONFIRMED', 'cash', false, you));
    expect(r.data['confirmedAt'], r.data['declaredAt']);
    expect(await nets(), [0, 0]);
    expect((await http.get('/groups/$gid/balances')).data['transfers'], isEmpty);

    final sid = r.data['id'];
    final cancelled = await http.post('/groups/$gid/settlements/$sid/cancel', null);
    expect((cancelled.statusCode, cancelled.data['status']), (200, 'CANCELLED'));
    expect(cancelled.data['cancelledAt'], isNotNull);
    expect(await nets(), [5000, -5000]);
    final again = await http.post('/groups/$gid/settlements/$sid/cancel', null);
    expect((again.statusCode, again.data['cancelledAt']), (200, cancelled.data['cancelledAt']));

    final list = await http.get('/groups/$gid/settlements');
    expect((list.data['items'] as List).single['status'], 'CANCELLED', reason: 'cancelled payments stay in the history');
    final onlyConfirmed = await http.get('/groups/$gid/settlements', query: {'status': 'CONFIRMED'});
    expect(onlyConfirmed.data['items'], isEmpty);
  });

  test('a payment on someone else\'s behalf is recordedByAdmin; transfers to "you" carry your own handles', () async {
    expect((await http.put('/me/payment-handles', {'instapay': 'me@cib', 'wallet': null})).statusCode, 200);
    final t = (await http.get('/groups/$gid/balances')).data['transfers'] as List;
    expect(t.single['toMemberId'], you);
    expect(t.single['receiverHandles'], {'instapay': 'me@cib'});
    expect((t.single['pendingMinor'], t.single['hasDispute']), (0, false));
    expect(t.single['openSettlementIds'], isEmpty);

    final sara = await http.member(gid, 'Sara');
    final r = await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': sara, 'amountMinor': 100, 'settledOn': '2026-11-12'});
    expect(r.data['recordedByAdmin'], isTrue);
  });

  test('refusals: same member, unknown member, unknown settlement', () async {
    final same = await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': ali, 'amountMinor': 100, 'settledOn': '2026-11-12'});
    expect((same.statusCode, same.data['code']), (422, 'VALIDATION_ERROR'));
    final stranger = await http.settlement(gid, {
      'fromMemberId': ali,
      'toMemberId': '11111111-2222-4333-8444-555555555555',
      'amountMinor': 100,
      'settledOn': '2026-11-12',
    });
    expect((stranger.statusCode, stranger.data['code']), (422, 'MEMBER_NOT_IN_GROUP'));
    final unknown = await http.post('/groups/$gid/settlements/11111111-2222-4333-8444-555555555555/cancel', null);
    expect((unknown.statusCode, unknown.data['code']), (404, 'NOT_FOUND'));
  });
}
