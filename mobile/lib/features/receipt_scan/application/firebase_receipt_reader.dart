import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../../expenses/data/expense_category.dart';
import 'receipt_reader.dart';

/// The Gemini model used for receipts (Flash-Lite, stable id from the Gemini model list read on 2026-11-19).
/// Changing the model is a one-line change here.
const String kReceiptModel = 'gemini-3.5-flash-lite';

const Duration kReceiptTimeout = Duration(seconds: 25);

const String _prompt = 'You read a restaurant or shop receipt photo (Arabic, English or both). Return only the JSON object '
    'of the schema. items: one entry per purchased line, name as printed, amount = that line total as printed. '
    'quantity = the count printed for that line (a column such as الكمية, العدد, Qty, or a prefix like "2 x" or "×2"), '
    'or an empty string if none is printed. unitPrice = the price of ONE unit as printed on that line (a column such as '
    'سعر الوحدة, السعر, Price, Unit), or an empty string if it is not printed; never work it out from the line total. '
    'subtotal, serviceAmount, taxAmount, deliveryAmount, total: as printed (deliveryAmount is a delivery fee line such as توصيل, دليفري, Delivery), or an empty string if not printed. servicePercent and '
    'taxPercent: the printed percentage number, or an empty string. discountAmount and discountPercent: a discount line '
    '(خصم, تخفيض, Discount, Offer) as printed, the amount without any minus sign or brackets and the percentage number, '
    'each or an empty string if not printed. merchantName: the shop or restaurant name printed at the top, or an empty '
    'string. category: the single best match for what was bought from the allowed values, or null if unsure. '
    'totalBeforeTax: the line labelled total before VAT or tax (الإجمالي قبل الضريبة, المجموع قبل الضريبة, Total before VAT), or an empty string if no such line is printed. '
    'currency: as printed or an empty string. '
    'Copy numbers exactly as printed (Arabic-Indic digits are fine). Never calculate, correct or guess a number.';

Schema _schema() => Schema.object(
      properties: {
        'items': Schema.array(
          items: Schema.object(
            properties: {
              'name': Schema.string(),
              'amount': Schema.string(),
              'quantity': Schema.string(),
              'unitPrice': Schema.string(),
            },
            optionalProperties: ['quantity', 'unitPrice'],
          ),
        ),
        'subtotal': Schema.string(),
        'servicePercent': Schema.string(),
        'serviceAmount': Schema.string(),
        'taxPercent': Schema.string(),
        'taxAmount': Schema.string(),
        'deliveryAmount': Schema.string(),
        'discountAmount': Schema.string(),
        'discountPercent': Schema.string(),
        'merchantName': Schema.string(),
        'category': Schema.enumString(enumValues: [for (final c in ExpenseCategory.values) c.wire], nullable: true),
        'total': Schema.string(),
        'totalBeforeTax': Schema.string(),
        'currency': Schema.string(),
      },
      optionalProperties: ['discountAmount', 'discountPercent', 'merchantName', 'category', 'totalBeforeTax'],
    );

/// Firebase AI Logic (Gemini Developer API, free tier) behind App Check. No API key in the app: the Firebase project
/// config in `google-services.json` and an App Check token identify the app. The image and the response are never
/// logged or stored here.
final class FirebaseReceiptReader implements ReceiptReader {
  FirebaseReceiptReader();

  GenerativeModel? _model;

  GenerativeModel _modelOrCreate() => _model ??= FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true).generativeModel(
        model: kReceiptModel,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _schema(),
          temperature: 0,
          maxOutputTokens: 4096,
        ),
      );

  @override
  Future<String> read(Uint8List jpegBytes) async {
    try {
      final response = await _modelOrCreate().generateContent([
        Content.multi([TextPart(_prompt), InlineDataPart('image/jpeg', jpegBytes)]),
      ]).timeout(kReceiptTimeout);
      final text = response.text;
      if (text == null || text.trim().isEmpty) throw const ReceiptScanException(ReceiptScanFailure.unreadablePhoto);
      return text;
    } catch (error) {
      throw classifyScanError(error);
    }
  }
}

/// The one place that turns a thrown object into a [ReceiptScanException] (kind only; the message text is read for
/// matching and never kept). 403 has no documented Dart class, so permission errors are matched on the message and
/// the observed classes are recorded in the SA12 gate (manual check M2).
ReceiptScanException classifyScanError(Object error) {
  if (error is ReceiptScanException) return error;
  if (error is TimeoutException) return const ReceiptScanException(ReceiptScanFailure.timeout);
  if (error is SocketException || error is HandshakeException) {
    return const ReceiptScanException(ReceiptScanFailure.offline);
  }
  if (error is QuotaExceeded) return const ReceiptScanException(ReceiptScanFailure.quotaExhausted);
  if (error is InvalidApiKey || error is ServiceApiNotEnabled || error is UnsupportedUserLocation) {
    return const ReceiptScanException(ReceiptScanFailure.permissionDenied);
  }
  final text = error.toString().toLowerCase();
  if (text.contains('permission_denied') || text.contains('app check') || text.contains('403') || text.contains('permission denied')) {
    return const ReceiptScanException(ReceiptScanFailure.permissionDenied);
  }
  if (text.contains('quota') || text.contains('resource exhausted') || text.contains('429')) {
    return const ReceiptScanException(ReceiptScanFailure.quotaExhausted);
  }
  if (text.contains('failed host lookup') || text.contains('socketexception') || text.contains('network')) {
    return const ReceiptScanException(ReceiptScanFailure.offline);
  }
  if (error is FormatException) return const ReceiptScanException(ReceiptScanFailure.invalidResponse);
  return const ReceiptScanException(ReceiptScanFailure.unavailable);
}
