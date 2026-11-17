import '../../core/api/uuid_v4.dart';
import '../db/local_database.dart';
import '../errors.dart';

/// What every local service shares: the database, the clock (UTC epoch ms, A151) and the id source (UUID v4).
final class LocalContext {
  LocalContext(this.db, {int Function()? clock, String Function()? newId})
      : clock = clock ?? utcNowMillis,
        newId = newId ?? newUuidV4;

  final LocalDatabase db;
  final int Function() clock;
  final String Function() newId;

  /// The one local user (A153). Before onboarding created it, every endpoint answers 401 (STANDALONE_SPEC 3.6).
  Future<LocalProfileRow> profile() async => await db.profileDao.find() ?? (throw LocalApiException.unauthorized());

  /// The group as the caller reaches it: through an ACTIVE member linked to the profile (ADR-009, invariant 7).
  /// An unknown group, or one the caller has no active member in, is the same 404. Locally that member is the
  /// OWNER of every group, so every permission of the role matrix is granted once membership holds.
  Future<GroupAccess> requireGroup(String groupId) async {
    final me = await profile();
    final group = await db.groupsDao.findById(groupId);
    if (group == null) throw LocalApiException.notFound();
    final members = await db.membersDao.listByGroup(groupId);
    final mine = members.where((m) => m.userId == me.id && m.status == 'ACTIVE');
    if (mine.isEmpty) throw LocalApiException.notFound();
    return GroupAccess(me, group, mine.first, members);
  }
}

/// A group the caller may use, with its roster in sortOrder (LEFT members included).
final class GroupAccess {
  const GroupAccess(this.profile, this.group, this.me, this.members);

  final LocalProfileRow profile;
  final GroupRow group;
  final MemberRow me;
  final List<MemberRow> members;

  Map<String, int> get sortOrders => {for (final m in members) m.id: m.sortOrder};

  MemberRow? member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}
