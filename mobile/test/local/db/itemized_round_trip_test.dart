import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';

import '../backend/support/local_http.dart';
import 'support/local_db_fixture.dart';

void main() {
  late LocalDatabase db;

  setUp(() async {
    db = LocalDatabase.inMemory();
    await seedGroup(db);
  });
  tearDown(() => db.close());

  void expectSameGraph(ExpenseGraph actual, ExpenseGraph expected) {
    expect(actual.expense, expected.expense);
    expect(actual.payers, unorderedEquals(expected.payers));
    expect(actual.splits, unorderedEquals(expected.splits));
    expect(actual.items, expected.items, reason: 'items come back in sort order');
    expect(actual.assignees, unorderedEquals(expected.assignees));
  }

  test('a full itemized expense is stored and read back unchanged', () async {
    final written = itemizedExpense(tid(101));
    await db.expensesDao.insertGraph(written);
    expectSameGraph((await db.expensesDao.loadGraph(tid(101)))!, written);
  });

  test('replacing the graph swaps every child row while the version matches', () async {
    await db.expensesDao.insertGraph(itemizedExpense(tid(101)));
    final eq = equalExpense(tid(101), total: 12768);
    final next = ExpenseGraph(expense: eq.expense.copyWith(version: 2), payers: eq.payers, splits: eq.splits);

    expect(await db.expensesDao.replaceGraphIfVersion(next, 9), isFalse, reason: 'stale version');
    expect(await db.expensesDao.replaceGraphIfVersion(next, 1), isTrue);

    expectSameGraph((await db.expensesDao.loadGraph(tid(101)))!, next);
    final orphans = await db.customSelect('SELECT count(*) AS n FROM expense_items').getSingle();
    expect(orphans.read<int>('n'), 0);
  });

  test('a failing child row rolls the whole graph back', () async {
    final g = itemizedExpense(tid(101));
    final broken = ExpenseGraph(
      expense: g.expense,
      payers: g.payers,
      splits: g.splits,
      items: g.items,
      assignees: [...g.assignees, AssigneeRow(itemId: g.items.first.id, memberId: tid(999))],
    );
    await expectLater(db.expensesDao.insertGraph(broken), throwsA(anything));
    expect(await db.expensesDao.findById(tid(101)), isNull);
  });

  // ---- SA15: itemized v2 through the local contract (quantity, discount, amount-form charges) -------------------
  group('itemized v2 via the local backend', () {
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

    Map<String, Object?> bill({required int quantity, required Map<String, Object?> discount, int? payer}) => {
          'title': 'Abou Tarek',
          'expenseDate': '2026-11-20',
          'splitType': 'ITEMIZED',
          'items': [
            {'name': 'Koshary', 'quantity': quantity, 'unitAmountMinor': 4500, 'assigneeMemberIds': [you, ali]},
            {'name': 'Rice pudding', 'amountMinor': 2500, 'assigneeMemberIds': [ali]},
          ],
          'discount': discount,
          'service': {'amountMinor': 1500},
          'tax': {'bps': 1400, 'base': 'SUBTOTAL_PLUS_SERVICE'},
          if (payer != null) 'payers': [{'memberId': you, 'amountMinor': payer}],
        };

    Future<Map<String, dynamic>> preview(Map<String, Object?> body) async {
      final r = await http.post('/groups/$gid/expenses/preview', body);
      expect(r.statusCode, 200, reason: '${r.data}');
      return r.data as Map<String, dynamic>;
    }

    List<(Object?, Object?, Object?, Object?, Object?)> shares(List<dynamic> list) => [
          for (final s in list.cast<Map<String, dynamic>>())
            (s['memberId'], s['owedMinor'], s['discountMinor'], s['serviceMinor'], s['taxMinor']),
        ];

    test('create, edit and history keep quantity, discount and amount-form charges; preview equals the saved result', () async {
      final p1 = await preview(bill(quantity: 3, discount: {'amountMinor': 1600}));
      // Lines 13500 + 2500 = 16000; discount 1600 -> net 14400; service 1500 (amount).
      expect((p1['subtotalMinor'], p1['discountMinor'], p1['serviceMinor']), (16000, 1600, 1500));
      final created = await http.expense(gid, bill(quantity: 3, discount: {'amountMinor': 1600}, payer: p1['totalMinor'] as int));
      expect(created.statusCode, 201, reason: '${created.data}');
      final v1 = created.data as Map<String, dynamic>;
      expect(v1['totalMinor'], p1['totalMinor']);
      expect(shares(v1['shares'] as List), shares(p1['members'] as List));
      expect([for (final i in v1['items'] as List) (i['name'], i['quantity'], i['unitAmountMinor'], i['amountMinor'])],
          [('Koshary', 3, 4500, 13500), ('Rice pudding', 1, 2500, 2500)]);
      expect(v1['charges']['discount'], {'amountMinor': 1600});
      expect(v1['charges']['service'], {'amountMinor': 1500});
      expect((v1['charges']['tax']['bps'], v1['charges']['tax']['base']), (1400, 'SUBTOTAL_PLUS_SERVICE'));
      final eid = v1['id'] as String;
      expect((await http.get('/groups/$gid/expenses/$eid')).data, v1);

      // Edit: quantity 2, a 10% discount instead of the amount.
      final p2 = await preview(bill(quantity: 2, discount: {'bps': 1000}));
      expect((p2['subtotalMinor'], p2['discountMinor']), (11500, 1150));
      final edited = await http.put('/groups/$gid/expenses/$eid', bill(quantity: 2, discount: {'bps': 1000}, payer: p2['totalMinor'] as int),
          ifMatch: '"1"');
      expect(edited.statusCode, 200, reason: '${edited.data}');
      expect(shares(edited.data['shares'] as List), shares(p2['members'] as List));
      expect(edited.data['charges']['discount'], {'bps': 1000, 'amountMinor': 1150});

      final history = (await http.get('/groups/$gid/expenses/$eid/revisions')).data as List;
      expect([for (final r in history) r['version']], [1, 2]);
      final old = history[0]['snapshot'] as Map<String, dynamic>;
      expect(old['items'][0]['quantity'], 3);
      expect(old['charges']['discount'], {'amountMinor': 1600});
      expect(history[1]['snapshot']['items'][0]['quantity'], 2);
      expect(history[1]['snapshot']['charges']['discount'], {'bps': 1000, 'amountMinor': 1150});
    });

    test('a revision written before SA15 reads back as quantity 1 with no discount (A177)', () async {
      final created = await http.expense(gid, {
        'title': 'Old bill',
        'expenseDate': '2026-11-01',
        'splitType': 'ITEMIZED',
        'items': [
          {'name': 'Tea', 'amountMinor': 1000, 'assigneeMemberIds': [you, ali]},
        ],
        'payers': [{'memberId': you, 'amountMinor': 1000}],
      });
      expect(created.statusCode, 201);
      final eid = created.data['id'] as String;
      final profile = (await http.db.profileDao.find())!.id;
      // The SA3-SA14 snapshot shape: no quantity / unitAmountMinor / discountMinor, no charges.discount.
      const oldSnapshot = '{"id":"%E","groupId":"%G","title":"Old bill","splitType":"ITEMIZED","totalMinor":1000,'
          '"expenseDate":"2026-11-01","createdAt":"2026-11-17T10:00:00.000Z","version":2,"category":"OTHER",'
          '"paidFromPool":false,"payers":[{"memberId":"%Y","amountMinor":1000}],'
          '"shares":[{"memberId":"%Y","owedMinor":500,"itemsMinor":500,"serviceMinor":0,"taxMinor":0,"adjustmentMinor":0}],'
          '"items":[{"id":"%I","name":"Tea","amountMinor":1000,"assigneeMemberIds":["%Y"]}],'
          '"charges":{"subtotalMinor":1000,"adjustmentMinor":0}}';
      await http.db.revisionsDao.insertRevision(RevisionRow(
        id: '00000000-0000-4000-8000-00000000abcd',
        expenseId: eid,
        version: 2,
        changeType: 'UPDATE',
        snapshot: oldSnapshot
            .replaceAll('%E', eid)
            .replaceAll('%G', gid)
            .replaceAll('%Y', you)
            .replaceAll('%I', '00000000-0000-4000-8000-00000000abce'),
        changedByUserId: profile,
        changedAt: 1,
      ));
      final r = await http.get('/groups/$gid/expenses/$eid/revisions');
      expect(r.statusCode, 200, reason: '${r.data}');
      final snapshot = (r.data as List)[1]['snapshot'] as Map<String, dynamic>;
      expect((snapshot['items'][0]['quantity'], snapshot['items'][0]['unitAmountMinor']), (1, 1000));
      expect(snapshot['shares'][0]['discountMinor'], 0);
      expect(snapshot['charges'].containsKey('discount'), isFalse);
      expect(http.failures, isEmpty);
    });
  });
}
