import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/app_mode.dart';
import 'local/backend/local_backend_overrides.dart';
import 'local/db/local_database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled font's licence (SIL OFL 1.1) shows on the in-app licences page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['IBM Plex Sans Arabic'],
      await rootBundle.loadString('assets/fonts/OFL.txt'),
    );
  });
  // QESMA_MODE (STANDALONE_SPEC 2): local = everything on the phone, server = the multi-user app. The database is
  // opened lazily on the first request; in server mode nothing local is ever created.
  final mode = AppMode.fromEnvironment();
  final overrides = mode == AppMode.local ? localModeOverrides(openLocalDatabase()) : [appModeProvider.overrideWithValue(mode)];
  runApp(ProviderScope(overrides: overrides, child: const QesmaApp()));
}
