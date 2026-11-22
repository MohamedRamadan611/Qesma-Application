import 'package:drift/drift.dart';

import '../local_database.dart';

part 'groups_dao.g.dart';

/// Groups. Persistence primitives only; usage checks and versions are decided by the SA3 services.
@DriftAccessor(include: {'../schema.drift'})
class GroupsDao extends DatabaseAccessor<LocalDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  Future<void> insertGroup(ExpenseGroupsCompanion row) => into(expenseGroups).insert(row);

  Future<GroupRow?> findById(String id) =>
      (select(expenseGroups)..where((g) => g.id.equals(id))).getSingleOrNull();

  /// Newest first (A19), with `id` as the tie-break.
  Future<List<GroupRow>> listByOwner(String ownerUserId, {required int limit, required int offset}) =>
      (select(expenseGroups)
            ..where((g) => g.ownerUserId.equals(ownerUserId) & g.archivedAt.isNull())
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt), (g) => OrderingTerm.desc(g.id)])
            ..limit(limit, offset: offset))
          .get();

  /// Archived groups of the owner, most recently archived first.
  Future<List<GroupRow>> listArchived(String ownerUserId) => (select(expenseGroups)
        ..where((g) => g.ownerUserId.equals(ownerUserId) & g.archivedAt.isNotNull())
        ..orderBy([(g) => OrderingTerm.desc(g.archivedAt), (g) => OrderingTerm.desc(g.id)]))
      .get();

  /// Sets or clears the archive time. Not a content edit, so `version` and `updated_at` stay as they are.
  Future<void> setArchivedAt(String groupId, int? archivedAt) =>
      (update(expenseGroups)..where((g) => g.id.equals(groupId))).write(ExpenseGroupsCompanion(archivedAt: Value(archivedAt)));

  Future<int> countByOwner(String ownerUserId) {
    final n = expenseGroups.id.count();
    return (selectOnly(expenseGroups)
          ..addColumns([n])
          ..where(expenseGroups.ownerUserId.equals(ownerUserId) & expenseGroups.archivedAt.isNull()))
        .map((r) => r.read(n)!)
        .getSingle();
  }

  /// Writes [changes] only while the stored version is [expectedVersion]; returns the rows changed (0 = stale).
  Future<int> updateIfVersion(String id, int expectedVersion, ExpenseGroupsCompanion changes) =>
      (update(expenseGroups)..where((g) => g.id.equals(id) & g.version.equals(expectedVersion))).write(changes);

  /// Moves the per-group member counter (A20) and returns its new value; the counter never goes back.
  Future<int> nextMemberSeq(String groupId) async {
    final rows = await customWriteReturning(
      'UPDATE expense_groups SET member_seq = member_seq + 1 WHERE id = ? RETURNING member_seq',
      variables: [Variable.withString(groupId)],
      updates: {expenseGroups},
    );
    if (rows.isEmpty) throw StateError('unknown group $groupId');
    return rows.single.read<int>('member_seq');
  }

  /// Hard delete of a group and its members (A23), in one transaction. Fails at the foreign keys if any
  /// ledger row still references them; the "unused" decision belongs to the service.
  Future<void> deleteGroupWithMembers(String groupId) => transaction(() async {
        // The treasurer reference points into members (circular FK): drop it first.
        await (update(expenseGroups)..where((g) => g.id.equals(groupId)))
            .write(const ExpenseGroupsCompanion(treasurerMemberId: Value(null)));
        await (delete(members)..where((m) => m.groupId.equals(groupId))).go();
        await (delete(expenseGroups)..where((g) => g.id.equals(groupId))).go();
      });

  /// Hard delete of a group together with ALL of its ledger rows (expenses with their payers, splits, items,
  /// assignees and revisions, and settlements), in one transaction and in foreign-key order. Only for a group whose
  /// balances the service has checked to be zero (settled); the caller decides, this only removes.
  Future<void> deleteGroupWithLedger(String groupId) => transaction(() async {
        Future<void> run(String sql) => customStatement(sql, [groupId]);
        const expenseIds = 'SELECT id FROM expenses WHERE group_id = ?';
        await run('DELETE FROM expense_item_assignees WHERE item_id IN (SELECT id FROM expense_items WHERE expense_id IN ($expenseIds))');
        await run('DELETE FROM expense_items WHERE expense_id IN ($expenseIds)');
        await run('DELETE FROM expense_splits WHERE expense_id IN ($expenseIds)');
        await run('DELETE FROM expense_payers WHERE expense_id IN ($expenseIds)');
        await run('DELETE FROM expense_revisions WHERE expense_id IN ($expenseIds)');
        await run('DELETE FROM expenses WHERE group_id = ?');
        await run('DELETE FROM settlements WHERE group_id = ?');
        await deleteGroupWithMembers(groupId);
      });
}
