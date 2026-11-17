import '../db/local_database.dart';
import 'backup_format.dart';
import 'backup_validator.dart';

/// Replace-all import (STANDALONE_SPEC 6.2): wipes the ledger and writes the file's rows in ONE transaction. The data
/// must already have passed [BackupValidator]; this class re-runs the cheap integrity check so a caller cannot skip it.
/// Any failure (including the database refusing a row) rolls the transaction back and nothing changes.
final class BackupImporter {
  BackupImporter(this._db, {this.beforeCommit});

  final LocalDatabase _db;

  /// Test seam: runs after every row is written and before the transaction ends (inject a failure to prove rollback).
  final Future<void> Function()? beforeCommit;

  Future<void> replaceAll(BackupData data) async {
    BackupValidator.check(data);
    try {
      await _db.transaction(() async {
        await _wipe();
        await _insert(data);
        final broken = await _db.customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) throw const BackupException(BackupError.invalid, 'foreign_key_check');
        await beforeCommit?.call();
      });
    } on BackupException {
      rethrow;
    } catch (_) {
      // The cause (a SQLite constraint message) can quote a value; the UI needs only the code.
      throw const BackupException(BackupError.failed);
    }
  }

  /// Children before parents. `local_meta` stays (per-device state); idempotency keys go (not part of the ledger).
  Future<void> _wipe() async {
    await _db.delete(_db.expenseItemAssignees).go();
    await _db.delete(_db.expenseItems).go();
    await _db.delete(_db.expenseSplits).go();
    await _db.delete(_db.expensePayers).go();
    await _db.delete(_db.expenseRevisions).go();
    await _db.delete(_db.settlements).go();
    await _db.delete(_db.expenses).go();
    await _db.delete(_db.members).go();
    await _db.delete(_db.paymentHandles).go();
    await _db.delete(_db.expenseGroups).go();
    await _db.delete(_db.idempotencyKeys).go();
    await _db.delete(_db.localProfile).go();
  }

  /// Parents before children, in batches (one statement list, still inside the transaction).
  Future<void> _insert(BackupData d) async {
    await _db.into(_db.localProfile).insert(d.profile);
    await _db.batch((b) {
      b.insertAll(_db.expenseGroups, d.groups);
      b.insertAll(_db.members, d.members);
      b.insertAll(_db.paymentHandles, d.paymentHandles);
      b.insertAll(_db.expenses, d.expenses);
      b.insertAll(_db.expensePayers, d.payers);
      b.insertAll(_db.expenseSplits, d.splits);
      b.insertAll(_db.expenseItems, d.items);
      b.insertAll(_db.expenseItemAssignees, d.assignees);
      b.insertAll(_db.expenseRevisions, d.revisions);
      b.insertAll(_db.settlements, d.settlements);
    });
  }
}
