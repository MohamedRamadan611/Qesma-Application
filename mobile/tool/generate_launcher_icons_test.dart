import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Renders the brand logo (the pie-chart glyph of `BrandLogo` in lib/core/widgets/brand.dart) to the legacy launcher icons
/// (API 24-25 and any launcher that ignores adaptive icons). The adaptive icon of API 26+ is a vector
/// (android/app/src/main/res/drawable/ic_launcher_foreground.xml) and needs no regeneration.
///
///   flutter test tool/generate_launcher_icons_test.dart
///
/// It is a "test" only because `flutter test` is the supported way to run dart:ui rendering headlessly. Keep the colours and the
/// geometry in sync with BrandLogo (light palette: primary 0xFF0F766E, glyph white).
const _teal = ui.Color(0xFF0F766E);
const _white = ui.Color(0xFFFFFFFF);
const _sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};

Future<List<int>> _render(int px) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final size = px.toDouble();
  final center = ui.Offset(size / 2, size / 2);
  canvas.drawCircle(center, size / 2, ui.Paint()..color = _teal..isAntiAlias = true);
  final radius = size * 0.27;
  final gap = size * 0.045;
  canvas.drawCircle(center, radius, ui.Paint()..color = _white..isAntiAlias = true);
  final cut = ui.Paint()
    ..color = _teal
    ..strokeWidth = gap
    ..isAntiAlias = true;
  canvas.drawLine(center - ui.Offset(0, radius), center + ui.Offset(0, radius), cut);
  canvas.drawLine(center, center + ui.Offset(radius, 0), cut);
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('write the legacy launcher icons', (tester) async {
    await tester.runAsync(() async {
      for (final entry in _sizes.entries) {
        final file = File('android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png');
        await file.writeAsBytes(await _render(entry.value));
      }
    });
  });
}
