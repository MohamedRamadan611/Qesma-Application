import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import 'support/local_db_fixture.dart';

void main() {
  late LocalDatabase db;

  setUp(() async {
    db = LocalDatabase.inMemory();
    await seedGroup(db);
    await db.expensesDao.insertGraph(equalExpense(tid(100)));
    await db.revisionsDao.insertRevision(revision(tid(400), tid(100), 1, 'CREATE'));
  });
  tearDown(() => db.close());

  test('the database refuses to UPDATE a revision (trigger), even by raw SQL', () async {
    await expectLater(
      db.customStatement("UPDATE expense_revisions SET snapshot = '{}' WHERE id = ?", [tid(400)]),
      throwsA(isA<SqliteException>().having((e) => e.message, 'message', contains('append-only'))),
    );
    final rows = await db.revisionsDao.listByExpense(tid(100));
    expect(rows.single.snapshot, '{"title":"x"}');
  });

  test('RevisionsDao has no way to change or remove a revision', () {
    final source = File('lib/local/db/daos/revisions_dao.dart').readAsStringSync();
    for (final forbidden in ['update(', 'delete(', 'customStatement', 'customUpdate', 'replace(', 'insertOnConflictUpdate', 'onConflict']) {
      expect(source.contains(forbidden), isFalse, reason: 'revisions_dao.dart must not use $forbidden');
    }
  });

  test('revisions are listed oldest first', () async {
    await db.revisionsDao.insertRevision(revision(tid(401), tid(100), 2, 'UPDATE'));
    final versions = (await db.revisionsDao.listByExpense(tid(100))).map((r) => r.version);
    expect(versions, [1, 2]);
  });
}
