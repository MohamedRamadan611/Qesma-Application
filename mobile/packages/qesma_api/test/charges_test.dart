import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';

// tests for Charges
void main() {
  final instance = ChargesBuilder();
  // TODO add properties to the builder and call build()

  group(Charges, () {
    // Integer minor units (piasters: 1 EGP = 100). Never a decimal.
    // int adjustmentMinor
    test('to test the property `adjustmentMinor`', () async {
      // TODO
    });

    // ServiceCharge service
    test('to test the property `service`', () async {
      // TODO
    });

    // Integer minor units (piasters: 1 EGP = 100). Never a decimal.
    // int subtotalMinor
    test('to test the property `subtotalMinor`', () async {
      // TODO
    });

    // TaxCharge tax
    test('to test the property `tax`', () async {
      // TODO
    });

  });
}
