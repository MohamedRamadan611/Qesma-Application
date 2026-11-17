import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/local_database.dart';

import 'support/local_db_fixture.dart';

/// The ledger is never hard-deleted (invariant 5): soft-deleted expenses and cancelled settlements stay readable
/// with their children and history, and only leave the live lists.
void main() {
  late LocalDatabase db;

  setUp(() async {
    db = LocalDatabase.inMemory();
    await seedGroup(db);
  });
  tearDown(() => db.close());

  test('a soft-deleted expense keeps its row, children and revisions', () async {
    await db.expensesDao.insertGraph(itemizedExpense(tid(101)));
    await db.revisionsDao.insertRevision(revision(tid(400), tid(101), 1, 'CREATE'));

    expect(await db.expensesDao.softDeleteIfVersion(tid(101), 1, deletedAt: t0 + 5, newVersion: 2), 1);
    await db.revisionsDao.insertRevision(revision(tid(401), tid(101), 2, 'DELETE'));

    expect(await db.expensesDao.listLive(groupId, limit: 20, offset: 0), isEmpty);
    expect(await db.expensesDao.countLive(groupId), 0);

    final graph = (await db.expensesDao.loadGraph(tid(101)))!;
    expect(graph.expense.deletedAt, t0 + 5);
    expect(graph.expense.version, 2);
    expect(graph.items, hasLength(2));
    expect(graph.splits, hasLength(3));
    expect((await db.revisionsDao.listByExpense(tid(101))).map((r) => r.changeType), ['CREATE', 'DELETE']);
  });

  test('a stale version or an already deleted expense changes nothing', () async {
    await db.expensesDao.insertGraph(equalExpense(tid(100)));
    expect(await db.expensesDao.softDeleteIfVersion(tid(100), 7, deletedAt: t0, newVersion: 8), 0);
    expect(await db.expensesDao.softDeleteIfVersion(tid(100), 1, deletedAt: t0, newVersion: 2), 1);
    expect(await db.expensesDao.softDeleteIfVersion(tid(100), 2, deletedAt: t0, newVersion: 3), 0);
  });

  test('a cancelled settlement stays listed with its status', () async {
    await db.settlementsDao.insertSettlement(confirmedSettlement(tid(300)));
    final changed = await db.settlementsDao.updateStatus(
      tid(300),
      'CONFIRMED',
      const SettlementsCompanion(status: Value('CANCELLED'), confirmedAt: Value(null), cancelledAt: Value(t0 + 9)),
    );
    expect(changed, 1);
    final list = await db.settlementsDao.listByGroup(groupId, limit: 20, offset: 0);
    expect(list.single.status, 'CANCELLED');
    expect(await db.settlementsDao.countByGroup(groupId, statuses: ['CONFIRMED']), 0);
  });
}
