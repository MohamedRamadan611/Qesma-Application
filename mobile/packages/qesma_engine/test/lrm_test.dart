import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Port of LrmTest (spec 7.1 Largest Remainder Method).
void main() {
  const order3 = [1, 2, 3];

  test('equal weights give the extra unit to the lowest sortOrder (V3)', () {
    expect(Lrm.allocate(10000, [1, 1, 1], order3), [3334, 3333, 3333]);
  });

  test('tie-break uses sortOrder, not array position', () {
    expect(Lrm.allocate(100, [1, 1, 1], [3, 1, 2]), [33, 34, 33]);
  });

  test('largest fractional remainder wins before sortOrder', () {
    expect(Lrm.allocate(10, [1, 2], [1, 2]), [3, 7]);
  });

  test('all-zero weights fall back to equal weights', () {
    expect(Lrm.allocate(100, [0, 0, 0], order3), [34, 33, 33]);
  });

  test('a zero-weight member gets nothing when others have positive weight', () {
    expect(Lrm.allocate(3, [0, 1, 1], order3), [0, 2, 1]);
  });

  test('a single member gets everything', () {
    expect(Lrm.allocate(12345, [7], [1]), [12345]);
  });

  test('one unit among seven goes to the lowest sortOrder', () {
    expect(Lrm.allocate(1, List.filled(7, 1), [1, 2, 3, 4, 5, 6, 7]), [1, 0, 0, 0, 0, 0, 0]);
  });

  test('zero total allocates zeros', () {
    expect(Lrm.allocate(0, [5, 9], [1, 2]), [0, 0]);
  });

  test('negative total allocates the absolute value, then applies the sign', () {
    expect(Lrm.allocate(-100, [1, 1, 1], order3), [-34, -33, -33]);
  });

  test('a large EGP amount splits exactly', () {
    expect(Lrm.allocate(125000050, [1, 1, 1], order3), [41666684, 41666683, 41666683]);
  });

  test('extreme values do not overflow', () {
    final parts = Lrm.allocate(longMax, [longMax, longMax], [1, 2]);
    expect(parts[0] + parts[1], longMax);
    expect(parts[0] - parts[1], 1);
  });

  test('rejects invalid input', () {
    expect(() => Lrm.allocate(10, [], []), throwsEngine(EngineErrorCode.validationError));
    expect(() => Lrm.allocate(10, [1, -1], [1, 2]), throwsEngine(EngineErrorCode.validationError));
    expect(() => Lrm.allocate(10, [1, 1], [1]), throwsAnyEngine);
    expect(() => Lrm.allocate(longMin, [1], [1]), throwsAnyEngine);
  });

  test('the result is a fresh list aligned with the inputs', () {
    final weights = [2, 1];
    final parts = Lrm.allocate(3, weights, [1, 2]);
    expect(parts, [2, 1]);
    expect(weights, [2, 1]);
  });
}
