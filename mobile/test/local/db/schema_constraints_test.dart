import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/local/db/daos/expenses_dao.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import 'support/local_db_fixture.dart';

/// Every invariant of the schema refuses a bad row (STANDALONE_SPEC 5.3). Each case changes one value of a
/// valid row, so a rejection proves that particular constraint.
void main() {
  late LocalDatabase db;

  setUp(() async {
    db = LocalDatabase.inMemory();
    await seedGroup(db);
  });
  tearDown(() => db.close());

  final rejected = throwsA(isA<SqliteException>());
  const cap = 1000000000000; // Limits.MAX_AMOUNT_MINOR = 10^12

  Future<void> insertExpense(ExpenseGraph g) => db.expensesDao.insertGraph(g);

  test('the valid baseline rows are accepted (so each rejection below is about one value)', () async {
    await insertExpense(equalExpense(tid(100), total: cap));
    await insertExpense(itemizedExpense(tid(101)));
    await db.settlementsDao.insertSettlement(confirmedSettlement(tid(300), amount: cap));
    expect(await db.expensesDao.countLive(groupId), 2);
  });

  test('connections enforce foreign keys and use WAL where possible', () async {
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.read<int>('foreign_keys'), 1);
  });

  group('amounts', () {
    test('expense total: zero, negative and above 10^12 are refused', () async {
      for (final total in [0, -1, cap + 1]) {
        final g = equalExpense(tid(100));
        await expectLater(
          insertExpense(ExpenseGraph(expense: g.expense.copyWith(totalMinor: total), payers: const [], splits: const [])),
          rejected,
          reason: 'total $total',
        );
      }
    });

    test('payer amount: negative and above 10^12 are refused', () async {
      for (final amount in [-5, cap + 1]) {
        final g = equalExpense(tid(100));
        await expectLater(
          insertExpense(ExpenseGraph(
            expense: g.expense,
            payers: [PayerRow(expenseId: tid(100), memberId: youId, amountMinor: amount)],
            splits: const [],
          )),
          rejected,
          reason: 'payer $amount',
        );
      }
    });

    test('split owed: negative and above 10^12 are refused', () async {
      for (final owed in [-1, cap + 1]) {
        final g = equalExpense(tid(100));
        await expectLater(
          insertExpense(ExpenseGraph(
            expense: g.expense,
            payers: g.payers,
            splits: [SplitRow(expenseId: tid(100), memberId: youId, owedMinor: owed)],
          )),
          rejected,
          reason: 'owed $owed',
        );
      }
    });

    test('item amount: zero and above 10^12 are refused', () async {
      for (final amount in [0, cap + 1]) {
        final g = itemizedExpense(tid(101));
        await expectLater(
          insertExpense(ExpenseGraph(
            expense: g.expense,
            payers: g.payers,
            splits: g.splits,
            items: [g.items.first.copyWith(amountMinor: amount)],
          )),
          rejected,
          reason: 'item $amount',
        );
      }
    });

    test('settlement amount: zero and above 10^12 are refused', () async {
      for (final amount in [0, cap + 1]) {
        await expectLater(db.settlementsDao.insertSettlement(confirmedSettlement(tid(300), amount: amount)), rejected);
      }
    });

    test('STRICT tables: a REAL in a money column is refused', () async {
      await expectLater(
        raw(db, 'INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES (?, ?, 12.5)', [tid(100), youId]),
        rejected,
      );
      await insertExpense(equalExpense(tid(100)));
      await expectLater(raw(db, "UPDATE expenses SET total_minor = '100' || 'x' WHERE id = ?", [tid(100)]), rejected);
    });
  });

  group('itemized', () {
    test('bps above 10000 are refused', () async {
      final g = itemizedExpense(tid(101));
      await expectLater(
        insertExpense(ExpenseGraph(expense: g.expense.copyWith(serviceBps: const Value(10001)), payers: g.payers, splits: g.splits)),
        rejected,
      );
      await expectLater(
        insertExpense(ExpenseGraph(expense: g.expense.copyWith(taxBps: const Value(10001)), payers: g.payers, splits: g.splits)),
        rejected,
      );
    });

    test('a total that is not subtotal + service + tax + adjustment is refused', () async {
      final g = itemizedExpense(tid(101));
      await expectLater(
        insertExpense(ExpenseGraph(expense: g.expense.copyWith(totalMinor: 12769), payers: g.payers, splits: g.splits)),
        rejected,
      );
    });

    test('a split breakdown that does not add up to owed is refused', () async {
      final g = itemizedExpense(tid(101));
      await expectLater(
        insertExpense(ExpenseGraph(
          expense: g.expense,
          payers: g.payers,
          splits: [g.splits.first.copyWith(owedMinor: 3831)],
        )),
        rejected,
      );
    });

    test('itemized columns on an EQUAL expense are refused', () async {
      final g = equalExpense(tid(100));
      await expectLater(
        insertExpense(ExpenseGraph(expense: g.expense.copyWith(subtotalMinor: const Value(10000)), payers: g.payers, splits: g.splits)),
        rejected,
      );
    });
  });

  group('itemized v2 (schema 8, Java V21)', () {
    // Baseline: subtotal 10000, service 12% = 1200, tax 1568, total 12768, discount 0.
    // A fresh id per attempt, so a wrongly accepted row cannot make the next case fail on its primary key instead.
    var next = 500;
    Future<void> withExpense(ExpenseRow Function(ExpenseRow e) change) {
      final g = itemizedExpense(tid(next++));
      return insertExpense(ExpenseGraph(expense: change(g.expense), payers: g.payers, splits: g.splits));
    }

    test('a discount in one form, below the subtotal, that the total subtracts, is accepted', () async {
      await withExpense((e) => e.copyWith(
          discountAmountMinor: const Value(1000), discountMinor: const Value(1000), totalMinor: 11768));
    });

    test('a discount in both forms, at or above the subtotal, out of range, or without its total is refused', () async {
      await expectLater(withExpense((e) => e.copyWith(
          discountBps: const Value(1000), discountAmountMinor: const Value(1000), discountMinor: const Value(1000),
          totalMinor: 11768)), rejected);
      await expectLater(withExpense((e) => e.copyWith(
          discountAmountMinor: const Value(10000), discountMinor: const Value(10000), totalMinor: 2768)), rejected);
      await expectLater(withExpense((e) => e.copyWith(
          discountBps: const Value(10000), discountMinor: const Value(9999), totalMinor: 2769)), rejected);
      await expectLater(withExpense((e) => e.copyWith(discountBps: const Value(1000))), rejected); // form, discount 0
      await expectLater(withExpense((e) => e.copyWith(discountMinor: const Value(1000), totalMinor: 11768)), rejected);
      await expectLater(withExpense((e) => e.copyWith(
          discountAmountMinor: const Value(1000), discountMinor: const Value(999), totalMinor: 11769)), rejected);
      await expectLater(withExpense((e) => e.copyWith(discountMinor: const Value(null))), rejected);
      await expectLater(withExpense((e) => e.copyWith(
          discountAmountMinor: const Value(1000), discountMinor: const Value(1000))), rejected); // total not reduced
    });

    test('a service or tax given as an amount must equal its total and cannot also have a rate', () async {
      await withExpense((e) => e.copyWith(serviceBps: const Value(null), serviceAmountMinor: const Value(1200)));



      await expectLater(
          withExpense((e) => e.copyWith(serviceBps: const Value(null), serviceAmountMinor: const Value(1300))), rejected);
      await expectLater(withExpense((e) => e.copyWith(serviceAmountMinor: const Value(1200))), rejected);
      await expectLater(withExpense((e) => e.copyWith(taxAmountMinor: const Value(1568))), rejected);
      await expectLater(withExpense((e) => e.copyWith(
          taxBps: const Value(null), taxAmountMinor: const Value(1568), taxBase: const Value(null))), rejected);
      await expectLater(withExpense((e) => e.copyWith(serviceAmountMinor: const Value(0))), rejected);
    });

    test('an item line must be quantity x unit price, quantity 1..999', () async {
      final g = itemizedExpense(tid(101));
      Future<void> withItem(ItemRow Function(ItemRow i) change) => insertExpense(ExpenseGraph(
          expense: g.expense, payers: g.payers, splits: g.splits, items: [change(g.items.first)], assignees: const []));
      await expectLater(withItem((i) => i.copyWith(quantity: 3)), rejected);
      await expectLater(withItem((i) => i.copyWith(quantity: 0, unitAmountMinor: 6000)), rejected);
      await expectLater(withItem((i) => i.copyWith(quantity: 1000, amountMinor: 6000, unitAmountMinor: 6)), rejected);
      await expectLater(withItem((i) => i.copyWith(unitAmountMinor: 0)), rejected);
      await withItem((i) => i.copyWith(quantity: 3, unitAmountMinor: 2000));
    });

    test('a split discount part is in the breakdown, never above the items, and subtracted from owed', () async {
      final g = itemizedExpense(tid(101));
      Future<void> withSplit(SplitRow Function(SplitRow s) change) =>
          insertExpense(ExpenseGraph(expense: g.expense, payers: g.payers, splits: [change(g.splits.first)]));
      await expectLater(withSplit((s) => s.copyWith(discountMinor: const Value(null))), rejected);
      await expectLater(withSplit((s) => s.copyWith(discountMinor: const Value(100))), rejected); // owed not reduced
      await expectLater(withSplit((s) => s.copyWith(discountMinor: const Value(3001), owedMinor: 829)), rejected);
      await withSplit((s) => s.copyWith(discountMinor: const Value(100), owedMinor: 3730));
    });

    test('delivery (schema 9, Java V22) is part of the total and of each breakdown, and mandatory on itemized rows', () async {
      // Baseline total 12768 + delivery 500 = 13268; the one member row carries its own part.
      await withExpense((e) => e.copyWith(deliveryMinor: const Value(500), totalMinor: 13268));
      await expectLater(withExpense((e) => e.copyWith(deliveryMinor: const Value(500))), rejected); // total not raised
      await expectLater(withExpense((e) => e.copyWith(deliveryMinor: const Value(null))), rejected);
      await expectLater(withExpense((e) => e.copyWith(deliveryMinor: const Value(-1), totalMinor: 12767)), rejected);
      await expectLater(
          withExpense((e) => e.copyWith(deliveryMinor: const Value(1000000000001), totalMinor: 1000000012769)), rejected);

      final g = itemizedExpense(tid(102));
      Future<void> withSplit(SplitRow Function(SplitRow s) change) =>
          insertExpense(ExpenseGraph(expense: g.expense, payers: g.payers, splits: [change(g.splits.first)]));
      await expectLater(withSplit((s) => s.copyWith(deliveryMinor: const Value(null))), rejected);
      await expectLater(withSplit((s) => s.copyWith(deliveryMinor: const Value(100))), rejected); // owed not raised
      await withSplit((s) => s.copyWith(deliveryMinor: const Value(100), owedMinor: 3930));
    });

    test('delivery is refused on an EQUAL expense', () async {
      final g = equalExpense(tid(103));
      await expectLater(
          insertExpense(ExpenseGraph(expense: g.expense.copyWith(deliveryMinor: const Value(0)), payers: g.payers, splits: g.splits)),
          rejected);
    });

    test('the v2 columns are refused on an EQUAL expense', () async {
      final g = equalExpense(tid(100));
      for (final e in [
        g.expense.copyWith(discountMinor: const Value(0)),
        g.expense.copyWith(discountBps: const Value(1000)),
        g.expense.copyWith(serviceAmountMinor: const Value(100)),
        g.expense.copyWith(taxAmountMinor: const Value(100)),
      ]) {
        await expectLater(insertExpense(ExpenseGraph(expense: e, payers: g.payers, splits: g.splits)), rejected);
      }
    });
  });

  test('impossible or malformed dates are refused', () async {
    for (final date in ['2026-02-30', '2026-2-03', '03/02/2026', '']) {
      final g = equalExpense(tid(100));
      await expectLater(
        insertExpense(ExpenseGraph(expense: g.expense.copyWith(expenseDate: date), payers: g.payers, splits: g.splits)),
        rejected,
        reason: date,
      );
    }
  });

  test('a settlement from a member to the same member is refused', () async {
    await expectLater(db.settlementsDao.insertSettlement(confirmedSettlement(tid(300), from: aliId, to: aliId)), rejected);
  });

  test('settlement status timestamps must match the status (V15)', () async {
    final s = confirmedSettlement(tid(300));
    await expectLater(db.settlementsDao.insertSettlement(s.copyWith(confirmedAt: const Value(null))), rejected);
    await expectLater(db.settlementsDao.insertSettlement(s.copyWith(status: 'CANCELLED')), rejected);
  });

  group('foreign keys', () {
    test('an orphan payer (unknown expense) is refused', () async {
      await expectLater(
        raw(db, 'INSERT INTO expense_payers (expense_id, member_id, amount_minor) VALUES (?, ?, 100)', [tid(999), youId]),
        rejected,
      );
    });

    test('a payer who is not a member is refused', () async {
      final g = equalExpense(tid(100));
      await expectLater(
        insertExpense(ExpenseGraph(
          expense: g.expense,
          payers: [PayerRow(expenseId: tid(100), memberId: tid(999), amountMinor: 10000)],
          splits: const [],
        )),
        rejected,
      );
    });

    test('a member used by the ledger cannot be hard-deleted, nor can its group', () async {
      await insertExpense(equalExpense(tid(100)));
      await expectLater(db.membersDao.deleteMember(aliId), rejected);
      await expectLater(db.groupsDao.deleteGroupWithMembers(groupId), rejected);
      expect(await db.membersDao.listByGroup(groupId), hasLength(3), reason: 'the failed transaction changed nothing');
    });

    test('an unused member and an empty group can be hard-deleted (A23)', () async {
      expect(await db.membersDao.deleteMember(saraId), 1);
      await db.groupsDao.deleteGroupWithMembers(groupId);
      expect(await db.groupsDao.findById(groupId), isNull);
    });
  });

  group('members', () {
    test('a duplicate name is refused after normalization (English case and spacing)', () async {
      await expectLater(
        db.membersDao.insertMember(id: tid(30), groupId: groupId, displayName: '  ALI ', sortOrder: 4, createdAt: t0),
        rejected,
      );
      await db.membersDao.insertMember(id: tid(31), groupId: groupId, displayName: 'Ahmed Ali', sortOrder: 4, createdAt: t0);
      await expectLater(
        db.membersDao.insertMember(id: tid(32), groupId: groupId, displayName: 'ahmed \t ALI', sortOrder: 5, createdAt: t0),
        rejected,
      );
    });

    test('a duplicate Arabic name is refused after normalization (spacing)', () async {
      await db.membersDao.insertMember(id: tid(30), groupId: groupId, displayName: 'محمد علي', sortOrder: 4, createdAt: t0);
      await expectLater(
        db.membersDao.insertMember(id: tid(31), groupId: groupId, displayName: '  محمد   علي ', sortOrder: 5, createdAt: t0),
        rejected,
      );
      // Arabic letters are not folded (owner decision): a different hamza form is a different name.
      await db.membersDao.insertMember(id: tid(32), groupId: groupId, displayName: 'أحمد', sortOrder: 6, createdAt: t0);
      await db.membersDao.insertMember(id: tid(33), groupId: groupId, displayName: 'احمد', sortOrder: 7, createdAt: t0);
    });

    test('a rename onto an existing name is refused', () async {
      await expectLater(db.membersDao.rename(aliId, '  سارة '), rejected);
    });

    test('the same name is fine in another group', () async {
      await db.groupsDao.insertGroup(ExpenseGroupsCompanion.insert(
          id: tid(11), ownerUserId: profileId, name: 'Home', type: 'HOUSING', createdAt: t0, updatedAt: t0));
      await db.membersDao.insertMember(id: tid(30), groupId: tid(11), displayName: 'ali', sortOrder: 1, createdAt: t0);
    });

    test('a reused sort order is refused', () async {
      await expectLater(
        db.membersDao.insertMember(id: tid(30), groupId: groupId, displayName: 'Omar', sortOrder: 2, createdAt: t0),
        rejected,
      );
    });

    test('a second OWNER and an unlinked OWNER are refused', () async {
      await expectLater(
        db.membersDao.insertMember(
            id: tid(30), groupId: groupId, displayName: 'Omar', sortOrder: 4, createdAt: t0, role: 'OWNER'),
        rejected,
      );
      await expectLater(
        db.membersDao.insertMember(
            id: tid(30), groupId: groupId, displayName: 'Omar', sortOrder: 4, createdAt: t0, role: 'OWNER', userId: profileId),
        rejected,
      );
    });

    test('a name longer than 40 characters is refused', () async {
      await expectLater(
        db.membersDao.insertMember(id: tid(30), groupId: groupId, displayName: 'ا' * 41, sortOrder: 4, createdAt: t0),
        rejected,
      );
    });

    test('nextMemberSeq moves the counter and never reuses a value', () async {
      expect(await db.groupsDao.nextMemberSeq(groupId), 1);
      expect(await db.groupsDao.nextMemberSeq(groupId), 2);
    });
  });

  group('revisions and idempotency', () {
    test('a snapshot that is not a JSON object is refused', () async {
      await insertExpense(equalExpense(tid(100)));
      for (final snapshot in ['{not json', '[1,2]']) {
        await expectLater(db.revisionsDao.insertRevision(revision(tid(400), tid(100), 1, 'CREATE', snapshot: snapshot)), rejected);
      }
    });

    test('an unknown change type and a duplicate version are refused', () async {
      await insertExpense(equalExpense(tid(100)));
      await expectLater(db.revisionsDao.insertRevision(revision(tid(400), tid(100), 1, 'PATCH')), rejected);
      await db.revisionsDao.insertRevision(revision(tid(400), tid(100), 1, 'CREATE'));
      await expectLater(db.revisionsDao.insertRevision(revision(tid(401), tid(100), 1, 'UPDATE')), rejected);
    });

    test('an idempotency key is stored once; old keys are purged', () async {
      IdempotencyRow key(String k, int at) => IdempotencyRow(
          key: k, endpoint: 'POST /groups/x/expenses', requestHash: 'h', responseStatus: 201, responseBody: '{}', createdAt: at);
      await db.idempotencyDao.insertKey(key(tid(600), t0));
      await expectLater(db.idempotencyDao.insertKey(key(tid(600), t0)), rejected);
      await expectLater(db.idempotencyDao.insertKey(key('short', t0)), rejected);
      await db.idempotencyDao.insertKey(key(tid(601), t0 + 1000));
      expect(await db.idempotencyDao.deleteCreatedBefore(t0 + 1), 1);
      expect(await db.idempotencyDao.find(tid(601)), isNotNull);
    });
  });

  group('singletons and handles', () {
    test('a second profile row is refused; local_meta exists at the current schema', () async {
      await expectLater(
        db.profileDao.insertProfile(LocalProfileCompanion.insert(id: tid(2), displayName: 'X', createdAt: t0, updatedAt: t0)),
        rejected,
      );
      expect((await db.metaDao.get()).createdSchemaVersion, db.schemaVersion);
      await expectLater(raw(db, 'INSERT INTO local_meta (id, created_schema_version, created_at) VALUES (2, 1, 0)'), rejected);
    });

    PaymentHandleRow handle(String type, String value) =>
        PaymentHandleRow(id: tid(700), userId: profileId, type: type, value: value, createdAt: t0, updatedAt: t0);

    test('wallet numbers follow ^01[0125][0-9]{8}\$', () async {
      for (final bad in ['0131234567', '01312345678', '0101234567', '010123456789', '٠١٠١٢٣٤٥٦٧٨', '+201012345678']) {
        await expectLater(db.paymentHandlesDao.upsert(handle('WALLET', bad)), rejected, reason: bad);
      }
      for (final ok in ['01012345678', '01112345678', '01212345678', '01512345678']) {
        await db.paymentHandlesDao.upsert(handle('WALLET', ok));
      }
      expect(await db.paymentHandlesDao.listForUser(profileId), hasLength(1), reason: 'one handle per type, updated in place');
    });

    test('InstaPay addresses follow ^[a-z0-9._-]+@[a-z0-9.-]+\$ with 3..60 characters', () async {
      for (final bad in ['@x', 'a@', 'ab', 'Mona@instapay', 'mona@@x', 'mo@na@x', 'mona@insta_pay', 'mo na@x', 'مني@x', 'a@${'b' * 59}']) {
        await expectLater(db.paymentHandlesDao.upsert(handle('INSTAPAY', bad)), rejected, reason: bad);
      }
      for (final ok in ['a@b', 'mona.ali_1-x@instapay', 'm@a.b-c', 'a@${'b' * 58}']) {
        await db.paymentHandlesDao.upsert(handle('INSTAPAY', ok));
      }
    });

    test('InstaPay links: https://ipn.eg/ + URL-safe characters, 16..200, case kept', () async {
      for (final bad in [
        'http://ipn.eg/S/m/instapay/6BrrCd', // not https
        'https://ipn.eg.evil.com/S/x', // lookalike host
        'https://evil.com/ipn.eg/S/x',
        'https://IPN.EG/S/x', // the stored form has a lower-case host
        'https://ipn.eg/', // empty path
        'https://ipn.eg/S/ x', // space
        'https://ipn.eg/S/\u0645', // non-ASCII
        'https://ipn.eg/S/<script>',
        'https://ipn.eg/${'a' * 190}', // over 200
      ]) {
        await expectLater(db.paymentHandlesDao.upsert(handle('INSTAPAY', bad)), rejected, reason: bad);
      }
      for (final ok in ['https://ipn.eg/S/m.ramadan611/instapay/6BrrCd', 'https://ipn.eg/x?a=1&b=2#f', 'https://ipn.eg/${'a' * 185}']) {
        await db.paymentHandlesDao.upsert(handle('INSTAPAY', ok));
      }
      expect((await db.paymentHandlesDao.listForUser(profileId)).single.value, 'https://ipn.eg/${'a' * 185}');
    });
  });
}
