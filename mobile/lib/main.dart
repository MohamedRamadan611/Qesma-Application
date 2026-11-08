import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // The bundled font's licence (SIL OFL 1.1) shows on the in-app licences page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['IBM Plex Sans Arabic'],
      await rootBundle.loadString('assets/fonts/OFL.txt'),
    );
  });
  runApp(const ProviderScope(child: QesmaApp()));
}
