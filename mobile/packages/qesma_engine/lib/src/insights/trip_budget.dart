import '../civil_date.dart';
import '../engine_exception.dart';
import '../lrm.dart';

/// One expense as the budget sees it: the total of its current revision and its date. Settlements (payments and
/// POOL_DEPOSIT) have no input type here on purpose: they move money between members and are never spending (A191).
final class TripBudgetExpenseInput {
  const TripBudgetExpenseInput({
    required this.expenseId,
    required this.totalMinor,
    required this.expenseDate,
    required this.paidFromPool,
    required this.deleted,
  });

  final String expenseId;
  final int totalMinor;

  /// `YYYY-MM-DD`.
  final String expenseDate;

  /// Carried for completeness and ignored: a pool expense counts once, like any expense (A191).
  final bool paidFromPool;

  /// Soft-deleted expenses are skipped.
  final bool deleted;

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'totalMinor': totalMinor,
        'expenseDate': expenseDate,
        'paidFromPool': paidFromPool,
        'deleted': deleted,
      };

  factory TripBudgetExpenseInput.fromJson(Map<String, dynamic> json) => TripBudgetExpenseInput(
        expenseId: json['expenseId'] as String,
        totalMinor: json['totalMinor'] as int,
        expenseDate: json['expenseDate'] as String,
        paidFromPool: json['paidFromPool'] as bool,
        deleted: json['deleted'] as bool,
      );
}

/// Spending on one calendar day.
final class TripBudgetDay {
  const TripBudgetDay({required this.date, required this.totalMinor});

  final String date;
  final int totalMinor;

  Map<String, dynamic> toJson() => {'date': date, 'totalMinor': totalMinor};
}

/// The budget figures (STANDALONE_SPEC 20.2). Computed on read, never stored. Every value a screen shows is here, so
/// widgets do no arithmetic: [overByMinor] and [barFillBps] are precomputed display values.
final class TripBudgetResult {
  const TripBudgetResult({
    required this.budgetMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.progressBps,
    required this.perDay,
    required this.elapsedDays,
    required this.dailyAverageMinor,
    required this.daysLeft,
    required this.perDayLeftMinor,
    required this.costPerHeadMinor,
  });

  final int budgetMinor;

  /// Σ totals of live expenses.
  final int spentMinor;

  /// budget − spent; negative when over budget.
  final int remainingMinor;

  /// spent × 10,000 ÷ budget, round half up, not capped (above 10,000 = over budget).
  final int progressBps;

  /// Newest first; days without expenses are absent.
  final List<TripBudgetDay> perDay;

  /// Absent when there are no expenses or the trip has not started.
  final int? elapsedDays;
  final int? dailyAverageMinor;

  /// Present only with a trip end date, today ≤ end and remaining > 0.
  final int? daysLeft;
  final int? perDayLeftMinor;

  /// The largest LRM part of the budget over the ACTIVE members: an estimate, not anyone's share. Absent with none.
  final int? costPerHeadMinor;

  bool get overBudget => remainingMinor < 0;

  /// How much over the budget, as a positive amount; null when not over.
  int? get overByMinor => overBudget ? -remainingMinor : null;

  /// [progressBps] capped at 10,000, for drawing the bar.
  int get barFillBps => progressBps > 10000 ? 10000 : progressBps;

  Map<String, dynamic> toJson() => {
        'budgetMinor': budgetMinor,
        'spentMinor': spentMinor,
        'remainingMinor': remainingMinor,
        'overBudget': overBudget,
        'overByMinor': overByMinor,
        'progressBps': progressBps,
        'barFillBps': barFillBps,
        'perDay': perDay.map((d) => d.toJson()).toList(),
        'elapsedDays': elapsedDays,
        'dailyAverageMinor': dailyAverageMinor,
        'daysLeft': daysLeft,
        'perDayLeftMinor': perDayLeftMinor,
        'costPerHeadMinor': costPerHeadMinor,
      };
}

/// Pure trip-budget computation (STANDALONE_SPEC 20.2, A190, A191). [today] is passed in (the Africa/Cairo date,
/// `YYYY-MM-DD`); the engine never reads a clock. Integer money only; products through [BigInt].
abstract final class TripBudget {
  static final BigInt _tenThousand = BigInt.from(10000);

  static TripBudgetResult compute({
    required List<TripBudgetExpenseInput> expenses,
    required int budgetMinor,
    String? tripStartDate,
    String? tripEndDate,
    required int activeMemberCount,
    required String today,
  }) {
    if (budgetMinor < 1) throw EngineException.invalid('Budget must be at least 1');
    if (activeMemberCount < 0) throw EngineException.invalid('Member count must not be negative');
    final todayDay = CivilDate.epochDay(today);
    final startDay = tripStartDate == null ? null : CivilDate.epochDay(tripStartDate);
    final endDay = tripEndDate == null ? null : CivilDate.epochDay(tripEndDate);
    if (startDay != null && endDay != null && endDay < startDay) {
      throw EngineException.invalid('Trip end date must not be before the start date');
    }

    // 1. Spent and per day (live expenses only; paidFromPool ignored).
    var spent = 0;
    final byDate = <String, int>{};
    int? firstDay;
    int? lastDay;
    for (final e in expenses) {
      if (e.totalMinor < 0) throw EngineException.invalid('Expense total must not be negative');
      final day = CivilDate.epochDay(e.expenseDate);
      if (e.deleted) continue;
      spent += e.totalMinor;
      byDate[e.expenseDate] = (byDate[e.expenseDate] ?? 0) + e.totalMinor;
      if (firstDay == null || day < firstDay) firstDay = day;
      if (lastDay == null || day > lastDay) lastDay = day;
    }
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    final perDay = [for (final d in dates) TripBudgetDay(date: d, totalMinor: byDate[d]!)];

    // 2-3. Remaining and progress.
    final remaining = budgetMinor - spent;
    final progress = _roundHalfUp(BigInt.from(spent) * _tenThousand, BigInt.from(budgetMinor));

    // 5. Daily average over the elapsed days.
    int? elapsed;
    if (perDay.isNotEmpty) {
      if (startDay != null) {
        final until = endDay != null && endDay < todayDay ? endDay : todayDay;
        if (until >= startDay) elapsed = until - startDay + 1;
      } else {
        elapsed = lastDay! - firstDay! + 1;
      }
    }
    final average = elapsed == null ? null : _roundHalfUp(BigInt.from(spent), BigInt.from(elapsed));

    // 6. Per day left.
    int? daysLeft;
    int? perDayLeft;
    if (endDay != null && todayDay <= endDay && remaining > 0) {
      final from = startDay != null && startDay > todayDay ? startDay : todayDay;
      daysLeft = endDay - from + 1;
      perDayLeft = _roundHalfUp(BigInt.from(remaining), BigInt.from(daysLeft));
    }

    // 7. Cost per head: the largest LRM part of the budget, one unit per ACTIVE member.
    int? costPerHead;
    if (activeMemberCount > 0) {
      final parts = Lrm.allocate(
        budgetMinor,
        List<int>.filled(activeMemberCount, 1),
        List<int>.generate(activeMemberCount, (i) => i),
      );
      costPerHead = parts.reduce((a, b) => a > b ? a : b);
    }

    return TripBudgetResult(
      budgetMinor: budgetMinor,
      spentMinor: spent,
      remainingMinor: remaining,
      progressBps: progress,
      perDay: perDay,
      elapsedDays: elapsed,
      dailyAverageMinor: average,
      daysLeft: daysLeft,
      perDayLeftMinor: perDayLeft,
      costPerHeadMinor: costPerHead,
    );
  }

  /// round_half_up(n ÷ d) for n ≥ 0, d > 0.
  static int _roundHalfUp(BigInt n, BigInt d) => ((n * BigInt.two + d) ~/ (d * BigInt.two)).toInt();
}
