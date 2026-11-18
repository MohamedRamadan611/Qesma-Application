import 'package:drift/drift.dart';
import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';

export 'package:qesma_engine/qesma_engine.dart'
    show
        TripRecapResult,
        TripRecapCategoryBreakdown,
        TripRecapTopPayer,
        TripRecapBiggestExpense,
        TripRecapMemberPaidTotal;

/// Repository for reading Trip Recap insights from the local database (STANDALONE_SPEC 9, Decision A132, A133, A149, A150).
/// Computes trip statistics over non-deleted expenses of a group.
/// If a group has no non-deleted expenses, returns null (spec: "a group with no expenses has no recap").
final class TripRecapRepository {
  TripRecapRepository(this._db);

  final LocalDatabase _db;

  Set<TableInfo<Table, dynamic>> get _readsFrom => {
        _db.expenses,
        _db.expensePayers,
        _db.members,
      };

  Future<TripRecapResult?> getTripRecap(String groupId) async {
    // 1. Fetch group members
    final memberRows = await (_db.select(_db.members)
          ..where((m) => m.groupId.equals(groupId))
          ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
        .get();

    if (memberRows.isEmpty) return null;

    // 2. Fetch non-deleted expenses
    final expenseRows = await (_db.select(_db.expenses)
          ..where((e) => e.groupId.equals(groupId) & e.deletedAt.isNull())
          ..orderBy([
            (e) => OrderingTerm.desc(e.expenseDate),
            (e) => OrderingTerm.desc(e.createdAt),
            (e) => OrderingTerm.desc(e.id),
          ]))
        .get();

    if (expenseRows.isEmpty) return null;

    // 3. Fetch payers for these expenses
    final expenseIds = expenseRows.map((e) => e.id).toList();
    // Chunked: older Android SQLite caps bound variables at 999 per statement.
    final payerRows = <PayerRow>[];
    for (var i = 0; i < expenseIds.length; i += 500) {
      final chunk = expenseIds.sublist(i, i + 500 > expenseIds.length ? expenseIds.length : i + 500);
      payerRows.addAll(await (_db.select(_db.expensePayers)..where((p) => p.expenseId.isIn(chunk))).get());
    }

    final payersByExpense = <String, List<TripRecapPayerInput>>{};
    for (final p in payerRows) {
      payersByExpense.putIfAbsent(p.expenseId, () => []).add(
            TripRecapPayerInput(
              memberId: p.memberId,
              amountMinor: p.amountMinor,
            ),
          );
    }

    final memberInputs = memberRows
        .map((m) => TripRecapMemberInput(
              memberId: m.id,
              displayName: m.displayName,
              sortOrder: m.sortOrder,
            ))
        .toList();

    final expenseInputs = expenseRows
        .map((e) => TripRecapExpenseInput(
              expenseId: e.id,
              title: e.title,
              totalMinor: e.totalMinor,
              expenseDate: e.expenseDate,
              createdAt: e.createdAt,
              category: e.category,
              payers: payersByExpense[e.id] ?? const [],
            ))
        .toList();

    return TripRecapCalculator.compute(
      members: memberInputs,
      expenses: expenseInputs,
    );
  }

  /// Live stream of Trip Recap updates for a group.
  Stream<TripRecapResult?> watchTripRecap(String groupId) {
    // Watch table updates for the relevant tables
    return _db
        .customSelect(
          'SELECT 1 FROM expenses WHERE group_id = ? AND deleted_at IS NULL LIMIT 1',
          variables: [Variable.withString(groupId)],
          readsFrom: _readsFrom,
        )
        .watch()
        .asyncMap((_) => getTripRecap(groupId));
  }
}
