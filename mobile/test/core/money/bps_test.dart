import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/money/money.dart';

void main() {
  group('Bps.parse', () {
    const valid = <String, int>{
      '0': 0,
      '12': 1200,
      '12.5': 1250,
      '12.05': 1205,
      '12.50': 1250,
      '100': 10000,
      '100.00': 10000,
      '0.01': 1,
      '١٢٫٥': 1250, // Arabic digits and decimal mark
    };
    valid.forEach((input, expected) {
      test('"$input" -> $expected', () => expect(Bps.parse(input), expected));
    });

    for (final input in ['', 'x', '100.01', '101', '12.345', '-1', '.5', '5.', '1,5', '1000']) {
      test('rejects "$input"', () => expect(Bps.parse(input), isNull));
    }
  });

  group('Bps.format', () {
    const cases = <int, String>{0: '0', 1200: '12', 1250: '12.5', 1205: '12.05', 10000: '100', 1: '0.01'};
    cases.forEach((bps, text) {
      test('$bps -> $text', () => expect(Bps.format(bps), text));
    });

    test('round trip for every valid value 0..10000', () {
      for (var bps = 0; bps <= Bps.max; bps++) {
        expect(Bps.parse(Bps.format(bps)), bps);
      }
    });
  });
}
