import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/uuid_v4.dart';

import 'support/local_http.dart';

/// Idempotency-Key semantics of spec 8.3 in local mode (STANDALONE_SPEC 3.4).
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
  });
  tearDown(() => http.close());

  Map<String, Object?> payment(int amount) =>
      {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': amount, 'settledOn': '2026-11-10'};

  test('expense: same key + same body replays the stored response once, marked Idempotency-Replayed', () async {
    final key = newUuidV4();
    final first = await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]), key: key);
    final again = await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]), key: key.toUpperCase());
    expect(first.statusCode, 201);
    expect(first.headers.value('idempotency-replayed'), isNull);
    expect(again.statusCode, 201);
    expect(again.headers.value('idempotency-replayed'), 'true');
    expect(again.data, first.data, reason: 'the stored body, byte for byte as JSON');
    expect(again.headers.value('etag'), first.headers.value('etag'));
    expect(again.headers.value('location'), first.headers.value('location'));
    expect(await http.count('expenses'), 1);
    expect(await http.count('expense_revisions'), 1);
    expect(await http.count('idempotency_keys'), 1);
  });

  test('expense: payer order does not change the request (canonical form), a different body is KEY_REUSED', () async {
    final key = newUuidV4();
    final a = await http.expense(gid, equalBody(9000, [(id: you, amount: 5000), (id: ali, amount: 4000)]), key: key);
    final b = await http.expense(gid, equalBody(9000, [(id: ali, amount: 4000), (id: you, amount: 5000)]), key: key);
    expect(a.statusCode, 201);
    expect(b.headers.value('idempotency-replayed'), 'true');
    final reused = await http.expense(gid, equalBody(9001, [(id: you, amount: 9001)]), key: key);
    expect(reused.statusCode, 422);
    expect(reused.data['code'], 'IDEMPOTENCY_KEY_REUSED');
    expect(reused.headers.value('content-type'), contains('application/problem+json'));
    expect(await http.count('expenses'), 1);
  });

  test('a key used for an expense cannot be reused for a payment (endpoint is part of the request)', () async {
    final key = newUuidV4();
    expect((await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]), key: key)).statusCode, 201);
    final other = await http.settlement(gid, payment(100), key: key);
    expect(other.statusCode, 422);
    expect(other.data['code'], 'IDEMPOTENCY_KEY_REUSED');
  });

  test('settlement: replay returns the same payment, a different body is KEY_REUSED', () async {
    final key = newUuidV4();
    final first = await http.settlement(gid, payment(2500), key: key);
    final again = await http.settlement(gid, payment(2500), key: key);
    expect(first.statusCode, 201);
    expect(first.headers.value('etag'), isNull, reason: 'settlements carry no ETag');
    expect(again.headers.value('idempotency-replayed'), 'true');
    expect(again.data['id'], first.data['id']);
    expect(await http.count('settlements'), 1);
    final reused = await http.settlement(gid, payment(2600), key: key);
    expect(reused.statusCode, 422);
    expect(reused.data['code'], 'IDEMPOTENCY_KEY_REUSED');
  });

  test('missing or malformed Idempotency-Key is 422 VALIDATION_ERROR and writes nothing', () async {
    final missing = await http.post('/groups/$gid/expenses', equalBody(9000, [(id: you, amount: 9000)]));
    expect((missing.statusCode, missing.data['code']), (422, 'VALIDATION_ERROR'));
    final bad = await http.post('/groups/$gid/settlements', payment(100), key: 'not-a-uuid');
    expect((bad.statusCode, bad.data['code']), (422, 'VALIDATION_ERROR'));
    expect(await http.count('expenses'), 0);
    expect(await http.count('settlements'), 0);
  });

  test('a key older than 24 hours counts as new (and is purged), a failed request stores no key', () async {
    final key = newUuidV4();
    expect((await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]), key: key)).statusCode, 201);
    http.advance(const Duration(hours: 24, minutes: 1));
    final later = await http.expense(gid, equalBody(7000, [(id: you, amount: 7000)]), key: key);
    expect(later.statusCode, 201);
    expect(later.headers.value('idempotency-replayed'), isNull);
    expect(await http.count('expenses'), 2);

    final failing = newUuidV4();
    final mismatch = await http.expense(gid, equalBody(9000, [(id: you, amount: 8000)]), key: failing);
    expect(mismatch.data['code'], 'PAYERS_TOTAL_MISMATCH');
    final fixed = await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]), key: failing);
    expect(fixed.statusCode, 201, reason: 'a failure stored nothing, so the same key may carry the corrected body');
  });
}
