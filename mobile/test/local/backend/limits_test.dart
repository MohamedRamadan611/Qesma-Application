import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// The local port is pinned to the server's limits (STANDALONE_SPEC 3.2): FieldRules, ExpenseValidator and
/// Limits.MAX_AMOUNT_MINOR = 10^12. Each limit is checked at the boundary and one past it.
void main() {
  const max = 1000000000000;
  late LocalHttp http;
  late String gid;
  late String you;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
  });
  tearDown(() => http.close());

  Future<int?> status(Future<dynamic> call) async => (await call).statusCode as int?;

  test('amounts: 10^12 accepted, 10^12 + 1 refused (expense total, payer, payment)', () async {
    expect(await status(http.expense(gid, equalBody(max, [(id: you, amount: max)]))), 201);
    final over = await http.expense(gid, equalBody(max + 1, [(id: you, amount: max + 1)]));
    expect((over.statusCode, over.data['code']), (422, 'VALIDATION_ERROR'));
    final ali = await http.member(gid, 'Ali');
    Map<String, Object?> pay(int a) => {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': a, 'settledOn': '2026-11-01'};
    expect(await status(http.settlement(gid, pay(max))), 201);
    expect(await status(http.settlement(gid, pay(max + 1))), 422);
    expect(await status(http.settlement(gid, pay(0))), 422);
  });

  test('an itemized bill whose computed total passes 10^12 is refused', () async {
    final r = await http.expense(gid, {
      'title': 'Big',
      'expenseDate': '2026-11-01',
      'splitType': 'ITEMIZED',
      'items': [
        {'name': 'A', 'amountMinor': max, 'assigneeMemberIds': [you]},
      ],
      'service': {'bps': 1},
      'payers': [
        {'memberId': you, 'amountMinor': max},
      ],
    });
    expect((r.statusCode, r.data['code']), (422, 'VALIDATION_ERROR'));
  });

  test('100 items, 100 participants and 100 payers are accepted; 101 is refused', () async {
    final ids = [you];
    for (var i = 2; i <= 101; i++) {
      ids.add(await http.member(gid, 'M$i'));
    }
    Map<String, Object?> itemized(int n) => {
          'title': 'Items',
          'expenseDate': '2026-11-01',
          'splitType': 'ITEMIZED',
          'items': [
            for (var i = 0; i < n; i++) {'name': 'Item $i', 'amountMinor': 100, 'assigneeMemberIds': [you]},
          ],
          'payers': [
            {'memberId': you, 'amountMinor': n * 100},
          ],
        };
    expect(await status(http.expense(gid, itemized(100))), 201);
    expect(await status(http.expense(gid, itemized(101))), 422);

    expect(await status(http.expense(gid, equalBody(10000, [(id: you, amount: 10000)], participants: ids.take(100).toList()))), 201);
    expect(await status(http.expense(gid, equalBody(10000, [(id: you, amount: 10000)], participants: ids))), 422);

    final payers = [for (final id in ids) (id: id, amount: 100)];
    expect(await status(http.expense(gid, equalBody(10000, payers.take(100).toList()))), 201);
    expect(await status(http.expense(gid, equalBody(10100, payers))), 422);
  });

  test('text lengths count code points: group 60, member 40, title 100, item name 100', () async {
    String ar(int n) => 'ع' * n;
    expect(await status(http.post('/groups', {'name': ar(60), 'type': 'TRIP'})), 201);
    expect(await status(http.post('/groups', {'name': ar(61), 'type': 'TRIP'})), 422);
    expect(await status(http.post('/groups', {'name': '   ', 'type': 'TRIP'})), 422);
    expect(await status(http.post('/groups/$gid/members', {'displayName': ar(40)})), 201);
    expect(await status(http.post('/groups/$gid/members', {'displayName': ar(41)})), 422);
    expect(await status(http.expense(gid, equalBody(100, [(id: you, amount: 100)], title: ar(100)))), 201);
    expect(await status(http.expense(gid, equalBody(100, [(id: you, amount: 100)], title: ar(101)))), 422);
    Map<String, Object?> item(String name) => {
          'title': 'x',
          'expenseDate': '2026-11-01',
          'splitType': 'ITEMIZED',
          'items': [
            {'name': name, 'amountMinor': 100, 'assigneeMemberIds': [you]},
          ],
          'payers': [
            {'memberId': you, 'amountMinor': 100},
          ],
        };
    expect(await status(http.expense(gid, item(ar(100)))), 201);
    expect(await status(http.expense(gid, item(ar(101)))), 422);
  });

  test('basis points 0..10000, dates 2000-01-01..2100-12-31, group type and currency', () async {
    Map<String, Object?> service(int bps) => {
          'title': 'x',
          'expenseDate': '2026-11-01',
          'splitType': 'ITEMIZED',
          'items': [
            {'name': 'a', 'amountMinor': 100, 'assigneeMemberIds': [you]},
          ],
          'service': {'bps': bps},
          'payers': [
            {'memberId': you, 'amountMinor': 100 + bps ~/ 100},
          ],
        };
    expect(await status(http.expense(gid, service(10000))), 201);
    expect(await status(http.expense(gid, service(10001))), 422);
    for (final (date, want) in [('2000-01-01', 201), ('1999-12-31', 422), ('2100-12-31', 201), ('2101-01-01', 422)]) {
      expect(await status(http.expense(gid, equalBody(100, [(id: you, amount: 100)], date: date))), want, reason: date);
    }
    expect(await status(http.expense(gid, equalBody(100, [(id: you, amount: 100)], date: '2026-02-30'))), 400);
    expect(await status(http.post('/groups', {'name': 'x', 'type': 'CRUISE'})), 422);
    expect(await status(http.post('/groups', {'name': 'x', 'type': ' trip ', 'currencyCode': 'usd'})), 201);
    expect(await status(http.post('/groups', {'name': 'x', 'type': 'TRIP', 'currencyCode': 'XXX'})), 422);
  });

  test('page size 1..100, page >= 0', () async {
    expect(await status(http.get('/groups', query: {'size': 100})), 200);
    expect(await status(http.get('/groups', query: {'size': 101})), 422);
    expect(await status(http.get('/groups', query: {'size': 0})), 422);
    expect(await status(http.get('/groups', query: {'page': -1})), 422);
    expect(await status(http.get('/groups/$gid/expenses', query: {'fromDate': '2026-11-02', 'toDate': '2026-11-01'})), 422);
    expect(await status(http.get('/groups/$gid/settlements', query: {'status': 'LOST'})), 422);
  });
}
