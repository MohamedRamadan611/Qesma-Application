import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/receipt_scan/application/receipt_draft_mapper.dart';
import 'package:qesma/features/receipt_scan/application/receipt_parser.dart';

/// SA17: ParsedReceipt -> the editor's draft. The mapper copies text and picks modes; it never computes an amount.
ScanDraft _map(String json) => scanDraftFrom(parseReceiptJson(json));

void main() {
  test('items keep their quantity and the unit price as the amount text', () {
    final d = _map('{"items":[{"name":"Pepsi","amount":"90","quantity":"3","unitPrice":"30"},{"name":"Tea","amount":"12.5"}]}');
    final items = d.itemized.items;
    expect(items.map((i) => (i.name, i.amountText, i.quantity)), [('Pepsi', '30', 3), ('Tea', '12.50', 1)]);
    expect(items.every((i) => i.assigneeIds.isEmpty), isTrue, reason: 'the user assigns members');
  });

  test('a flagged item is touched so its error shows at once; a clean one is not', () {
    final d = _map('{"items":[{"name":"A","amount":"x"},{"name":"B","amount":"5"}]}');
    expect(d.itemized.items.map((i) => i.touched), [true, false]);
    expect(d.notes, {ScanNote.flaggedItems});
  });

  test('a discount percentage opens in percent mode', () {
    final i = _map('{"items":[{"name":"A","amount":"100"}],"subtotal":"100","discountPercent":"10%"}').itemized;
    expect((i.discountOn, i.discountMode, i.discountPercentText, i.discountAmountText), (true, ChargeMode.percent, '10', ''));
  });

  test('a discount amount opens in amount mode', () {
    final i = _map('{"items":[{"name":"A","amount":"100"}],"subtotal":"100","discountAmount":"-20"}').itemized;
    expect((i.discountOn, i.discountMode, i.discountAmountText, i.discountPercentText), (true, ChargeMode.amount, '20', ''));
  });

  test('no discount: the switch is off and the editor defaults are untouched', () {
    final i = _map('{"items":[{"name":"A","amount":"100"}]}').itemized;
    expect((i.discountOn, i.discountMode, i.discountPercentText, i.discountAmountText), (false, ChargeMode.percent, '', ''));
  });

  test('service and tax: percent mode when a percent was printed, amount mode when only an amount was (A179)', () {
    final i = _map('{"items":[{"name":"A","amount":"100"}],"servicePercent":"12","taxAmount":"14"}').itemized;
    expect((i.serviceOn, i.serviceMode, i.servicePercentText, i.serviceAmountText), (true, ChargeMode.percent, '12', ''));
    expect((i.taxOn, i.taxMode, i.taxPercentText, i.taxAmountText), (true, ChargeMode.amount, '', '14'));
    expect(i.taxBps, isNull);
    expect(i.taxAmountMinor, 1400);
    expect(i.valid(const []), isFalse, reason: 'nobody is assigned yet');
    expect((i.serviceValid, i.taxValid), (true, true), reason: 'an amount needs no percent, so no "type the percentage" step remains');
  });

  group('notes', () {
    test('a plain receipt has none (the same draft as SA12)', () {
      final d = _map('{"items":[{"name":"A","amount":"10"}],"total":"10"}');
      expect(d.notes, isEmpty);
      expect((d.merchantName, d.category, d.printedTotalMinor), (null, null, 1000));
    });

    test('every new note appears for its own reason', () {
      expect(_map('{"items":[{"name":"A","amount":"9","quantity":"two"}]}').notes, {ScanNote.quantityCheck});
      expect(_map('{"items":[{"name":"A","amount":"90","quantity":"3"}]}').notes, {ScanNote.unitPriceCheck});
      expect(_map('{"items":[{"name":"A","amount":"90"}],"discountAmount":"5"}').notes, {ScanNote.discountFound});
      expect(_map('{"items":[{"name":"A","amount":"90"}],"discountAmount":"5","discountPercent":"10"}').notes, {ScanNote.discountFound, ScanNote.discountPercentKept});
      expect(_map('{"items":[{"name":"A","amount":"90"}],"subtotal":"90","discountAmount":"90"}').notes, {ScanNote.discountDropped});
    });

    test('the title and category note is not the mapper\'s: the form adds it only when it applied them', () {
      final d = _map('{"items":[{"name":"A","amount":"9"}],"merchantName":"Zooba","category":"FOOD"}');
      expect(d.notes, isEmpty);
      expect((d.merchantName, d.category), ('Zooba', 'FOOD'));
    });
  });

  test('a quantity above 1 without a unit price keeps the printed line total as a quantity-1 price: no division', () {
    final item = _map('{"items":[{"name":"Koshary","amount":"135","quantity":"3"}]}').itemized.items.single;
    expect((item.quantity, item.amountText), (1, '135'));
  });

  // The recorded SA12 receipts have none of the SA17 fields: they must give the same draft as before.
  group('regression: the SA12 receipts still produce the same draft', () {
    ScanDraft fixture(String name) => _map(File('test/fixtures/receipts/$name').readAsStringSync());

    test('Arabic receipt: two items, no charges, printed total 120', () {
      final d = fixture('arabic_receipt.json');
      expect(d.itemized.items.map((i) => (i.name, i.amountText, i.quantity, i.touched)), [('شاورما فراخ', '85', 1, false), ('عصير مانجو', '35', 1, false)]);
      expect((d.itemized.serviceOn, d.itemized.taxOn, d.itemized.discountOn, d.printedTotalMinor), (false, false, false, 12000));
      expect(d.notes, isEmpty);
    });

    test('service and tax percentages: both on, percent mode, the percent wins over the printed amounts', () {
      final i = fixture('service_and_tax.json').itemized;
      expect((i.serviceOn, i.serviceMode, i.servicePercentText, i.serviceAmountText), (true, ChargeMode.percent, '12', ''));
      expect((i.taxOn, i.taxMode, i.taxPercentText, i.taxAmountText), (true, ChargeMode.percent, '14', ''));
    });

    test('tax only with an Arabic percent sign: service stays off', () {
      final i = fixture('tax_only.json').itemized;
      expect((i.serviceOn, i.taxOn, i.taxPercentText), (false, true, '14'));
    });

    test('unreadable amounts: flagged and empty, the readable one kept, the same note', () {
      final d = fixture('negative_huge.json');
      expect(d.itemized.items.map((i) => (i.name, i.amountText, i.touched)), [('Refund', '', true), ('Free', '', true), ('Huge', '', true), ('Cola', '10', false), ('Unreadable', '', true)]);
      expect(d.notes, {ScanNote.flaggedItems});
    });

    for (final name in ['arabic_receipt.json', 'english_receipt.json', 'arabic_indic_digits.json', 'missing_total.json', 'service_and_tax.json', 'tax_only.json', 'extra_fields.json']) {
      test('$name: quantity 1 everywhere, no discount, no suggestion, no new note', () {
        final d = fixture(name);
        expect(d.itemized.items.every((i) => i.quantity == 1), isTrue);
        expect((d.itemized.discountOn, d.merchantName, d.category), (false, null, null));
        expect(d.notes.difference({ScanNote.flaggedItems}), isEmpty);
      });
    }
  });

  test('a printed delivery fee turns delivery on with its amount; none printed leaves it off', () {
    final withFee = _map('{"items":[{"name":"Pizza","amount":"200"}],"deliveryAmount":"15","total":"215"}');
    expect((withFee.itemized.deliveryOn, withFee.itemized.deliveryAmountText), (true, '15'));
    final without = _map('{"items":[{"name":"Pizza","amount":"200"}],"deliveryAmount":""}');
    expect((without.itemized.deliveryOn, without.itemized.deliveryAmountText), (false, ''));
  });
}
