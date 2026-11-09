import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/theme/app_theme.dart';
import 'package:qesma/core/theme/tokens.dart';

/// Registers the bundled IBM Plex Sans Arabic so tests (and goldens) lay text out with the
/// real glyph widths instead of the test framework's square placeholder font.
Future<void> loadAppFonts() async {
  final loader = FontLoader(kFontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/IBMPlexSansArabic-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  // Icons are drawn from the Material Icons font; without it every icon is an empty box.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final dir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
    // The file name's case differs between SDK versions and operating systems.
    final icons = dir.existsSync()
        ? dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('materialicons-regular.otf')).firstOrNull
        : null;
    if (icons != null) {
      final iconLoader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
      await iconLoader.load();
    }
  }
}

/// One of the layouts every component must survive: language/direction x text scale.
typedef Config = ({String name, Locale locale, double textScale});

const List<Config> allConfigs = [
  (name: 'ar 1.0x', locale: Locale('ar'), textScale: 1.0),
  (name: 'ar 2.0x', locale: Locale('ar'), textScale: 2.0),
  (name: 'en 1.0x', locale: Locale('en'), textScale: 1.0),
  (name: 'en 2.0x', locale: Locale('en'), textScale: 2.0),
];

/// Pumps [child] inside the real theme, localization and a 360x800 screen.
/// Animations are disabled so `pumpAndSettle` terminates.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  Size size = const Size(360, 800),
  bool scaffold = true,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: app!,
      ),
      home: scaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pump();
}

/// True when [text] contains an Arabic-Indic (٠-٩) or Eastern Arabic-Indic (۰-۹) digit.
bool hasNonWesternDigits(String text) => RegExp('[٠-٩۰-۹]').hasMatch(text);

/// Wraps [s] in a left-to-right isolate, as MoneyText does around the number.
String isolated(String s) => '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';

/// Non-breaking space between a number and its currency.
final String nbspChar = String.fromCharCode(0x00A0);

AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

/// First-strong isolate around [s] (what the app puts around each payer with an amount).
String fsIsolated(String s) => '${String.fromCharCode(0x2068)}$s${String.fromCharCode(0x2069)}';
