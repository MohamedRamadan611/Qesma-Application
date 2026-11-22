import '../db/local_database.dart';
import 'group_service.dart';
import 'ledger.dart';
import 'local_context.dart';

/// One archived group as the Archive screen shows it.
final class ArchivedGroup {
  const ArchivedGroup({required this.id, required this.name, required this.type, required this.archivedAt, required this.deletesAt, required this.totalSpentMinor});

  final String id;
  final String name;
  final String type;

  /// UTC epoch ms.
  final int archivedAt;

  /// UTC epoch ms: when the group is deleted for good (archived time + the retention period).
  final int deletesAt;
  final int totalSpentMinor;
}

/// A184: the archive of settled groups, for the app's own screens (not part of the HTTP contract).
/// Archived groups are hidden from the groups list; each is deleted, with its whole ledger, once the retention
/// period (7, 15 or 30 days, set in Account) has passed. A group that stopped being settled meanwhile is restored
/// instead of deleted, so open money is never removed.
final class ArchiveService {
  ArchiveService(this._ctx)
      : _groups = GroupService(_ctx),
        _ledger = Ledger(_ctx.db);

  final LocalContext _ctx;
  final GroupService _groups;
  final Ledger _ledger;

  static const int dayMillis = 24 * 60 * 60 * 1000;
  static const Set<int> retentionOptions = {7, 15, 30};

  LocalDatabase get _db => _ctx.db;

  Future<int> retentionDays() async => (await _db.metaDao.get()).archiveRetentionDays;

  Future<void> setRetentionDays(int days) async {
    if (!retentionOptions.contains(days)) throw ArgumentError.value(days, 'days', 'must be 7, 15 or 30');
    await _db.metaDao.setArchiveRetentionDays(days);
  }

  Future<List<ArchivedGroup>> list() async {
    final me = await _db.profileDao.find();
    if (me == null) return const [];
    final days = await retentionDays();
    final rows = await _db.groupsDao.listArchived(me.id);
    return [
      for (final g in rows)
        ArchivedGroup(
          id: g.id,
          name: g.name,
          type: g.type,
          archivedAt: g.archivedAt!,
          deletesAt: g.archivedAt! + days * dayMillis,
          totalSpentMinor: (await _ledger.groupTotals(g.id)).totalSpentMinor,
        ),
    ];
  }

  Future<void> archive(String groupId) => _groups.archive(groupId);

  Future<void> restore(String groupId) => _groups.restore(groupId);

  /// Deletes an archived (or any settled) group now, with its whole ledger (A183).
  Future<void> deleteNow(String groupId) => _groups.delete(groupId);

  /// Deletes every archived group whose retention period is over; returns how many were deleted. One that is no
  /// longer settled is brought back to the list instead. Safe to call often.
  Future<int> purgeExpired() async {
    final me = await _db.profileDao.find();
    if (me == null) return 0;
    final cutoff = _ctx.clock() - (await retentionDays()) * dayMillis;
    var deleted = 0;
    for (final g in await _db.groupsDao.listArchived(me.id)) {
      if (g.archivedAt! > cutoff) continue;
      if (await _groups.isSettled(g.id)) {
        await _groups.delete(g.id);
        deleted++;
      } else {
        await _groups.restore(g.id);
      }
    }
    return deleted;
  }
}
