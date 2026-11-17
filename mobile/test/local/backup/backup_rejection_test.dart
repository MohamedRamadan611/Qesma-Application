import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/backup/backup_format.dart';
import 'package:qesma/local/backup/backup_importer.dart';
import 'package:qesma/local/backup/backup_service.dart';
import 'package:qesma/local/backup/backup_validator.dart';

import '../backend/support/local_http.dart';
import 'support/backup_support.dart';

/// A bad file is rejected before anything is written, and the database is byte-for-byte what it was (STANDALONE_SPEC 6.2).
void main() {
  late LocalHttp target; // a non-empty database that must survive every rejected restore
  late Map<String, dynamic> good; // a valid backup of another ledger, as JSON
  late String before;

  setUp(() async {
    final source = await LocalHttp.open(profileName: 'Mona');
    await seedRichLedger(source);
    good = decodeBackup(await exportBytes(source.db));
    await source.close();
    target = await LocalHttp.open(profileName: 'Target');
    final g = await target.group(name: 'Keep me');
    await target.member(g['id'] as String, 'Friend');
    before = await fingerprint(target.db);
  });
  tearDown(() => target.close());

  Map<String, dynamic> copy() => decodeBackup(encodeBackup(good));
  Map<String, dynamic> row(Map<String, dynamic> json, String table, [int i = 0]) => (json[table] as List)[i] as Map<String, dynamic>;

  Future<void> expectRejected(Uint8List bytes, BackupError code) async {
    final service = BackupService(target.db);
    await expectLater(
      () async => service.restore(await service.prepareRestore(bytes)),
      throwsA(isA<BackupException>().having((e) => e.code, 'code', code)),
    );
    expect(await fingerprint(target.db), before, reason: 'a rejected restore must change nothing');
  }

  test('the untouched file is accepted (the mutations below are the only difference)', () async {
    final service = BackupService(target.db);
    final data = await service.prepareRestore(encodeBackup(copy()));
    expect(data.groups.length, 2);
  });

  group('unreadable files', () {
    test('empty', () => expectRejected(Uint8List(0), BackupError.unreadable));
    test('truncated JSON', () => expectRejected(Uint8List.fromList('{"formatVersion":1,"groups":['.codeUnits), BackupError.unreadable));
    test('not UTF-8', () => expectRejected(Uint8List.fromList([0xff, 0xfe, 0x00, 0x80]), BackupError.unreadable));
    test('a JSON list, not an object', () => expectRejected(Uint8List.fromList('[1,2,3]'.codeUnits), BackupError.unreadable));
    test('some other JSON object', () => expectRejected(Uint8List.fromList('{"hello":"world"}'.codeUnits), BackupError.invalid));
  });

  group('versions', () {
    test('a newer formatVersion is refused with its own code', () async {
      final j = copy()..['formatVersion'] = 2;
      await expectRejected(encodeBackup(j), BackupError.newerFormat);
    });
    test('a newer schemaVersion is refused with the same code', () async {
      final j = copy()..['schemaVersion'] = BackupValidator.currentSchemaVersion + 1;
      await expectRejected(encodeBackup(j), BackupError.newerFormat);
    });
    test('formatVersion 0, a string or a fraction is invalid', () async {
      await expectRejected(encodeBackup(copy()..['formatVersion'] = 0), BackupError.invalid);
      await expectRejected(encodeBackup(copy()..['formatVersion'] = '1'), BackupError.invalid);
      await expectRejected(encodeBackup(copy()..['formatVersion'] = 1.5), BackupError.invalid);
    });
    test('an older schemaVersion is accepted (the ledger tables are the same)', () async {
      final service = BackupService(target.db);
      expect((await service.prepareRestore(encodeBackup(copy()..['schemaVersion'] = 1))).schemaVersion, 1);
    });
  });

  group('structure', () {
    test('a payer that is not a member of the group', () async {
      final j = copy();
      row(j, 'expense_payers')['member_id'] = '11111111-2222-4333-8444-555555555555';
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('an expense in an unknown group', () async {
      final j = copy();
      row(j, 'expenses')['group_id'] = '11111111-2222-4333-8444-555555555555';
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('a settlement between members of another group', () async {
      final j = copy();
      final s = row(j, 'settlements');
      final other = (j['members'] as List).cast<Map<String, dynamic>>().firstWhere((m) => m['group_id'] != s['group_id']);
      s['to_member_id'] = other['id'];
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('a duplicate group id', () async {
      final j = copy();
      row(j, 'groups', 1)['id'] = row(j, 'groups')['id'];
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('a missing table', () async {
      final j = copy()..remove('expense_payers');
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('a revision history that stops before the current version', () async {
      final j = copy();
      final revisions = j['expense_revisions'] as List;
      final edited = (j['expenses'] as List).cast<Map<String, dynamic>>().firstWhere((e) => e['version'] == 2);
      revisions.removeWhere((r) => r['expense_id'] == edited['id'] && r['version'] == 2);
      await expectRejected(encodeBackup(j), BackupError.inconsistent);
    });
  });

  group('amounts', () {
    test('over the 10^12 cap', () async {
      final j = copy();
      row(j, 'expenses')['total_minor'] = 1000000000001;
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('a JSON fraction where an integer is required', () async {
      final j = copy();
      row(j, 'expense_payers')['amount_minor'] = 100.5;
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
    test('zero or negative', () async {
      final j = copy();
      row(j, 'settlements')['amount_minor'] = 0;
      await expectRejected(encodeBackup(j), BackupError.invalid);
    });
  });

  group('recompute check', () {
    test('shares that do not add up to the expense total', () async {
      final j = copy();
      final first = (j['expenses'] as List).first as Map<String, dynamic>;
      final split = (j['expense_splits'] as List).cast<Map<String, dynamic>>().firstWhere((s) => s['expense_id'] == first['id']);
      split['owed_minor'] = (split['owed_minor'] as int) + 1;
      await expectRejected(encodeBackup(j), BackupError.inconsistent);
    });
    test('payers that do not add up to the expense total', () async {
      final j = copy();
      final first = (j['expenses'] as List).first as Map<String, dynamic>;
      final payer = (j['expense_payers'] as List).cast<Map<String, dynamic>>().firstWhere((p) => p['expense_id'] == first['id']);
      payer['amount_minor'] = (payer['amount_minor'] as int) + 1;
      await expectRejected(encodeBackup(j), BackupError.inconsistent);
    });
    test('an itemized total that is not subtotal + service + tax + adjustment', () async {
      final j = copy();
      final itemized = (j['expenses'] as List).cast<Map<String, dynamic>>().firstWhere((e) => e['split_type'] == 'ITEMIZED');
      itemized['adjustment_minor'] = 5;
      await expectRejected(encodeBackup(j), BackupError.inconsistent);
    });
  });

  group('limits', () {
    test('a file over the size cap', () async {
      expect(() => BackupValidator.parse(Uint8List(11), maxBytes: 10), throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupError.tooLarge)));
    });
    test('more groups than the cap is refused before any row is decoded', () async {
      final j = copy()..['groups'] = List.generate(maxBackupGroups + 1, (_) => <String, dynamic>{});
      await expectRejected(encodeBackup(j), BackupError.tooLarge);
    });
  });

  test('a failure in the middle of the write rolls everything back (nothing changes)', () async {
    final service = BackupService(target.db);
    final data = await service.prepareRestore(encodeBackup(copy()));
    final importer = BackupImporter(target.db, beforeCommit: () async => throw StateError('disk full'));
    await expectLater(importer.replaceAll(data), throwsA(isA<BackupException>().having((e) => e.code, 'code', BackupError.failed)));
    expect(await fingerprint(target.db), before);
  });

  test('errors never carry file content', () async {
    final j = copy();
    row(j, 'groups')['name'] = 'SECRET-NAME-' * 10; // too long
    try {
      BackupValidator.parse(encodeBackup(j));
      fail('should have been rejected');
    } on BackupException catch (e) {
      expect(e.toString(), isNot(contains('SECRET')));
      expect(e.path, 'groups[0].name');
    }
  });
}
