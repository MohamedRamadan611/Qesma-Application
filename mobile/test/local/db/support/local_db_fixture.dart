import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';

/// Deterministic UUID-shaped ids for tests (36 characters, like the real ones).
String tid(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

const t0 = 1763337600000; // 2025-11-17T00:00:00Z in epoch millis

final profileId = tid(1);
final groupId = tid(10);
final youId = tid(20);
final aliId = tid(21);
final saraId = tid(22);

/// A profile, one group and three members: "you" (OWNER, linked, #1), Ali (#2), Sara (#3).
Future<void> seedGroup(LocalDatabase db) async {
  await db.profileDao.insertProfile(LocalProfileCompanion.insert(
    id: profileId,
    displayName: 'Mona',
    createdAt: t0,
    updatedAt: t0,
  ));
  await db.groupsDao.insertGroup(ExpenseGroupsCompanion.insert(
    id: groupId,
    ownerUserId: profileId,
    name: 'Dahab',
    type: 'TRIP',
    createdAt: t0,
    updatedAt: t0,
  ));
  await db.membersDao.insertMember(
      id: youId, groupId: groupId, displayName: 'Mona', sortOrder: 1, createdAt: t0, userId: profileId, role: 'OWNER', joinedAt: t0);
  await db.membersDao.insertMember(id: aliId, groupId: groupId, displayName: 'Ali', sortOrder: 2, createdAt: t0);
  await db.membersDao.insertMember(id: saraId, groupId: groupId, displayName: 'سارة', sortOrder: 3, createdAt: t0);
}

/// An EQUAL expense of [total] paid by "you", owed by "you" and Ali.
ExpenseGraph equalExpense(String id, {int total = 10000}) => ExpenseGraph(
      expense: ExpenseRow(
        id: id,
        groupId: groupId,
        title: 'Taxi',
        splitType: 'EQUAL',
        totalMinor: total,
        expenseDate: '2025-11-16',
        createdByUserId: profileId,
        createdAt: t0,
        updatedAt: t0,
        version: 1,
      ),
      payers: [PayerRow(expenseId: id, memberId: youId, amountMinor: total)],
      splits: [
        SplitRow(expenseId: id, memberId: youId, owedMinor: total - total ~/ 2),
        SplitRow(expenseId: id, memberId: aliId, owedMinor: total ~/ 2),
      ],
    );

/// A full itemized bill: 2 items, 12% service, 14% tax on subtotal + service, three members.
/// subtotal 10000 + service 1200 + tax 1568 + adjustment 0 = 12768.
ExpenseGraph itemizedExpense(String id) {
  final item1 = tid(900);
  final item2 = tid(901);
  return ExpenseGraph(
    expense: ExpenseRow(
      id: id,
      groupId: groupId,
      title: 'مطعم',
      splitType: 'ITEMIZED',
      totalMinor: 12768,
      expenseDate: '2025-11-16',
      subtotalMinor: 10000,
      serviceBps: 1200,
      serviceMinor: 1200,
      taxBps: 1400,
      taxMinor: 1568,
      taxBase: 'SUBTOTAL_PLUS_SERVICE',
      adjustmentMinor: 0,
      createdByUserId: profileId,
      createdAt: t0,
      updatedAt: t0,
      version: 1,
    ),
    payers: [PayerRow(expenseId: id, memberId: youId, amountMinor: 12768)],
    splits: [
      SplitRow(expenseId: id, memberId: youId, owedMinor: 3830, itemsMinor: 3000, serviceMinor: 360, taxMinor: 470, adjustmentMinor: 0),
      SplitRow(expenseId: id, memberId: aliId, owedMinor: 3830, itemsMinor: 3000, serviceMinor: 360, taxMinor: 470, adjustmentMinor: 0),
      SplitRow(expenseId: id, memberId: saraId, owedMinor: 5108, itemsMinor: 4000, serviceMinor: 480, taxMinor: 628, adjustmentMinor: 0),
    ],
    items: [
      ItemRow(id: item1, expenseId: id, name: 'Pizza', amountMinor: 6000, sortOrder: 0),
      ItemRow(id: item2, expenseId: id, name: 'كشري', amountMinor: 4000, sortOrder: 1),
    ],
    assignees: [
      AssigneeRow(itemId: item1, memberId: youId),
      AssigneeRow(itemId: item1, memberId: aliId),
      AssigneeRow(itemId: item2, memberId: saraId),
    ],
  );
}

RevisionRow revision(String id, String expenseId, int version, String changeType, {String snapshot = '{"title":"x"}'}) =>
    RevisionRow(
      id: id,
      expenseId: expenseId,
      version: version,
      changeType: changeType,
      snapshot: snapshot,
      changedByUserId: profileId,
      changedAt: t0,
    );

SettlementRow confirmedSettlement(String id, {String? from, String? to, int amount = 5000}) => SettlementRow(
      id: id,
      groupId: groupId,
      fromMemberId: from ?? aliId,
      toMemberId: to ?? youId,
      amountMinor: amount,
      settledOn: '2025-11-17',
      createdByUserId: profileId,
      createdByMemberId: youId,
      createdAt: t0,
      status: 'CONFIRMED',
      declaredAt: t0,
      confirmedAt: t0,
      recordedByAdmin: 1,
    );

/// Runs a raw statement; for rows the typed API cannot even express (wrong storage types).
Future<void> raw(LocalDatabase db, String sql, [List<Object?> args = const []]) =>
    db.customStatement(sql, args);

