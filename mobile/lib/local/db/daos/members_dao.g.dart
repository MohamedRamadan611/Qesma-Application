// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_dao.dart';

// ignore_for_file: type=lint
mixin _$MembersDaoMixin on DatabaseAccessor<LocalDatabase> {
  LocalProfile get localProfile => attachedDatabase.localProfile;
  LocalMeta get localMeta => attachedDatabase.localMeta;
  Members get members => attachedDatabase.members;
  ExpenseGroups get expenseGroups => attachedDatabase.expenseGroups;
  Expenses get expenses => attachedDatabase.expenses;
  ExpensePayers get expensePayers => attachedDatabase.expensePayers;
  ExpenseSplits get expenseSplits => attachedDatabase.expenseSplits;
  ExpenseItems get expenseItems => attachedDatabase.expenseItems;
  ExpenseItemAssignees get expenseItemAssignees =>
      attachedDatabase.expenseItemAssignees;
  ExpenseRevisions get expenseRevisions => attachedDatabase.expenseRevisions;
  Settlements get settlements => attachedDatabase.settlements;
  PaymentHandles get paymentHandles => attachedDatabase.paymentHandles;
  IdempotencyKeys get idempotencyKeys => attachedDatabase.idempotencyKeys;
  FuelPrices get fuelPrices => attachedDatabase.fuelPrices;
  MembersDaoManager get managers => MembersDaoManager(this);
}

class MembersDaoManager {
  final _$MembersDaoMixin _db;
  MembersDaoManager(this._db);
  $LocalProfileTableManager get localProfile =>
      $LocalProfileTableManager(_db.attachedDatabase, _db.localProfile);
  $LocalMetaTableManager get localMeta =>
      $LocalMetaTableManager(_db.attachedDatabase, _db.localMeta);
  $MembersTableManager get members =>
      $MembersTableManager(_db.attachedDatabase, _db.members);
  $ExpenseGroupsTableManager get expenseGroups =>
      $ExpenseGroupsTableManager(_db.attachedDatabase, _db.expenseGroups);
  $ExpensesTableManager get expenses =>
      $ExpensesTableManager(_db.attachedDatabase, _db.expenses);
  $ExpensePayersTableManager get expensePayers =>
      $ExpensePayersTableManager(_db.attachedDatabase, _db.expensePayers);
  $ExpenseSplitsTableManager get expenseSplits =>
      $ExpenseSplitsTableManager(_db.attachedDatabase, _db.expenseSplits);
  $ExpenseItemsTableManager get expenseItems =>
      $ExpenseItemsTableManager(_db.attachedDatabase, _db.expenseItems);
  $ExpenseItemAssigneesTableManager get expenseItemAssignees =>
      $ExpenseItemAssigneesTableManager(
        _db.attachedDatabase,
        _db.expenseItemAssignees,
      );
  $ExpenseRevisionsTableManager get expenseRevisions =>
      $ExpenseRevisionsTableManager(_db.attachedDatabase, _db.expenseRevisions);
  $SettlementsTableManager get settlements =>
      $SettlementsTableManager(_db.attachedDatabase, _db.settlements);
  $PaymentHandlesTableManager get paymentHandles =>
      $PaymentHandlesTableManager(_db.attachedDatabase, _db.paymentHandles);
  $IdempotencyKeysTableManager get idempotencyKeys =>
      $IdempotencyKeysTableManager(_db.attachedDatabase, _db.idempotencyKeys);
  $FuelPricesTableManager get fuelPrices =>
      $FuelPricesTableManager(_db.attachedDatabase, _db.fuelPrices);
}
