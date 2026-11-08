import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/auth/presentation/sign_in_screen.dart';
import 'package:qesma/features/auth/presentation/welcome_screen.dart';
import 'package:qesma_api/qesma_api.dart';

import '../support/auth_ui.dart';
import '../support/test_app.dart';

/// Goldens of the auth screens (Arabic, RTL, 360x800). Update with
/// `flutter test --update-goldens test/goldens` and review the PNG diff before committing.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('auth_goldens_test.dart'));
  });

  /// Images decode asynchronously; load the Google "G" before the frame is captured.
  Future<void> check(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/brand/google_g.png'), tester.element(find.byType(Scaffold).first));
    });
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));
  }

  testWidgets('welcome screen (P1-02)', (tester) async {
    await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut());
    await check(tester, 'welcome_ar');
  });

  testWidgets('sign-in screen with an error (P1-03)', (tester) async {
    await pumpScreen(tester, const SignInScreen(), const AuthSignedOut(error: SignInError.rateLimited));
    await check(tester, 'sign_in_error_ar');
  });

  testWidgets('session-expired dialog (P11-04)', (tester) async {
    final user = UserDto((b) => b
      ..id = 'u1'
      ..displayName = 'Test User');
    await pumpScreen(tester, const Scaffold(body: SizedBox.expand()), AuthSignedIn(user));
    stub.set(const AuthSessionExpired());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await check(tester, 'session_expired_ar');
  });
}
