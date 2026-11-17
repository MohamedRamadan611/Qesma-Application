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
      .where((f) => f.path.contains('trip-recap-') && f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  group('TripRecapCalculator Fixtures', () {
    test('insights fixtures are present', () {
      final files = _fixtureFiles();
      expect(files.length, greaterThanOrEqualTo(5));
    });

    for (final file in _fixtureFiles()) {
      final name = file.uri.pathSegments.last;
      test(name, () {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final rawMembers = json['members'] as List<dynamic>;
        final rawExpenses = json['expenses'] as List<dynamic>;
        final expected = json['expected'] as Map<String, dynamic>;

        final members = rawMembers
            .map((m) => TripRecapMemberInput.fromJson(m as Map<String, dynamic>))
            .toList();
        final expenses = rawExpenses
            .map((e) => TripRecapExpenseInput.fromJson(e as Map<String, dynamic>))
            .toList();

        final result = TripRecapCalculator.compute(
          members: members,
          expenses: expenses,
        );

        expect(result.toJson(), equals(expected));
      });
    }
  });

  group('TripRecapCalculator Invariants & Properties', () {
    test('throws when expenses is empty (no expenses -> no recap)', () {
      expect(
        () => TripRecapCalculator.compute(
          members: [
            const TripRecapMemberInput(memberId: 'm1', displayName: 'A', sortOrder: 0),
          ],
          expenses: [],
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('throws when members is empty', () {
      expect(
        () => TripRecapCalculator.compute(
          members: [],
          expenses: [
            const TripRecapExpenseInput(
              expenseId: 'e1',
              title: 'X',
              totalMinor: 100,
              expenseDate: '2026-11-01',
              createdAt: 1,
              category: 'FOOD',
              payers: [],
            ),
          ],
        ),
        throwsA(isA<EngineException>()),
      );
    });

    test('percentages always sum to exactly 10000 bps', () {
      final members = [
        const TripRecapMemberInput(memberId: 'm1', displayName: 'A', sortOrder: 0),
        const TripRecapMemberInput(memberId: 'm2', displayName: 'B', sortOrder: 1),
      ];

      final categories = myShareCategoryOrder;
      for (var seed = 1; seed <= 50; seed++) {
        final expenses = <TripRecapExpenseInput>[];
        for (var i = 0; i < 9; i++) {
          final amt = (seed * 37 + i * 19) % 25000 + 1;
          expenses.add(TripRecapExpenseInput(
            expenseId: 'e$i',
            title: 'Expense $i',
            totalMinor: amt,
            expenseDate: '2026-11-0${(i % 9) + 1}',
            createdAt: 1000 + i,
            category: categories[i],
            payers: [
              TripRecapPayerInput(memberId: i.isEven ? 'm1' : 'm2', amountMinor: amt),
            ],
          ));
        }

        final res = TripRecapCalculator.compute(members: members, expenses: expenses);
        final sumBps = res.categoryBreakdown.fold<int>(0, (acc, c) => acc + c.percentageBps);
        expect(sumBps, equals(10000), reason: 'LRM percentages must sum to 10000');
      }
    });

    test('top payer tie breaks by lower sortOrder', () {
      final members = [
        const TripRecapMemberInput(memberId: 'm1', displayName: 'Member 1', sortOrder: 10),
        const TripRecapMemberInput(memberId: 'm2', displayName: 'Member 2', sortOrder: 3),
        const TripRecapMemberInput(memberId: 'm3', displayName: 'Member 3', sortOrder: 7),
      ];

      final expenses = [
        const TripRecapExpenseInput(
          expenseId: 'e1',
          title: 'Shared',
          totalMinor: 3000,
          expenseDate: '2026-11-01',
          createdAt: 1,
          category: 'FOOD',
          payers: [
            TripRecapPayerInput(memberId: 'm1', amountMinor: 1000),
            TripRecapPayerInput(memberId: 'm2', amountMinor: 1000),
            TripRecapPayerInput(memberId: 'm3', amountMinor: 1000),
          ],
        ),
      ];

      final res = TripRecapCalculator.compute(members: members, expenses: expenses);
      expect(res.topPayer.memberId, equals('m2'), reason: 'm2 has lowest sortOrder (3)');
    });

    test('biggest expense tie breaks by date then createdAt', () {
      final members = [
        const TripRecapMemberInput(memberId: 'm1', displayName: 'M', sortOrder: 0),
      ];

      final expenses = [
        const TripRecapExpenseInput(
          expenseId: 'e1',
          title: 'Later date',
          totalMinor: 5000,
          expenseDate: '2026-11-10',
          createdAt: 100,
          category: 'FOOD',
          payers: [TripRecapPayerInput(memberId: 'm1', amountMinor: 5000)],
        ),
        const TripRecapExpenseInput(
          expenseId: 'e2',
          title: 'Earlier date late createdAt',
          totalMinor: 5000,
          expenseDate: '2026-11-05',
          createdAt: 999,
          category: 'FUEL',
          payers: [TripRecapPayerInput(memberId: 'm1', amountMinor: 5000)],
        ),
        const TripRecapExpenseInput(
          expenseId: 'e3',
          title: 'Earlier date early createdAt',
          totalMinor: 5000,
          expenseDate: '2026-11-05',
          createdAt: 500,
          category: 'SHOPPING',
          payers: [TripRecapPayerInput(memberId: 'm1', amountMinor: 5000)],
        ),
      ];

      final res = TripRecapCalculator.compute(members: members, expenses: expenses);
      expect(res.biggestExpense.expenseId, equals('e3'), reason: 'e3 has earlier date and earlier createdAt');
    });
  });
}
