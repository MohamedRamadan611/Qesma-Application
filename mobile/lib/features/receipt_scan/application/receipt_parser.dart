import 'dart:convert';

import '../../../core/money/money.dart';
import '../../expenses/application/expense_form_state.dart' show kItemNameMax, kMaxItems;
import 'parsed_receipt.dart';
import 'receipt_reader.dart';

/// Turns the model's JSON text into a [ParsedReceipt] (SA12). Every amount goes through [Money.parse], every
/// percentage through [Bps.parse]; a string that does not parse leaves an item with an empty amount and a flag.
/// Nothing is added up and nothing the model computed is believed. Throws [ReceiptScanException] with
/// `invalidResponse` for text that is not the expected object, and `unreadablePhoto` when it holds no items.
ParsedReceipt parseReceiptJson(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(_unfence(text));
  } on FormatException {
    throw const ReceiptScanException(ReceiptScanFailure.invalidResponse);
  }
  if (decoded is! Map) throw const ReceiptScanException(ReceiptScanFailure.invalidResponse);
  final rawItems = decoded['items'];
  if (rawItems is! List) throw const ReceiptScanException(ReceiptScanFailure.invalidResponse);

  final items = <ParsedItem>[];
  var truncated = false;
  for (final raw in rawItems) {
    if (raw is! Map) continue;
    if (items.length >= kMaxItems) {
      truncated = true;
      break;
    }
    var name = _string(raw['name']).trim();
    var flagged = false;
    final runes = name.runes.toList();
    if (runes.length > kItemNameMax) {
      name = String.fromCharCodes(runes.take(kItemNameMax));
      flagged = true;
    }
    final minor = _amount(raw['amount']);
    if (name.isEmpty && minor == null && _string(raw['amount']).trim().isEmpty) continue; // an empty row
    items.add(ParsedItem(name: name, amountText: minor == null ? '' : Money.formatPlain(minor), flagged: flagged || minor == null));
  }
  if (items.isEmpty) throw const ReceiptScanException(ReceiptScanFailure.unreadablePhoto);

  final servicePercent = _percent(decoded['servicePercent']);
  final taxPercent = _percent(decoded['taxPercent']);
  final serviceAmountPrinted = _amount(decoded['serviceAmount']) != null;
  final taxAmountPrinted = _amount(decoded['taxAmount']) != null;
  final serviceOn = servicePercent != null || serviceAmountPrinted;
  final taxOn = taxPercent != null || taxAmountPrinted;
  final currency = _string(decoded['currency']).trim();

  return ParsedReceipt(
    items: items,
    serviceOn: serviceOn,
    servicePercentText: servicePercent == null ? '' : Bps.format(servicePercent),
    taxOn: taxOn,
    taxPercentText: taxPercent == null ? '' : Bps.format(taxPercent),
    printedTotalMinor: _amount(decoded['total']),
    currency: currency.isEmpty ? null : currency,
    truncated: truncated,
    chargeNeedsPercent: (serviceOn && servicePercent == null) || (taxOn && taxPercent == null),
  );
}

/// A JSON string, or the text of a bare JSON number (never a computed value); anything else is empty.
String _string(Object? value) => switch (value) {
      String() => value,
      null || bool() || List() || Map() => '',
      _ => value.toString(),
    };

/// Some models wrap JSON in a code fence even when told not to.
String _unfence(String text) {
  final t = text.trim();
  if (!t.startsWith('```')) return t;
  final start = t.indexOf('\n');
  final end = t.lastIndexOf('```');
  return start < 0 || end <= start ? t : t.substring(start + 1, end).trim();
}

final RegExp _currencyWords = RegExp(r'(EGP|E\.?G\.?P\.?|L\.?E\.?|ج\.م\.?|جنيه|ج)', caseSensitive: false);

int? _amount(Object? value) {
  final raw = _string(value).trim();
  if (raw.isEmpty) return null;
  return Money.parse(raw) ?? Money.parse(raw.replaceAll(_currencyWords, '').replaceAll(RegExp(r'\s'), ''));
}

int? _percent(Object? value) {
  final raw = _string(value).trim();
  if (raw.isEmpty) return null;
  final bps = Bps.parse(raw.replaceAll('%', '').replaceAll('٪', '').replaceAll(RegExp(r'\s'), ''));
  return bps == null || bps == 0 ? null : bps;
}
