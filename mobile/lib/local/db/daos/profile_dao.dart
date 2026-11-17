import 'package:drift/drift.dart';

import '../local_database.dart';

part 'profile_dao.g.dart';

/// The single local profile (the local user). Persistence only.
@DriftAccessor(include: {'../schema.drift'})
class ProfileDao extends DatabaseAccessor<LocalDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Future<LocalProfileRow?> find() => select(localProfile).getSingleOrNull();

  Future<void> insertProfile(LocalProfileCompanion row) => into(localProfile).insert(row);

  /// Number of rows changed (0 when [id] is unknown).
  Future<int> rename(String id, String displayName, int updatedAt) =>
      (update(localProfile)..where((p) => p.id.equals(id)))
          .write(LocalProfileCompanion(displayName: Value(displayName), updatedAt: Value(updatedAt)));
}
