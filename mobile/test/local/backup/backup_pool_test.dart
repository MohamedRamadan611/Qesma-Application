import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_format.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';

import '../backend/support/local_http.dart';
import 'support/backup_support.dart';

/// SA10: the pool (treasurer, pool expenses, deposits) survives export -> import, older files without the pool
/// columns still import, and a treasurer from another group is refused before anything is written.
void main() {
  late LocalHttp source;
  late String gid;
  late String ali;

  setUp(() async {
    source = await LocalHttp.open(profileName: 'Mona');
    final g = await source.group();
    gid = g['id'] as String;
    final you = g['yourMemberId'] as String;
    ali = await source.member(gid, 'Ali');
    expect((await source.patch('/groups/$gid', {'treasurerMemberId': you}, ifMatch: '"1"')).statusCode, 200);
    await source.settlement(gid, {'fromMemberId': ali, 'toMemberId': you, 'amountMinor': 5000, 'settledOn': '2026-11-12', 'kind': 'POOL_DEPOSIT'});
    await source.expense(gid, {...equalBody(3000, [(id: you, amount: 3000)]), 'paidFromPool': true});
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

  test('round trip keeps the treasurer, the meter, the flag and the kind', () async {
    final restored = await restore(await exportBytes(source.db));
    final g = (await restored.get('/groups/$gid')).data;
    expect((g['treasurerMemberId'], g['poolBalanceMinor']), ((await source.get('/groups/$gid')).data['treasurerMemberId'], 2000));
    expect(((await restored.get('/groups/$gid/expenses')).data['items'] as List).single['paidFromPool'], isTrue);
    expect(((await restored.get('/groups/$gid/settlements')).data['items'] as List).single['kind'], 'POOL_DEPOSIT');
    expect(await contractDump(restored), await contractDump(source));
  });

  test('a schema-4 file (no pool columns) imports with the defaults', () async {
    final json = decodeBackup(await exportBytes(source.db));
    json['schemaVersion'] = 4;
    for (final g in json['groups'] as List) {
      (g as Map).remove('treasurer_member_id');
    }
    for (final e in json['expenses'] as List) {
      (e as Map).remove('paid_from_pool');
    }
    for (final s in json['settlements'] as List) {
      (s as Map).remove('kind');
    }
    final restored = await restore(encodeBackup(json));
    final g = (await restored.get('/groups/$gid')).data as Map;
    expect(g.containsKey('treasurerMemberId'), isFalse);
    expect(((await restored.get('/groups/$gid/settlements')).data['items'] as List).single['kind'], 'PAYMENT');
  });

  test('a treasurer that is not a member of its group is refused', () async {
    final json = decodeBackup(await exportBytes(source.db));
    (json['groups'] as List).single['treasurer_member_id'] = '11111111-2222-4333-8444-555555555555';
    final service = BackupService(LocalDatabase.inMemory());
    await expectLater(
      service.prepareRestore(encodeBackup(json)),
      throwsA(isA<BackupException>().having((e) => e.path, 'path', 'groups[0].treasurer_member_id')),
    );
  });
}
