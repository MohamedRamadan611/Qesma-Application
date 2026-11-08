import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/qesma_text.dart';
import 'package:qesma/core/theme/tokens.dart';

import '../../support/test_app.dart';

double _width(String text, TextStyle style) {
  final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  return painter.width;
}

void main() {
  setUpAll(loadAppFonts);

  test('the bundled font is really used (the test fallback gives every glyph the same width)', () {
    const style = TextStyle(fontFamily: kFontFamily, fontSize: 20);
    expect(_width('iiii', style), lessThan(_width('WWWW', style)));
  });

  test('tabular figures: every digit has the same width, so decimals line up in columns', () {
    final style = QesmaText.amountSmall();
    final widths = {for (var d = 0; d <= 9; d++) _width('$d$d$d.$d$d', style)};
    expect(widths, hasLength(1), reason: 'digit widths differ with tabular figures on: $widths');
    expect(_width('1,111.11', style), _width('0,000.00', style));
  });

  test('ASCII digits are drawn from the font (not mapped to Arabic-Indic forms)', () {
    // Arabic-Indic digits come from a different glyph set; if 0-9 were substituted the widths of
    // the Western and the Arabic-Indic string would be identical. They are not.
    final style = QesmaText.amountSmall();
    expect(_width('0123456789', style), isNot(_width('٠١٢٣٤٥٦٧٨٩', style)));
  });

  test('weights 400, 500, 600 and 700 are all available and differ', () {
    double w(FontWeight weight) =>
        _width('المصاريف 1,061.79', TextStyle(fontFamily: kFontFamily, fontSize: 20, fontWeight: weight));
    expect({w(FontWeight.w400), w(FontWeight.w500), w(FontWeight.w600), w(FontWeight.w700)}.length, greaterThan(2));
  });
}
