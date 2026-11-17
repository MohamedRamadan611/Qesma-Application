import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_format.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';

import '../backend/support/local_http.dart';
import 'support/backup_support.dart';

/// Export -> import keeps the ledger: balances, expense details and revision history are identical when read through
/// the same contract the app uses (STANDALONE_SPEC 6).
void main() {
  late LocalHttp source;

  setUp(() async {
    source = await LocalHttp.open(profileName: 'Mona');
    await seedRichLedger(source);
  });
  tearDown(() => source.close());

  test('the export has the documented shape, no idempotency keys and no per-device state', () async {
    final json = decodeBackup(await exportBytes(source.db));
    expect(json['formatVersion'], 1);
    expect(json['schemaVersion'], source.db.schemaVersion);
    expect(json['exportedAt'], isA<int>());
    expect(json['appVersion'], '0.1.0+1');
    expect(json.keys, containsAll(['profile', 'groups', 'members', 'expenses', 'expense_payers', 'expense_splits', 'expense_items', 'expense_item_assignees', 'expense_revisions', 'settlements', 'payment_handles']));
    expect(json.containsKey('idempotency_keys'), isFalse);
    expect(json.containsKey('local_meta'), isFalse);
    expect((json['expenses'] as List).length, 6, reason: 'the soft-deleted expense is part of the ledger');
    expect((json['settlements'] as List).length, 2, reason: 'the cancelled settlement is kept');
  });

  test('round trip into an empty database: balances, expense details and revisions are identical', () async {
    final bytes = await exportBytes(source.db);
    final before = await contractDump(source);

    final target = LocalDatabase.inMemory();
    final service = BackupService(target);
    await service.restore(await service.prepareRestore(bytes));
    final restored = await LocalHttp.open(database: target, withProfile: false);
    addTearDown(restored.close);

    expect(await contractDump(restored), before);
    // The history survived, including the soft-deleted expense and the edit.
    expect(await restored.count('expense_revisions'), await source.count('expense_revisions'));
    expect(await restored.count('idempotency_keys'), 0);
  });

  test('importing into a database that already has other data replaces everything', () async {
    final bytes = await exportBytes(source.db);
    final before = await contractDump(source);

    final other = await LocalHttp.open(profileName: 'Someone else');
    addTearDown(other.close);
    final g = await other.group(name: 'Old group');
    await other.member(g['id'] as String, 'Old friend');

    final service = BackupService(other.db);
    await service.restore(await service.prepareRestore(bytes));
    expect(await contractDump(other), before);
    expect((await other.get('/me')).data['displayName'], 'Mona');
  });

  test('the restored database keeps working: a new expense can be added and balances stay consistent', () async {
    final bytes = await exportBytes(source.db);
    final target = LocalDatabase.inMemory();
    final service = BackupService(target);
    await service.restore(await service.prepareRestore(bytes));
    final http = await LocalHttp.open(database: target, withProfile: false);
    addTearDown(http.close);
    final gid = ((await http.get('/groups')).data['items'] as List).first['id'] as String;
    final detail = (await http.get('/groups/$gid')).data as Map;
    final r = await http.expense(gid, {
      'title': 'After restore',
      'expenseDate': '2026-11-14',
      'splitType': 'EQUAL',
      'totalMinor': 1000,
      'payers': [
        {'memberId': detail['yourMemberId'], 'amountMinor': 1000}
      ],
    });
    expect(r.statusCode, 201, reason: '${r.data}');
    expect((await http.get('/groups/$gid/balances')).statusCode, 200);
  });

  test('export records the time and clears the reminder snooze', () async {
    final service = BackupService(source.db, clock: () => 5000);
    await service.snoozeReminder();
    expect((await source.db.metaDao.get()).backupReminderSnoozedUntil, isNotNull);
    final data = await service.snapshot();
    await service.markExported(data);
    final meta = await source.db.metaDao.get();
    expect((meta.lastExportAt, meta.lastExportFormatVersion, meta.backupReminderSnoozedUntil), (5000, backupFormatVersion, null));
  });
}
