import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/receipt_scan/application/jpeg_metadata.dart';

/// A receipt photo must leave the phone without EXIF (GPS, device, time) or any other metadata (SA12).
List<int> _segment(int marker, List<int> payload) => [0xFF, marker, (payload.length + 2) >> 8, (payload.length + 2) & 0xFF, ...payload];

Uint8List _jpeg({List<List<int>> before = const []}) => Uint8List.fromList([
      0xFF, 0xD8,
      ...before.expand((s) => s),
      ..._segment(0xDB, List.filled(65, 1)), // DQT
      ..._segment(0xC0, [8, 0, 1, 0, 1, 1, 1, 0x11, 0]), // SOF0
      ..._segment(0xDA, [1, 1, 0, 0, 0x3F, 0]), // SOS header
      0x12, 0xFF, 0x00, 0x34, // entropy-coded data with a stuffed 0xFF
      0xFF, 0xD9,
    ]);

bool _contains(Uint8List bytes, List<int> pattern) {
  for (var i = 0; i + pattern.length <= bytes.length; i++) {
    var ok = true;
    for (var j = 0; j < pattern.length; j++) {
      if (bytes[i + j] != pattern[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

void main() {
  final gps = 'GPSLatitude'.codeUnits;
  final exif = _segment(0xE1, [...'Exif\x00\x00'.codeUnits, ...gps]);
  final xmp = _segment(0xE1, 'http://ns.adobe.com/xap/1.0/\x00<x:xmpmeta/>'.codeUnits);
  final comment = _segment(0xFE, 'made on my phone'.codeUnits);
  final iptc = _segment(0xED, 'Photoshop 3.0'.codeUnits);
  final jfif = _segment(0xE0, 'JFIF\x00'.codeUnits);
  final icc = _segment(0xE2, 'ICC_PROFILE\x00'.codeUnits);

  test('EXIF with GPS, XMP, IPTC and comments are removed; the picture data stays byte for byte', () {
    final clean = stripJpegMetadata(_jpeg(before: [jfif, exif, xmp, iptc, comment]));
    expect(_contains(clean, gps), isFalse);
    expect(_contains(clean, 'Exif'.codeUnits), isFalse);
    expect(_contains(clean, 'xmpmeta'.codeUnits), isFalse);
    expect(_contains(clean, 'Photoshop'.codeUnits), isFalse);
    expect(_contains(clean, 'my phone'.codeUnits), isFalse);
    expect(clean, _jpeg(before: [jfif]), reason: 'only JFIF remains of the metadata; every other segment and the scan are untouched');
  });

  test('the ICC colour profile and the JFIF header are kept', () {
    final clean = stripJpegMetadata(_jpeg(before: [jfif, exif, icc]));
    expect(clean, _jpeg(before: [jfif, icc]));
  });

  test('a JPEG without metadata is returned unchanged', () {
    final plain = _jpeg();
    expect(stripJpegMetadata(plain), plain);
  });

  test('something that is not a JPEG, or is cut short, is refused', () {
    expect(() => stripJpegMetadata(Uint8List.fromList([1, 2, 3, 4, 5])), throwsFormatException);
    expect(() => stripJpegMetadata(Uint8List(0)), throwsFormatException);
    final cut = _jpeg(before: [exif]).sublist(0, 12);
    expect(() => stripJpegMetadata(cut), throwsFormatException);
  });
}
