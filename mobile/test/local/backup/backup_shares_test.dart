import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_format.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/backup/backup_validator.dart';
import 'package:qesma/local/db/local_database.dart';

import '../backend/support/local_http.dart';
import 'support/backup_support.dart';

/// Schema 12 (SA18): SHARES expenses, the member default weight and the group budget survive export -> import; files
/// from before schema 12 import unchanged; a hand-edited SHARES row is refused before anything is written.
void main() {
  late LocalHttp source;
  late String gid;
  late String you;
  late String ali;
  late String sara;

  setUp(() async {
    source = await LocalHttp.open(profileName: 'Mona');
    final g = await source.group(name: 'Flat', type: 'HOUSING');
    gid = g['id'] as String;
    you = g['yourMemberId'] as String;
    ali = await source.member(gid, 'Ali');
    sara = await source.member(gid, 'Sara');
    await seedRichLedger(source);
    final rent = await source.expense(gid, {
      'title': 'Rent',
      'expenseDate': '2026-12-01',
      'splitType': 'SHARES',
      'totalMinor': 900000,
      'periodFrom': '2026-11-01',
      'periodTo': '2026-11-30',
      'payers': [
        {'memberId': you, 'amountMinor': 900000},
      ],
      'shareParticipants': [
        {'memberId': you, 'shareUnits': 2},
        {'memberId': ali, 'shareUnits': 1},
        {'memberId': sara, 'shareUnits': 1, 'presentFrom': '2026-11-12'},
      ],
    });
    expect(rent.statusCode, 201, reason: '${rent.data}');
    final noPeriod = await source.expense(gid, {
      'title': 'Internet',
      'expenseDate': '2026-12-02',
      'splitType': 'SHARES',
      'totalMinor': 1000,
      'payers': [
        {'memberId': ali, 'amountMinor': 1000},
      ],
      'shareParticipants': [
        {'memberId': you, 'shareUnits': 3},
        {'memberId': ali, 'shareUnits': 3},
        {'memberId': sara, 'shareUnits': 3},
      ],
    });
    expect(noPeriod.statusCode, 201);
    final v = (await source.get('/groups/$gid')).data['version'];
    expect((await source.patch('/groups/$gid', {'budgetMinor': 2000000, 'tripStartDate': '2026-11-01'}, ifMatch: '"$v"'))
        .statusCode, 200);
    expect((await source.patch('/groups/$gid/members/$ali', {'defaultShareUnits': 2})).statusCode, 200);
  });
  tearDown(() => source.close());

  Future<LocalHttp> restore(Uint8List bytes) async {
    final target = LocalDatabase.inMemory();
    final service = BackupService(target);
    await service.restore(await service.prepareRestore(bytes));
    final restored = await LocalHttp.open(database: target, withProfile: false);
    addTearDown(restored.close);
    return restored;
  }

  Future<void> expectRefused(Map<String, dynamic> json, BackupError code) async {
    final target = LocalDatabase.inMemory();
    addTearDown(target.close);
    await expectLater(BackupService(target).prepareRestore(encodeBackup(json)),
        throwsA(isA<BackupException>().having((e) => e.code, 'code', code)));
  }

  Map<String, dynamic> rentRow(Map<String, dynamic> json) =>
      (json['expenses'] as List).cast<Map<String, dynamic>>().firstWhere((e) => e['title'] == 'Rent');

  List<Map<String, dynamic>> splitsOf(Map<String, dynamic> json, Object? expenseId) =>
      (json['expense_splits'] as List).cast<Map<String, dynamic>>().where((s) => s['expense_id'] == expenseId).toList();

  test('round trip: the contract reads back identically (SHARES, budget, default weight) at schema 12', () async {
    final bytes = await exportBytes(source.db);
    final json = decodeBackup(bytes);
    expect(json['schemaVersion'], 12);
    expect(BackupValidator.currentSchemaVersion, 12);
    final restored = await restore(bytes);
    expect(await contractDump(restored), await contractDump(source));
    final g = (await restored.get('/groups/$gid')).data;
    expect((g['budgetMinor'], g['tripStartDate'], g.containsKey('tripEndDate')), (2000000, '2026-11-01', false));
  });

  test('a v11 file (no schema-12 keys) imports unchanged', () async {
    // Built from a ledger without SHARES: a v11 app could not have written one.
    final plain = await LocalHttp.open(profileName: 'Mona');
    addTearDown(plain.close);
    await seedRichLedger(plain);
    final json = decodeBackup(await exportBytes(plain.db));
    json['schemaVersion'] = 11;
    for (final table in ['groups', 'members', 'expenses', 'expense_splits']) {
      for (final row in (json[table] as List).cast<Map<String, dynamic>>()) {
        row.removeWhere((k, _) => const {
              'budget_minor', 'trip_start_date', 'trip_end_date', 'default_share_units', 'period_from', 'period_to',
              'share_units', 'present_from', 'present_to'
            }.contains(k));
      }
    }
    final restored = await restore(encodeBackup(json));
    expect(await contractDump(restored), await contractDump(plain));
  });

  test('a stored owed amount that is not what the engine gives is refused', () async {
    final json = decodeBackup(await exportBytes(source.db));
    final splits = splitsOf(json, rentRow(json)['id']);
    splits[0]['owed_minor'] = (splits[0]['owed_minor'] as int) + 1;
    splits[1]['owed_minor'] = (splits[1]['owed_minor'] as int) - 1;
    await expectRefused(json, BackupError.inconsistent);
  });

  test('units on an EQUAL split, a period on EQUAL, presence outside the period or without units are refused', () async {
    Future<void> tamper(void Function(Map<String, dynamic> json) change) async {
      final json = decodeBackup(await exportBytes(source.db));
      change(json);
      await expectRefused(json, BackupError.invalid);
    }

    Map<String, dynamic> equalRow(Map<String, dynamic> json) =>
        (json['expenses'] as List).cast<Map<String, dynamic>>().firstWhere((e) => e['split_type'] == 'EQUAL');

    await tamper((j) => splitsOf(j, equalRow(j)['id']).first['share_units'] = 1);
    await tamper((j) => equalRow(j)
      ..['period_from'] = '2026-11-01'
      ..['period_to'] = '2026-11-30');
    await tamper((j) => splitsOf(j, rentRow(j)['id']).last['present_from'] = '2026-10-31');
    await tamper((j) => splitsOf(j, rentRow(j)['id']).last['share_units'] = null);
    await tamper((j) => splitsOf(j, rentRow(j)['id']).last['present_to'] = null);
    await tamper((j) => rentRow(j)['period_to'] = null);
    await tamper((j) => rentRow(j)['period_to'] = '2027-11-30');
    await tamper((j) => splitsOf(j, rentRow(j)['id']).first['share_units'] = 101);
    Map<String, dynamic> flat(Map<String, dynamic> j) =>
        (j['groups'] as List).cast<Map<String, dynamic>>().firstWhere((g) => g['id'] == gid);
    await tamper((j) => flat(j)['trip_end_date'] = '2026-10-31');
    await tamper((j) => flat(j)['budget_minor'] = 0);
    await tamper((j) => (j['members'] as List).first['default_share_units'] = 0);
  });
}
