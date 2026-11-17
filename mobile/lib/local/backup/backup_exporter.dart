import 'package:drift/drift.dart';

import '../db/local_database.dart';
import 'backup_format.dart';

/// Reads the whole ledger in one transaction (a consistent snapshot) and turns it into the backup document.
/// Idempotency keys and `local_meta` are deliberately not read.
final class BackupExporter {
  BackupExporter(this._db, {required this.appVersion, int Function()? clock}) : _clock = clock ?? utcNowMillis;

  final LocalDatabase _db;
  final String appVersion;
  final int Function() _clock;

  Future<BackupData> read() => _db.transaction(() async {
        final profile = await _db.profileDao.find();
        if (profile == null) throw const BackupException(BackupError.invalid, 'profile');
        return BackupData(
          formatVersion: backupFormatVersion,
          schemaVersion: _db.schemaVersion,
          exportedAt: _clock(),
          appVersion: appVersion,
          profile: profile,
          paymentHandles: await (_db.select(_db.paymentHandles)..orderBy([(t) => _asc(t.id)])).get(),
          groups: await (_db.select(_db.expenseGroups)..orderBy([(t) => _asc(t.createdAt), (t) => _asc(t.id)])).get(),
          members: await (_db.select(_db.members)..orderBy([(t) => _asc(t.groupId), (t) => _asc(t.sortOrder)])).get(),
          expenses: await (_db.select(_db.expenses)..orderBy([(t) => _asc(t.createdAt), (t) => _asc(t.id)])).get(),
          payers: await (_db.select(_db.expensePayers)..orderBy([(t) => _asc(t.expenseId), (t) => _asc(t.memberId)])).get(),
          splits: await (_db.select(_db.expenseSplits)..orderBy([(t) => _asc(t.expenseId), (t) => _asc(t.memberId)])).get(),
          items: await (_db.select(_db.expenseItems)..orderBy([(t) => _asc(t.expenseId), (t) => _asc(t.sortOrder)])).get(),
          assignees:
              await (_db.select(_db.expenseItemAssignees)..orderBy([(t) => _asc(t.itemId), (t) => _asc(t.memberId)])).get(),
          revisions: await (_db.select(_db.expenseRevisions)..orderBy([(t) => _asc(t.expenseId), (t) => _asc(t.version)])).get(),
          settlements: await (_db.select(_db.settlements)..orderBy([(t) => _asc(t.createdAt), (t) => _asc(t.id)])).get(),
        );
      });
}

OrderingTerm _asc(Expression<Object> column) => OrderingTerm.asc(column);
