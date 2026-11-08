import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/money/money.dart';

void main() {
  group('Money.parse', () {
    const valid = <String, int>{
      '1': 100,
      '1.5': 150,
      '1.50': 150,
      '0.01': 1,
      '10': 1000,
      '1,000': 100000,
      '1,000.50': 100050,
      '1,234,567.89': 123456789,
      '1061.79': 106179,
      '007': 700,
      '  25  ': 2500,
      // Arabic-Indic and Eastern Arabic-Indic digits, Arabic decimal and thousands marks
      '١٢٣': 12300,
      '١٬٠٠٠٫٥٠': 100050,
      '۱۲۳': 12300,
      '10000000000': 1000000000000, // exactly 10^12 piasters
    };
    valid.forEach((input, expected) {
      test('"$input" -> $expected', () => expect(Money.parse(input), expected));
    });

    const invalid = [
      '',
      ' ',
      'abc',
      '1.234', // three decimals
      '1e3',
      '1,00', // would silently be 100 EGP if grouping were lenient
      '1,0000',
      ',100',
      '1,,000',
      '.5',
      '5.',
      '1.2.3',
      '0', // zero is not an amount unless allowZero
      '0.00',
      '-5', // negative unless allowNegative
      '10000000000.01', // above 10^12 piasters
      '99999999999999999999', // overflow guard
      '1 000',
      '٣.٤٥٦',
    ];
    for (final input in invalid) {
      test('rejects "$input"', () => expect(Money.parse(input), isNull));
    }

    test('allowZero accepts 0 and 0.00', () {
      expect(Money.parse('0', allowZero: true), 0);
      expect(Money.parse('0.00', allowZero: true), 0);
    });

    test('allowNegative mirrors the range, including the Unicode minus', () {
      expect(Money.parse('-5.25', allowNegative: true), -525);
      expect(Money.parse('−5', allowNegative: true), -500);
      expect(Money.parse('-10000000000', allowNegative: true), -1000000000000);
      expect(Money.parse('-10000000000.01', allowNegative: true), isNull);
      expect(Money.parse('-0', allowNegative: true), isNull);
      expect(Money.parse('-0', allowNegative: true, allowZero: true), 0);
    });
  });

  group('Money.format', () {
    const cases = <int, String>{
      0: '0.00 ج.م',
      1: '0.01 ج.م',
      99: '0.99 ج.م',
      100: '1.00 ج.م',
      106179: '1,061.79 ج.م',
      100000: '1,000.00 ج.م',
      123456789: '1,234,567.89 ج.م',
      1000000000000: '10,000,000,000.00 ج.م',
      -525: '−5.25 ج.م',
    };
    cases.forEach((minor, text) {
      test('$minor -> $text', () => expect(Money.format(minor), text));
    });

    test('formatSigned always carries sign or zero, never colour only', () {
      expect(Money.formatSigned(106179), '+1,061.79 ج.م');
      expect(Money.formatSigned(-106179), '−1,061.79 ج.م');
      expect(Money.formatSigned(0), '0.00 ج.م');
    });

    test('formatPlain prefills edit fields', () {
      expect(Money.formatPlain(106179), '1061.79');
      expect(Money.formatPlain(106100), '1061');
      expect(Money.formatPlain(5), '0.05');
      expect(Money.formatPlain(-5), '-0.05');
    });
  });

  group('property: format then parse round-trips', () {
    test('10,000 random amounts across the whole range', () {
      final seed = DateTime.now().microsecondsSinceEpoch;
      final random = Random(seed);
      for (var i = 0; i < 10000; i++) {
        // Mix magnitudes (1..40 bits) so small, medium and near-maximum values are all exercised.
        final bits = 1 + random.nextInt(40);
        final raw = ((random.nextInt(1 << 30) << 12) ^ random.nextInt(1 << 30)) & ((1 << bits) - 1);
        final value = i == 0 ? Money.maxMinor : (raw < 1 ? 1 : min(raw, Money.maxMinor));

        final formatted = Money.format(value).replaceAll(' ج.م', '');
        expect(Money.parse(formatted), value, reason: 'seed=$seed value=$value formatted=$formatted');
        expect(Money.parse(Money.formatPlain(value)), value, reason: 'seed=$seed value=$value (plain)');
      }
    });

    test('anything with three decimals or an exponent is rejected', () {
      final seed = DateTime.now().microsecondsSinceEpoch;
      final random = Random(seed);
      for (var i = 0; i < 2000; i++) {
        final whole = random.nextInt(100000);
        final threeDecimals = '$whole.${100 + random.nextInt(900)}';
        expect(Money.parse(threeDecimals), isNull, reason: 'seed=$seed input=$threeDecimals');
        expect(Money.parse('${whole}e${random.nextInt(5)}'), isNull, reason: 'seed=$seed');
      }
    });
  });
}
