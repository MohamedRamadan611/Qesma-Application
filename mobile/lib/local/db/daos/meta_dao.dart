import 'package:drift/drift.dart';

import '../local_database.dart';

part 'meta_dao.g.dart';

/// The `local_meta` row (id 1), written when the database is created.
@DriftAccessor(include: {'../schema.drift'})
class MetaDao extends DatabaseAccessor<LocalDatabase> with _$MetaDaoMixin {
  MetaDao(super.db);

  Future<LocalMetaRow> get() => (select(localMeta)..where((m) => m.id.equals(1))).getSingle();

  /// Records a successful export and clears the reminder snooze (the banner starts counting again).
  Future<void> recordExport({required int exportedAt, required int formatVersion}) =>
      (update(localMeta)..where((m) => m.id.equals(1))).write(
        LocalMetaCompanion(
          lastExportAt: Value(exportedAt),
          lastExportFormatVersion: Value(formatVersion),
          backupReminderSnoozedUntil: const Value(null),
        ),
      );

  /// Hides the backup reminder until [untilMillis] (UTC epoch ms).
  Future<void> snoozeBackupReminder(int untilMillis) => (update(localMeta)..where((m) => m.id.equals(1)))
      .write(LocalMetaCompanion(backupReminderSnoozedUntil: Value(untilMillis)));
}
