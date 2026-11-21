import 'dart:convert';

import '../../../core/money/money.dart';
import '../../expenses/application/expense_form_state.dart' show kExpenseTitleMax, kItemNameMax, kMaxItems, kMaxQuantity, kMinQuantity;
import '../../expenses/data/expense_category.dart';
import 'parsed_receipt.dart';
import 'receipt_reader.dart';

/// Turns the model's JSON text into a [ParsedReceipt] (SA12, SA17). Every amount goes through [Money.parse], every
/// percentage through [Bps.parse], every quantity through [Count.parse]; a string that does not parse leaves an
/// item with an empty amount and a flag. Nothing is added up, multiplied or divided and nothing the model computed
/// is believed. Throws [ReceiptScanException] with `invalidResponse` for text that is not the expected object, and
/// `unreadablePhoto` when it holds no items. Fields an older answer does not have are simply absent.
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
    final item = _item(raw);
    if (item != null) items.add(item);
  }
  if (items.isEmpty) throw const ReceiptScanException(ReceiptScanFailure.unreadablePhoto);

  final servicePercent = _percent(decoded['servicePercent']);
  final taxPercent = _percent(decoded['taxPercent']);
  final serviceAmount = servicePercent == null ? _amount(decoded['serviceAmount']) : null;
  final taxAmount = taxPercent == null ? _amount(decoded['taxAmount']) : null;
  final deliveryAmount = _amount(decoded['deliveryAmount']);
  final currency = _string(decoded['currency']).trim();
  final discount = _discount(decoded);

  return ParsedReceipt(
    items: items,
    serviceOn: servicePercent != null || serviceAmount != null,
    servicePercentText: servicePercent == null ? '' : Bps.format(servicePercent),
    serviceAmountText: serviceAmount == null ? '' : Money.formatPlain(serviceAmount),
    taxOn: taxPercent != null || taxAmount != null,
    taxPercentText: taxPercent == null ? '' : Bps.format(taxPercent),
    taxAmountText: taxAmount == null ? '' : Money.formatPlain(taxAmount),
    deliveryAmountText: deliveryAmount == null ? '' : Money.formatPlain(deliveryAmount),
    discountPercentText: discount.percentText,
    discountAmountText: discount.amountText,
    discountBothPrinted: discount.both,
    discountDropped: discount.dropped,
    merchantName: _merchantName(decoded['merchantName']),
    category: _category(decoded['category']),
    printedTotalMinor: _amount(decoded['total']),
    currency: currency.isEmpty ? null : currency,
    truncated: truncated,
  );
}

/// One receipt line. The printed line total is the amount of a line of quantity 1. A quantity above 1 is used only
/// with a printed unit price (the amount is then the UNIT price); without one the line opens as quantity 1 with its
/// printed line total and is flagged, because the client never divides. An unreadable quantity opens as 1, flagged.
ParsedItem? _item(Map<Object?, Object?> raw) {
  var name = _string(raw['name']).trim();
  var flagged = false;
  final runes = name.runes.toList();
  if (runes.length > kItemNameMax) {
    name = String.fromCharCodes(runes.take(kItemNameMax));
    flagged = true;
  }
  final lineTotal = _amount(raw['amount']);
  final unitPrice = _amount(raw['unitPrice']);
  final printedAnything = _string(raw['amount']).trim().isNotEmpty || _string(raw['unitPrice']).trim().isNotEmpty;
  if (name.isEmpty && lineTotal == null && unitPrice == null && !printedAnything) return null; // an empty row

  final quantityText = _string(raw['quantity']).replaceAll(_quantityNoise, '');
  final quantity = quantityText.isEmpty ? null : Count.parse(quantityText, min: kMinQuantity, max: kMaxQuantity);
  final quantityNeedsCheck = quantityText.isNotEmpty && quantity == null;

  int? amount;
  var opensAs = 1;
  var needsUnitPrice = false;
  if (quantity != null && quantity > 1) {
    if (unitPrice != null) {
      amount = unitPrice;
      opensAs = quantity;
    } else if (lineTotal != null) {
      amount = lineTotal;
      needsUnitPrice = true;
    } else {
      opensAs = quantity;
    }
  } else {
    amount = lineTotal ?? unitPrice;
  }
  return ParsedItem(
    name: name,
    amountText: amount == null ? '' : Money.formatPlain(amount),
    flagged: flagged || amount == null,
    quantity: opensAs,
    quantityNeedsCheck: quantityNeedsCheck,
    needsUnitPrice: needsUnitPrice,
  );
}

/// "x3", "3 ×", "3x" -> "3" (the multiplication sign and spaces are not part of the number).
final RegExp _quantityNoise = RegExp(r'[xX×*\s]');

typedef _Discount = ({String percentText, String amountText, bool both, bool dropped});

/// The bill discount as printed. A percentage wins over an amount (A179). A printed sign or brackets are not part of
/// the amount. A 100% discount, or an amount as large as the printed subtotal, is not a discount (A171): dropped.
_Discount _discount(Map<Object?, Object?> decoded) {
  const none = (percentText: '', amountText: '', both: false, dropped: false);
  final rawPercent = _string(decoded['discountPercent']).trim();
  final rawAmount = _string(decoded['discountAmount']).trim();
  final percent = _percent(rawPercent);
  final amount = _amount(rawAmount.replaceAll(RegExp(r'[-−()\s]'), ''));
  final subtotal = _amount(decoded['subtotal']);

  if (percent != null) {
    if (percent >= Bps.max) return (percentText: '', amountText: '', both: false, dropped: true);
    return (percentText: Bps.format(percent), amountText: '', both: amount != null, dropped: false);
  }
  if (amount == null) return none;
  if (subtotal != null && amount >= subtotal) return (percentText: '', amountText: '', both: false, dropped: true);
  return (percentText: '', amountText: Money.formatPlain(amount), both: false, dropped: false);
}

/// Trimmed, inner whitespace collapsed, cut to the title limit by code points; null when nothing is left.
String? _merchantName(Object? value) {
  final text = _string(value).trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return null;
  final runes = text.runes.toList();
  return runes.length > kExpenseTitleMax ? String.fromCharCodes(runes.take(kExpenseTitleMax)) : text;
}

/// A known category's wire value, or null. `OTHER` and anything unknown are no suggestion (the form keeps its own).
String? _category(Object? value) {
  final upper = _string(value).trim().toUpperCase();
  for (final c in ExpenseCategory.values) {
    if (c != ExpenseCategory.other && c.wire == upper) return c.wire;
  }
  return null;
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
