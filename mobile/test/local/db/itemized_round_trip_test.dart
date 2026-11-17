import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';

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
}
