import 'dart:convert';
import 'dart:io';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

final Directory _fixturesDir = Directory('../../../fixtures/insights');

List<File> _fixtureFiles() {
  if (!_fixturesDir.existsSync()) return [];
  return _fixturesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('budget-') && f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

TripBudgetExpenseInput _e(int total, String date, {bool pool = false, bool deleted = false, String id = 'e'}) =>
    TripBudgetExpenseInput(expenseId: id, totalMinor: total, expenseDate: date, paidFromPool: pool, deleted: deleted);

TripBudgetResult _compute({
  List<TripBudgetExpenseInput> expenses = const [],
  int budget = 100000,
  String? start,
  String? end,
  int members = 2,
  String today = '2026-11-02',
}) =>
    TripBudget.compute(
      expenses: expenses,
      budgetMinor: budget,
      tripStartDate: start,
      tripEndDate: end,
      activeMemberCount: members,
      today: today,
    );

void main() {
  group('TripBudget fixtures (STANDALONE_SPEC 20.3)', () {
    test('all six budget fixtures are present', () {
      expect(_fixtureFiles().length, greaterThanOrEqualTo(6));
    });

    for (final file in _fixtureFiles()) {
      final name = file.uri.pathSegments.last;
      test(name, () {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final input = json['input'] as Map<String, dynamic>;
        final result = TripBudget.compute(
          expenses: (input['expenses'] as List<dynamic>)
              .map((e) => TripBudgetExpenseInput.fromJson(e as Map<String, dynamic>))
              .toList(),
          budgetMinor: input['budgetMinor'] as int,
          tripStartDate: input['tripStartDate'] as String?,
          tripEndDate: input['tripEndDate'] as String?,
          activeMemberCount: input['activeMemberCount'] as int,
          today: input['today'] as String,
        );
        expect(result.toJson(), equals(json['expected']));
      });
    }
  });

  group('TripBudget rules (20.2, A191)', () {
    test('a pool expense counts exactly once, like any expense', () {
      final withPool = _compute(expenses: [_e(5000, '2026-11-01', pool: true)]);
      final withoutPool = _compute(expenses: [_e(5000, '2026-11-01')]);
      expect(withPool.spentMinor, 5000);
      expect(withPool.toJson(), withoutPool.toJson());
    });

    test('a soft-deleted expense changes nothing, not even the no-start-date range', () {
      final base = [_e(3000, '2026-11-02')];
      expect(
        _compute(expenses: [...base, _e(9999, '2026-10-01', deleted: true)]).toJson(),
        _compute(expenses: base).toJson(),
      );
    });

    test('progress rounds half up and is not capped; the bar is', () {
      expect(_compute(budget: 3, expenses: [_e(1, '2026-11-01')]).progressBps, 3333); // 3333.33
      expect(_compute(budget: 3, expenses: [_e(2, '2026-11-01')]).progressBps, 6667); // 6666.67
      expect(_compute(budget: 20000, expenses: [_e(1, '2026-11-01')]).progressBps, 1); // 0.5 -> 1
      final at = _compute(budget: 5000, expenses: [_e(5000, '2026-11-01')]);
      expect((at.progressBps, at.barFillBps, at.remainingMinor, at.overBudget, at.overByMinor), (10000, 10000, 0, false, null));
      final over = _compute(budget: 5000, expenses: [_e(15000, '2026-11-01')]);
      expect((over.progressBps, over.barFillBps, over.overByMinor), (30000, 10000, 10000));
    });

    test('progress at the amount cap does not overflow', () {
      const cap = Limits.maxAmountMinor;
      final r = _compute(budget: 1, expenses: [_e(cap, '2026-11-01'), _e(cap, '2026-11-02')]);
      expect(r.progressBps, 2 * cap * 10000);
    });

    test('daily average rounds half up', () {
      // 5 / 2 = 2.5 -> 3 ; 7 / 3 = 2.33 -> 2
      expect(_compute(expenses: [_e(5, '2026-11-01')], start: '2026-11-01').dailyAverageMinor, 3);
      expect(_compute(expenses: [_e(7, '2026-11-01')], start: '2026-11-01', today: '2026-11-03').dailyAverageMinor, 2);
    });

    test('elapsed days stop at the trip end', () {
      final r = _compute(expenses: [_e(900, '2026-11-01')], start: '2026-11-01', end: '2026-11-03', today: '2026-11-20');
      expect((r.elapsedDays, r.dailyAverageMinor), (3, 300));
    });

    test('no daily average before the trip starts or without expenses', () {
      final notStarted = _compute(expenses: [_e(900, '2026-10-20')], start: '2026-11-05', end: '2026-11-09');
      expect((notStarted.elapsedDays, notStarted.dailyAverageMinor), (null, null));
      final empty = _compute(start: '2026-11-01');
      expect((empty.elapsedDays, empty.dailyAverageMinor), (null, null));
    });

    test('per day left counts from the start when the trip has not started', () {
      final r = _compute(budget: 1000, start: '2026-11-05', end: '2026-11-09'); // 5 days, 1000 / 5
      expect((r.daysLeft, r.perDayLeftMinor), (5, 200));
    });

    test('per day left rounds half up and includes today', () {
      final r = _compute(budget: 1001, end: '2026-11-03'); // 11-02..11-03 = 2 days, 500.5 -> 501
      expect((r.daysLeft, r.perDayLeftMinor), (2, 501));
    });

    test('no per day left after the trip end, at zero remaining, or over budget', () {
      expect(_compute(end: '2026-11-01').perDayLeftMinor, isNull);
      expect(_compute(budget: 500, expenses: [_e(500, '2026-11-01')], end: '2026-11-09').perDayLeftMinor, isNull);
      final over = _compute(budget: 500, expenses: [_e(600, '2026-11-01')], end: '2026-11-09');
      expect((over.daysLeft, over.perDayLeftMinor), (null, null));
    });

    test('per day is grouped by date, newest first, and sums to spent', () {
      final r = _compute(expenses: [
        _e(100, '2026-11-01'),
        _e(250, '2026-11-03'),
        _e(5, '2026-11-01'),
        _e(1, '2026-10-31'),
      ]);
      expect(r.perDay.map((d) => (d.date, d.totalMinor)).toList(),
          [('2026-11-03', 250), ('2026-11-01', 105), ('2026-10-31', 1)]);
      expect(r.perDay.fold<int>(0, (a, d) => a + d.totalMinor), r.spentMinor);
    });

    test('cost per head is the largest LRM part (budget / members rounded up)', () {
      for (var budget = 1; budget <= 400; budget += 7) {
        for (var n = 1; n <= 9; n++) {
          final head = _compute(budget: budget, members: n).costPerHeadMinor!;
          expect(head, (budget + n - 1) ~/ n, reason: 'budget $budget over $n');
        }
      }
      expect(_compute(members: 0).costPerHeadMinor, isNull);
    });

    test('invalid input is rejected', () {
      expect(() => _compute(budget: 0), throwsA(isA<EngineException>()));
      expect(() => _compute(members: -1), throwsA(isA<EngineException>()));
      expect(() => _compute(expenses: [_e(-1, '2026-11-01')]), throwsA(isA<EngineException>()));
      expect(() => _compute(expenses: [_e(1, '2026-02-30')]), throwsA(isA<EngineException>()));
      expect(() => _compute(today: '2026-11-2'), throwsA(isA<EngineException>()));
      expect(() => _compute(start: '2026-11-05', end: '2026-11-04'), throwsA(isA<EngineException>()));
    });
  });
}
