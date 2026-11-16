import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/profile/application/payment_handles_input.dart';

void main() {
  group('wallet', () {
    final cases = <String, String>{
      '01012345678': '01012345678',
      '٠١٠١٢٣٤٥٦٧٨': '01012345678',
      '۰۱۰۱۲۳۴۵۶۷۸': '01012345678',
      '010 1234 5678': '01012345678',
      '010-1234-5678': '01012345678',
      '010 1234‎5678': '01012345678',
      '+20 10 1234 5678': '01012345678',
      '0020 10 1234 5678': '01012345678',
      '  01512345678  ': '01512345678',
    };
    cases.forEach((input, expected) {
      test('"$input" -> $expected', () {
        final r = normaliseWallet(input);
        expect(r.isValid, isTrue);
        expect(r.value, expected);
      });
    });

    for (final bad in ['01312345678', '0101234567', '010123456789', 'abc', '---', '٠٣٠١٢٣٤٥٦٧٨']) {
      test('"$bad" is invalid', () {
        final r = normaliseWallet(bad);
        expect(r.issue, HandleIssue.wallet);
        expect(r.value, isNull);
      });
    }

    test('blank removes', () {
      for (final blank in [null, '', '   ']) {
        final r = normaliseWallet(blank);
        expect(r.isValid, isTrue);
        expect(r.value, isNull);
      }
    });
  });

  group('instapay', () {
    test('lower-cases and trims', () => expect(normaliseInstapay('  Demo.User@Bank ').value, 'demo.user@bank'));
    test('blank removes', () {
      final r = normaliseInstapay('  ');
      expect(r.isValid, isTrue);
      expect(r.value, isNull);
    });
    for (final bad in ['no-at-sign', 'a@b@c', 'ab', 'demo user@bank', 'دمو@bank', '@bank', 'demo@', '${'a' * 59}@b']) {
      test('"${bad.length > 20 ? '${bad.length} chars' : bad}" is invalid', () => expect(normaliseInstapay(bad).issue, HandleIssue.instapay));
    }
    test('exactly 60 characters is accepted', () => expect(normaliseInstapay('${'a' * 58}@b').isValid, isTrue));
  });
}
