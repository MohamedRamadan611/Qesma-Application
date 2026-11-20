import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';

// tests for DiscountInput
void main() {
  final instance = DiscountInputBuilder();
  // TODO add properties to the builder and call build()

  group(DiscountInput, () {
    // Integer minor units (piasters: 1 EGP = 100). Never a decimal.
    // int amountMinor
    test('to test the property `amountMinor`', () async {
      // TODO
    });

    // Integer basis points: 1200 = 12.00%.
    // int bps
    test('to test the property `bps`', () async {
      // TODO
    });

  });
}
