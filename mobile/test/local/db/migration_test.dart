import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/local_database.dart';

import 'generated/schema.dart';

/// Forward-only migrations (STANDALONE_SPEC 5.4). Exported snapshots live in `drift_schemas/local/`; the
/// helpers in `generated/` come from `dart run drift_dev schema generate drift_schemas/local/ test/local/db/generated/`.
/// Every version adds a `from N-1 to N` case with data (SA5: 1 -> 2 adds the backup-reminder snooze).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the exported v1 snapshot matches the schema in code', () async {
    final connection = await verifier.startAt(1);
    final db = LocalDatabase(connection);
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('every exported version migrates to the current schema', () async {
    for (final from in GeneratedHelper.versions) {
      final db = LocalDatabase(await verifier.startAt(from));
      await verifier.migrateAndValidate(db, db.schemaVersion);
      await db.close();
    }
  });

  test('v1 -> v2 keeps the existing data and adds the nullable backup-reminder snooze (SA5)', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute('INSERT INTO local_meta (id, created_schema_version, created_at, last_export_at, last_export_format_version) VALUES (1, 1, 1000, 2000, 1)');
    schema.rawDatabase.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('00000000-0000-4000-8000-000000000001', 'Mona', 1, 1)");
    final db = LocalDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    final meta = await db.metaDao.get();
    expect((meta.createdSchemaVersion, meta.createdAt, meta.lastExportAt, meta.backupReminderSnoozedUntil), (1, 1000, 2000, null));
    expect((await db.profileDao.find())!.displayName, 'Mona');
    await db.metaDao.snoozeBackupReminder(5);
    expect((await db.metaDao.get()).backupReminderSnoozedUntil, 5);
    await db.close();
  });

  test('v3 -> v4 keeps the existing data and adds the nullable last_reminder_tone (SA9)', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute('INSERT INTO local_meta (id, created_schema_version, created_at, last_export_at, last_export_format_version, backup_reminder_snoozed_until) VALUES (1, 1, 1000, 2000, 1, 5)');
    schema.rawDatabase.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('00000000-0000-4000-8000-000000000001', 'Mona', 1, 1)");
    final db = LocalDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    final meta = await db.metaDao.get();
    expect(meta.lastReminderTone, isNull);
    await db.metaDao.setLastReminderTone('FUNNY');
    expect((await db.metaDao.get()).lastReminderTone, 'FUNNY');
    await db.close();
  });
}
