import 'dart:typed_data';

/// Removes the metadata segments of a JPEG (EXIF incl. GPS, XMP, IPTC, comments) and keeps everything the picture
/// needs. image_picker's resizer may copy EXIF tags, so the app strips them itself before anything leaves the phone
/// (STANDALONE_SPEC 13). Pure bytes in, bytes out. Not a JPEG (no SOI marker) => throws [FormatException].
///
/// Dropped: APP1 (EXIF, XMP), APP3..APP13 and APP15 (IPTC, vendor data) and COM (comments).
/// Kept: APP0 (JFIF), APP2 (ICC colour profile), APP14 (Adobe colour transform), DQT, DHT, SOF, SOS, image data.
Uint8List stripJpegMetadata(Uint8List input) {
  if (input.length < 4 || input[0] != 0xFF || input[1] != 0xD8) {
    throw const FormatException('not a JPEG');
  }
  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  var i = 2;
  while (i < input.length) {
    if (input[i] != 0xFF) throw const FormatException('bad JPEG marker');
    // Skip fill bytes.
    while (i < input.length && input[i] == 0xFF) {
      i++;
    }
    if (i >= input.length) throw const FormatException('truncated JPEG');
    final marker = input[i++];
    if (marker == 0xD9) {
      out.add(const [0xFF, 0xD9]);
      return out.takeBytes();
    }
    // Markers without a length field.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      out.add([0xFF, marker]);
      continue;
    }
    if (i + 2 > input.length) throw const FormatException('truncated JPEG');
    final length = (input[i] << 8) | input[i + 1];
    if (length < 2 || i + length > input.length) throw const FormatException('bad JPEG segment length');
    final segmentEnd = i + length;
    if (marker == 0xDA) {
      // Start of scan: the entropy-coded data runs to the end of the file (EOI included); copy it as is.
      out.add([0xFF, marker]);
      out.add(Uint8List.sublistView(input, i));
      return out.takeBytes();
    }
    final drop = marker == 0xFE || (marker >= 0xE1 && marker <= 0xEF && marker != 0xE2 && marker != 0xEE);
    if (!drop) {
      out.add([0xFF, marker]);
      out.add(Uint8List.sublistView(input, i, segmentEnd));
    }
    i = segmentEnd;
  }
  return out.takeBytes();
}
