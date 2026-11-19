import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    expect(r.chargeNeedsPercent, isFalse);
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

  test('an amount printed without a percentage turns the charge on with an empty percent and a note', () {
    final r = parseReceiptJson('{"items":[{"name":"A","amount":"10"}],"serviceAmount":"1.20","taxPercent":"14"}');
    expect((r.serviceOn, r.servicePercentText, r.taxOn, r.taxPercentText, r.chargeNeedsPercent), (true, '', true, '14', true));
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
}
