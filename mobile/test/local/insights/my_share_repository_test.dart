import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/insights/my_share_repository.dart';

import '../db/support/local_db_fixture.dart';

void main() {
  late LocalDatabase db;
  late MyShareRepository repo;

  setUp(() {
    db = LocalDatabase.inMemory();
    repo = MyShareRepository(db);
  });

  tearDown(() => db.close());

  test('empty db yields empty sections', () async {
    final result = await repo.getMyShare();
    expect(result.sections, isEmpty);
  });

  test('profile with no expenses yields empty sections', () async {
    await seedGroup(db);
    final result = await repo.getMyShare();
    expect(result.sections, isEmpty);
  });

  test('aggregates non-deleted expenses for you across groups and currencies, excluding soft-deleted, settlements and other groups', () async {
    await seedGroup(db); // Group 1: Dahab (EGP), youId=tid(20), aliId=tid(21)

    // Group 2: Work (USD), with you as member
    final group2Id = tid(50);
    final youInGroup2Id = tid(51);
    await db.groupsDao.insertGroup(ExpenseGroupsCompanion.insert(
      id: group2Id,
      ownerUserId: profileId,
      name: 'Work Trip',
      type: 'TRIP',
      currencyCode: const Value('USD'),
      createdAt: t0,
      updatedAt: t0,
    ));
    await db.membersDao.insertMember(
      id: youInGroup2Id,
      groupId: group2Id,
      displayName: 'Mona',
      sortOrder: 1,
      createdAt: t0,
      userId: profileId,
      role: 'OWNER',
      joinedAt: t0,
    );

    // Group 3: Strangers (EGP), WITHOUT you
    final group3Id = tid(60);
    final stranger1Id = tid(61);
    final stranger2Id = tid(62);
    await db.groupsDao.insertGroup(ExpenseGroupsCompanion.insert(
      id: group3Id,
      ownerUserId: profileId, // even if owned, no member with userId = profileId
      name: 'Strangers',
      type: 'OTHER',
      createdAt: t0,
      updatedAt: t0,
    ));
    await db.membersDao.insertMember(id: stranger1Id, groupId: group3Id, displayName: 'Bob', sortOrder: 1, createdAt: t0);
    await db.membersDao.insertMember(id: stranger2Id, groupId: group3Id, displayName: 'Charlie', sortOrder: 2, createdAt: t0);

    // Expense in Group 3 (should be ignored)
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(100),
        groupId: group3Id,
        title: 'Stranger Expense',
        splitType: 'EQUAL',
        totalMinor: 10000,
        expenseDate: '2026-11-01',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'FOOD',
      ),
      payers: [PayerRow(expenseId: tid(100), memberId: stranger1Id, amountMinor: 10000)],
      splits: [
        SplitRow(expenseId: tid(100), memberId: stranger1Id, owedMinor: 5000),
        SplitRow(expenseId: tid(100), memberId: stranger2Id, owedMinor: 5000),
      ],
    ));

    // Expense 1: Group 1, 2026-11-10, FOOD. Total 30000. You paid 30000, you owed 15000.
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(101),
        groupId: groupId,
        title: 'Seafood Feast',
        splitType: 'EQUAL',
        totalMinor: 30000,
        expenseDate: '2026-11-10',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'FOOD',
      ),
      payers: [PayerRow(expenseId: tid(101), memberId: youId, amountMinor: 30000)],
      splits: [
        SplitRow(expenseId: tid(101), memberId: youId, owedMinor: 15000),
        SplitRow(expenseId: tid(101), memberId: aliId, owedMinor: 15000),
      ],
    ));

    // Expense 2: Group 1, 2026-11-12, FUEL. Total 5000. Ali paid 5000, you owed 2500.
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(102),
        groupId: groupId,
        title: 'Gas',
        splitType: 'EQUAL',
        totalMinor: 5000,
        expenseDate: '2026-11-12',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'FUEL',
      ),
      payers: [PayerRow(expenseId: tid(102), memberId: aliId, amountMinor: 5000)],
      splits: [
        SplitRow(expenseId: tid(102), memberId: youId, owedMinor: 2500),
        SplitRow(expenseId: tid(102), memberId: aliId, owedMinor: 2500),
      ],
    ));

    // Expense 3: Group 1, 2026-10-05, BILLS. You paid 20000, you owed 20000.
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(103),
        groupId: groupId,
        title: 'Internet',
        splitType: 'EXACT',
        totalMinor: 20000,
        expenseDate: '2026-10-05',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'BILLS',
      ),
      payers: [PayerRow(expenseId: tid(103), memberId: youId, amountMinor: 20000)],
      splits: [SplitRow(expenseId: tid(103), memberId: youId, owedMinor: 20000)],
    ));

    // Expense 4: Group 1, 2026-11-14, SHOPPING - Soft-deleted!
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(104),
        groupId: groupId,
        title: 'Deleted Clothes',
        splitType: 'EQUAL',
        totalMinor: 10000,
        expenseDate: '2026-11-14',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t0 + 1000,
        version: 2,
        category: 'SHOPPING',
      ),
      payers: [PayerRow(expenseId: tid(104), memberId: youId, amountMinor: 10000)],
      splits: [SplitRow(expenseId: tid(104), memberId: youId, owedMinor: 10000)],
    ));

    // Expense 5: Group 2 (USD), 2026-11-20, FOOD. You paid 4000, you owed 2000.
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(105),
        groupId: group2Id,
        title: 'NY Lunch',
        splitType: 'EQUAL',
        totalMinor: 4000,
        expenseDate: '2026-11-20',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'FOOD',
      ),
      payers: [PayerRow(expenseId: tid(105), memberId: youInGroup2Id, amountMinor: 4000)],
      splits: [SplitRow(expenseId: tid(105), memberId: youInGroup2Id, owedMinor: 2000)],
    ));

    // Settlement in Group 1 (should be ignored by My Share)
    await db.settlementsDao.insertSettlement(confirmedSettlement(tid(200), amount: 5000));

    final result = await repo.getMyShare();

    // Verify sections: EGP first, then USD
    expect(result.sections.length, equals(2));
    expect(result.sections[0].currencyCode, equals('EGP'));
    expect(result.sections[1].currencyCode, equals('USD'));

    // EGP months: 2026-11, 2026-10
    final egp = result.sections[0];
    expect(egp.months.length, equals(2));
    expect(egp.months[0].month, equals('2026-11'));
    expect(egp.months[1].month, equals('2026-10'));

    // 2026-11:
    // FOOD: consumed 15000, paid 30000
    // FUEL: consumed 2500, paid 0
    // Total consumed: 17500, paid: 30000
    // LRM bps: 15000 / 17500 * 10000 = 8571.42... -> 8571
    //           2500 / 17500 * 10000 = 1428.57... -> 1428
    // leftover = 1. Remainder: 2500*10000 % 17500 = 10000, 15000*10000 % 17500 = 10000.
    // Tied remainder -> lower sort order wins (FOOD has 0 < FUEL 2) -> FOOD gets +1 = 8572!
    final nov = egp.months[0];
    expect(nov.totalConsumedMinor, equals(17500));
    expect(nov.totalPaidUpFrontMinor, equals(30000));
    expect(nov.netDiffMinor, equals(12500));
    expect(nov.categories.length, equals(2));

    expect(nov.categories[0].category, equals('FOOD'));
    expect(nov.categories[0].consumedMinor, equals(15000));
    expect(nov.categories[0].paidUpFrontMinor, equals(30000));
    expect(nov.categories[0].percentageBps, equals(8571));
    expect(nov.categories[0].expenses.length, equals(1));
    expect(nov.categories[0].expenses[0].expenseId, equals(tid(101)));
    expect(nov.categories[0].expenses[0].groupName, equals('Dahab'));

    expect(nov.categories[1].category, equals('FUEL'));
    expect(nov.categories[1].consumedMinor, equals(2500));
    expect(nov.categories[1].paidUpFrontMinor, equals(0));
    expect(nov.categories[1].percentageBps, equals(1429));

    // USD month: 2026-11
    final usd = result.sections[1];
    expect(usd.months.length, equals(1));
    expect(usd.months[0].totalConsumedMinor, equals(2000));
    expect(usd.months[0].totalPaidUpFrontMinor, equals(4000));
    expect(usd.months[0].categories[0].category, equals('FOOD'));
    expect(usd.months[0].categories[0].percentageBps, equals(10000));
  });

  test('watchMyShare streams updates when an expense is added', () async {
    await seedGroup(db);

    final stream = repo.watchMyShare();

    expect(
      stream.map((r) => r.sections.isEmpty ? 0 : r.sections.first.months.first.totalConsumedMinor),
      emitsInOrder([
        0, // initially 0
        10000, // after inserting expense
      ]),
    );

    // Initial query has run; now insert an expense
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await db.expensesDao.insertGraph(ExpenseGraph(
      expense: ExpenseRow(
        id: tid(301),
        groupId: groupId,
        title: 'Dinner',
        splitType: 'EQUAL',
        totalMinor: 20000,
        expenseDate: '2026-11-15',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
        category: 'FOOD',
      ),
      payers: [PayerRow(expenseId: tid(301), memberId: youId, amountMinor: 20000)],
      splits: [
        SplitRow(expenseId: tid(301), memberId: youId, owedMinor: 10000),
        SplitRow(expenseId: tid(301), memberId: aliId, owedMinor: 10000),
      ],
    ));
  });
}
