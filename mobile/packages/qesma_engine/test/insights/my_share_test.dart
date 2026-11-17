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
      .where((f) => f.path.contains('my-share-') && f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  group('MyShareCalculator Fixtures', () {
    test('insights fixtures are present', () {
      final files = _fixtureFiles();
      expect(files.length, greaterThanOrEqualTo(5));
    });

    for (final file in _fixtureFiles()) {
      final name = file.uri.pathSegments.last;
      test(name, () {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final rawInputs = json['input'] as List<dynamic>;
        final expected = json['expected'] as Map<String, dynamic>;

        final inputs = rawInputs
            .map((e) => MyShareExpenseInput.fromJson(e as Map<String, dynamic>))
            .toList();

        final result = MyShareCalculator.compute(inputs);
        expect(result.toJson(), equals(expected));
      });
    }
  });

  group('MyShareCalculator Invariants & Properties', () {
    test('empty inputs yield empty sections', () {
      final res = MyShareCalculator.compute([]);
      expect(res.sections, isEmpty);
    });

    test('properties hold for randomized multi-month multi-category data', () {
      final inputs = <MyShareExpenseInput>[];
      final categories = myShareCategoryOrder;
      final currencies = ['EGP', 'USD', 'EUR'];

      var idCounter = 1;
      for (final cur in currencies) {
        for (var m = 1; m <= 3; m++) {
          final monthStr = '2026-0$m';
          for (var i = 0; i < 5; i++) {
            final cat = categories[(idCounter * 3) % categories.length];
            final owed = (idCounter * 137) % 50000;
            final paid = (idCounter * 241) % 70000;
            inputs.add(MyShareExpenseInput(
              expenseId: 'exp-$idCounter',
              groupId: 'grp-${idCounter % 3}',
              expenseTitle: 'Title $idCounter',
              groupName: 'Group ${idCounter % 3}',
              expenseDate: '$monthStr-1${i % 9}',
              category: cat,
              currencyCode: cur,
              owedMinor: owed,
              paidMinor: paid,
            ));
            idCounter++;
          }
        }
      }

      final result = MyShareCalculator.compute(inputs);

      // Invariant: Currencies sorted EGP first, then alphabetical
      expect(result.sections.first.currencyCode, equals('EGP'));
      for (var i = 1; i < result.sections.length - 1; i++) {
        expect(
          result.sections[i].currencyCode.compareTo(result.sections[i + 1].currencyCode),
          lessThanOrEqualTo(0),
        );
      }

      for (final section in result.sections) {
        // Invariant: Months descending
        for (var i = 0; i < section.months.length - 1; i++) {
          expect(section.months[i].month.compareTo(section.months[i + 1].month), greaterThan(0));
        }

        for (final month in section.months) {
          var sumConsumed = 0;
          var sumPaid = 0;
          var sumBps = 0;

          // Invariant: Categories follow enum order
          for (var i = 0; i < month.categories.length - 1; i++) {
            final idxA = myShareCategoryOrder.indexOf(month.categories[i].category);
            final idxB = myShareCategoryOrder.indexOf(month.categories[i + 1].category);
            expect(idxA, lessThan(idxB));
          }

          for (final cat in month.categories) {
            sumConsumed += cat.consumedMinor;
            sumPaid += cat.paidUpFrontMinor;
            sumBps += cat.percentageBps;

            // Invariant: Expenses inside category are date descending, then id desc
            for (var i = 0; i < cat.expenses.length - 1; i++) {
              final cmpDate = cat.expenses[i].expenseDate.compareTo(cat.expenses[i + 1].expenseDate);
              expect(cmpDate, greaterThanOrEqualTo(0));
              if (cmpDate == 0) {
                expect(cat.expenses[i].expenseId.compareTo(cat.expenses[i + 1].expenseId), greaterThanOrEqualTo(0));
              }
            }
          }

          // Invariant: Sum over categories = month total
          expect(month.totalConsumedMinor, equals(sumConsumed));
          expect(month.totalPaidUpFrontMinor, equals(sumPaid));
          expect(month.netDiffMinor, equals(sumPaid - sumConsumed));

          // Invariant: LRM percentages sum to exactly 10000 bps (when total consumed > 0)
          if (month.totalConsumedMinor > 0) {
            expect(sumBps, equals(10000));
          } else {
            expect(sumBps, equals(0));
          }
        }
      }
    });

    test('negative amounts throw EngineException', () {
      expect(
        () => MyShareCalculator.compute([
          const MyShareExpenseInput(
            expenseId: 'e',
            groupId: 'g',
            expenseTitle: 't',
            groupName: 'gn',
            expenseDate: '2026-11-01',
            category: 'FOOD',
            currencyCode: 'EGP',
            owedMinor: -100,
            paidMinor: 0,
          )
        ]),
        throwsA(isA<EngineException>()),
      );
    });

    test('invalid date format throws EngineException', () {
      expect(
        () => MyShareCalculator.compute([
          const MyShareExpenseInput(
            expenseId: 'e',
            groupId: 'g',
            expenseTitle: 't',
            groupName: 'gn',
            expenseDate: 'bad',
            category: 'FOOD',
            currencyCode: 'EGP',
            owedMinor: 100,
            paidMinor: 0,
          )
        ]),
        throwsA(isA<EngineException>()),
      );
    });
  });
}
