import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_receipt_reader.dart';
import 'receipt_reader.dart';

/// A fixed App Check debug token for closed testing (APKs shared by hand, not installed from Google Play, which
/// Play Integrity would refuse). Given at build time (`--dart-define=QESMA_APPCHECK_DEBUG_TOKEN=<uuid>`), registered
/// in the Firebase console, and revoked there when testing ends. Never committed; empty in the Play build.
const String _testingToken = String.fromEnvironment('QESMA_APPCHECK_DEBUG_TOKEN');

AndroidAppCheckProvider _provider() {
  if (_testingToken.isNotEmpty) return const AndroidDebugProvider(debugToken: _testingToken);
  return kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider();
}

/// Starts Firebase and App Check for the receipt scan (local mode only, called once from `main`). The Firebase config
/// comes from `google-services.json` (downloaded from the console, not a secret, not edited by hand); there is no API
/// key in the app. Debug builds use the App Check debug provider, release builds Play Integrity.
///
/// Returns null when the config is missing or anything fails: the app then runs without scanning (the entry points
/// and the profile row hide) and the user types manually. Nothing about the failure is logged or shown.
Future<ReceiptReader?> startReceiptReader() async {
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(providerAndroid: _provider());
    return FirebaseReceiptReader();
  } catch (_) {
    return null;
  }
}
