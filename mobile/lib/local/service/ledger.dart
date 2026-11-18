import 'package:drift/drift.dart';
import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';

/// The one balance predicate (A83, Java `SettlementLedgerSql.COUNTS_IN_BALANCE`): only CONFIRMED settlements count.
const String countsInBalance = "t.status = 'CONFIRMED'";

/// Ledger reads for balances. Plain sums of stored amounts only (STANDALONE_SPEC 15.2); every net, the
/// `sum = 0` check and the suggested transfers come from `qesma_engine`.
final class Ledger {
  Ledger(this._db);

  final LocalDatabase _db;

  /// Paid / owed (non-deleted expenses) and sent / received (CONFIRMED settlements) per member of [groupId],
  /// for every member in sortOrder, zeros included (Java `BalanceTotalsQuery`).
  Future<List<MemberTotals>> totals(String groupId) async {
    final rows = await _db.customSelect(
      '''
SELECT m.id AS member_id,
  COALESCE((SELECT SUM(p.amount_minor) FROM expense_payers p JOIN expenses e ON e.id = p.expense_id
            WHERE e.deleted_at IS NULL AND p.member_id = m.id), 0) AS paid,
  COALESCE((SELECT SUM(s.owed_minor) FROM expense_splits s JOIN expenses e ON e.id = s.expense_id
            WHERE e.deleted_at IS NULL AND s.member_id = m.id), 0) AS owed,
  COALESCE((SELECT SUM(t.amount_minor) FROM settlements t WHERE $countsInBalance AND t.from_member_id = m.id), 0) AS sent,
  COALESCE((SELECT SUM(t.amount_minor) FROM settlements t WHERE $countsInBalance AND t.to_member_id = m.id), 0) AS received
FROM members m WHERE m.group_id = ? ORDER BY m.sort_order''',
      variables: [Variable.withString(groupId)],
      readsFrom: {_db.members, _db.expensePayers, _db.expenseSplits, _db.expenses, _db.settlements},
    ).get();
    return [
      for (final r in rows)
        MemberTotals(
          r.read<String>('member_id'),
          r.read<int>('paid'),
          r.read<int>('owed'),
          r.read<int>('sent'),
          r.read<int>('received'),
        ),
    ];
  }

  /// Nets of every member (sortOrder, zeros included). A sum other than 0 is a broken invariant: the engine throws
  /// and the request ends as 500 INTERNAL_ERROR (never a wrong number on screen).
  Future<Map<String, int>> nets(String groupId, List<MemberRow> members) async {
    final roster = refs(members);
    try {
      return BalanceCalculator.netsFromTotals(roster, await totals(groupId));
    } on EngineException catch (e) {
      throw StateError('Balance invariant violated for group $groupId: ${e.code.wireName}');
    }
  }

  /// The caller's own net in a group (`yourNetMinor`), from that member's sums.
  Future<int> netOf(String groupId, String memberId) async {
    final all = await totals(groupId);
    for (final t in all) {
      if (t.memberId == memberId) return BalanceCalculator.memberNet(t);
    }
    return 0;
  }

  /// Sum of the totals of the group's non-deleted expenses and the newest creation time among them.
  Future<({int totalSpentMinor, int? lastExpenseAt})> groupTotals(String groupId) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(SUM(total_minor), 0) AS total, MAX(created_at) AS last '
      'FROM expenses WHERE group_id = ? AND deleted_at IS NULL',
      variables: [Variable.withString(groupId)],
      readsFrom: {_db.expenses},
    ).getSingle();
    return (totalSpentMinor: row.read<int>('total'), lastExpenseAt: row.readNullable<int>('last'));
  }

  /// The pool meter in one statement (A136, Java `SettlementRepository.poolBalanceMinor`): CONFIRMED deposits minus
  /// the totals of live (not deleted) pool expenses. May be negative. Computed, never stored.
  Future<int> poolBalance(String groupId) async {
    final row = await _db.customSelect(
      '''
SELECT (SELECT COALESCE(SUM(amount_minor), 0) FROM settlements
        WHERE group_id = ?1 AND kind = 'POOL_DEPOSIT' AND status = 'CONFIRMED')
     - (SELECT COALESCE(SUM(total_minor), 0) FROM expenses
        WHERE group_id = ?1 AND paid_from_pool = 1 AND deleted_at IS NULL) AS meter''',
      variables: [Variable.withString(groupId)],
      readsFrom: {_db.settlements, _db.expenses},
    ).getSingle();
    return row.read<int>('meter');
  }

  /// A137: the pool was used — any deposit or pool expense, cancelled and soft-deleted rows included.
  Future<bool> poolUsed(String groupId) async {
    final row = await _db.customSelect(
      "SELECT EXISTS(SELECT 1 FROM settlements WHERE group_id = ?1 AND kind = 'POOL_DEPOSIT') "
      'OR EXISTS(SELECT 1 FROM expenses WHERE group_id = ?1 AND paid_from_pool = 1) AS used',
      variables: [Variable.withString(groupId)],
      readsFrom: {_db.settlements, _db.expenses},
    ).getSingle();
    return row.read<bool>('used');
  }

  static List<MemberRef> refs(List<MemberRow> members) => [for (final m in members) MemberRef(m.id, m.sortOrder)];
}
