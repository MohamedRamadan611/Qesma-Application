// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = LocalDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldLocalProfileData = <v1.LocalProfileData>[];
    final expectedNewLocalProfileData = <v2.LocalProfileData>[];

    final oldLocalMetaData = <v1.LocalMetaData>[];
    final expectedNewLocalMetaData = <v2.LocalMetaData>[];

    final oldExpenseGroupsData = <v1.ExpenseGroupsData>[];
    final expectedNewExpenseGroupsData = <v2.ExpenseGroupsData>[];

    final oldMembersData = <v1.MembersData>[];
    final expectedNewMembersData = <v2.MembersData>[];

    final oldExpensesData = <v1.ExpensesData>[];
    final expectedNewExpensesData = <v2.ExpensesData>[];

    final oldExpensePayersData = <v1.ExpensePayersData>[];
    final expectedNewExpensePayersData = <v2.ExpensePayersData>[];

    final oldExpenseSplitsData = <v1.ExpenseSplitsData>[];
    final expectedNewExpenseSplitsData = <v2.ExpenseSplitsData>[];

    final oldExpenseItemsData = <v1.ExpenseItemsData>[];
    final expectedNewExpenseItemsData = <v2.ExpenseItemsData>[];

    final oldExpenseItemAssigneesData = <v1.ExpenseItemAssigneesData>[];
    final expectedNewExpenseItemAssigneesData = <v2.ExpenseItemAssigneesData>[];

    final oldExpenseRevisionsData = <v1.ExpenseRevisionsData>[];
    final expectedNewExpenseRevisionsData = <v2.ExpenseRevisionsData>[];

    final oldSettlementsData = <v1.SettlementsData>[];
    final expectedNewSettlementsData = <v2.SettlementsData>[];

    final oldPaymentHandlesData = <v1.PaymentHandlesData>[];
    final expectedNewPaymentHandlesData = <v2.PaymentHandlesData>[];

    final oldIdempotencyKeysData = <v1.IdempotencyKeysData>[];
    final expectedNewIdempotencyKeysData = <v2.IdempotencyKeysData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: LocalDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.localProfile, oldLocalProfileData);
        batch.insertAll(oldDb.localMeta, oldLocalMetaData);
        batch.insertAll(oldDb.expenseGroups, oldExpenseGroupsData);
        batch.insertAll(oldDb.members, oldMembersData);
        batch.insertAll(oldDb.expenses, oldExpensesData);
        batch.insertAll(oldDb.expensePayers, oldExpensePayersData);
        batch.insertAll(oldDb.expenseSplits, oldExpenseSplitsData);
        batch.insertAll(oldDb.expenseItems, oldExpenseItemsData);
        batch.insertAll(
          oldDb.expenseItemAssignees,
          oldExpenseItemAssigneesData,
        );
        batch.insertAll(oldDb.expenseRevisions, oldExpenseRevisionsData);
        batch.insertAll(oldDb.settlements, oldSettlementsData);
        batch.insertAll(oldDb.paymentHandles, oldPaymentHandlesData);
        batch.insertAll(oldDb.idempotencyKeys, oldIdempotencyKeysData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewLocalProfileData,
          await newDb.select(newDb.localProfile).get(),
        );
        expect(
          expectedNewLocalMetaData,
          await newDb.select(newDb.localMeta).get(),
        );
        expect(
          expectedNewExpenseGroupsData,
          await newDb.select(newDb.expenseGroups).get(),
        );
        expect(expectedNewMembersData, await newDb.select(newDb.members).get());
        expect(
          expectedNewExpensesData,
          await newDb.select(newDb.expenses).get(),
        );
        expect(
          expectedNewExpensePayersData,
          await newDb.select(newDb.expensePayers).get(),
        );
        expect(
          expectedNewExpenseSplitsData,
          await newDb.select(newDb.expenseSplits).get(),
        );
        expect(
          expectedNewExpenseItemsData,
          await newDb.select(newDb.expenseItems).get(),
        );
        expect(
          expectedNewExpenseItemAssigneesData,
          await newDb.select(newDb.expenseItemAssignees).get(),
        );
        expect(
          expectedNewExpenseRevisionsData,
          await newDb.select(newDb.expenseRevisions).get(),
        );
        expect(
          expectedNewSettlementsData,
          await newDb.select(newDb.settlements).get(),
        );
        expect(
          expectedNewPaymentHandlesData,
          await newDb.select(newDb.paymentHandles).get(),
        );
        expect(
          expectedNewIdempotencyKeysData,
          await newDb.select(newDb.idempotencyKeys).get(),
        );
      },
    );
  });
}
