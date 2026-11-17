import 'package:drift/drift.dart';

import '../local_database.dart';
import '../name_key.dart';

part 'members_dao.g.dart';

/// Members. `name_key` is always derived here from the display name by [memberNameKey], so a caller
/// cannot store a key that disagrees with the name.
@DriftAccessor(include: {'../schema.drift'})
class MembersDao extends DatabaseAccessor<LocalDatabase> with _$MembersDaoMixin {
  MembersDao(super.db);

  Future<void> insertMember({
    required String id,
    required String groupId,
    required String displayName,
    required int sortOrder,
    required int createdAt,
    String? userId,
    String role = 'MEMBER',
    int? joinedAt,
  }) =>
      into(members).insert(MembersCompanion.insert(
        id: id,
        groupId: groupId,
        displayName: displayName,
        nameKey: memberNameKey(displayName),
        userId: Value(userId),
        sortOrder: sortOrder,
        role: Value(role),
        joinedAt: Value(joinedAt),
        createdAt: createdAt,
      ));

  Future<MemberRow?> findById(String id) => (select(members)..where((m) => m.id.equals(id))).getSingleOrNull();

  /// The member whose normalized name equals that of [displayName], if any.
  Future<MemberRow?> findByName(String groupId, String displayName) => (select(members)
        ..where((m) => m.groupId.equals(groupId) & m.nameKey.equals(memberNameKey(displayName))))
      .getSingleOrNull();

  Future<List<MemberRow>> listByGroup(String groupId) => (select(members)
        ..where((m) => m.groupId.equals(groupId))
        ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
      .get();

  /// Number of rows changed (0 when [id] is unknown).
  Future<int> rename(String id, String displayName) => (update(members)..where((m) => m.id.equals(id)))
      .write(MembersCompanion(displayName: Value(displayName), nameKey: Value(memberNameKey(displayName))));

  /// Hard delete (A23); fails at the foreign keys if the member is referenced by the ledger.
  Future<int> deleteMember(String id) => (delete(members)..where((m) => m.id.equals(id))).go();
}
