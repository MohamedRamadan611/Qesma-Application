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

  test('v4 -> v5 keeps the ledger and adds the pool columns with their defaults (SA10, Java V20)', () async {
    const p = '00000000-0000-4000-8000-000000000001';
    const g = '00000000-0000-4000-8000-0000000000a1';
    const g2 = '00000000-0000-4000-8000-0000000000a2';
    const m1 = '00000000-0000-4000-8000-0000000000b1';
    const m2 = '00000000-0000-4000-8000-0000000000b2';
    const other = '00000000-0000-4000-8000-0000000000b3';
    const e = '00000000-0000-4000-8000-0000000000c1';
    const s = '00000000-0000-4000-8000-0000000000d1';
    final schema = await verifier.schemaAt(4);
    final raw = schema.rawDatabase;
    raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 4, 1000)');
    raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
    for (final id in [g, g2]) {
      raw.execute("INSERT INTO expense_groups (id, owner_user_id, name, type, created_at, updated_at) VALUES ('$id', '$p', 'Trip', 'TRIP', 1, 1)");
    }
    raw.execute("INSERT INTO members (id, group_id, display_name, name_key, user_id, sort_order, role, created_at) VALUES ('$m1', '$g', 'Mona', 'mona', '$p', 1, 'OWNER', 1)");
    raw.execute("INSERT INTO members (id, group_id, display_name, name_key, sort_order, created_at) VALUES ('$m2', '$g', 'Ali', 'ali', 2, 1)");
    raw.execute("INSERT INTO members (id, group_id, display_name, name_key, sort_order, created_at) VALUES ('$other', '$g2', 'Sara', 'sara', 1, 1)");
    raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id, created_at, updated_at) VALUES ('$e', '$g', 'Dinner', 'EQUAL', 1000, '2026-11-10', '$p', 1, 1)");
    raw.execute("INSERT INTO settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, created_by_user_id, created_at, status, declared_at, confirmed_at) VALUES ('$s', '$g', '$m2', '$m1', 500, '2026-11-11', '$p', 1, 'CONFIRMED', 1, 1)");

    final db = LocalDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);
    expect((await db.groupsDao.findById(g))!.treasurerMemberId, isNull);
    expect((await db.expensesDao.loadGraph(e))!.expense.paidFromPool, 0);
    expect((await db.settlementsDao.findById(s))!.kind, 'PAYMENT');

    // The same-group rule (V20's composite FK) holds after the upgrade: a member of another group is refused.
    await db.customStatement("UPDATE expense_groups SET treasurer_member_id = '$m2' WHERE id = '$g'");
    await expectLater(db.customStatement("UPDATE expense_groups SET treasurer_member_id = '$other' WHERE id = '$g'"), throwsA(anything));
    await expectLater(db.customStatement("UPDATE settlements SET kind = 'GIFT' WHERE id = '$s'"), throwsA(anything));
    await expectLater(db.customStatement("UPDATE expenses SET paid_from_pool = 2 WHERE id = '$e'"), throwsA(anything));
    await db.close();
  });

  test('v5 -> v6 keeps the existing data and adds the empty fuel_prices table (SA11, A168)', () async {
    const p = '00000000-0000-4000-8000-000000000001';
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase.execute("INSERT INTO local_meta (id, created_schema_version, created_at, last_reminder_tone) VALUES (1, 5, 1000, 'FIRM')");
    schema.rawDatabase.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");

    final db = LocalDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 6);
    expect((await db.metaDao.get()).lastReminderTone, 'FIRM');
    expect(await db.fuelPricesDao.watchAll().first, isEmpty);
    await db.fuelPricesDao.upsert(fuelType: 'GASOLINE_92', pricePerLitreMinor: 1375, updatedAt: 5);
    expect((await db.fuelPricesDao.watchAll().first).single.pricePerLitreMinor, 1375);
    await db.close();
  });
}
