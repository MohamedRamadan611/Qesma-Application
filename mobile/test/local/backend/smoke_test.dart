import 'package:flutter_test/flutter_test.dart';

import 'support/local_http.dart';

void main() {
  late LocalHttp http;
  setUp(() async => http = await LocalHttp.open());
  tearDown(() => http.close());

  test('a group, members, an equal expense and balances over the HTTP contract', () async {
    final g = await http.group();
    final gid = g['id'] as String;
    final you = g['yourMemberId'] as String;
    expect(g['members'], hasLength(1));
    expect((g['members'] as List).first['isYou'], isTrue);
    expect(g['yourRole'], 'OWNER');
    final ali = await http.member(gid, 'Ali');

    final created = await http.expense(gid, equalBody(10000, [(id: you, amount: 10000)]));
    expect(created.statusCode, 201, reason: '${created.data}');
    expect(created.headers.value('etag'), '"1"');
    expect(created.headers.value('location'), '/api/v1/groups/$gid/expenses/${created.data['id']}');
    expect([for (final s in created.data['shares'] as List) s['owedMinor']], [5000, 5000]);

    final b = await http.get('/groups/$gid/balances');
    expect(b.statusCode, 200, reason: '${b.data}');
    expect(b.data['nets'], [
      {'memberId': you, 'netMinor': 5000},
      {'memberId': ali, 'netMinor': -5000},
    ]);
    expect((b.data['transfers'] as List).single['amountMinor'], 5000);

    final detail = await http.get('/groups/$gid');
    expect(detail.data['yourNetMinor'], 5000);
    expect(detail.data['totalSpentMinor'], 10000);
    expect(http.failures, isEmpty);
  });
}
