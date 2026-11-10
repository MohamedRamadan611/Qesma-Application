import 'package:flutter/material.dart';

import 'tokens.dart';

/// Every colour of the app for ONE brightness, as a theme extension. Widgets read it with
/// `context.colors.x`; only this folder knows raw colour values (guard test). The field names are
/// the ones of [QesmaColors], which keeps the light palette and is the source of [QesmaPalette.light].
///
/// Contrast of every text and boundary pair is verified for BOTH palettes by
/// `test/core/theme/contrast_test.dart`.
@immutable
class QesmaPalette extends ThemeExtension<QesmaPalette> {
  const QesmaPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.primaryLight,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.tint,
    required this.tintBorder,
    required this.canvas,
    required this.card,
    required this.surfaceLow,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHelper,
    required this.textDisabled,
    required this.outline,
    required this.buttonBorder,
    required this.error,
    required this.errorFill,
    required this.onError,
    required this.errorContainer,
    required this.warning,
    required this.warningContainer,
    required this.warningDecor,
    required this.info,
    required this.infoContainer,
    required this.success,
    required this.successContainer,
    required this.owed,
    required this.owedBg,
    required this.owes,
    required this.owesBg,
    required this.settled,
    required this.settledBg,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.snackbarAction,
    required this.skeleton,
    required this.avatarTints,
  });

  final Brightness brightness;

  // Brand
  final Color primary;

  /// Text and icons on a [primary] fill.
  final Color onPrimary;
  final Color primaryPressed;
  final Color primaryLight;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color tint;
  final Color tintBorder;

  // Surfaces
  final Color canvas;
  final Color card;
  final Color surfaceLow;
  final Color hairline;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHelper;
  final Color textDisabled;

  // Boundaries
  final Color outline;
  final Color buttonBorder;

  // Status
  /// Error as TEXT, icon or outline.
  final Color error;

  /// Error as a button FILL (with [onError] on top).
  final Color errorFill;
  final Color onError;
  final Color errorContainer;
  final Color warning;
  final Color warningContainer;
  final Color warningDecor;
  final Color info;
  final Color infoContainer;
  final Color success;
  final Color successContainer;

  // Balances (word + sign always accompany the colour)
  final Color owed;
  final Color owedBg;
  final Color owes;
  final Color owesBg;
  final Color settled;
  final Color settledBg;

  // Inverse (snackbars)
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color snackbarAction;

  /// Placeholder blocks while loading (decorative).
  final Color skeleton;

  /// Member avatar palette: (background, initial).
  final List<(Color, Color)> avatarTints;

  bool get isDark => brightness == Brightness.dark;

  /// Today's palette, unchanged.
  static const QesmaPalette light = QesmaPalette(
    brightness: Brightness.light,
    primary: QesmaColors.primary,
    onPrimary: QesmaColors.onPrimary,
    primaryPressed: QesmaColors.primaryPressed,
    primaryLight: QesmaColors.primaryLight,
    primaryContainer: QesmaColors.primaryContainer,
    onPrimaryContainer: QesmaColors.onPrimaryContainer,
    tint: QesmaColors.tint,
    tintBorder: QesmaColors.tintBorder,
    canvas: QesmaColors.canvas,
    card: QesmaColors.card,
    surfaceLow: QesmaColors.surfaceLow,
    hairline: QesmaColors.hairline,
    textPrimary: QesmaColors.textPrimary,
    textSecondary: QesmaColors.textSecondary,
    textHelper: QesmaColors.textHelper,
    textDisabled: QesmaColors.textDisabled,
    outline: QesmaColors.outline,
    buttonBorder: QesmaColors.buttonBorder,
    error: QesmaColors.error,
    errorFill: QesmaColors.error,
    onError: QesmaColors.onPrimary,
    errorContainer: QesmaColors.errorContainer,
    warning: QesmaColors.warning,
    warningContainer: QesmaColors.warningContainer,
    warningDecor: QesmaColors.warningDecor,
    info: QesmaColors.info,
    infoContainer: QesmaColors.infoContainer,
    success: QesmaColors.success,
    successContainer: QesmaColors.successContainer,
    owed: QesmaColors.owed,
    owedBg: QesmaColors.owedBg,
    owes: QesmaColors.owes,
    owesBg: QesmaColors.owesBg,
    settled: QesmaColors.settled,
    settledBg: QesmaColors.settledBg,
    inverseSurface: QesmaColors.inverseSurface,
    onInverseSurface: QesmaColors.onInverseSurface,
    snackbarAction: QesmaColors.primaryContainer,
    skeleton: QesmaColors.skeleton,
    avatarTints: QesmaColors.avatarTints,
  );

  /// The dark palette: derived from the brand teal (not an inversion of the light one). Dark navy
  /// surfaces, light text, teal fills with dark text on top, status colours as light text on dark
  /// containers. Every pair is held to the same contrast rules as the light palette.
  static const QesmaPalette dark = QesmaPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF14B8A6),
    onPrimary: Color(0xFF042F2E),
    primaryPressed: Color(0xFF2DD4BF),
    primaryLight: Color(0xFF5EEAD4),
    primaryContainer: Color(0xFF134E4A),
    onPrimaryContainer: Color(0xFF99F6E4),
    tint: Color(0xFF0F2A2C),
    tintBorder: Color(0xFF134E4A),
    canvas: Color(0xFF0B1220),
    card: Color(0xFF111B2E),
    surfaceLow: Color(0xFF172238),
    hairline: Color(0xFF26334B),
    textPrimary: Color(0xFFE8EEF8),
    textSecondary: Color(0xFFB4C0D2),
    textHelper: Color(0xFF94A3B8),
    textDisabled: Color(0xFF64748B),
    outline: Color(0xFF7C8CA5),
    buttonBorder: Color(0xFF3B4A63),
    error: Color(0xFFF87171),
    errorFill: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF3B1418),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF3A2A0A),
    warningDecor: Color(0xFFF59E0B),
    info: Color(0xFFA5B4FC),
    infoContainer: Color(0xFF1E2347),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF0F2E1A),
    owed: Color(0xFF4ADE80),
    owedBg: Color(0xFF0F2E1A),
    owes: Color(0xFFFB923C),
    owesBg: Color(0xFF3A1F0C),
    settled: Color(0xFFB4C0D2),
    settledBg: Color(0xFF1B2740),
    inverseSurface: Color(0xFFE8EEF8),
    onInverseSurface: Color(0xFF0B1220),
    snackbarAction: Color(0xFF0F766E),
    skeleton: Color(0xFF1B2740),
    avatarTints: [
      (Color(0xFF134E4A), Color(0xFF99F6E4)),
      (Color(0xFF43210F), Color(0xFFFDBA74)),
      (Color(0xFF1E2347), Color(0xFFA5B4FC)),
      (Color(0xFF431423), Color(0xFFFDA4AF)),
      (Color(0xFF3A2A0A), Color(0xFFFCD34D)),
      (Color(0xFF0F2E1A), Color(0xFF86EFAC)),
    ],
  );

  /// Themes switch at once (no cross-fade between palettes).
  @override
  QesmaPalette lerp(ThemeExtension<QesmaPalette>? other, double t) => other is QesmaPalette && t >= 0.5 ? other : this;

  @override
  QesmaPalette copyWith() => this;
}

extension QesmaPaletteX on BuildContext {
  /// The colours of the current theme (light when no theme carries a palette, as in bare widget tests).
  QesmaPalette get colors => Theme.of(this).extension<QesmaPalette>() ?? QesmaPalette.light;
}
