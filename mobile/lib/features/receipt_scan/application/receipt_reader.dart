import 'dart:typed_data';

/// Why a scan failed. Each kind has its own message and a "type manually" action (STANDALONE_SPEC 13).
enum ReceiptScanFailure {
  offline,
  timeout,
  quotaExhausted,
  permissionDenied,
  unreadablePhoto,
  invalidResponse,
  dailyCapReached,
  unavailable,
}

/// Thrown by a [ReceiptReader] and by the scan flow. Carries a kind only: never the image or the model's text.
final class ReceiptScanException implements Exception {
  const ReceiptScanException(this.failure);

  final ReceiptScanFailure failure;

  @override
  String toString() => 'ReceiptScanException(${failure.name})';
}

/// Sends one receipt photo and returns the model's raw JSON text. The real one talks to Firebase AI Logic; tests use
/// a fake. It must not log or store the image or the response.
abstract interface class ReceiptReader {
  Future<String> read(Uint8List jpegBytes);
}
