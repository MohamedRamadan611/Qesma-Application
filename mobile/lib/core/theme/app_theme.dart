import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'balance_colors.dart';
import 'palette.dart';
import 'qesma_text.dart';
import 'tokens.dart';

/// The light or the dark theme. The [ColorScheme] is explicit, not `fromSeed`, so no generated
/// tonal colour can appear that the design does not define; every colour comes from the
/// [QesmaPalette] of the brightness, which every widget also reads with `context.colors`.
ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final p = brightness == Brightness.dark ? QesmaPalette.dark : QesmaPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    secondary: p.textSecondary,
    onSecondary: p.card,
    secondaryContainer: p.surfaceLow,
    onSecondaryContainer: p.textPrimary,
    tertiary: p.warning,
    onTertiary: p.card,
    tertiaryContainer: p.warningContainer,
    onTertiaryContainer: p.warning,
    error: p.errorFill,
    onError: p.onError,
    errorContainer: p.errorContainer,
    onErrorContainer: p.error,
    surface: p.canvas,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    surfaceContainerLowest: p.card,
    surfaceContainerLow: p.surfaceLow,
    surfaceContainer: p.surfaceLow,
    surfaceContainerHigh: p.hairline,
    surfaceContainerHighest: p.hairline,
    outline: p.outline,
    outlineVariant: p.hairline,
    inverseSurface: p.inverseSurface,
    onInverseSurface: p.onInverseSurface,
    inversePrimary: p.primaryLight,
    surfaceTint: Colors.transparent,
    shadow: p.textPrimary,
    scrim: p.textPrimary,
  );

  final text = QesmaText.textTheme(p.textPrimary);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.control));
  const minSize = Size(0, kMinTouch);

  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.canvas,
    canvasColor: p.canvas,
    fontFamily: kFontFamily,
    textTheme: text,
    primaryTextTheme: text,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    extensions: [p, BalanceColors.of(p)],
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.canvas,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Status-bar icons follow the theme: dark icons on the light canvas, light icons on the dark one.
      systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
              ? p.hairline
              : s.contains(WidgetState.pressed)
                  ? p.primaryPressed
                  : p.primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? p.textHelper : p.onPrimary,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: controlShape,
        textStyle: text.labelLarge,
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.buttonBorder, width: 1.5),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minSize,
        shape: controlShape,
        textStyle: text.labelLarge,
        foregroundColor: p.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(kMinTouch, kMinTouch), foregroundColor: p.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      isDense: false,
      constraints: const BoxConstraints(minHeight: 52),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.bodyLarge?.copyWith(color: p.textHelper),
      errorStyle: text.bodySmall?.copyWith(color: p.error),
      border: border(p.outline, 1),
      enabledBorder: border(p.outline, 1),
      focusedBorder: border(p.primary, 2),
      errorBorder: border(p.error, 1.5),
      focusedErrorBorder: border(p.error, 2),
      disabledBorder: border(p.hairline, 1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 4,
      extendedTextStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.card)),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QesmaRadii.card),
        side: BorderSide(color: p.hairline),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      modalBackgroundColor: p.card,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(QesmaRadii.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.card)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.onInverseSurface),
      actionTextColor: p.snackbarAction,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.control)),
    ),
    focusColor: p.primary.withValues(alpha: 0.12),
  );
}
