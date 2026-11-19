import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_mode.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/format/clock.dart';
import 'ocr_settings_store.dart';
import 'receipt_reader.dart';
import 'receipt_scan_service.dart';

/// The real reader (Firebase AI Logic), provided by `main.dart` only in local mode after Firebase and App Check were
/// initialised. Null = scanning is not available on this run (server mode, no Firebase config, init failed).
final receiptReaderProvider = Provider<ReceiptReader?>((ref) => null);

final receiptScanServiceProvider = Provider<ReceiptScanService?>((ref) {
  final reader = ref.watch(receiptReaderProvider);
  if (reader == null || ref.watch(appModeProvider) != AppMode.local) return null;
  final clock = ref.watch(clockProvider);
  return ReceiptScanService(reader: reader, store: ref.watch(ocrSettingsStoreProvider), now: () => clock().toUtc());
});

/// Consent and limit state; invalidate it after any change.
final ocrSettingsProvider = FutureProvider<OcrSettings>((ref) => ref.watch(ocrSettingsStoreProvider).read());

/// Whether the "Scan receipt" entry points exist right now: local mode, Firebase ready, and not hidden after repeated
/// permission errors (SA12 decision Q1). While the settings load they are shown (the scan checks again).
final receiptScanVisibleProvider = Provider<bool>((ref) {
  if (!ref.watch(modeFeaturesProvider).receiptScan) return false;
  if (ref.watch(receiptScanServiceProvider) == null) return false;
  final settings = ref.watch(ocrSettingsProvider).value;
  final nowMs = ref.watch(clockProvider)().toUtc().millisecondsSinceEpoch;
  return settings == null || !settings.isHidden(nowMs);
});

enum ReceiptPhotoSource { camera, gallery }

/// Takes or picks one photo and returns its bytes (a JPEG, at most 1600 px on a side, quality 80). The photo only
/// ever lives in memory; the picker's cache copy is deleted at once.
abstract interface class ReceiptPhotoPicker {
  /// Null when the user cancelled.
  Future<Uint8List?> pick(ReceiptPhotoSource source);
}

/// Longest side in pixels (written as a literal where it is used: image_picker takes a floating-point size).
const int kPhotoQuality = 80;

final class ImagePickerReceiptPhotoPicker implements ReceiptPhotoPicker {
  ImagePickerReceiptPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(ReceiptPhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == ReceiptPhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600, // 1600 px longest side, see the doc above
      maxHeight: 1600,
      imageQuality: kPhotoQuality,
      requestFullMetadata: false, // no location permission and no full EXIF read
    );
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } finally {
      await _deleteIfCached(file.path);
    }
  }

  /// Deletes the picker's copy, only when it is inside the app's temp/cache directory (never a gallery original).
  Future<void> _deleteIfCached(String path) async {
    try {
      final temp = (await getTemporaryDirectory()).path;
      if (path.startsWith(temp)) await File(path).delete();
    } on FileSystemException {
      // The cache is cleaned by the system anyway.
    }
  }
}

final receiptPhotoPickerProvider = Provider<ReceiptPhotoPicker>((ref) => ImagePickerReceiptPhotoPicker());
