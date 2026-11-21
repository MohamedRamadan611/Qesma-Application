import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';

import '../backup/support/backup_support.dart';
import 'support/local_http.dart';

/// A180 (Java V22) through the local HTTP contract: delivery is stored, previewed, edited, replayed, kept in the
/// revision history and survives a backup round trip.
void main() {
  late LocalHttp http;
  late String gid;
  late String you;
  late String ali;
  late String sara;
  late String lina;

  setUp(() async {
    http = await LocalHttp.open();
    final g = await http.group();
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await http.member(gid, 'Ali');
    sara = await http.member(gid, 'Sara');
    lina = await http.member(gid, 'Lina');
  });
  tearDown(() => http.close());

  Map<String, Object?> bill({int? delivery, int total = 30000}) => {
        'title': 'Pizza night',
        'expenseDate': '2026-11-12',
        'splitType': 'ITEMIZED',
        'items': [
          {'name': 'Pizza', 'amountMinor': 20000, 'assigneeMemberIds': [you, ali]},
          {'name': 'Pasta', 'amountMinor': 9000, 'assigneeMemberIds': [sara]},
        ],
        'deliveryMinor': ?delivery,
        'adjustmentMinor': 0,
        'payers': [
          {'memberId': you, 'amountMinor': total},
        ],
      };

  List<int> owed(Map<String, dynamic> view) => [for (final s in view['shares'] as List) s['owedMinor'] as int];

  test('delivery is split equally among the members with an item; Lina has none and owes nothing', () async {
    final created = await http.expense(gid, bill(delivery: 1000));
    expect(created.statusCode, 201, reason: '${created.data}');
    final view = created.data as Map<String, dynamic>;
    expect(owed(view), [10334, 10333, 9333]);
    expect([for (final s in view['shares'] as List) s['deliveryMinor']], [334, 333, 333]);
    expect((view['charges'] as Map)['deliveryMinor'], 1000);
    expect(view['totalMinor'], 30000);
    expect((view['shares'] as List).any((s) => s['memberId'] == lina), isFalse);

    // preview == create, and the detail reads the same numbers back from SQLite
    final preview = (await http.post('/groups/$gid/expenses/preview', bill(delivery: 1000))).data as Map<String, dynamic>;
    expect(preview['deliveryMinor'], 1000);
    expect(preview['members'], view['shares']);
    final got = (await http.get('/groups/$gid/expenses/${view['id']}')).data as Map<String, dynamic>;
    expect(got['shares'], view['shares']);
    expect(got['charges'], view['charges']);
  });

  test('a bill without delivery shows 0, never null', () async {
    final view = (await http.expense(gid, bill(total: 29000))).data as Map<String, dynamic>;
    expect((view['charges'] as Map)['deliveryMinor'], 0);
    expect([for (final s in view['shares'] as List) s['deliveryMinor']], [0, 0, 0]);
    final preview = (await http.post('/groups/$gid/expenses/preview', bill(total: 29000))).data as Map<String, dynamic>;
    expect(preview['deliveryMinor'], 0);
  });

  test('a negative or over-limit delivery, or delivery on an EQUAL expense, is a 422 and stores nothing', () async {
    for (final bad in [-1, 1000000000001]) {
      final r = await http.expense(gid, bill(delivery: bad));
      expect(r.statusCode, 422, reason: '${r.data}');
      expect(r.data['code'], 'VALIDATION_ERROR');
    }
    final equal = await http.expense(gid, {
      'title': 'Taxi',
      'expenseDate': '2026-11-12',
      'splitType': 'EQUAL',
      'totalMinor': 3000,
      'deliveryMinor': 100,
      'payers': [
        {'memberId': you, 'amountMinor': 3000}
      ],
    });
    expect(equal.statusCode, 422);
    expect(await http.count('expenses'), 0);
  });

  test('an edit adds, changes and removes delivery; every version keeps its own in the history', () async {
    final created = (await http.expense(gid, bill(total: 29000))).data as Map<String, dynamic>;
    final id = created['id'] as String;

    final added = await http.put('/groups/$gid/expenses/$id', bill(delivery: 600, total: 29600), ifMatch: '"1"');
    expect(added.statusCode, 200, reason: '${added.data}');
    expect((added.data['charges'] as Map)['deliveryMinor'], 600);
    expect(owed(added.data as Map<String, dynamic>), [10200, 10200, 9200]);

    final removed = await http.put('/groups/$gid/expenses/$id', bill(total: 29000), ifMatch: '"2"');
    expect(removed.statusCode, 200, reason: '${removed.data}');
    expect((removed.data['charges'] as Map)['deliveryMinor'], 0);

    final history = (await http.get('/groups/$gid/expenses/$id/revisions')).data as List<dynamic>;
    final deliveries = [
      for (final r in history)
        ((r['snapshot'] as Map)['charges'] as Map)['deliveryMinor']
    ];
    expect(deliveries.toSet(), {0, 600});
  });

  test('a backup round trip keeps delivery and the restored database accepts a new delivery bill', () async {
    final view = (await http.expense(gid, bill(delivery: 1000))).data as Map<String, dynamic>;
    final bytes = await exportBytes(http.db);

    final target = LocalDatabase.inMemory();
    final service = BackupService(target);
    await service.restore(await service.prepareRestore(bytes));
    final restored = await LocalHttp.open(database: target, withProfile: false);
    addTearDown(restored.close);

    final got = (await restored.get('/groups/$gid/expenses/${view['id']}')).data as Map<String, dynamic>;
    expect(got['shares'], view['shares']);
    expect(got['charges'], view['charges']);
    final again = await restored.expense(gid, bill(delivery: 400, total: 29400));
    expect(again.statusCode, 201, reason: '${again.data}');
  });
}
