import 'dart:typed_data';

import 'package:qesma/features/receipt_scan/application/ocr_settings_store.dart';
import 'package:qesma/features/receipt_scan/application/receipt_reader.dart';
import 'package:qesma/features/receipt_scan/application/receipt_scan_providers.dart';

/// A tiny valid JPEG with an EXIF segment (the service strips it before the reader sees it).
Uint8List fakeJpeg() => Uint8List.fromList([
      0xFF, 0xD8,
      0xFF, 0xE1, 0x00, 0x08, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // EXIF
      0xFF, 0xDB, 0x00, 0x04, 0x01, 0x02,
      0xFF, 0xDA, 0x00, 0x04, 0x01, 0x02, 0x12, 0xFF, 0xD9,
    ]);

const goodJson = '{"items":[{"name":"Tea","amount":"12.50"},{"name":"Cake","amount":"30"}],"total":"42.50","currency":"EGP"}';

/// Answers with [responses] in order (a String is the model's text, an Object is thrown); records what it was sent.
final class FakeReceiptReader implements ReceiptReader {
  FakeReceiptReader(this.responses);

  final List<Object> responses;
  final List<Uint8List> received = [];

  @override
  Future<String> read(Uint8List jpegBytes) async {
    received.add(jpegBytes);
    final next = responses.length > 1 ? responses.removeAt(0) : responses.first;
    if (next is String) return next;
    throw next;
  }
}

final class MemoryOcrStore implements OcrSettingsStore {
  MemoryOcrStore([this.value = const OcrSettings()]);

  OcrSettings value;

  @override
  Future<OcrSettings> read() async => value;

  @override
  Future<void> write(OcrSettings settings) async => value = settings;
}

final class FakePhotoPicker implements ReceiptPhotoPicker {
  FakePhotoPicker([this.photo]);

  final Uint8List? photo;
  final List<ReceiptPhotoSource> asked = [];

  @override
  Future<Uint8List?> pick(ReceiptPhotoSource source) async {
    asked.add(source);
    return photo;
  }
}
