import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

/// ETag / If-Match (spec 7.9) and the B17 conflict body (A113) in local mode.
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

  test('PUT expense with a stale If-Match is 409 with currentVersion and the latest ExpenseView', () async {
    final created = await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]));
    final eid = created.data['id'] as String;
    final edit = await http.put('/groups/$gid/expenses/$eid', equalBody(8000, [(id: you, amount: 8000)], title: 'Edited'),
        ifMatch: '"1"');
    expect(edit.statusCode, 200, reason: '${edit.data}');
    expect(edit.headers.value('etag'), '"2"');

    final stale = await http.put('/groups/$gid/expenses/$eid', equalBody(7000, [(id: you, amount: 7000)]), ifMatch: 'W/"1"');
    expect(stale.statusCode, 409);
    expect(stale.data['code'], 'VERSION_CONFLICT');
    expect(stale.data['currentVersion'], 2);
    final current = await http.get('/groups/$gid/expenses/$eid');
    expect(stale.data['current'], current.data, reason: 'exactly what GET returns');
    expect(current.data['title'], 'Edited', reason: 'the stale write changed nothing');
    expect(await http.count('expense_revisions'), 2);
  });

  test('DELETE expense: stale is 409, fresh is 204 with the new ETag, a second delete is 404', () async {
    final eid = (await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]))).data['id'] as String;
    final stale = await http.delete('/groups/$gid/expenses/$eid', ifMatch: '"7"');
    expect((stale.statusCode, stale.data['code'], stale.data['currentVersion']), (409, 'VERSION_CONFLICT', 1));
    final ok = await http.delete('/groups/$gid/expenses/$eid', ifMatch: '1');
    expect(ok.statusCode, 204);
    expect(ok.headers.value('etag'), '"2"');
    expect((await http.get('/groups/$gid/expenses/$eid')).statusCode, 404);
    expect((await http.delete('/groups/$gid/expenses/$eid', ifMatch: '"2"')).statusCode, 404);
    final history = await http.get('/groups/$gid/expenses/$eid/revisions');
    expect([for (final r in history.data as List) (r['version'], r['changeType'])], [(1, 'CREATE'), (2, 'DELETE')]);
    expect((await http.get('/groups/$gid')).data['totalSpentMinor'], 0, reason: 'a deleted expense leaves the totals');
  });

  test('PATCH group with a stale If-Match is 409 with the current GroupDto; an unchanged edit keeps the version',
      () async {
    final ok = await http.patch('/groups/$gid', {'name': 'Sinai'}, ifMatch: '"1"');
    expect((ok.statusCode, ok.data['version'], ok.headers.value('etag')), (200, 2, '"2"'));
    final same = await http.patch('/groups/$gid', {'name': 'Sinai'}, ifMatch: '"2"');
    expect(same.data['version'], 2, reason: 'nothing changed, no new version');
    final stale = await http.patch('/groups/$gid', {'name': 'Late'}, ifMatch: '"1"');
    expect((stale.statusCode, stale.data['code'], stale.data['currentVersion']), (409, 'VERSION_CONFLICT', 2));
    expect(stale.data['current'], (await http.get('/groups/$gid')).data);
  });

  test('If-Match missing is 428, malformed is 422, both VALIDATION_ERROR', () async {
    final eid = (await http.expense(gid, equalBody(9000, [(id: you, amount: 9000)]))).data['id'] as String;
    final missing = await http.put('/groups/$gid/expenses/$eid', equalBody(9000, [(id: you, amount: 9000)]));
    expect((missing.statusCode, missing.data['code']), (428, 'VALIDATION_ERROR'));
    final star = await http.patch('/groups/$gid', {'name': 'x'}, ifMatch: '*');
    expect((star.statusCode, star.data['code']), (422, 'VALIDATION_ERROR'));
    expect((await http.delete('/groups/$gid/expenses/$eid')).statusCode, 428);
  });
}
