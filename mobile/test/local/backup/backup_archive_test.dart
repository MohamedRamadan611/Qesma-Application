import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_format.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/service/archive_service.dart';
import 'package:qesma/local/service/local_context.dart';

import '../backend/support/local_http.dart';
import 'support/backup_support.dart';

/// A184: the archived state of a group is part of the backup (it is a property of the group); the retention period
/// is a device setting and is not. Files from before schema 11 import as active groups.
void main() {
  late LocalHttp source;
  late String gid;

  setUp(() async {
    source = await LocalHttp.open(profileName: 'Mona');
    gid = (await source.group())['id'] as String;
    await ArchiveService(LocalContext(source.db, clock: () => source.now[0])).archive(gid);
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

  Future<int> listed(LocalHttp http) async => ((await http.get('/groups')).data['items'] as List).length;

  test('an archived group stays archived after export -> import, with its archive time', () async {
    final json = decodeBackup(await exportBytes(source.db));
    final archivedAt = (json['groups'] as List).single['archived_at'];
    expect(archivedAt, source.now[0]);

    final restored = await restore(encodeBackup(json));
    expect(await listed(restored), 0);
    final archived = await ArchiveService(LocalContext(restored.db, clock: () => restored.now[0])).list();
    expect((archived.single.id, archived.single.archivedAt), (gid, archivedAt));
  });

  test('a file from before schema 11 (no archived_at) imports as an active group', () async {
    final json = decodeBackup(await exportBytes(source.db));
    json['schemaVersion'] = 10;
    for (final g in json['groups'] as List) {
      (g as Map).remove('archived_at');
    }
    final restored = await restore(encodeBackup(json));
    expect(await listed(restored), 1);
  });

  test('a bad archived_at is refused', () async {
    final json = decodeBackup(await exportBytes(source.db));
    (json['groups'] as List).single['archived_at'] = 'yesterday';
    final target = LocalDatabase.inMemory();
    addTearDown(target.close);
    await expectLater(BackupService(target).prepareRestore(encodeBackup(json)), throwsA(isA<BackupException>()));
  });
}
