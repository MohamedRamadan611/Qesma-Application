import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/auth/presentation/auth_widgets.dart';
import 'package:qesma/features/auth/presentation/sign_in_screen.dart';
import 'package:qesma/features/auth/presentation/splash_screen.dart';
import 'package:qesma/features/auth/presentation/welcome_screen.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/auth_ui.dart';
import '../../support/test_app.dart';

String _t(Config c, String ar, String en) => c.locale.languageCode == 'ar' ? ar : en;

final UserDto _user = UserDto((b) => b
  ..hasPassword = false
  ..emailVerified = true
  ..id = 'u1'
  ..displayName = 'Test User');

void main() {
  setUpAll(loadAppFonts);

  group('splash', () {
    for (final c in allConfigs) {
      testWidgets('restoring shows the brand and says "loading" to screen readers at ${c.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, const SplashScreen(), const AuthRestoring(), locale: c.locale, textScale: c.textScale);
        expect(tester.takeException(), isNull);
        expect(find.text(_t(c, 'قِسْمَة', 'Qesma')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(_t(c, 'جاري التحميل', 'Loading'))), findsWidgets);
        handle.dispose();
      });
    }

    testWidgets('offline: the shared no-internet state, and retry restores again', (tester) async {
      await pumpScreen(tester, const SplashScreen(), const AuthRestoreFailed(ApiNoConnection()));
      expect(find.text('مفيش اتصال بالإنترنت'), findsOneWidget);
      await tester.tap(find.text('حاول تاني'));
      expect(stub.restores, 1);
    });

    testWidgets('server error: the generic error state with the request id', (tester) async {
      await pumpScreen(
        tester,
        const SplashScreen(),
        const AuthRestoreFailed(ApiHttpFailure(status: 502, problem: ApiProblem(code: ApiErrorCode.internalError, status: 502, requestId: 'req-77'))),
      );
      expect(find.textContaining('req-77'), findsOneWidget);
      await tester.tap(find.text('حاول تاني'));
      expect(stub.restores, 1);
    });
  });

  group('welcome', () {
    for (final c in allConfigs) {
      testWidgets('three value cards, the start button and the consent line at ${c.name}', (tester) async {
        await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut(), locale: c.locale, textScale: c.textScale);
        expect(tester.takeException(), isNull);
        expect(find.text(_t(c, 'حسابات دقيقة بالقرش', 'Accurate to the piaster'), skipOffstage: false), findsOneWidget);
        expect(find.text(_t(c, 'تقسيم فواتير المطاعم', 'Restaurant bills, split fairly'), skipOffstage: false), findsOneWidget);
        await tester.scrollUntilVisible(find.text(_t(c, 'أسهل طريقة لتصفية الحساب', 'The easiest way to settle up')), 150, scrollable: find.byType(Scrollable).first);
        expect(find.text(_t(c, 'أسهل طريقة لتصفية الحساب', 'The easiest way to settle up')), findsOneWidget);
        expect(find.text(_t(c, 'شروط الاستخدام', 'Terms of Use')), findsOneWidget);
        expect(find.text(_t(c, 'ابدأ الآن', 'Get started')), findsOneWidget);
      });
    }

    testWidgets('there is no guest option', (tester) async {
      await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut());
      expect(find.textContaining('زائر'), findsNothing);
      expect(find.textContaining('استكشف'), findsNothing);
    });

    testWidgets('start goes to sign-in', (tester) async {
      await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut());
      await tester.tap(find.text('ابدأ الآن'));
      await tester.pumpAndSettle();
      expect(find.text('SIGN-IN-PAGE'), findsOneWidget);
    });

    testWidgets('the legal links open the placeholder pages; a failure shows a message', (tester) async {
      final opened = <Uri>[];
      await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut(), opener: (uri) async {
        opened.add(uri);
        return opened.length == 1; // the second attempt fails
      });
      await tester.tap(find.text('شروط الاستخدام'));
      await tester.pump();
      await tester.tap(find.text('سياسة الخصوصية'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, [LegalLinks.terms, LegalLinks.privacy]);
      expect(find.textContaining('مقدرناش نفتح الرابط'), findsOneWidget);
    });

    testWidgets('both legal links are 48 px targets', (tester) async {
      await pumpScreen(tester, const WelcomeScreen(), const AuthSignedOut());
      for (final label in ['شروط الاستخدام', 'سياسة الخصوصية']) {
        final button = find.ancestor(of: find.text(label), matching: find.byType(TextButton));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(kMinTouch), reason: label);
      }
    });
  });

  group('sign-in', () {
    for (final c in allConfigs) {
      testWidgets('idle: Google button and (debug) fake sign-in at ${c.name}', (tester) async {
        await pumpScreen(tester, const SignInScreen(), const AuthSignedOut(), locale: c.locale, textScale: c.textScale);
        expect(tester.takeException(), isNull);
        expect(find.text(_t(c, 'المتابعة باستخدام Google', 'Continue with Google')), findsOneWidget);
        expect(find.textContaining(_t(c, 'دخول تجريبي', 'Debug sign-in')), findsOneWidget, reason: 'tests run in debug mode');
      });
    }

    testWidgets('tapping the buttons calls the controller; the Google button is a 48 px target', (tester) async {
      await pumpScreen(tester, const SignInScreen(), const AuthSignedOut());
      expect(tester.getSize(find.byType(GoogleSignInButton)).height, greaterThanOrEqualTo(kMinTouch));
      await tester.tap(find.text('المتابعة باستخدام Google'));
      await tester.tap(find.textContaining('دخول تجريبي'));
      expect(stub.googleTaps, 1);
      expect(stub.fakeTaps, 1);
    });

    testWidgets('signing in: spinner, button disabled, announced as loading', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, const SignInScreen(), const AuthSigningIn());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(GoogleSignInButton), warnIfMissed: false);
      expect(stub.googleTaps, 0);
      expect(find.bySemanticsLabel('المتابعة باستخدام Google, جاري التحميل…'), findsOneWidget);
      handle.dispose();
    });

    final messages = <SignInError, (String, String)>{
      SignInError.failed: ('مقدرناش نسجّل دخولك. جرّب تاني.', "We couldn't sign you in. Please try again."),
      SignInError.rateLimited: ('محاولات كتير في وقت قصير. استنى دقيقة وجرّب تاني.', 'Too many attempts in a short time. Wait a minute and try again.'),
      SignInError.providerUnavailable: ('مش قادرين نتواصل مع جوجل دلوقتي. جرّب تاني بعد شوية.', "We can't reach Google right now. Please try again in a moment."),
      SignInError.offline: ('مفيش اتصال بالإنترنت. اتأكد من النت وجرّب تاني.', 'No internet connection. Check it and try again.'),
      SignInError.notConfigured: ('تسجيل الدخول بجوجل مش متظبط على الجهاز ده (GOOGLE_SERVER_CLIENT_ID).', 'Google sign-in is not configured on this device (GOOGLE_SERVER_CLIENT_ID).'),
    };
    messages.forEach((error, text) {
      for (final c in allConfigs) {
        testWidgets('${error.name} shows its message at ${c.name} and the button stays usable', (tester) async {
          await pumpScreen(tester, const SignInScreen(), AuthSignedOut(error: error), locale: c.locale, textScale: c.textScale);
          expect(tester.takeException(), isNull);
          expect(find.text(_t(c, text.$1, text.$2)), findsOneWidget);
          await tester.ensureVisible(find.text(_t(c, 'المتابعة باستخدام Google', 'Continue with Google')));
          await tester.tap(find.text(_t(c, 'المتابعة باستخدام Google', 'Continue with Google')));
          expect(stub.googleTaps, 1);
        });
      }
    });

    testWidgets('a cancelled picker shows no message', (tester) async {
      await pumpScreen(tester, const SignInScreen(), const AuthSignedOut(error: SignInError.cancelled));
      expect(find.byType(SignInErrorBanner), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('the error is announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, const SignInScreen(), const AuthSignedOut(error: SignInError.failed));
      expect(tester.getSemantics(find.byType(SignInErrorBanner)), isSemantics(isLiveRegion: true));
      handle.dispose();
    });

    testWidgets('there is no guest option', (tester) async {
      await pumpScreen(tester, const SignInScreen(), const AuthSignedOut());
      expect(find.textContaining('زائر'), findsNothing);
    });
  });

  group('session expired dialog', () {
    Future<void> expire(WidgetTester tester, {AuthState state = const AuthSessionExpired(), Config? c}) async {
      await pumpScreen(tester, const Scaffold(body: Text('SCREEN-UNDER')), AuthSignedIn(_user), locale: c?.locale ?? const Locale('ar'), textScale: c?.textScale ?? 1.0);
      stub.set(state);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('appears over the current screen when the session ends, with no guest option', (tester) async {
      await expire(tester);
      expect(find.text('SCREEN-UNDER'), findsOneWidget);
      expect(find.text('انتهت الجلسة'), findsOneWidget);
      expect(find.textContaining('محفوظة بالكامل'), findsOneWidget);
      expect(find.textContaining('زائر'), findsNothing);
    });

    for (final c in allConfigs) {
      testWidgets('fits and works at ${c.name}', (tester) async {
        await expire(tester, c: c);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(_t(c, 'المتابعة باستخدام Google', 'Continue with Google')));
        await tester.tap(find.text(_t(c, 'المتابعة باستخدام Google', 'Continue with Google')));
        expect(stub.googleTaps, 1);
        await tester.ensureVisible(find.text(_t(c, 'الرجوع للبداية', 'Back to the start')));
        await tester.tap(find.text(_t(c, 'الرجوع للبداية', 'Back to the start')));
        expect(stub.leaves, 1);
      });
    }

    testWidgets('shown ONCE however many times the state is re-emitted, and gone after signing in', (tester) async {
      await expire(tester);
      stub.set(const AuthSessionExpired(busy: true));
      await tester.pump();
      stub.set(const AuthSessionExpired(error: SignInError.rateLimited));
      await tester.pump();
      expect(find.text('انتهت الجلسة'), findsOneWidget);

      stub.set(AuthSignedIn(_user));
      await tester.pumpAndSettle();
      expect(find.text('انتهت الجلسة'), findsNothing);
      expect(find.text('SCREEN-UNDER'), findsOneWidget);
    });

    testWidgets('while signing in the buttons are disabled; an error from the last attempt is shown', (tester) async {
      await expire(tester, state: const AuthSessionExpired(busy: true));
      await tester.tap(find.text('الرجوع للبداية'), warnIfMissed: false);
      expect(stub.leaves, 0);
      stub.set(const AuthSessionExpired(error: SignInError.rateLimited));
      await tester.pump();
      expect(find.textContaining('محاولات كتير'), findsOneWidget);
    });

    testWidgets('the Android back button cannot dismiss it', (tester) async {
      await expire(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('انتهت الجلسة'), findsOneWidget);
    });

    testWidgets('going back to the start closes the dialog', (tester) async {
      await expire(tester);
      stub.set(const AuthSignedOut());
      await tester.pumpAndSettle();
      expect(find.text('انتهت الجلسة'), findsNothing);
    });
  });
}

