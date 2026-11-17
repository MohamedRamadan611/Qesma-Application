import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/insights/trip_recap_repository.dart';

import '../db/support/local_db_fixture.dart';

void main() {
  late LocalDatabase db;
  late TripRecapRepository repo;

  setUp(() {
    db = LocalDatabase.inMemory();
    repo = TripRecapRepository(db);
  });

  tearDown(() => db.close());

  test('group with no expenses returns null (no expenses -> no recap)', () async {
    await seedGroup(db);
    final result = await repo.getTripRecap(groupId);
    expect(result, isNull);
  });

  test('non-existent group returns null', () async {
    final result = await repo.getTripRecap(tid(999));
    expect(result, isNull);
  });

  test('computes trip recap for non-deleted expenses, excluding soft-deleted ones', () async {
    await seedGroup(db);

    // Expense 1: Taxi (Transport), 10,000 minor, paid by youId
    await db.expensesDao.insertGraph(
      equalExpense(tid(101), total: 10000),
    );

    // Expense 2: Dinner (Food), 30,000 minor, paid by aliId
    await db.expensesDao.insertGraph(
      ExpenseGraph(
        expense: ExpenseRow(
          id: tid(102),
          groupId: groupId,
          title: 'Dinner',
          splitType: 'EQUAL',
          totalMinor: 30000,
          expenseDate: '2025-11-18',
          createdByUserId: profileId,
          createdAt: t0 + 1000,
          updatedAt: t0 + 1000,
          version: 1,
          category: 'FOOD',
        ),
        payers: [
          PayerRow(expenseId: tid(102), memberId: aliId, amountMinor: 30000),
        ],
        splits: [
          SplitRow(expenseId: tid(102), memberId: youId, owedMinor: 15000),
          SplitRow(expenseId: tid(102), memberId: aliId, owedMinor: 15000),
        ],
      ),
    );

    // Expense 3: Deleted expense (Fuel), 20,000 minor -> soft-deleted
    await db.expensesDao.insertGraph(
      ExpenseGraph(
        expense: ExpenseRow(
          id: tid(103),
          groupId: groupId,
          title: 'Fuel Deleted',
          splitType: 'EQUAL',
          totalMinor: 20000,
          expenseDate: '2025-11-17',
          createdByUserId: profileId,
          createdAt: t0 + 500,
          updatedAt: t0 + 500,
          version: 1,
          category: 'FUEL',
        ),
        payers: [
          PayerRow(expenseId: tid(103), memberId: youId, amountMinor: 20000),
        ],
        splits: [
          SplitRow(expenseId: tid(103), memberId: youId, owedMinor: 20000),
        ],
      ),
    );
    await db.expensesDao.softDeleteIfVersion(tid(103), 1, deletedAt: t0 + 600, newVersion: 2);

    final result = await repo.getTripRecap(groupId);
    expect(result, isNotNull);
    expect(result!.totalSpentMinor, equals(40000));
    expect(result.expenseCount, equals(2));
    expect(result.dateRangeStart, equals('2025-11-16'));
    expect(result.dateRangeEnd, equals('2025-11-18'));

    // Top payer is Ali (30,000 > 10,000)
    expect(result.topPayer.memberId, equals(aliId));
    expect(result.topPayer.displayName, equals('Ali'));
    expect(result.topPayer.amountPaidMinor, equals(30000));

    // Biggest expense is Dinner (30,000)
    expect(result.biggestExpense.expenseId, equals(tid(102)));
    expect(result.biggestExpense.title, equals('Dinner'));
    expect(result.biggestExpense.totalMinor, equals(30000));

    // Category breakdown
    final food = result.categoryBreakdown.firstWhere((c) => c.category == 'FOOD');
    final transport = result.categoryBreakdown.firstWhere((c) => c.category == 'TRANSPORT');
    final fuel = result.categoryBreakdown.firstWhere((c) => c.category == 'FUEL');

    expect(food.totalMinor, equals(30000));
    expect(food.percentageBps, equals(7500));
    expect(transport.totalMinor, equals(10000));
    expect(transport.percentageBps, equals(2500));
    expect(fuel.totalMinor, equals(0));
    expect(fuel.percentageBps, equals(0));

    final totalBps = result.categoryBreakdown.fold<int>(0, (acc, c) => acc + c.percentageBps);
    expect(totalBps, equals(10000));
  });

  test('watchTripRecap emits updates as new expenses are added', () async {
    await seedGroup(db);

    final stream = repo.watchTripRecap(groupId);
    final emissions = <TripRecapResult?>[];
    final sub = stream.listen(emissions.add);

    // Initial state: no expenses -> null
    await pumpEventQueue();
    expect(emissions.last, isNull);

    // Add expense
    await db.expensesDao.insertGraph(
      equalExpense(tid(201), total: 5000),
    );
    await pumpEventQueue();

    expect(emissions.last, isNotNull);
    expect(emissions.last!.totalSpentMinor, equals(5000));

    await sub.cancel();
  });
}
