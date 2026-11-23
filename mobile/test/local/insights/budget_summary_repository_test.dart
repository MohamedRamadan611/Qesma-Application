import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/insights/budget_summary_repository.dart';

import '../db/support/local_db_fixture.dart';

/// SA20 (STANDALONE_SPEC 20.2, A191): the budget read-model over the real local schema.
void main() {
  late LocalDatabase db;
  late BudgetSummaryRepository repo;
  const today = '2025-11-17';

  setUp(() async {
    db = LocalDatabase.inMemory();
    repo = BudgetSummaryRepository(db);
    await seedGroup(db);
  });

  tearDown(() => db.close());

  Future<void> setBudget(int? budget, {String? start, String? end}) => raw(
      db,
      'UPDATE expense_groups SET budget_minor = ?, trip_start_date = ?, trip_end_date = ? WHERE id = ?',
      [budget, start, end, groupId]);

  ExpenseGraph dated(String id, int total, String date, {bool pool = false}) {
    final g = equalExpense(id, total: total);
    return ExpenseGraph(
      expense: g.expense.copyWith(expenseDate: date, paidFromPool: pool ? 1 : 0),
      payers: g.payers,
      splits: g.splits,
    );
  }

  test('no budget set -> null; unknown group -> null', () async {
    await db.expensesDao.insertGraph(equalExpense(tid(101)));
    expect(await repo.summary(groupId, today), isNull);
    expect(await repo.summary(tid(999), today), isNull);
  });

  test('pool expense counted once; pool deposit and payment never count (A191)', () async {
    await raw(db, 'UPDATE expense_groups SET treasurer_member_id = ? WHERE id = ?', [youId, groupId]);
    await setBudget(1000000);
    await db.settlementsDao.insertSettlement(
        confirmedSettlement(tid(201), from: aliId, to: youId, amount: 300000).copyWith(kind: 'POOL_DEPOSIT'));
    await db.settlementsDao.insertSettlement(confirmedSettlement(tid(202), from: saraId, to: youId, amount: 4000));
    await db.expensesDao.insertGraph(dated(tid(101), 120000, '2025-11-16', pool: true));

    final s = (await repo.summary(groupId, today))!;
    expect(s.spentMinor, 120000);
    expect(s.remainingMinor, 880000);
    expect(s.progressBps, 1200);
    expect(s.perDay.map((d) => (d.date, d.totalMinor)), [('2025-11-16', 120000)]);
  });

  test('soft-deleted expenses are ignored; an edited expense counts its current total once', () async {
    await setBudget(500000);
    await db.expensesDao.insertGraph(dated(tid(101), 100000, '2025-11-10'));
    await db.expensesDao.insertGraph(dated(tid(102), 100000, '2025-11-16'));
    expect(await db.expensesDao.softDeleteIfVersion(tid(101), 1, deletedAt: t0, newVersion: 2), 1);
    final edited = dated(tid(102), 75000, '2025-11-16');
    expect(
      await db.expensesDao.replaceGraphIfVersion(
          ExpenseGraph(expense: edited.expense.copyWith(version: 2), payers: edited.payers, splits: edited.splits), 1),
      isTrue,
    );

    final s = (await repo.summary(groupId, today))!;
    expect(s.spentMinor, 75000);
    expect(s.perDay.map((d) => (d.date, d.totalMinor)), [('2025-11-16', 75000)]);
    // The deleted expense's date does not widen the no-start-date range.
    expect((s.elapsedDays, s.dailyAverageMinor), (1, 75000));
  });

  test('a LEFT member is not counted in the cost per head', () async {
    await setBudget(10000);
    expect((await repo.summary(groupId, today))!.costPerHeadMinor, 3334); // 3 ACTIVE
    // Local mode cannot make a LEFT member (it needs a linked account); only restored data can. FKs off for this row.
    await raw(db, 'PRAGMA foreign_keys = OFF');
    await raw(db, "UPDATE members SET status = 'LEFT', left_at = ?, user_id = ? WHERE id = ?", [t0, tid(2), saraId]);
    expect((await repo.summary(groupId, today))!.costPerHeadMinor, 5000); // 2 ACTIVE
  });

  test('trip dates feed the daily average and per day left; today is passed in', () async {
    await setBudget(1000000, start: '2025-11-16', end: '2025-11-20');
    await db.expensesDao.insertGraph(dated(tid(101), 150000, '2025-11-16'));
    await db.expensesDao.insertGraph(dated(tid(102), 250000, '2025-11-17'));

    final s = (await repo.summary(groupId, '2025-11-17'))!;
    expect((s.elapsedDays, s.dailyAverageMinor, s.daysLeft, s.perDayLeftMinor), (2, 200000, 4, 150000));
    final later = (await repo.summary(groupId, '2025-11-25'))!;
    expect((later.elapsedDays, later.daysLeft, later.perDayLeftMinor), (5, null, null));
  });

  test('over budget is reported with the amount over', () async {
    await setBudget(100000);
    await db.expensesDao.insertGraph(dated(tid(101), 125050, '2025-11-16'));
    final s = (await repo.summary(groupId, today))!;
    expect((s.overBudget, s.overByMinor, s.remainingMinor, s.progressBps, s.barFillBps), (true, 25050, -25050, 12505, 10000));
  });

  test('watch re-emits after a new expense and after the budget is cleared', () async {
    await setBudget(100000);
    final stream = repo.watch(groupId, today);
    final seen = <int?>[];
    final sub = stream.listen((s) => seen.add(s?.spentMinor));
    await pumpEventQueue();
    await db.expensesDao.insertGraph(dated(tid(101), 4000, '2025-11-16'));
    await pumpEventQueue();
    // Typed update, as the group service does (a raw statement would not notify drift streams).
    await (db.update(db.expenseGroups)..where((g) => g.id.equals(groupId)))
        .write(const ExpenseGroupsCompanion(budgetMinor: Value(null)));
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen, contains(4000));
    expect(seen.last, isNull);
  });
}
