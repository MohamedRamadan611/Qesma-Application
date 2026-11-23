import 'dart:math';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

/// SHARES (STANDALONE_SPEC 19.1, A185-A187, A194): the day count, the rules the engine enforces itself, and
/// seeded properties (Σ owed == total, units 1 equals EQUAL, scaling invariance). The shared vectors V21-V28 are
/// in fixture_test.dart.
void main() {
  Matcher invalid() => throwsA(isA<EngineException>().having((e) => e.code, 'code', EngineErrorCode.validationError));

  group('inclusiveDays', () {
    test('the same date is one day', () {
      expect(SplitCalculator.inclusiveDays('2026-11-30', '2026-11-30'), 1);
    });
    test('a month, a leap day and a year boundary', () {
      expect(SplitCalculator.inclusiveDays('2026-11-01', '2026-11-30'), 30);
      expect(SplitCalculator.inclusiveDays('2028-02-28', '2028-03-01'), 3); // 2028 is a leap year
      expect(SplitCalculator.inclusiveDays('2026-02-28', '2026-03-01'), 2);
      expect(SplitCalculator.inclusiveDays('2100-02-28', '2100-03-01'), 2); // 2100 is not
      expect(SplitCalculator.inclusiveDays('2000-02-28', '2000-03-01'), 3); // 2000 is
      expect(SplitCalculator.inclusiveDays('2026-12-31', '2027-01-01'), 2);
      expect(SplitCalculator.inclusiveDays('2028-01-01', '2028-12-31'), 366);
      expect(SplitCalculator.inclusiveDays('2000-01-01', '2100-12-31'), 36890);
    });
    test('malformed or impossible dates are rejected', () {
      for (final bad in ['2026-02-30', '2026-13-01', '2026-1-01', '26-11-01', '2026-11-01T00:00', '', '2026/11/01']) {
        expect(() => SplitCalculator.inclusiveDays(bad, '2026-12-01'), invalid(), reason: bad);
      }
    });
  });

  group('rules', () {
    const a = 'A', b = 'B';
    WeightedShare s(String id, int order, int units, {String? from, String? to}) =>
        WeightedShare(id, order, units, presentFrom: from, presentTo: to);

    test('a period of 366 days is accepted, 367 is rejected', () {
      expect(SplitCalculator.shares(1000, [s(a, 1, 1), s(b, 2, 1)], period: const SharePeriod('2028-01-01', '2028-12-31')),
          {a: 500, b: 500});
      expect(() => SplitCalculator.shares(1000, [s(a, 1, 1)], period: const SharePeriod('2026-01-01', '2027-01-02')),
          invalid());
    });
    test('total, units and duplicates', () {
      expect(() => SplitCalculator.shares(0, [s(a, 1, 1)]), invalid());
      expect(() => SplitCalculator.shares(100, const []), invalid());
      expect(() => SplitCalculator.shares(100, [s(a, 1, 0)]), invalid());
      expect(() => SplitCalculator.shares(100, [s(a, 1, 101)]), invalid());
      expect(() => SplitCalculator.shares(100, [s(a, 1, 1), s(a, 2, 1)]), invalid());
    });
    test('presence defaults to the period bounds and weighs by days', () {
      final owed = SplitCalculator.shares(3100, [s(a, 1, 1), s(b, 2, 1, to: '2026-11-01')],
          period: const SharePeriod('2026-11-01', '2026-11-30'));
      expect(owed, {a: 3000, b: 100});
    });
    test('results are in sortOrder and keep zero shares', () {
      final owed = SplitCalculator.shares(1, [s(b, 2, 1), s(a, 1, 1)]);
      expect(owed.keys.toList(), [a, b]);
      expect(owed, {a: 1, b: 0});
    });
  });

  group('properties (seeded)', () {
    test('Σ owed == total, every part >= 0, and the parts are deterministic', () {
      for (var seed = 0; seed < 3000; seed++) {
        final rnd = Random(seed);
        final input = _randomInput(rnd);
        final owed = SplitCalculator.shares(input.total, input.shares, period: input.period);
        expect(owed.values.fold<int>(0, (x, y) => x + y), input.total, reason: 'seed $seed');
        expect(owed.values.every((v) => v >= 0), isTrue, reason: 'seed $seed');
        expect(SplitCalculator.shares(input.total, input.shares.reversed.toList(), period: input.period), owed,
            reason: 'seed $seed: input order is not meaning');
      }
    });

    test('units 1 for everyone without a period equals EQUAL', () {
      for (var seed = 0; seed < 3000; seed++) {
        final rnd = Random(seed);
        final n = 1 + rnd.nextInt(30);
        final total = 1 + rnd.nextInt(1 << 31) * (1 + rnd.nextInt(400));
        final members = [for (var i = 0; i < n; i++) MemberRef('m$i', 1 + i * (1 + rnd.nextInt(3)))];
        expect(
          SplitCalculator.shares(total, [for (final m in members) WeightedShare(m.id, m.sortOrder, 1)]),
          SplitCalculator.equal(total, members),
          reason: 'seed $seed',
        );
      }
    });

    test('scaling every unit by the same factor changes nothing', () {
      for (var seed = 0; seed < 3000; seed++) {
        final rnd = Random(seed);
        final input = _randomInput(rnd, maxUnits: 10);
        final k = 1 + rnd.nextInt(10);
        final scaled = [
          for (final x in input.shares)
            WeightedShare(x.memberId, x.sortOrder, x.shareUnits * k, presentFrom: x.presentFrom, presentTo: x.presentTo),
        ];
        expect(SplitCalculator.shares(input.total, scaled, period: input.period),
            SplitCalculator.shares(input.total, input.shares, period: input.period),
            reason: 'seed $seed k $k');
      }
    });
  });
}

final class _Input {
  _Input(this.total, this.shares, this.period);
  final int total;
  final List<WeightedShare> shares;
  final SharePeriod? period;
}

String _day(int d) => '2026-11-${(d + 1).toString().padLeft(2, '0')}';

_Input _randomInput(Random rnd, {int maxUnits = 100}) {
  final n = 1 + rnd.nextInt(20);
  final total = 1 + rnd.nextInt(1 << 31) * (1 + rnd.nextInt(400));
  final withPeriod = rnd.nextBool();
  final shares = <WeightedShare>[];
  for (var i = 0; i < n; i++) {
    final units = 1 + rnd.nextInt(maxUnits);
    String? from, to;
    if (withPeriod && rnd.nextBool()) {
      final x = rnd.nextInt(30), y = rnd.nextInt(30);
      from = _day(min(x, y));
      to = _day(max(x, y));
    }
    shares.add(WeightedShare('m$i', i + 1, units, presentFrom: from, presentTo: to));
  }
  return _Input(total, shares, withPeriod ? const SharePeriod('2026-11-01', '2026-11-30') : null);
}
