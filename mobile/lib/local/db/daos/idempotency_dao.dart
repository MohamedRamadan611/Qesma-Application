import 'package:drift/drift.dart';

import '../local_database.dart';

part 'idempotency_dao.g.dart';

/// Stored responses of idempotent creates (spec 8.3). The comparison and replay logic is the service's (SA3).
@DriftAccessor(include: {'../schema.drift'})
class IdempotencyDao extends DatabaseAccessor<LocalDatabase> with _$IdempotencyDaoMixin {
  IdempotencyDao(super.db);

  Future<IdempotencyRow?> find(String key) =>
      (select(idempotencyKeys)..where((k) => k.key.equals(key))).getSingleOrNull();

  Future<void> insertKey(IdempotencyRow row) => into(idempotencyKeys).insert(row);

  /// Retention purge (24 hours, at app start): deletes keys created before [cutoffMillis].
  Future<int> deleteCreatedBefore(int cutoffMillis) =>
      (delete(idempotencyKeys)..where((k) => k.createdAt.isSmallerThanValue(cutoffMillis))).go();
}
