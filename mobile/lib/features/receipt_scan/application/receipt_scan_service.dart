import 'dart:typed_data';

import 'cairo_day.dart';
import 'firebase_receipt_reader.dart' show classifyScanError;
import 'jpeg_metadata.dart';
import 'ocr_settings_store.dart';
import 'parsed_receipt.dart';
import 'receipt_parser.dart';
import 'receipt_reader.dart';

/// One scan, end to end (SA12): daily cap, metadata strip, request, parse, and the bookkeeping that follows
/// (counter, permission-error streak, hiding). The photo is never stored or logged; only a [ParsedReceipt] comes out,
/// or a [ReceiptScanException] with a kind.
final class ReceiptScanService {
  ReceiptScanService({required this.reader, required this.store, required this.now});

  final ReceiptReader reader;
  final OcrSettingsStore store;

  /// "Now" (UTC); injected so the cap and the hiding are testable.
  final DateTime Function() now;

  /// The state the entry points and the profile show.
  Future<OcrSettings> settings() => store.read();

  Future<void> giveConsent() async => store.write((await store.read()).copyWith(consentAt: now().toUtc().millisecondsSinceEpoch));

  Future<void> revokeConsent() async => store.write((await store.read()).copyWith(clearConsent: true));

  /// Sends [photo] (a JPEG) and returns the proposal. The attempt counts against the daily cap as soon as it is sent.
  Future<ParsedReceipt> scan(Uint8List photo) async {
    final nowUtc = now().toUtc();
    final nowMs = nowUtc.millisecondsSinceEpoch;
    final today = cairoDay(nowUtc);
    var s = await store.read();
    if (!s.consented) throw const ReceiptScanException(ReceiptScanFailure.unavailable);
    if (s.isHidden(nowMs)) throw const ReceiptScanException(ReceiptScanFailure.permissionDenied);
    if (s.scansOn(today) >= kDailyScanCap) throw const ReceiptScanException(ReceiptScanFailure.dailyCapReached);

    final Uint8List clean;
    try {
      clean = stripJpegMetadata(photo);
    } on FormatException {
      throw const ReceiptScanException(ReceiptScanFailure.unreadablePhoto);
    }

    s = s.copyWith(scanDay: today, scanCount: s.scansOn(today) + 1);
    await store.write(s);

    try {
      final parsed = parseReceiptJson(await reader.read(clean));
      await store.write(s.copyWith(permissionErrors: 0, clearHidden: true));
      return parsed;
    } on ReceiptScanException catch (failure) {
      await store.write(_afterFailure(s, failure.failure, nowMs));
      rethrow;
    } catch (error) {
      // Whatever the reader threw is turned into a kind (an unknown error becomes "unavailable", never a crash).
      final failure = classifyScanError(error);
      await store.write(_afterFailure(s, failure.failure, nowMs));
      throw failure;
    }
  }

  /// Permission errors in a row hide the feature for a week; an answer from the server (quota, bad JSON, no items)
  /// proves the app is accepted and resets the streak; offline and timeout say nothing and leave it as it is.
  OcrSettings _afterFailure(OcrSettings s, ReceiptScanFailure failure, int nowMs) {
    switch (failure) {
      case ReceiptScanFailure.permissionDenied:
        final streak = s.permissionErrors + 1;
        return streak >= kPermissionErrorsToHide
            ? s.copyWith(permissionErrors: 0, hiddenUntil: nowMs + kHiddenFor.inMilliseconds)
            : s.copyWith(permissionErrors: streak);
      case ReceiptScanFailure.quotaExhausted:
      case ReceiptScanFailure.invalidResponse:
      case ReceiptScanFailure.unreadablePhoto:
        return s.copyWith(permissionErrors: 0);
      default:
        return s;
    }
  }
}
