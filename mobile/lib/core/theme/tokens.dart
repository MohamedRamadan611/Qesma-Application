import 'package:flutter/painting.dart';

/// Design tokens from docs/design/DESIGN.md (prose and English spec values; the
/// auto-generated Material palette in its front-matter is NOT used). Contrast of every
/// text and boundary pair is verified by test/core/theme/contrast_test.dart.
///
/// This folder is the only place raw colours and sizes may be written (guard test).

/// Minimum touch target (dp) for every interactive element.
const double kMinTouch = 48;

/// Font family bundled in assets/fonts (IBM Plex Sans Arabic, SIL OFL 1.1).
const String kFontFamily = 'IBMPlexSansArabic';

abstract final class QesmaColors {
  // Brand
  static const Color primary = Color(0xFF0F766E);
  /// Text and icons on primary and error fills.
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryPressed = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF115E59);
  static const Color tint = Color(0xFFF0FDFA);
  static const Color tintBorder = Color(0xFFCCFBF1);

  // Surfaces
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF1F5F9);
  static const Color hairline = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);

  /// Helper text. 4.76:1 on white. Do not place it on [surfaceLow] (4.34:1).
  static const Color textHelper = Color(0xFF64748B);

  /// Disabled or decorative only. 2.56:1: never carries information.
  static const Color textDisabled = Color(0xFF94A3B8);

  // Boundaries
  /// Input outline: 3.6:1 on white (WCAG 1.4.11 needs 3:1). The mock-up's #CBD5E1 is 1.48:1.
  static const Color outline = Color(0xFF7A889C);

  /// Secondary button border. The button always carries a text label, so it stays identifiable.
  static const Color buttonBorder = Color(0xFFCBD5E1);

  // Status
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Amber for icons and decoration only (2.86:1 on its container).
  static const Color warningDecor = Color(0xFFD97706);
  static const Color info = Color(0xFF3730A3);
  static const Color infoContainer = Color(0xFFE0E7FF);
  static const Color success = Color(0xFF166534);
  static const Color successContainer = Color(0xFFDCFCE7);

  // Balances (English spec pairs: all >= 4.5:1; DESIGN.md's pairs fail AA)
  static const Color owed = Color(0xFF15803D);
  static const Color owedBg = Color(0xFFDCFCE7);
  static const Color owes = Color(0xFFC2410C);
  static const Color owesBg = Color(0xFFFFEDD5);
  static const Color settled = Color(0xFF475569);
  static const Color settledBg = Color(0xFFF1F5F9);

  // Inverse (snackbars)
  static const Color inverseSurface = Color(0xFF0F172A);
  static const Color onInverseSurface = Color(0xFFF8FAFC);

  /// Placeholder blocks while loading (decorative; 1.18:1 against the canvas by design).
  static const Color skeleton = Color(0xFFE2E8F0);

  /// Member avatar palette: (background, initial). Chosen by a stable hash of the member id.
  static const List<(Color, Color)> avatarTints = [
    (Color(0xFFCCFBF1), Color(0xFF115E59)),
    (Color(0xFFFFEDD5), Color(0xFF9A3412)),
    (Color(0xFFE0E7FF), Color(0xFF3730A3)),
    (Color(0xFFFFE4E6), Color(0xFF9F1239)),
    (Color(0xFFFEF3C7), Color(0xFF92400E)),
    (Color(0xFFDCFCE7), Color(0xFF166534)),
  ];
}

abstract final class QesmaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Screen edge margin on phones.
  static const double margin = 16;
}

abstract final class QesmaRadii {
  static const double card = 16;
  static const double control = 12; // buttons and inputs
  static const double hero = 24;
  static const double sheet = 28;
  static const double pill = 9999;
}

abstract final class QesmaDurations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration pulse = Duration(milliseconds: 1200);
}

/// Elevation levels from DESIGN.md as box-shadow lists.
abstract final class QesmaShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x050F172A), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x080F172A), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, -4)),
  ];
  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x590F766E), blurRadius: 14, offset: Offset(0, 4)),
  ];
}
