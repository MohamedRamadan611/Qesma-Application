import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/money/money.dart';

/// Decimal inputs of the Khorouga calculator (STANDALONE_SPEC 11, A168): string logic only, no double.
void main() {
  int? p(String s, {int min = 0, int max = 100000}) => Tenths.parse(s, min: min, max: max);

  test('whole numbers and one decimal', () {
    expect(p('120'), 1200);
    expect(p('12.5'), 125);
    expect(p('0.1'), 1);
    expect(p('7.'), null);
    expect(p('.5'), null);
    expect(p(' 15 '), 150);
  });

  test('comma and the Arabic decimal separator are decimal points (A168)', () {
    expect(p('12,5'), 125);
    expect(p('١٢٫٥'), 125);
    expect(p('١٢,٥'), 125);
  });

  test('Arabic-Indic and Eastern Arabic-Indic digits', () {
    expect(p('١٢٠'), 1200);
    expect(p('۱۲۰'), 1200);
  });

  test('no thousands grouping: "1,200" is too many decimals', () {
    expect(p('1,200'), null);
    expect(p('1.25'), null);
    expect(p('1,000,5'), null);
  });

  test('rejects empty, signs, spaces inside and letters', () {
    for (final s in ['', ' ', '-5', '+5', '1 2', 'abc', '5km', '1e3', '٫']) {
      expect(p(s), null, reason: s);
    }
  });

  test('range is inclusive, in tenths', () {
    expect(p('1', min: 10, max: 300), 10);
    expect(p('30', min: 10, max: 300), 300);
    expect(p('0.9', min: 10, max: 300), null);
    expect(p('30.1', min: 10, max: 300), null);
    expect(p('99999999999999999999'), null); // no int overflow
  });

  test('format drops a zero decimal and uses Western digits', () {
    expect(Tenths.format(1200), '120');
    expect(Tenths.format(125), '12.5');
    expect(Tenths.format(1), '0.1');
    expect(Tenths.format(0), '0');
  });
}
