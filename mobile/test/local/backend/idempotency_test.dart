import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/uuid_v4.dart';
import 'package:qesma/local/service/commands.dart';
import 'package:qesma/local/service/expense_service.dart';
import 'package:qesma/local/service/expense_validator.dart';
import 'package:qesma/local/service/idempotency_service.dart';

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

  // ---- SA15 (A175): the hash adds the itemized v2 fields only when not default ----------------------------------

  test('a legacy itemized request keeps its pre-SA15 hash (golden, from the SA14 canonical form)', () {
    const a = '00000000-0000-4000-8000-0000000000b1';
    const b = '00000000-0000-4000-8000-0000000000b2';
    const g = '00000000-0000-4000-8000-0000000000a1';
    ValidExpense valid(List<ItemIn> items) => ExpenseValidator.validate(ExpenseIn(
          title: 'Dinner',
          expenseDate: '2026-11-10',
          splitType: 'ITEMIZED',
          payers: const [PayerIn(a, 56179)],
          items: items,
          service: const ChargeIn(1200, null),
          tax: const TaxIn(1400, null),
          adjustmentMinor: 0,
        ));
    String hash(ValidExpense v) => IdempotencyService.fingerprint(ExpenseService.canonical(ExpenseService.createEndpoint, g, v));
    const golden = '{"endpoint":"POST /api/v1/groups/{gid}/expenses","groupId":"$g","title":"Dinner",'
        '"expenseDate":"2026-11-10","splitType":"ITEMIZED","totalMinor":0,"payers":[{"memberId":"$a","amountMinor":56179}],'
        '"participantMemberIds":null,"shares":null,"items":[{"name":"Pizza","amountMinor":20000,"assigneeMemberIds":["$a","$b"]},'
        '{"name":"Pasta","amountMinor":15000,"assigneeMemberIds":["$b"]}],"serviceBps":1200,"taxBps":1400,'
        '"taxBase":"SUBTOTAL_PLUS_SERVICE","adjustmentMinor":0}';
    expect(hash(valid(const [ItemIn('Pizza', 20000, [b, a]), ItemIn('Pasta', 15000, [b])])), golden);
    // The unit form with quantity 1 is the same request (amountMinor is the line).
    expect(hash(valid(const [ItemIn('Pizza', null, [a, b], unitAmountMinor: 20000), ItemIn('Pasta', null, [b], unitAmountMinor: 15000, quantity: 1)])), golden);
  });

  Map<String, Object?> bill(Map<String, Object?> item, {Map<String, Object?>? discount}) => {
        'title': 'Koshary',
        'expenseDate': '2026-11-10',
        'splitType': 'ITEMIZED',
        'payers': [{'memberId': you, 'amountMinor': discount == null ? 3000 : 2700}],
        'items': [item],
        'discount': ?discount,
      };

  test('itemized v2: {amountMinor} and {unitAmountMinor} replay each other; quantity or a discount is a new request', () async {
    final key = newUuidV4();
    final legacy = await http.expense(gid, bill({'name': 'Plate', 'amountMinor': 3000, 'assigneeMemberIds': [you, ali]}), key: key);
    expect(legacy.statusCode, 201, reason: '${legacy.data}');
    final unit = await http.expense(gid, bill({'name': 'Plate', 'unitAmountMinor': 3000, 'assigneeMemberIds': [ali, you]}), key: key);
    expect(unit.statusCode, 201);
    expect(unit.headers.value('idempotency-replayed'), 'true');
    final quantity = await http.expense(gid, bill({'name': 'Plate', 'quantity': 2, 'unitAmountMinor': 1500, 'assigneeMemberIds': [you, ali]}), key: key);
    expect((quantity.statusCode, quantity.data['code']), (422, 'IDEMPOTENCY_KEY_REUSED'));
    final discounted = await http.expense(gid,
        bill({'name': 'Plate', 'amountMinor': 3000, 'assigneeMemberIds': [you, ali]}, discount: {'amountMinor': 300}), key: key);
    expect((discounted.statusCode, discounted.data['code']), (422, 'IDEMPOTENCY_KEY_REUSED'));
    expect(await http.count('expenses'), 1);
  });

  test('a create response stored before SA15 replays with quantity 1 and discount 0 (upgraded, never rewritten)', () async {
    final key = newUuidV4();
    final body = bill({'name': 'Plate', 'amountMinor': 3000, 'assigneeMemberIds': [you, ali]});
    final first = await http.expense(gid, body, key: key);
    expect(first.statusCode, 201);
    // Rewrite the stored body into the pre-SA15 shape (no quantity / unitAmountMinor / discountMinor).
    final old = (first.data as Map<String, dynamic>)
      ..['items'] = [for (final i in (first.data['items'] as List).cast<Map<String, dynamic>>()) Map.of(i)..remove('quantity')..remove('unitAmountMinor')]
      ..['shares'] = [for (final x in (first.data['shares'] as List).cast<Map<String, dynamic>>()) Map.of(x)..remove('discountMinor')];
    await http.db.customStatement('UPDATE idempotency_keys SET response_body = ? WHERE "key" = ?', [jsonEncode(old), key]);

    final again = await http.expense(gid, body, key: key);
    expect(again.headers.value('idempotency-replayed'), 'true');
    expect([for (final i in again.data['items'] as List) (i['quantity'], i['unitAmountMinor'], i['amountMinor'])], [(1, 3000, 3000)]);
    expect([for (final x in again.data['shares'] as List) x['discountMinor']], [0, 0]);
    final stored = await http.db.customSelect('SELECT response_body AS b FROM idempotency_keys WHERE "key" = ?', variables: [Variable.withString(key)]).getSingle();
    expect(stored.read<String>('b'), isNot(contains('quantity')), reason: 'the stored text is not rewritten');
  });
}
