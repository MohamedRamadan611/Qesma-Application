import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Port of BpsTest (spec 7.1: round_half_up(amount x bps / 10000)).
void main() {
  test('rounds half up', () {
    expect(Bps.percentOf(49280, 1400), 6899); // 6899.2
    expect(Bps.percentOf(44000, 1200), 5280); // exact
    expect(Bps.percentOf(1, 5000), 1); // 0.5 -> 1
    expect(Bps.percentOf(1, 4999), 0); // 0.4999 -> 0
    expect(Bps.percentOf(3, 5000), 2); // 1.5 -> 2
  });

  test('zero cases', () {
    expect(Bps.percentOf(0, 1400), 0);
    expect(Bps.percentOf(1000, 0), 0);
  });

  test('large amounts do not overflow', () {
    expect(Bps.percentOf(longMax, 10000), longMax);
  });

  test('rejects a negative amount and out-of-range bps', () {
    expect(() => Bps.percentOf(-1, 100), throwsAnyEngine);
    expect(() => Bps.percentOf(100, -1), throwsAnyEngine);
    expect(() => Bps.percentOf(100, 10001), throwsAnyEngine);
    expect(Bps.maxBps, 10000);
  });
}
