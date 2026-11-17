import 'package:drift/drift.dart';

import '../local_database.dart';

part 'expenses_dao.g.dart';

/// One expense with all its child rows, as stored.
class ExpenseGraph {
  const ExpenseGraph({
    required this.expense,
    required this.payers,
    required this.splits,
    this.items = const [],
    this.assignees = const [],
  });

  final ExpenseRow expense;
  final List<PayerRow> payers;
  final List<SplitRow> splits;
  final List<ItemRow> items;
  final List<AssigneeRow> assignees;
}

/// Expenses and their children. Persistence primitives only: the service (SA3) validates, computes the
/// splits with qesma_engine, decides versions and writes the revision in the same transaction.
@DriftAccessor(include: {'../schema.drift'})
class ExpensesDao extends DatabaseAccessor<LocalDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  /// Inserts the expense row and every child row in one transaction.
  Future<void> insertGraph(ExpenseGraph graph) => transaction(() async {
        await into(expenses).insert(graph.expense);
        await _insertChildren(graph);
      });

  /// Replaces the expense row and all its children while the stored version is [expectedVersion].
  /// Returns false (and writes nothing) when the version is stale or the expense is unknown.
  Future<bool> replaceGraphIfVersion(ExpenseGraph graph, int expectedVersion) => transaction(() async {
        final e = graph.expense;
        // toCompanion(false): null columns are written as NULL (a row object alone would leave them unchanged).
        final changed = await (update(expenses)..where((x) => x.id.equals(e.id) & x.version.equals(expectedVersion)))
            .write(e.toCompanion(false));
        if (changed == 0) return false;
        await _deleteChildren(e.id);
        await _insertChildren(graph);
        return true;
      });

  /// Soft delete: sets `deleted_at` and `version` while the stored version is [expectedVersion] and the
  /// expense is live. Children stay for history. Returns the rows changed (0 = stale, unknown or deleted).
  Future<int> softDeleteIfVersion(String id, int expectedVersion,
          {required int deletedAt, required int newVersion}) =>
      (update(expenses)
            ..where((x) => x.id.equals(id) & x.version.equals(expectedVersion) & x.deletedAt.isNull()))
          .write(ExpensesCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
        version: Value(newVersion),
      ));

  /// The expense row, deleted ones included (history stays readable).
  Future<ExpenseRow?> findById(String id) => (select(expenses)..where((x) => x.id.equals(id))).getSingleOrNull();

  /// The expense with its children, deleted ones included.
  Future<ExpenseGraph?> loadGraph(String id) async {
    final expense = await findById(id);
    if (expense == null) return null;
    final payers = await (select(expensePayers)..where((p) => p.expenseId.equals(id))).get();
    final splits = await (select(expenseSplits)..where((s) => s.expenseId.equals(id))).get();
    final items = await (select(expenseItems)
          ..where((i) => i.expenseId.equals(id))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .get();
    final assignees = await (select(expenseItemAssignees).join([
      innerJoin(expenseItems, expenseItems.id.equalsExp(expenseItemAssignees.itemId)),
    ])
          ..where(expenseItems.expenseId.equals(id)))
        .map((r) => r.readTable(expenseItemAssignees))
        .get();
    return ExpenseGraph(expense: expense, payers: payers, splits: splits, items: items, assignees: assignees);
  }

  /// Live expenses of a group, newest `expenseDate` first, then `createdAt`, then id.
  Future<List<ExpenseRow>> listLive(String groupId, {required int limit, required int offset}) => (select(expenses)
        ..where((x) => x.groupId.equals(groupId) & x.deletedAt.isNull())
        ..orderBy([
          (x) => OrderingTerm.desc(x.expenseDate),
          (x) => OrderingTerm.desc(x.createdAt),
          (x) => OrderingTerm.desc(x.id),
        ])
        ..limit(limit, offset: offset))
      .get();

  Future<int> countLive(String groupId) {
    final n = expenses.id.count();
    return (selectOnly(expenses)
          ..addColumns([n])
          ..where(expenses.groupId.equals(groupId) & expenses.deletedAt.isNull()))
        .map((r) => r.read(n)!)
        .getSingle();
  }

  Future<void> _insertChildren(ExpenseGraph graph) async {
    await batch((b) {
      b.insertAll(expensePayers, graph.payers);
      b.insertAll(expenseSplits, graph.splits);
      b.insertAll(expenseItems, graph.items);
      b.insertAll(expenseItemAssignees, graph.assignees);
    });
  }

  Future<void> _deleteChildren(String expenseId) async {
    final itemIds = selectOnly(expenseItems)
      ..addColumns([expenseItems.id])
      ..where(expenseItems.expenseId.equals(expenseId));
    await (delete(expenseItemAssignees)..where((a) => a.itemId.isInQuery(itemIds))).go();
    await (delete(expenseItems)..where((i) => i.expenseId.equals(expenseId))).go();
    await (delete(expenseSplits)..where((s) => s.expenseId.equals(expenseId))).go();
    await (delete(expensePayers)..where((p) => p.expenseId.equals(expenseId))).go();
  }
}
