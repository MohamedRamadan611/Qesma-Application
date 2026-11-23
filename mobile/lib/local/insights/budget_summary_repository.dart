import 'package:drift/drift.dart';
import 'package:qesma_engine/qesma_engine.dart';

import '../db/local_database.dart';

/// Spending on one calendar day (`YYYY-MM-DD`).
final class BudgetDay {
  const BudgetDay({required this.date, required this.totalMinor});

  final String date;
  final int totalMinor;
}

/// The trip-budget figures a screen shows (STANDALONE_SPEC 20.2), copied from the engine's [TripBudgetResult] so
/// `lib/features/` never imports the engine (A149). Every value is precomputed: widgets do no arithmetic.
final class BudgetSummary {
  const BudgetSummary({
    required this.budgetMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.overBudget,
    required this.overByMinor,
    required this.progressBps,
    required this.barFillBps,
    required this.perDay,
    required this.elapsedDays,
    required this.dailyAverageMinor,
    required this.daysLeft,
    required this.perDayLeftMinor,
    required this.costPerHeadMinor,
  });

  factory BudgetSummary.of(TripBudgetResult r) => BudgetSummary(
        budgetMinor: r.budgetMinor,
        spentMinor: r.spentMinor,
        remainingMinor: r.remainingMinor,
        overBudget: r.overBudget,
        overByMinor: r.overByMinor,
        progressBps: r.progressBps,
        barFillBps: r.barFillBps,
        perDay: [for (final d in r.perDay) BudgetDay(date: d.date, totalMinor: d.totalMinor)],
        elapsedDays: r.elapsedDays,
        dailyAverageMinor: r.dailyAverageMinor,
        daysLeft: r.daysLeft,
        perDayLeftMinor: r.perDayLeftMinor,
        costPerHeadMinor: r.costPerHeadMinor,
      );

  final int budgetMinor;
  final int spentMinor;

  /// Negative when over budget.
  final int remainingMinor;
  final bool overBudget;

  /// Positive amount over the budget; null when not over.
  final int? overByMinor;

  /// Uncapped (above 10,000 = over budget).
  final int progressBps;

  /// [progressBps] capped at 10,000, for the bar.
  final int barFillBps;

  /// Newest first.
  final List<BudgetDay> perDay;
  final int? elapsedDays;
  final int? dailyAverageMinor;
  final int? daysLeft;
  final int? perDayLeftMinor;

  /// An estimate (budget over the ACTIVE members, rounded up), not anyone's share.
  final int? costPerHeadMinor;
}

/// Local-mode read-model of a group's trip budget (STANDALONE_SPEC 20.2, A191; local computation like A150). The
/// figures come from the pure engine [TripBudget]; nothing here is stored. Only `expenses` rows are read for spending:
/// settlements (payments and POOL_DEPOSIT) are never spending, and the `expenses` row is the current revision.
final class BudgetSummaryRepository {
  BudgetSummaryRepository(this._db);

  final LocalDatabase _db;

  static const String _settings = '''
SELECT g.budget_minor, g.trip_start_date, g.trip_end_date,
  (SELECT COUNT(*) FROM members m WHERE m.group_id = g.id AND m.status = 'ACTIVE') AS active_members
FROM expense_groups g WHERE g.id = ?1''';

  static const String _expenses = '''
SELECT id, total_minor, expense_date, paid_from_pool FROM expenses
WHERE group_id = ?1 AND deleted_at IS NULL''';

  Set<ResultSetImplementation<dynamic, dynamic>> get _readsFrom => {_db.expenseGroups, _db.members, _db.expenses};

  /// The figures for [groupId] on [today] (`YYYY-MM-DD`, Africa/Cairo), or null when the group is unknown or has no
  /// budget set.
  Future<BudgetSummary?> summary(String groupId, String today) => _db.transaction(() async {
        final vars = [Variable.withString(groupId)];
        final settings = await _db.customSelect(_settings, variables: vars, readsFrom: _readsFrom).getSingleOrNull();
        final budget = settings?.readNullable<int>('budget_minor');
        if (settings == null || budget == null) return null;
        final rows = await _db.customSelect(_expenses, variables: vars, readsFrom: _readsFrom).get();
        return BudgetSummary.of(TripBudget.compute(
          expenses: [
            for (final r in rows)
              TripBudgetExpenseInput(
                expenseId: r.read<String>('id'),
                totalMinor: r.read<int>('total_minor'),
                expenseDate: r.read<String>('expense_date'),
                paidFromPool: r.read<bool>('paid_from_pool'),
                deleted: false,
              ),
          ],
          budgetMinor: budget,
          tripStartDate: settings.readNullable<String>('trip_start_date'),
          tripEndDate: settings.readNullable<String>('trip_end_date'),
          activeMemberCount: settings.read<int>('active_members'),
          today: today,
        ));
      });

  /// Re-emits whenever the group's settings, its members or its expenses change.
  Stream<BudgetSummary?> watch(String groupId, String today) {
    final vars = [Variable.withString(groupId)];
    return _db
        .customSelect(_settings, variables: vars, readsFrom: _readsFrom)
        .watch()
        .asyncMap((_) => summary(groupId, today));
  }
}
