import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Port of SplitCalculatorTest (spec 7.2 EQUAL, 7.3 EXACT, 7.5 payers).
void main() {
  const m1 = MemberRef('M1', 1);
  const m2 = MemberRef('M2', 2);
  const m3 = MemberRef('M3', 3);

  test('equal gives the extra piaster to the lowest sortOrder regardless of input order', () {
    final owed = SplitCalculator.equal(10000, [m3, m1, m2]);
    expect(owed, {'M1': 3334, 'M2': 3333, 'M3': 3333});
    expect(owed.keys, ['M1', 'M2', 'M3']); // sortOrder order
    expect(sumOf(owed.values), 10000);
  });

  test('equal keeps participants that owe zero', () {
    expect(SplitCalculator.equal(2, [m1, m2, m3]), {'M1': 1, 'M2': 1, 'M3': 0});
  });

  test('equal is stable for tied sortOrders (input order kept, like Java)', () {
    final owed = SplitCalculator.equal(2, [const MemberRef('B', 1), const MemberRef('A', 1), m3]);
    expect(owed.keys, ['B', 'A', 'M3']);
    expect(owed, {'B': 1, 'A': 1, 'M3': 0});
  });

  test('equal rejects bad input', () {
    expect(() => SplitCalculator.equal(100, []), throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.equal(0, [m1]), throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.equal(-5, [m1]), throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.equal(100, [m1, m1]), throwsEngine(EngineErrorCode.validationError));
  });

  test('exact accepts a matching sum and allows zero shares (input order kept)', () {
    final owed = SplitCalculator.exact(10000, [
      const Share('A', 5000),
      const Share('S', 5000),
      const Share('M', 0),
    ]);
    expect(owed, {'A': 5000, 'S': 5000, 'M': 0});
    expect(owed.keys, ['A', 'S', 'M']);
  });

  test('exact rejects a sum mismatch', () {
    expect(() => SplitCalculator.exact(10000, [const Share('A', 5000), const Share('S', 4999)]),
        throwsEngine(EngineErrorCode.splitTotalMismatch));
    expect(() => SplitCalculator.exact(10000, [const Share('A', 10001)]),
        throwsEngine(EngineErrorCode.splitTotalMismatch));
  });

  test('exact rejects invalid shares', () {
    expect(() => SplitCalculator.exact(100, []), throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.exact(100, [const Share('A', -10), const Share('B', 110)]),
        throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.exact(100, [const Share('A', 50), const Share('A', 50)]),
        throwsEngine(EngineErrorCode.validationError));
    expect(() => SplitCalculator.exact(0, [const Share('A', 0)]), throwsEngine(EngineErrorCode.validationError));
  });

  test('payers must sum to the total', () {
    PayerValidator.validate(50000, [const Payer('X', 30000), const Payer('Y', 20000)]);
    expect(() => PayerValidator.validate(50000, [const Payer('X', 30000), const Payer('Y', 19999)]),
        throwsEngine(EngineErrorCode.payersTotalMismatch));
  });

  test('payers reject empty, zero, negative and duplicates', () {
    expect(() => PayerValidator.validate(100, []), throwsEngine(EngineErrorCode.validationError));
    expect(() => PayerValidator.validate(100, [const Payer('X', 0), const Payer('Y', 100)]),
        throwsEngine(EngineErrorCode.validationError));
    expect(() => PayerValidator.validate(100, [const Payer('X', -5), const Payer('Y', 105)]),
        throwsEngine(EngineErrorCode.validationError));
    expect(() => PayerValidator.validate(100, [const Payer('X', 50), const Payer('X', 50)]),
        throwsEngine(EngineErrorCode.validationError));
  });

  test('payer amount overflow is a typed error', () {
    expect(() => PayerValidator.validate(100, [const Payer('X', longMax), const Payer('Y', longMax)]),
        throwsEngine(EngineErrorCode.validationError));
  });

  test('exact share overflow is a typed error, not a wrap-around', () {
    expect(() => SplitCalculator.exact(100, [const Share('X', longMax), const Share('Y', longMax)]),
        throwsEngine(EngineErrorCode.validationError));
  });
}
