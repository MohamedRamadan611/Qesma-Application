import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Abstract seam for sharing trip recap image and text without requiring native platform dialogs in tests.
abstract class TripRecapSharer {
  Future<bool> shareImage(Uint8List pngBytes, {String? text});
  Future<bool> shareText(String text);
}

final class SystemTripRecapSharer implements TripRecapSharer {
  const SystemTripRecapSharer();

  @override
  Future<bool> shareImage(Uint8List pngBytes, {String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}qesma-recap.png');
    try {
      await file.writeAsBytes(pngBytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path, mimeType: 'image/png', name: 'qesma-recap.png')],
        ),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Temp directory cleanup failure is ignored
      }
    }
  }

  @override
  Future<bool> shareText(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    return result.status != ShareResultStatus.dismissed;
  }
}

final tripRecapSharerProvider = Provider<TripRecapSharer>((ref) {
  return const SystemTripRecapSharer();
});
