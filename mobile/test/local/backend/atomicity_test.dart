import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// Every write is one drift transaction with its revision and idempotency record (STANDALONE_SPEC 3.8): a failure in
/// the middle leaves no partial rows. The failure is injected with a test-only SQLite trigger on the LAST table each
/// write touches, so everything before it must roll back.
void main() {
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

  Future<void> failInsertsInto(String table) => http.db.customStatement(
      'CREATE TEMP TRIGGER fail_$table BEFORE INSERT ON $table BEGIN SELECT RAISE(ABORT, \'injected failure\'); END');

  Map<String, Object?> itemizedBody() => {
        'title': 'Sea food',
        'expenseDate': '2026-11-01',
        'splitType': 'ITEMIZED',
        'items': [
          {'name': 'Fish', 'amountMinor': 5000, 'assigneeMemberIds': [you]},
        ],
        'payers': [
          {'memberId': you, 'amountMinor': 5000},
        ],
      };

  test('expense create failing at the revision insert: 500 INTERNAL_ERROR and no partial rows', () async {
    await failInsertsInto('expense_revisions');
    final r = await http.expense(gid, itemizedBody());
    expect(r.statusCode, 500);
    expect(r.data['code'], 'INTERNAL_ERROR');
    expect(r.data.keys, isNot(contains('trace')));
    expect('${r.data}', isNot(contains('injected failure')), reason: 'no internal message reaches the client');
    for (final table in ['expenses', 'expense_payers', 'expense_splits', 'expense_items', 'expense_item_assignees', 'idempotency_keys']) {
      expect(await http.count(table), 0, reason: table);
    }
    expect(http.failures.single.route, '/groups/{gid}/expenses', reason: 'logged by route template, no ids or data');
    expect(http.failures.single.requestId, r.headers.value('x-request-id'));
  });

  test('expense create failing at the idempotency record: nothing is written either', () async {
    await failInsertsInto('idempotency_keys');
    expect((await http.expense(gid, itemizedBody())).statusCode, 500);
    expect(await http.count('expenses'), 0);
    expect(await http.count('expense_revisions'), 0);
  });

  test('expense update failing at the revision insert: graph and version unchanged', () async {
    final created = await http.expense(gid, itemizedBody());
    final eid = created.data['id'] as String;
    await failInsertsInto('expense_revisions');
    final r = await http.put('/groups/$gid/expenses/$eid', equalBody(7000, [(id: you, amount: 7000)]), ifMatch: '"1"');
    expect(r.statusCode, 500);
    final now = await http.get('/groups/$gid/expenses/$eid');
    expect(now.data, created.data, reason: 'still the itemized v1 bill, items and charges included');
    expect(await http.count('expense_items'), 1);
  });

  test('expense delete failing at the revision insert: still live', () async {
    final eid = (await http.expense(gid, itemizedBody())).data['id'] as String;
    await failInsertsInto('expense_revisions');
    expect((await http.delete('/groups/$gid/expenses/$eid', ifMatch: '"1"')).statusCode, 500);
    expect((await http.get('/groups/$gid/expenses/$eid')).data['version'], 1);
  });

  test('payment create failing at the idempotency record: no payment', () async {
    final ali = await http.member(gid, 'Ali');
    await failInsertsInto('idempotency_keys');
    final r = await http.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 100, 'settledOn': '2026-11-01'});
    expect(r.statusCode, 500);
    expect(await http.count('settlements'), 0);
  });

  test('group create failing at the owner member: no group without its "you" member', () async {
    await failInsertsInto('members');
    expect((await http.post('/groups', {'name': 'Half', 'type': 'TRIP'})).statusCode, 500);
    expect(await http.count('expense_groups'), 1, reason: 'only the group from setUp');
  });
}
