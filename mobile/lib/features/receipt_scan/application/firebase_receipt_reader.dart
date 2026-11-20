import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import 'receipt_reader.dart';

/// The Gemini model used for receipts (Flash-Lite, stable id from the Gemini model list read on 2026-11-19).
/// Changing the model is a one-line change here.
const String kReceiptModel = 'gemini-3.5-flash-lite';

const Duration kReceiptTimeout = Duration(seconds: 25);

const String _prompt = 'You read a restaurant or shop receipt photo (Arabic, English or both). Return only the JSON object '
    'of the schema. items: one entry per purchased line, name as printed, amount = that line total as printed. '
    'subtotal, serviceAmount, taxAmount, total: as printed, or an empty string if not printed. servicePercent and '
    'taxPercent: the printed percentage number, or an empty string. currency: as printed or an empty string. '
    'Copy numbers exactly as printed (Arabic-Indic digits are fine). Never calculate, correct or guess a number.';

Schema _schema() => Schema.object(
      properties: {
        'items': Schema.array(
          items: Schema.object(properties: {'name': Schema.string(), 'amount': Schema.string()}),
        ),
        'subtotal': Schema.string(),
        'servicePercent': Schema.string(),
        'serviceAmount': Schema.string(),
        'taxPercent': Schema.string(),
        'taxAmount': Schema.string(),
        'total': Schema.string(),
        'currency': Schema.string(),
      },
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
