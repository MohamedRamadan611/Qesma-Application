import 'package:flutter/material.dart';

import 'tokens.dart';

/// Type scale from DESIGN.md (IBM Plex Sans Arabic). `height` is lineHeight / fontSize.
abstract final class QesmaText {
  static TextStyle _s(double size, double line, FontWeight weight) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        letterSpacing: 0,
      );

  /// Tabular lining figures so decimals line up in columns (DESIGN.md numeral rules).
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme() => TextTheme(
        displayLarge: _s(32, 40, FontWeight.w700),
        displayMedium: _s(26, 34, FontWeight.w700),
        displaySmall: _s(24, 32, FontWeight.w700),
        headlineLarge: _s(24, 32, FontWeight.w600),
        headlineMedium: _s(20, 28, FontWeight.w600),
        headlineSmall: _s(18, 26, FontWeight.w600),
        titleLarge: _s(18, 26, FontWeight.w600),
        titleMedium: _s(16, 24, FontWeight.w500),
        titleSmall: _s(14, 20, FontWeight.w600),
        bodyLarge: _s(16, 24, FontWeight.w400),
        bodyMedium: _s(14, 20, FontWeight.w400),
        bodySmall: _s(12, 18, FontWeight.w400),
        labelLarge: _s(14, 20, FontWeight.w600),
        labelMedium: _s(12, 16, FontWeight.w600),
        labelSmall: _s(11, 14, FontWeight.w500),
      ).apply(bodyColor: QesmaColors.textPrimary, displayColor: QesmaColors.textPrimary);

  /// Amount styles: same scale, tabular figures.
  static TextStyle amountLarge() => _s(32, 40, FontWeight.w700).copyWith(fontFeatures: tabular);
  static TextStyle amountMedium() => _s(24, 32, FontWeight.w600).copyWith(fontFeatures: tabular);
  static TextStyle amountSmall() => _s(16, 24, FontWeight.w600).copyWith(fontFeatures: tabular);
  static TextStyle amountInline() => _s(14, 20, FontWeight.w600).copyWith(fontFeatures: tabular);
}
