import 'package:drift/drift.dart';

import '../db/local_database.dart';

/// One pool deposit as recorded (a settlement of kind POOL_DEPOSIT); cancelled ones stay with their status.
final class PoolDeposit {
  const PoolDeposit({
    required this.id,
    required this.fromMemberId,
    required this.amountMinor,
    required this.settledOn,
    required this.status,
    this.note,
  });

  final String id;
  final String fromMemberId;
  final int amountMinor;

  /// `YYYY-MM-DD`.
  final String settledOn;
  final String status;
  final String? note;

  bool get cancelled => status == 'CANCELLED';
}

/// The pool breakdown the meter card cannot get from the contract (STANDALONE_SPEC 10, A136, SA10 decision): the
/// remaining amount itself is `GroupDto.poolBalanceMinor`; these sums are its two parts. Computed, never stored.
final class PoolSummary {
  const PoolSummary({required this.depositedMinor, required this.spentMinor, required this.locked, required this.deposits});

  /// Σ CONFIRMED deposits.
  final int depositedMinor;

  /// Σ totals of live (not deleted) pool expenses.
  final int spentMinor;

  /// A137: the treasurer can no longer change (any deposit or pool expense, cancelled and soft-deleted included).
  final bool locked;

  /// Newest first.
  final List<PoolDeposit> deposits;
}

/// Local-mode read-model of a group's pool (like My share and the recap, the sums are plain SQL in `lib/local/`).
final class PoolSummaryRepository {
  PoolSummaryRepository(this._db);

  final LocalDatabase _db;

  static const String _totals = '''
SELECT
  (SELECT COALESCE(SUM(amount_minor), 0) FROM settlements
   WHERE group_id = ?1 AND kind = 'POOL_DEPOSIT' AND status = 'CONFIRMED') AS deposited,
  (SELECT COALESCE(SUM(total_minor), 0) FROM expenses
   WHERE group_id = ?1 AND paid_from_pool = 1 AND deleted_at IS NULL) AS spent,
  EXISTS(SELECT 1 FROM settlements WHERE group_id = ?1 AND kind = 'POOL_DEPOSIT')
   OR EXISTS(SELECT 1 FROM expenses WHERE group_id = ?1 AND paid_from_pool = 1) AS locked''';

  static const String _deposits = '''
SELECT id, from_member_id, amount_minor, settled_on, status, note FROM settlements
WHERE group_id = ?1 AND kind = 'POOL_DEPOSIT'
ORDER BY settled_on DESC, created_at DESC, id DESC''';

  Set<ResultSetImplementation<dynamic, dynamic>> get _readsFrom => {_db.settlements, _db.expenses};

  Future<PoolSummary> summary(String groupId) => _db.transaction(() async {
        final vars = [Variable.withString(groupId)];
        final totals = await _db.customSelect(_totals, variables: vars, readsFrom: _readsFrom).getSingle();
        final rows = await _db.customSelect(_deposits, variables: vars, readsFrom: _readsFrom).get();
        return _map(totals, rows);
      });

  /// Re-emits whenever a settlement or an expense changes (the pool screen stays live).
  Stream<PoolSummary> watch(String groupId) {
    final vars = [Variable.withString(groupId)];
    return _db
        .customSelect(_deposits, variables: vars, readsFrom: _readsFrom)
        .watch()
        .asyncMap((_) => summary(groupId));
  }

  static PoolSummary _map(QueryRow totals, List<QueryRow> rows) => PoolSummary(
        depositedMinor: totals.read<int>('deposited'),
        spentMinor: totals.read<int>('spent'),
        locked: totals.read<bool>('locked'),
        deposits: [
          for (final r in rows)
            PoolDeposit(
              id: r.read<String>('id'),
              fromMemberId: r.read<String>('from_member_id'),
              amountMinor: r.read<int>('amount_minor'),
              settledOn: r.read<String>('settled_on'),
              status: r.read<String>('status'),
              note: r.readNullable<String>('note'),
            ),
        ],
      );
}
