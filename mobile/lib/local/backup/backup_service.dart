import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../db/local_database.dart';
import '../db/local_database_provider.dart';
import 'backup_exporter.dart';
import 'backup_format.dart';
import 'backup_importer.dart';
import 'backup_reminder.dart';
import 'backup_validator.dart';

/// What the profile hub and the banner need to know about backups.
final class BackupStatus {
  const BackupStatus({required this.lastExportAt, required this.showReminder});

  /// UTC epoch ms of the last successful export, null when the user never exported.
  final int? lastExportAt;
  final bool showReminder;
}

/// Backup use cases over the local database (STANDALONE_SPEC 6). No network, and nothing from a file is ever logged.
final class BackupService {
  BackupService(this._db, {String? appVersion, int Function()? clock})
      : _appVersion = appVersion ?? AppInfo.raw,
        _clock = clock ?? utcNowMillis;

  final LocalDatabase _db;
  final String _appVersion;
  final int Function() _clock;

  /// Files above this size are parsed on a background isolate so the UI never freezes.
  static const int _isolateThresholdBytes = 512 * 1024;

  /// The backup document for the current ledger (the export time is taken now).
  Future<BackupData> snapshot() => BackupExporter(_db, appVersion: _appVersion, clock: _clock).read();

  /// The file's bytes (UTF-8 JSON) for [data].
  Uint8List encode(BackupData data) => Uint8List.fromList(utf8.encode(jsonEncode(data.toJson())));

  /// Called after the share sheet was shown for [data]: remembers the export and resets the reminder.
  Future<void> markExported(BackupData data) =>
      _db.metaDao.recordExport(exportedAt: data.exportedAt, formatVersion: data.formatVersion);

  /// Validates [bytes] completely (nothing is written). Throws [BackupException].
  Future<BackupData> prepareRestore(Uint8List bytes) async {
    if (bytes.length > _isolateThresholdBytes) {
      return Isolate.run(() => BackupValidator.parse(bytes));
    }
    return BackupValidator.parse(bytes);
  }

  /// Replace-all (one transaction). Throws [BackupException]; on failure nothing changed.
  Future<void> restore(BackupData data) => BackupImporter(_db).replaceAll(data);

  Future<BackupStatus> status() async {
    final meta = await _db.metaDao.get();
    final live = await _count('SELECT COUNT(*) AS n FROM expenses WHERE deleted_at IS NULL', const []);
    final since = await _count(
      'SELECT COUNT(*) AS n FROM expenses WHERE deleted_at IS NULL AND created_at > ?',
      [Variable<int>(meta.lastExportAt ?? -1)],
    );
    return BackupStatus(
      lastExportAt: meta.lastExportAt,
      showReminder: BackupReminder.shouldShow(
        now: _clock(),
        liveExpenseCount: live,
        expensesSinceExport: since,
        lastExportAt: meta.lastExportAt,
        installedAt: meta.createdAt,
        snoozedUntil: meta.backupReminderSnoozedUntil,
      ),
    );
  }

  Future<void> snoozeReminder() => _db.metaDao.snoozeBackupReminder(BackupReminder.snoozeUntil(_clock()));

  /// Folds the write-ahead log into the main database file, so the single file that Android auto-backup copies is
  /// complete (A157). Cheap; called when the app goes to the background.
  Future<void> checkpoint() => _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

  Future<int> _count(String sql, List<Variable<Object>> variables) async {
    final row = await _db.customSelect(sql, variables: variables, readsFrom: {_db.expenses}).getSingle();
    return row.read<int>('n');
  }
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(localDatabaseProvider)));

/// Last export time and whether the banner shows. Invalidate after an export, a snooze or a restore.
final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) => ref.watch(backupServiceProvider).status());
