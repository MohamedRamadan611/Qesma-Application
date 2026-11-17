import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/local_database.dart';

import 'generated/schema.dart';

/// Forward-only migrations (STANDALONE_SPEC 5.4). Exported snapshots live in `drift_schemas/local/`; the
/// helpers in `generated/` come from `dart run drift_dev schema generate drift_schemas/local/ test/local/db/generated/`.
/// Schema 1 is the first shipped version, so today this proves the snapshot equals the code; every later
/// version (SA6, SA10) adds a `from N-1 to N` case with data.
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
}
