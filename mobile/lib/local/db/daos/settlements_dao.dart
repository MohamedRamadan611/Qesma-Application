import 'package:drift/drift.dart';

import '../local_database.dart';

part 'settlements_dao.g.dart';

/// Settlements. Never deleted: a cancel is a status write decided by the service (A87).
@DriftAccessor(include: {'../schema.drift'})
class SettlementsDao extends DatabaseAccessor<LocalDatabase> with _$SettlementsDaoMixin {
  SettlementsDao(super.db);

  Future<void> insertSettlement(SettlementRow row) => into(settlements).insert(row);

  Future<SettlementRow?> findById(String id) =>
      (select(settlements)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Newest `settledOn` first, then `createdAt`, then id; [statuses] empty = every status.
  Future<List<SettlementRow>> listByGroup(
    String groupId, {
    required int limit,
    required int offset,
    List<String> statuses = const [],
  }) =>
      (select(settlements)
            ..where((s) => s.groupId.equals(groupId) & (statuses.isEmpty ? const Constant(true) : s.status.isIn(statuses)))
            ..orderBy([
              (s) => OrderingTerm.desc(s.settledOn),
              (s) => OrderingTerm.desc(s.createdAt),
              (s) => OrderingTerm.desc(s.id),
            ])
            ..limit(limit, offset: offset))
          .get();

  Future<int> countByGroup(String groupId, {List<String> statuses = const []}) {
    final n = settlements.id.count();
    return (selectOnly(settlements)
          ..addColumns([n])
          ..where(settlements.groupId.equals(groupId) &
              (statuses.isEmpty ? const Constant(true) : settlements.status.isIn(statuses))))
        .map((r) => r.read(n)!)
        .getSingle();
  }

  /// Writes a status change only while the stored status is [expectedStatus]; returns the rows changed.
  Future<int> updateStatus(String id, String expectedStatus, SettlementsCompanion changes) =>
      (update(settlements)..where((s) => s.id.equals(id) & s.status.equals(expectedStatus))).write(changes);
}
