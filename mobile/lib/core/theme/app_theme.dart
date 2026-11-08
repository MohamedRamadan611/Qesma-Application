import 'package:flutter/material.dart';

import 'balance_colors.dart';
import 'qesma_text.dart';
import 'tokens.dart';

/// The one light theme (Phase 1 has no dark theme). The [ColorScheme] is explicit, not
/// `fromSeed`, so no generated tonal colour can appear that the design does not define.
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: QesmaColors.primary,
    onPrimary: Colors.white,
    primaryContainer: QesmaColors.primaryContainer,
    onPrimaryContainer: QesmaColors.onPrimaryContainer,
    secondary: QesmaColors.textSecondary,
    onSecondary: Colors.white,
    secondaryContainer: QesmaColors.surfaceLow,
    onSecondaryContainer: QesmaColors.textPrimary,
    tertiary: QesmaColors.warning,
    onTertiary: Colors.white,
    tertiaryContainer: QesmaColors.warningContainer,
    onTertiaryContainer: QesmaColors.warning,
    error: QesmaColors.error,
    onError: Colors.white,
    errorContainer: QesmaColors.errorContainer,
    onErrorContainer: QesmaColors.error,
    surface: QesmaColors.canvas,
    onSurface: QesmaColors.textPrimary,
    onSurfaceVariant: QesmaColors.textSecondary,
    surfaceContainerLowest: QesmaColors.card,
    surfaceContainerLow: QesmaColors.surfaceLow,
    surfaceContainer: QesmaColors.surfaceLow,
    surfaceContainerHigh: QesmaColors.hairline,
    surfaceContainerHighest: QesmaColors.hairline,
    outline: QesmaColors.outline,
    outlineVariant: QesmaColors.hairline,
    inverseSurface: QesmaColors.inverseSurface,
    onInverseSurface: QesmaColors.onInverseSurface,
    inversePrimary: QesmaColors.primaryLight,
    surfaceTint: Colors.transparent,
    shadow: QesmaColors.textPrimary,
    scrim: QesmaColors.textPrimary,
  );

  final text = QesmaText.textTheme();
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.control));
  const minSize = Size(0, kMinTouch);

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: QesmaColors.canvas,
    canvasColor: QesmaColors.canvas,
    fontFamily: kFontFamily,
    textTheme: text,
    primaryTextTheme: text,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    extensions: const [BalanceColors()],
    dividerTheme: const DividerThemeData(color: QesmaColors.hairline, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: QesmaColors.canvas,
      foregroundColor: QesmaColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        shape: controlShape,
        textStyle: text.labelLarge,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? QesmaColors.hairline
              : s.contains(WidgetState.pressed)
                  ? QesmaColors.primaryPressed
                  : QesmaColors.primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? QesmaColors.textHelper : Colors.white,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: controlShape,
        textStyle: text.labelLarge,
        foregroundColor: QesmaColors.textPrimary,
        side: const BorderSide(color: QesmaColors.buttonBorder, width: 1.5),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minSize,
        shape: controlShape,
        textStyle: text.labelLarge,
        foregroundColor: QesmaColors.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(kMinTouch, kMinTouch), foregroundColor: QesmaColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: QesmaColors.card,
      isDense: false,
      constraints: const BoxConstraints(minHeight: 52),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.bodyLarge?.copyWith(color: QesmaColors.textHelper),
      errorStyle: text.bodySmall?.copyWith(color: QesmaColors.error),
      border: border(QesmaColors.outline, 1),
      enabledBorder: border(QesmaColors.outline, 1),
      focusedBorder: border(QesmaColors.primary, 2),
      errorBorder: border(QesmaColors.error, 1.5),
      focusedErrorBorder: border(QesmaColors.error, 2),
      disabledBorder: border(QesmaColors.hairline, 1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: QesmaColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      extendedTextStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.card)),
    ),
    cardTheme: CardThemeData(
      color: QesmaColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QesmaRadii.card),
        side: const BorderSide(color: QesmaColors.hairline),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: QesmaColors.card,
      modalBackgroundColor: QesmaColors.card,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(QesmaRadii.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: QesmaColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.card)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(color: QesmaColors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: QesmaColors.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: QesmaColors.onInverseSurface),
      actionTextColor: QesmaColors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.control)),
    ),
    focusColor: QesmaColors.primary.withValues(alpha: 0.12),
  );
}
