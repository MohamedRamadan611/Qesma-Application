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

  _deliveryMigrationTests(() => verifier);
  _instapayLinkMigrationTests(() => verifier);
  _archiveMigrationTests(() => verifier);
  _sharesBudgetMigrationTests(() => verifier);

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
    await verifier.migrateAndValidate(db, db.schemaVersion); // SA12: later NOT NULL columns exist, so the row is read at the current version
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
    await verifier.migrateAndValidate(db, db.schemaVersion);
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
    await verifier.migrateAndValidate(db, db.schemaVersion); // SA15: the DAOs read the v8 item columns
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
    await verifier.migrateAndValidate(db, db.schemaVersion);
    expect((await db.metaDao.get()).lastReminderTone, 'FIRM');
    expect(await db.fuelPricesDao.watchAll().first, isEmpty);
    await db.fuelPricesDao.upsert(fuelType: 'GASOLINE_92', pricePerLitreMinor: 1375, updatedAt: 5);
    expect((await db.fuelPricesDao.watchAll().first).single.pricePerLitreMinor, 1375);
    await db.close();
  });

  test('v6 -> v7 keeps the data and adds the receipt-scan state with safe defaults (SA12)', () async {
    const p = '00000000-0000-4000-8000-000000000001';
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase.execute("INSERT INTO local_meta (id, created_schema_version, created_at, last_reminder_tone) VALUES (1, 6, 1000, 'SOFT')");
    schema.rawDatabase.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");

    final db = LocalDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 7);
    // Read raw: the current row class also maps columns added after v7 (archive_retention_days, schema 11).
    Future<(String?, int?, String?, int, int, int?)> ocr() async {
      final r = await db
          .customSelect('SELECT last_reminder_tone, ocr_consent_at, ocr_scan_day, ocr_scan_count, '
              'ocr_permission_errors, ocr_hidden_until FROM local_meta')
          .getSingle();
      return (
        r.readNullable<String>('last_reminder_tone'),
        r.readNullable<int>('ocr_consent_at'),
        r.readNullable<String>('ocr_scan_day'),
        r.read<int>('ocr_scan_count'),
        r.read<int>('ocr_permission_errors'),
        r.readNullable<int>('ocr_hidden_until'),
      );
    }

    expect(await ocr(), ('SOFT', null, null, 0, 0, null));
    await db.metaDao.writeOcr(consentAt: 5, scanDay: '2026-11-19', scanCount: 3, permissionErrors: 1, hiddenUntil: 99);
    expect(await ocr(), ('SOFT', 5, '2026-11-19', 3, 1, 99));
    // The schema refuses a malformed day and a negative counter.
    await expectLater(db.metaDao.writeOcr(consentAt: null, scanDay: '19/11/2026', scanCount: 0, permissionErrors: 0, hiddenUntil: null), throwsA(anything));
    await expectLater(db.metaDao.writeOcr(consentAt: null, scanDay: null, scanCount: -1, permissionErrors: 0, hiddenUntil: null), throwsA(anything));
    await db.close();
  });

  group('v7 -> v8 itemized v2 (SA15, Java V21)', () {
    const p = '00000000-0000-4000-8000-000000000001';
    const g = '00000000-0000-4000-8000-0000000000a1';
    const m1 = '00000000-0000-4000-8000-0000000000b1';
    const m2 = '00000000-0000-4000-8000-0000000000b2';
    const eq = '00000000-0000-4000-8000-0000000000c1';
    const it = '00000000-0000-4000-8000-0000000000c2';
    const pizza = '00000000-0000-4000-8000-0000000000e1';
    const drinks = '00000000-0000-4000-8000-0000000000e2';
    const s = '00000000-0000-4000-8000-0000000000d1';

    /// A v7 ledger: an EQUAL expense, an ITEMIZED one with service and tax, a confirmed payment.
    void seedV7(dynamic raw) {
      raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 7, 1000)');
      raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
      raw.execute("INSERT INTO expense_groups (id, owner_user_id, name, type, created_at, updated_at) VALUES ('$g', '$p', 'Trip', 'TRIP', 1, 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, user_id, sort_order, role, created_at) VALUES ('$m1', '$g', 'Mona', 'mona', '$p', 1, 'OWNER', 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, sort_order, created_at) VALUES ('$m2', '$g', 'Ali', 'ali', 2, 1)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id, created_at, updated_at) VALUES ('$eq', '$g', 'Taxi', 'EQUAL', 1000, '2026-11-10', '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '$m1', 1000)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor) VALUES ('$eq', '$m1', 500), ('$eq', '$m2', 500)");
      // Items m1 1000, m2 2000; service 12% = 360 (120 / 240); tax 14% of 3360 = 470 (157 / 313); total 3830.
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor, service_bps, service_minor, tax_bps, tax_minor, tax_base, adjustment_minor, created_by_user_id, created_at, updated_at) VALUES ('$it', '$g', 'Dinner', 'ITEMIZED', 3830, '2026-11-10', 3000, 1200, 360, 1400, 470, 'SUBTOTAL_PLUS_SERVICE', 0, '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$it', '$m2', 3830)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor, items_minor, service_minor, tax_minor, adjustment_minor) VALUES ('$it', '$m1', 1277, 1000, 120, 157, 0), ('$it', '$m2', 2553, 2000, 240, 313, 0)");
      raw.execute("INSERT INTO expense_items (id, expense_id, name, amount_minor, sort_order) VALUES ('$pizza', '$it', 'Pizza', 2000, 0), ('$drinks', '$it', 'Drinks', 1000, 1)");
      raw.execute("INSERT INTO expense_item_assignees (item_id, member_id) VALUES ('$pizza', '$m1'), ('$pizza', '$m2'), ('$drinks', '$m2')");
      raw.execute("INSERT INTO expense_revisions (id, expense_id, version, change_type, snapshot, changed_by_user_id, changed_at) VALUES ('00000000-0000-4000-8000-0000000000f1', '$it', 1, 'CREATE', '{\"id\":\"$it\"}', '$p', 1)");
      raw.execute("INSERT INTO settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, created_by_user_id, created_at, status, declared_at, confirmed_at) VALUES ('$s', '$g', '$m2', '$m1', 500, '2026-11-11', '$p', 1, 'CONFIRMED', 1, 1)");
    }

    // The same SQL before and after: paid - owed - received + sent over live expenses and CONFIRMED settlements.
    const netsSql = '''
      SELECT m.id AS id,
        (SELECT COALESCE(SUM(p.amount_minor), 0) FROM expense_payers p JOIN expenses e ON e.id = p.expense_id
           WHERE p.member_id = m.id AND e.deleted_at IS NULL)
      - (SELECT COALESCE(SUM(x.owed_minor), 0) FROM expense_splits x JOIN expenses e ON e.id = x.expense_id
           WHERE x.member_id = m.id AND e.deleted_at IS NULL)
      + (SELECT COALESCE(SUM(amount_minor), 0) FROM settlements WHERE from_member_id = m.id AND status = 'CONFIRMED')
      - (SELECT COALESCE(SUM(amount_minor), 0) FROM settlements WHERE to_member_id = m.id AND status = 'CONFIRMED')
        AS net
      FROM members m ORDER BY m.sort_order''';

    test('keeps the ledger: nets identical, items 1 x amount, discount 0 on itemized rows only', () async {
      final schema = await verifier.schemaAt(7);
      seedV7(schema.rawDatabase);
      final before = [for (final r in schema.rawDatabase.select(netsSql)) (r['id'], r['net'])];
      // m1 paid 1000, owes 500 + 1277, received 500; m2 paid 3830, owes 500 + 2553, sent 500.
      expect(before, [(m1, -1277), (m2, 1277)]);

      final db = LocalDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 8);
      final after = [
        for (final r in await db.customSelect(netsSql).get()) (r.read<String>('id'), r.read<int>('net')),
      ];
      expect(after, before);
      expect(after.fold<int>(0, (a, r) => a + r.$2), 0);

      final graph = (await db.expensesDao.loadGraph(it))!;
      expect([for (final i in graph.items) (i.name, i.quantity, i.unitAmountMinor, i.amountMinor)],
          containsAll([('Pizza', 1, 2000, 2000), ('Drinks', 1, 1000, 1000)]));
      final e = graph.expense;
      expect((e.discountMinor, e.discountBps, e.discountAmountMinor, e.serviceAmountMinor, e.taxAmountMinor), (0, null, null, null, null));
      expect((e.totalMinor, e.subtotalMinor, e.serviceMinor, e.taxMinor), (3830, 3000, 360, 470));
      expect({for (final x in graph.splits) x.memberId: (x.owedMinor, x.discountMinor)}, {m1: (1277, 0), m2: (2553, 0)});
      final equal = (await db.expensesDao.loadGraph(eq))!;
      expect(equal.expense.discountMinor, isNull);
      expect(equal.splits.map((x) => x.discountMinor), [null, null]);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      expect((await db.customSelect('SELECT COUNT(*) AS n FROM expense_revisions').getSingle()).read<int>('n'), 1);

      // The V21 rules hold after the rebuild.
      await expectLater(db.customStatement("UPDATE expense_items SET quantity = 2 WHERE id = '$pizza'"), throwsA(anything));
      await expectLater(db.customStatement("UPDATE expenses SET service_amount_minor = 360 WHERE id = '$it'"), throwsA(anything));
      await expectLater(db.customStatement("UPDATE expenses SET discount_minor = 1 WHERE id = '$eq'"), throwsA(anything));
      await db.customStatement("UPDATE expense_items SET quantity = 2, unit_amount_minor = 1000 WHERE id = '$pizza'");
      await db.close();
    });

    test('is atomic: a broken reference rolls the whole upgrade back and the file stays at v7 (7 -> 8)', () async {
      final schema = await verifier.schemaAt(7);
      final raw = schema.rawDatabase;
      seedV7(raw);
      raw.execute('PRAGMA foreign_keys = OFF');
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '00000000-0000-4000-8000-0000000000ff', 1)");
      raw.execute('PRAGMA foreign_keys = ON');

      final db = LocalDatabase(schema.newConnection());
      await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
      expect(raw.select('PRAGMA user_version').single.values.single, 7);
      expect([for (final c in raw.select('PRAGMA table_info(expense_items)')) c['name']], isNot(contains('quantity')));
      expect([for (final c in raw.select('PRAGMA table_info(expense_splits)')) c['name']], isNot(contains('discount_minor')));
    });
  });
}

/// v8 -> v9: itemized delivery (A180, Java V22). The two tables are rebuilt; every old row keeps its meaning.
void _deliveryMigrationTests(SchemaVerifier Function() verifier) {
  group('v8 -> v9 itemized delivery (A180, Java V22)', () {
    const p = '00000000-0000-4000-8000-000000000001';
    const g = '00000000-0000-4000-8000-0000000000a1';
    const m1 = '00000000-0000-4000-8000-0000000000b1';
    const m2 = '00000000-0000-4000-8000-0000000000b2';
    const eq = '00000000-0000-4000-8000-0000000000c1';
    const it = '00000000-0000-4000-8000-0000000000c2';

    void seedV8(dynamic raw) {
      raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 8, 1000)');
      raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
      raw.execute("INSERT INTO expense_groups (id, owner_user_id, name, type, created_at, updated_at) VALUES ('$g', '$p', 'Trip', 'TRIP', 1, 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, user_id, sort_order, role, created_at) VALUES ('$m1', '$g', 'Mona', 'mona', '$p', 1, 'OWNER', 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, sort_order, created_at) VALUES ('$m2', '$g', 'Ali', 'ali', 2, 1)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id, created_at, updated_at) VALUES ('$eq', '$g', 'Taxi', 'EQUAL', 1000, '2026-11-10', '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '$m1', 1000)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor) VALUES ('$eq', '$m1', 500), ('$eq', '$m2', 500)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor, service_minor, tax_minor, adjustment_minor, discount_minor, created_by_user_id, created_at, updated_at) VALUES ('$it', '$g', 'Dinner', 'ITEMIZED', 3000, '2026-11-10', 3000, 0, 0, 0, 0, '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$it', '$m2', 3000)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor, items_minor, service_minor, tax_minor, adjustment_minor, discount_minor) VALUES ('$it', '$m1', 1000, 1000, 0, 0, 0, 0), ('$it', '$m2', 2000, 2000, 0, 0, 0, 0)");
    }

    test('keeps the ledger: delivery 0 on itemized rows, NULL on the others, nets unchanged', () async {
      final schema = await verifier().schemaAt(8);
      seedV8(schema.rawDatabase);
      final db = LocalDatabase(schema.newConnection());
      await verifier().migrateAndValidate(db, 9);

      final graph = (await db.expensesDao.loadGraph(it))!;
      expect(graph.expense.deliveryMinor, 0);
      expect({for (final x in graph.splits) x.memberId: (x.owedMinor, x.deliveryMinor)}, {m1: (1000, 0), m2: (2000, 0)});
      expect((graph.expense.totalMinor, graph.expense.subtotalMinor), (3000, 3000));
      final equal = (await db.expensesDao.loadGraph(eq))!;
      expect(equal.expense.deliveryMinor, isNull);
      expect(equal.splits.map((x) => x.deliveryMinor), [null, null]);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);

      // The V22 rules hold after the rebuild.
      await expectLater(db.customStatement("UPDATE expenses SET delivery_minor = 100 WHERE id = '$it'"), throwsA(anything));
      await expectLater(db.customStatement("UPDATE expenses SET delivery_minor = 0 WHERE id = '$eq'"), throwsA(anything));
      await db.customStatement(
          "UPDATE expenses SET delivery_minor = 100, total_minor = 3100 WHERE id = '$it'; "
          "UPDATE expense_splits SET delivery_minor = 50, owed_minor = owed_minor + 50 WHERE expense_id = '$it';");
      await db.close();
    });

    test('is atomic: a broken reference rolls the whole upgrade back and the file stays at v8', () async {
      final schema = await verifier().schemaAt(8);
      final raw = schema.rawDatabase;
      seedV8(raw);
      raw.execute('PRAGMA foreign_keys = OFF');
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '00000000-0000-4000-8000-0000000000ff', 1)");
      raw.execute('PRAGMA foreign_keys = ON');

      final db = LocalDatabase(schema.newConnection());
      await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
      expect(raw.select('PRAGMA user_version').single.values.single, 8);
      expect([for (final c in raw.select('PRAGMA table_info(expense_splits)')) c['name']], isNot(contains('delivery_minor')));
    });
  });
}

void _instapayLinkMigrationTests(SchemaVerifier Function() verifier) {
  group('v9 -> v10 InstaPay link in payment_handles', () {
    const p = '00000000-0000-4000-8000-000000000001';
    const link = 'https://ipn.eg/S/m.ramadan611/instapay/6BrrCd';

    test('keeps the stored handles and now accepts an ipn.eg link', () async {
      final schema = await verifier().schemaAt(9);
      final raw = schema.rawDatabase;
      raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 9, 1000)');
      raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
      raw.execute("INSERT INTO payment_handles (id, user_id, type, value, created_at, updated_at) VALUES ('00000000-0000-4000-8000-0000000000d1', '$p', 'INSTAPAY', 'mona@instapay', 1, 1)");
      raw.execute("INSERT INTO payment_handles (id, user_id, type, value, created_at, updated_at) VALUES ('00000000-0000-4000-8000-0000000000d2', '$p', 'WALLET', '01012345678', 1, 1)");
      final db = LocalDatabase(schema.newConnection());
      await verifier().migrateAndValidate(db, 10);

      final rows = {for (final r in await db.paymentHandlesDao.listForUser(p)) r.type: r.value};
      expect(rows, {'INSTAPAY': 'mona@instapay', 'WALLET': '01012345678'});
      const now = 1700000000000;
      await db.paymentHandlesDao.upsert(PaymentHandleRow(id: '00000000-0000-4000-8000-0000000000d1', userId: p, type: 'INSTAPAY', value: link, createdAt: now, updatedAt: now));
      expect((await db.paymentHandlesDao.listForUser(p)).firstWhere((r) => r.type == 'INSTAPAY').value, link);
      await db.close();
    });
  });
}

void _archiveMigrationTests(SchemaVerifier Function() verifier) {
  group('v10 -> v11 archive (A184)', () {
    const p = '00000000-0000-4000-8000-000000000001';
    const g = '00000000-0000-4000-8000-0000000000a1';

    test('every group stays active and the retention period defaults to 30 days', () async {
      final schema = await verifier().schemaAt(10);
      final raw = schema.rawDatabase;
      raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 10, 1000)');
      raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
      raw.execute("INSERT INTO expense_groups (id, owner_user_id, name, type, created_at, updated_at) VALUES ('$g', '$p', 'Trip', 'TRIP', 1, 1)");
      final db = LocalDatabase(schema.newConnection());
      await verifier().migrateAndValidate(db, 11);

      expect((await db.groupsDao.findById(g))!.archivedAt, isNull);
      expect((await db.groupsDao.listByOwner(p, limit: 10, offset: 0)).map((x) => x.id), [g]);
      expect((await db.metaDao.get()).archiveRetentionDays, 30);
      await db.groupsDao.setArchivedAt(g, 5000);
      expect(await db.groupsDao.listByOwner(p, limit: 10, offset: 0), isEmpty);
      expect((await db.groupsDao.listArchived(p)).single.archivedAt, 5000);
      await db.close();
    });

    test('the retention period accepts only 7, 15 or 30', () async {
      final db = LocalDatabase.inMemory();
      await db.metaDao.get().then((_) {}, onError: (_) {});
      await db.customStatement('INSERT OR IGNORE INTO local_meta (id, created_schema_version, created_at) VALUES (1, 11, 1)');
      for (final ok in [7, 15, 30]) {
        await db.metaDao.setArchiveRetentionDays(ok);
      }
      for (final bad in [0, 1, 10, 31, 60]) {
        await expectLater(db.metaDao.setArchiveRetentionDays(bad), throwsA(anything), reason: '$bad');
      }
      await db.close();
    });
  });
}

/// v11 -> v12: SHARES and trip budget settings (SA18, Java V23). expenses and expense_splits are rebuilt; members and
/// expense_groups gain nullable columns. Every existing row keeps its values and the new columns are NULL.
void _sharesBudgetMigrationTests(SchemaVerifier Function() verifier) {
  group('v11 -> v12 SHARES and trip budget (SA18, Java V23)', () {
    const p = '00000000-0000-4000-8000-000000000001';
    const g = '00000000-0000-4000-8000-0000000000a1';
    const m1 = '00000000-0000-4000-8000-0000000000b1';
    const m2 = '00000000-0000-4000-8000-0000000000b2';
    const eq = '00000000-0000-4000-8000-0000000000c1';
    const ex = '00000000-0000-4000-8000-0000000000c2';
    const it = '00000000-0000-4000-8000-0000000000c3';
    const st = '00000000-0000-4000-8000-0000000000d1';

    void seedV11(dynamic raw) {
      raw.execute('INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (1, 11, 1000)');
      raw.execute("INSERT INTO local_profile (id, display_name, created_at, updated_at) VALUES ('$p', 'Mona', 1, 1)");
      raw.execute("INSERT INTO expense_groups (id, owner_user_id, name, type, created_at, updated_at) VALUES ('$g', '$p', 'Flat', 'HOUSING', 1, 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, user_id, sort_order, role, created_at) VALUES ('$m1', '$g', 'Mona', 'mona', '$p', 1, 'OWNER', 1)");
      raw.execute("INSERT INTO members (id, group_id, display_name, name_key, sort_order, created_at) VALUES ('$m2', '$g', 'Ali', 'ali', 2, 1)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id, created_at, updated_at) VALUES ('$eq', '$g', 'Taxi', 'EQUAL', 1001, '2026-11-10', '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '$m1', 1001)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor) VALUES ('$eq', '$m1', 501), ('$eq', '$m2', 500)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id, created_at, updated_at, deleted_at, version) VALUES ('$ex', '$g', 'Rent', 'EXACT', 9000, '2026-11-01', '$p', 1, 2, 2, 2)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$ex', '$m2', 9000)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor) VALUES ('$ex', '$m1', 6000), ('$ex', '$m2', 3000)");
      raw.execute("INSERT INTO expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor, service_minor, tax_minor, adjustment_minor, discount_minor, delivery_minor, created_by_user_id, created_at, updated_at) VALUES ('$it', '$g', 'Dinner', 'ITEMIZED', 3000, '2026-11-10', 3000, 0, 0, 0, 0, 0, '$p', 1, 1)");
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$it', '$m2', 3000)");
      raw.execute("INSERT INTO expense_splits (expense_id, member_id, owed_minor, items_minor, service_minor, tax_minor, adjustment_minor, discount_minor, delivery_minor) VALUES ('$it', '$m1', 1000, 1000, 0, 0, 0, 0, 0), ('$it', '$m2', 2000, 2000, 0, 0, 0, 0, 0)");
      raw.execute("INSERT INTO expense_revisions (id, expense_id, version, change_type, snapshot, changed_by_user_id, changed_at) VALUES ('00000000-0000-4000-8000-0000000000e1', '$eq', 1, 'CREATE', '{\"id\":\"$eq\"}', '$p', 1)");
      raw.execute("INSERT INTO settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, created_by_user_id, created_at, status, declared_at, confirmed_at) VALUES ('$st', '$g', '$m1', '$m2', 700, '2026-11-12', '$p', 1, 'CONFIRMED', 1, 1)");
    }

    // Nets as the ledger reads them: payers - owed over live expenses, plus CONFIRMED settlements.
    const netsSql = '''
      SELECT m.id AS id,
        COALESCE((SELECT SUM(p.amount_minor) FROM expense_payers p JOIN expenses e ON e.id = p.expense_id
                  WHERE p.member_id = m.id AND e.deleted_at IS NULL), 0)
        - COALESCE((SELECT SUM(s.owed_minor) FROM expense_splits s JOIN expenses e ON e.id = s.expense_id
                  WHERE s.member_id = m.id AND e.deleted_at IS NULL), 0)
        + COALESCE((SELECT SUM(amount_minor) FROM settlements WHERE from_member_id = m.id AND status = 'CONFIRMED'), 0)
        - COALESCE((SELECT SUM(amount_minor) FROM settlements WHERE to_member_id = m.id AND status = 'CONFIRMED'), 0)
        AS net
      FROM members m ORDER BY m.sort_order''';
    const dumpSql = [
      'SELECT id, split_type, total_minor, expense_date, subtotal_minor, discount_minor, delivery_minor, deleted_at, version FROM expenses ORDER BY id',
      'SELECT * FROM expense_payers ORDER BY expense_id, member_id',
      'SELECT expense_id, member_id, owed_minor, items_minor, discount_minor, delivery_minor FROM expense_splits ORDER BY expense_id, member_id',
      'SELECT * FROM expense_revisions ORDER BY id',
      'SELECT * FROM settlements ORDER BY id',
      'SELECT id, name, version, treasurer_member_id, archived_at FROM expense_groups ORDER BY id',
      'SELECT id, display_name, sort_order, role, status FROM members ORDER BY id',
    ];

    test('keeps every row and the nets; the new columns are NULL', () async {
      final schema = await verifier().schemaAt(11);
      final raw = schema.rawDatabase;
      seedV11(raw);
      List<Object?> dump() => [for (final q in dumpSql) for (final r in raw.select(q)) r.values];
      final before = dump();
      final netsBefore = [for (final r in raw.select(netsSql)) (r['id'], r['net'])];
      // m1: paid 1001, owes 501 + 1000 (the EXACT rent is deleted), sent 700 -> 200; m2: 3000 - 2500 - 700 -> -200.
      expect(netsBefore, [(m1, 200), (m2, -200)]);
      final db = LocalDatabase(schema.newConnection());
      await verifier().migrateAndValidate(db, 12);

      expect(dump(), before);
      expect([for (final r in raw.select(netsSql)) (r['id'], r['net'])], netsBefore);
      expect(raw.select('SELECT period_from, period_to FROM expenses WHERE period_from IS NOT NULL OR period_to IS NOT NULL'), isEmpty);
      expect(raw.select('SELECT 1 FROM expense_splits WHERE share_units IS NOT NULL OR present_from IS NOT NULL OR present_to IS NOT NULL'), isEmpty);
      expect(raw.select('SELECT 1 FROM members WHERE default_share_units IS NOT NULL'), isEmpty);
      expect(raw.select('SELECT 1 FROM expense_groups WHERE budget_minor IS NOT NULL OR trip_start_date IS NOT NULL OR trip_end_date IS NOT NULL'), isEmpty);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      // The treasurer triggers survived (expense_groups was not rebuilt) and the rebuilt tables keep their indexes.
      final names = [for (final r in raw.select("SELECT name FROM sqlite_master WHERE type IN ('index', 'trigger')")) r['name']];
      expect(names, containsAll(['expense_groups_treasurer_insert', 'expense_groups_treasurer_update', 'ix_expenses_group_list', 'ix_expense_splits_member']));
      await db.close();
    });

    test('is atomic: a broken reference rolls the whole upgrade back and the file stays at v11', () async {
      final schema = await verifier().schemaAt(11);
      final raw = schema.rawDatabase;
      seedV11(raw);
      raw.execute('PRAGMA foreign_keys = OFF');
      raw.execute("INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES ('$eq', '00000000-0000-4000-8000-0000000000ff', 1)");
      raw.execute('PRAGMA foreign_keys = ON');

      final db = LocalDatabase(schema.newConnection());
      await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
      expect(raw.select('PRAGMA user_version').single.values.single, 11);
      expect([for (final c in raw.select('PRAGMA table_info(expense_splits)')) c['name']], isNot(contains('share_units')));
      expect([for (final c in raw.select('PRAGMA table_info(members)')) c['name']], isNot(contains('default_share_units')));
    });
  });
}
