import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/data/expense_category.dart';
import 'package:qesma/features/receipt_scan/application/parsed_receipt.dart';
import 'package:qesma/features/receipt_scan/application/receipt_parser.dart';
import 'package:qesma/features/receipt_scan/application/receipt_reader.dart';

/// SA12: the model's JSON text -> a proposal. Recorded responses live in test/fixtures/receipts/. Every amount goes
/// through Money.parse, every percent through Bps.parse; nothing the model computed is believed.
String _fixture(String name) => File('test/fixtures/receipts/$name').readAsStringSync();

ReceiptScanFailure _failureOf(String text) {
  try {
    parseReceiptJson(text);
  } on ReceiptScanException catch (e) {
    return e.failure;
  }
  fail('expected a ReceiptScanException');
}

void main() {
  test('Arabic receipt: Arabic-Indic amounts, no charges, the printed total is kept for the comparison', () {
    final r = parseReceiptJson(_fixture('arabic_receipt.json'));
    expect(r.items, const [
      ParsedItem(name: 'شاورما فراخ', amountText: '85', flagged: false),
      ParsedItem(name: 'عصير مانجو', amountText: '35', flagged: false),
    ]);
    expect((r.serviceOn, r.taxOn, r.printedTotalMinor, r.currency), (false, false, 12000, 'ج.م'));
    expect(r.hasFlaggedItems, isFalse);
  });

  test('English receipt: a currency word after the amount is tolerated', () {
    final r = parseReceiptJson(_fixture('english_receipt.json'));
    expect(r.items.map((i) => (i.name, i.amountText, i.flagged)), [('Chicken Shawarma', '85', false), ('Mango Juice', '35', false)]);
    expect((r.printedTotalMinor, r.currency), (12000, 'EGP'));
  });

  test('Arabic-Indic and extended digits, Arabic grouping and decimal separators', () {
    final r = parseReceiptJson(_fixture('arabic_indic_digits.json'));
    expect(r.items.map((i) => i.amountText), ['1200.50', '45']);
    expect(r.printedTotalMinor, 124550);
  });

  test('service and tax: percentages become basis points text (12% -> 12, 14 -> 14), both switches on', () {
    final r = parseReceiptJson(_fixture('service_and_tax.json'));
    expect((r.serviceOn, r.servicePercentText, r.taxOn, r.taxPercentText), (true, '12', true, '14'));
    expect(r.printedTotalMinor, 19152);
  });

  test('tax only (Arabic percent sign): service stays off', () {
    final r = parseReceiptJson(_fixture('tax_only.json'));
    expect((r.serviceOn, r.taxOn, r.taxPercentText), (false, true, '14'));
  });

  test('missing total: no printed total, nothing else changes', () {
    final r = parseReceiptJson(_fixture('missing_total.json'));
    expect(r.printedTotalMinor, isNull);
    expect(r.items.single, const ParsedItem(name: 'Tea', amountText: '12.50', flagged: false));
  });

  test('garbage JSON is an invalid response, not a crash', () {
    expect(_failureOf(_fixture('garbage.json')), ReceiptScanFailure.invalidResponse);
    expect(_failureOf('[1,2,3]'), ReceiptScanFailure.invalidResponse);
    expect(_failureOf('{"items":"none"}'), ReceiptScanFailure.invalidResponse);
    expect(_failureOf(''), ReceiptScanFailure.invalidResponse);
  });

  test('a valid object with no items is an unreadable photo', () {
    expect(_failureOf('{"items":[]}'), ReceiptScanFailure.unreadablePhoto);
    expect(_failureOf('{"items":[{"name":"","amount":""}]}'), ReceiptScanFailure.unreadablePhoto);
  });

  test('extra fields are ignored', () {
    final r = parseReceiptJson(_fixture('extra_fields.json'));
    expect(r.items.single, const ParsedItem(name: 'Tea', amountText: '12.50', flagged: false));
    expect(r.printedTotalMinor, 1250);
  });

  test('negative, zero, huge and unreadable amounts keep the item with an empty amount and a flag', () {
    final r = parseReceiptJson(_fixture('negative_huge.json'));
    expect(r.items.map((i) => (i.name, i.amountText, i.flagged)), [
      ('Refund', '', true),
      ('Free', '', true),
      ('Huge', '', true),
      ('Cola', '10', false),
      ('Unreadable', '', true),
    ]);
    expect(r.hasFlaggedItems, isTrue);
  });

  test('an amount printed without a percentage turns the charge on in amount form (A179)', () {
    final r = parseReceiptJson('{"items":[{"name":"A","amount":"10"}],"serviceAmount":"1.20","taxPercent":"14"}');
    expect((r.serviceOn, r.servicePercentText, r.serviceAmountText), (true, '', '1.20'));
    expect((r.taxOn, r.taxPercentText, r.taxAmountText), (true, '14', ''));
  });

  test('a printed percentage wins over a printed amount for service and tax (A179)', () {
    final r = parseReceiptJson('{"items":[{"name":"A","amount":"10"}],"servicePercent":"12","serviceAmount":"1.20","taxPercent":"٪١٤","taxAmount":"9"}');
    expect((r.servicePercentText, r.serviceAmountText, r.taxPercentText, r.taxAmountText), ('12', '', '14', ''));
  });

  test('a bad percentage never turns a charge on (0, over 100, text)', () {
    final r = parseReceiptJson('{"items":[{"name":"A","amount":"10"}],"servicePercent":"0","taxPercent":"140"}');
    expect((r.serviceOn, r.taxOn), (false, false));
    expect(parseReceiptJson('{"items":[{"name":"A","amount":"10"}],"servicePercent":"twelve"}').serviceOn, isFalse);
  });

  test('a JSON number instead of a string is read from its text, never computed with', () {
    final r = parseReceiptJson('{"items":[{"name":"A","amount":12.5}],"total":125}');
    expect(r.items.single.amountText, '12.50');
    expect(r.printedTotalMinor, 12500);
  });

  test('a code fence around the JSON is removed', () {
    final r = parseReceiptJson('```json\n${_fixture('missing_total.json')}\n```');
    expect(r.items.length, 1);
  });

  test('a name over 100 code points is cut and flagged; more than 100 items are cut with a note', () {
    final long = 'ص' * 120;
    final r = parseReceiptJson(jsonEncode({'items': [{'name': long, 'amount': '5'}]}));
    expect(r.items.single.name.runes.length, 100);
    expect(r.items.single.flagged, isTrue);

    final many = jsonEncode({'items': [for (var i = 0; i < 105; i++) {'name': 'i$i', 'amount': '1'}]});
    final m = parseReceiptJson(many);
    expect((m.items.length, m.truncated), (100, true));
  });

  // ---- SA17 (STANDALONE_SPEC 18.4, A176, A179) ----

  String item(Map<String, Object?> fields) => jsonEncode({'items': [{'name': 'A', 'amount': '90', ...fields}]});
  ParsedItem only(String json) => parseReceiptJson(json).items.single;

  group('quantity and unit price (the client never multiplies or divides)', () {
    test('quantity with a unit price: quantity and the UNIT price, the line total is not used', () {
      expect(only(item({'quantity': '3', 'unitPrice': '30'})), const ParsedItem(name: 'A', amountText: '30', flagged: false, quantity: 3));
    });

    test('Arabic-Indic digits and an "x" around the quantity', () {
      expect(only(item({'quantity': '٣', 'unitPrice': '٣٠'})).quantity, 3);
      expect(only(item({'quantity': 'x3', 'unitPrice': '30'})).quantity, 3);
      expect(only(item({'quantity': '3 ×', 'unitPrice': '30'})).quantity, 3);
    });

    test('the model did not do the arithmetic: a line total that is not quantity x price is ignored, not corrected', () {
      final i = only(item({'amount': '100', 'quantity': '3', 'unitPrice': '30'}));
      expect((i.amountText, i.quantity, i.flagged, i.needsUnitPrice), ('30', 3, false, false));
    });

    test('quantity above 1 with only a line total: opens as quantity 1 with the line total and a flag for the unit price', () {
      expect(only(item({'quantity': '3'})), const ParsedItem(name: 'A', amountText: '90', flagged: false, needsUnitPrice: true));
      expect(only(item({'quantity': '3', 'unitPrice': ''})).needsUnitPrice, isTrue);
      expect(only(item({'quantity': '3', 'unitPrice': 'abc'})).needsUnitPrice, isTrue);
    });

    test('quantity above 1 with neither a unit price nor a line total: the quantity stays, the amount is empty and flagged', () {
      final i = only(jsonEncode({'items': [{'name': 'A', 'amount': '', 'quantity': '3'}]}));
      expect((i.quantity, i.amountText, i.flagged, i.needsUnitPrice), (3, '', true, false));
    });

    test('no quantity, quantity 1, or a missing field: quantity 1 and the line total, nothing to check', () {
      for (final fields in [<String, Object?>{}, {'quantity': ''}, {'quantity': '1'}, {'quantity': '1', 'unitPrice': '90'}]) {
        final i = only(item(fields));
        expect((i.quantity, i.amountText, i.flagged, i.quantityNeedsCheck, i.needsUnitPrice), (1, '90', false, false, false), reason: '$fields');
      }
    });

    test('only a unit price and no quantity: the unit price is the amount (quantity 1)', () {
      final i = only(jsonEncode({'items': [{'name': 'A', 'amount': '', 'unitPrice': '30'}]}));
      expect((i.quantity, i.amountText, i.flagged), (1, '30', false));
    });

    for (final bad in ['0', '1000', '-2', '1.5', 'two', '٣٫٥', '99999']) {
      test('quantity "$bad" is unreadable: quantity 1, the line total, flagged for a check', () {
        final i = only(item({'quantity': bad, 'unitPrice': '30'}));
        expect((i.quantity, i.amountText, i.quantityNeedsCheck, i.needsUnitPrice), (1, '90', true, false));
      });
    }

    test('quantity limits: 2 and 999 are accepted', () {
      expect(only(item({'quantity': '2', 'unitPrice': '30'})).quantity, 2);
      expect(only(item({'quantity': '999', 'unitPrice': '30'})).quantity, 999);
    });

    test('a JSON number for the quantity is read from its text', () {
      expect(only(item({'quantity': 3, 'unitPrice': 30})), const ParsedItem(name: 'A', amountText: '30', flagged: false, quantity: 3));
    });
  });

  group('discount', () {
    ParsedReceipt discount(Map<String, Object?> fields) =>
        parseReceiptJson(jsonEncode({'items': [{'name': 'A', 'amount': '100'}], 'subtotal': '100', ...fields}));

    test('an amount', () {
      final r = discount({'discountAmount': '20'});
      expect((r.discountOn, r.discountAmountText, r.discountPercentText, r.discountBothPrinted, r.discountDropped), (true, '20', '', false, false));
    });

    test('a percentage (Arabic percent sign and digits too)', () {
      expect(discount({'discountPercent': '10%'}).discountPercentText, '10');
      expect(discount({'discountPercent': '٪١٥'}).discountPercentText, '15');
      expect(discount({'discountPercent': '12.5'}).discountPercentText, '12.5');
    });

    test('a sign or brackets around the amount are removed (a printed -20 or (20) is a discount of 20)', () {
      for (final printed in ['-20', '−20', '(20)', '- 20', '-٢٠']) {
        expect(discount({'discountAmount': printed}).discountAmountText, '20', reason: printed);
      }
    });

    test('both printed: the percentage wins and the note says so (A179)', () {
      final r = discount({'discountAmount': '20', 'discountPercent': '10'});
      expect((r.discountPercentText, r.discountAmountText, r.discountBothPrinted, r.discountDropped), ('10', '', true, false));
    });

    test('an amount equal to or above the printed subtotal is dropped with a note', () {
      for (final printed in ['100', '150']) {
        final r = discount({'discountAmount': printed});
        expect((r.discountOn, r.discountDropped), (false, true), reason: printed);
      }
    });

    test('an amount below the subtotal by one piaster is kept', () {
      expect(discount({'discountAmount': '99.99'}).discountAmountText, '99.99');
    });

    test('without a printed subtotal an amount cannot be compared, so it is kept (the editor validates it)', () {
      final r = parseReceiptJson('{"items":[{"name":"A","amount":"100"}],"discountAmount":"500"}');
      expect((r.discountAmountText, r.discountDropped), ('500', false));
    });

    test('a 100% discount is dropped with a note; 0 or text is simply absent', () {
      final full = discount({'discountPercent': '100'});
      expect((full.discountOn, full.discountDropped), (false, true));
      for (final printed in ['0', 'ten', '', '140']) {
        final r = discount({'discountPercent': printed});
        expect(r.discountOn, isFalse, reason: printed);
      }
    });

    test('Arabic-Indic digits and Arabic separators in the amount', () {
      expect(discount({'discountAmount': '٢٥٫٥٠'}).discountAmountText, '25.50');
    });

    test('nothing printed: no discount, nothing dropped', () {
      final r = discount({'discountAmount': '', 'discountPercent': ''});
      expect((r.discountOn, r.discountDropped, r.discountBothPrinted), (false, false, false));
    });
  });

  group('merchant name', () {
    String? name(Object? v) => parseReceiptJson('{"items":[{"name":"A","amount":"5"}],"merchantName":${jsonEncode(v)}}').merchantName;

    test('trimmed with inner whitespace collapsed', () => expect(name('  مطعم   الشاورما \n'), 'مطعم الشاورما'));
    test('empty, blank, null or not text is absent', () {
      expect(name(''), isNull);
      expect(name('   '), isNull);
      expect(name(null), isNull);
      expect(name(['x']), isNull);
    });
    test('over 100 code points is cut to 100 (no broken characters)', () {
      final cut = name('😀' * 120)!;
      expect(cut.runes.length, 100);
    });
    test('the old schema has none', () => expect(parseReceiptJson(goodOldJson).merchantName, isNull));
  });

  group('category', () {
    String? category(Object? v) => parseReceiptJson('{"items":[{"name":"A","amount":"5"}],"category":${jsonEncode(v)}}').category;

    test('a known value, any case', () {
      expect(category('FOOD'), 'FOOD');
      expect(category(' groceries '), 'GROCERIES');
      expect(category('Entertainment'), 'ENTERTAINMENT');
    });
    test('unknown, OTHER, empty and null are no suggestion', () {
      for (final v in ['SPORTS', 'OTHER', 'other', '', null, 5]) {
        expect(category(v), isNull, reason: '$v');
      }
    });
    test('every category except OTHER is accepted', () {
      for (final c in ExpenseCategory.values.where((c) => c != ExpenseCategory.other)) {
        expect(category(c.wire), c.wire);
      }
    });
  });

  group('the old schema (no SA17 fields) parses as before', () {
    test('items, charges and the total are unchanged and every new field is empty', () {
      final r = parseReceiptJson(goodOldJson);
      expect(r.items, const [
        ParsedItem(name: 'Tea', amountText: '12.50', flagged: false),
        ParsedItem(name: 'Cake', amountText: '30', flagged: false),
      ]);
      expect((r.serviceOn, r.servicePercentText, r.taxOn, r.taxPercentText, r.printedTotalMinor), (true, '12', true, '14', 5600));
      expect((r.discountOn, r.discountDropped, r.merchantName, r.category), (false, false, null, null));
      expect((r.hasQuantityToCheck, r.hasUnitPriceToCheck), (false, false));
    });
  });
}

const goodOldJson = '{"items":[{"name":"Tea","amount":"12.50"},{"name":"Cake","amount":"30"}],'
    '"subtotal":"42.50","servicePercent":"12","taxPercent":"14","total":"56","currency":"EGP"}';
