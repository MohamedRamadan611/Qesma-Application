import 'package:drift/drift.dart';
import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';

export 'package:qesma_engine/qesma_engine.dart'
    show
        MyShareResult,
        MyShareCurrencySection,
        MyShareMonth,
        MyShareCategoryBreakdown,
        MyShareExpenseDetail;

/// Repository for reading My Share insights from the local database (STANDALONE_SPEC 8, Decision A130, A131, A149, A150).
/// Only non-deleted expenses across groups where the user is an active linked member are included.
/// Excluded: settlements, soft-deleted expenses, expenses from groups where the user has no linked member.
final class MyShareRepository {
  MyShareRepository(this._db);

  final LocalDatabase _db;

  static const String _query = '''
SELECT
  e.id AS expense_id,
  e.group_id AS group_id,
  e.title AS expense_title,
  g.name AS group_name,
  g.currency_code AS currency_code,
  e.expense_date AS expense_date,
  e.category AS category,
  COALESCE((SELECT s.owed_minor FROM expense_splits s WHERE s.expense_id = e.id AND s.member_id = m.id), 0) AS owed_minor,
  COALESCE((SELECT p.amount_minor FROM expense_payers p WHERE p.expense_id = e.id AND p.member_id = m.id), 0) AS paid_minor
FROM expenses e
JOIN expense_groups g ON g.id = e.group_id
JOIN members m ON m.group_id = g.id
JOIN local_profile lp ON lp.id = m.user_id
WHERE e.deleted_at IS NULL
ORDER BY e.expense_date DESC, e.created_at DESC, e.id DESC
''';

  Set<TableInfo<Table, dynamic>> get _readsFrom => {
        _db.expenses,
        _db.expenseGroups,
        _db.members,
        _db.localProfile,
        _db.expenseSplits,
        _db.expensePayers,
      };

  MyShareResult _mapQueryRows(List<QueryRow> rows) {
    final inputs = <MyShareExpenseInput>[];
    for (final r in rows) {
      final owed = r.read<int>('owed_minor');
      final paid = r.read<int>('paid_minor');
      if (owed <= 0 && paid <= 0) continue;

      inputs.add(MyShareExpenseInput(
        expenseId: r.read<String>('expense_id'),
        groupId: r.read<String>('group_id'),
        expenseTitle: r.read<String>('expense_title'),
        groupName: r.read<String>('group_name'),
        expenseDate: r.read<String>('expense_date'),
        category: r.read<String>('category'),
        currencyCode: r.read<String>('currency_code'),
        owedMinor: owed,
        paidMinor: paid,
      ));
    }
    return MyShareCalculator.compute(inputs);
  }

  /// One-shot computation of My Share.
  Future<MyShareResult> getMyShare() async {
    final rows = await _db.customSelect(_query, readsFrom: _readsFrom).get();
    return _mapQueryRows(rows);
  }

  /// Live stream of My Share, emitting updates whenever ledger tables change.
  Stream<MyShareResult> watchMyShare() {
    return _db.customSelect(_query, readsFrom: _readsFrom).watch().map(_mapQueryRows);
  }
}
