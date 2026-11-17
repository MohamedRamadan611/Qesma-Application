import 'package:drift/drift.dart';

import '../local_database.dart';

part 'revisions_dao.g.dart';

/// Expense revisions are append-only: this DAO inserts and reads, nothing else (a trigger also refuses UPDATE).
@DriftAccessor(include: {'../schema.drift'})
class RevisionsDao extends DatabaseAccessor<LocalDatabase> with _$RevisionsDaoMixin {
  RevisionsDao(super.db);

  Future<void> insertRevision(RevisionRow row) => into(expenseRevisions).insert(row);

  /// Oldest first.
  Future<List<RevisionRow>> listByExpense(String expenseId) => (select(expenseRevisions)
        ..where((r) => r.expenseId.equals(expenseId))
        ..orderBy([(r) => OrderingTerm.asc(r.version)]))
      .get();
}
