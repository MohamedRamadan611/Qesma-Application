import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/api_config.dart';
import 'package:qesma/core/app_mode.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma_api/qesma_api.dart';

void main() {
  group('AppMode.resolve (QESMA_MODE)', () {
    test('explicit values win in either build mode', () {
      for (final release in [true, false]) {
        expect(AppMode.resolve('local', isRelease: release), AppMode.local);
        expect(AppMode.resolve('server', isRelease: release), AppMode.server);
      }
    });

    test('empty: release builds are local, debug builds and tests are server', () {
      expect(AppMode.resolve('', isRelease: true), AppMode.local);
      expect(AppMode.resolve('', isRelease: false), AppMode.server);
    });

    test('an unknown value fails fast', () {
      expect(() => AppMode.resolve('Local', isRelease: true), throwsStateError);
      expect(() => AppMode.resolve('offline', isRelease: false), throwsStateError);
    });

    test('tests run in server mode by default (existing tests keep their fake servers)', () {
      expect(AppMode.fromEnvironment(), AppMode.server);
    });
  });

  test('API_BASE_URL is needed in server mode only: local mode never reads it', () {
    expect(ApiConfig.baseUrlFor(AppMode.local), ApiConfig.localOrigin);
    expect(() => ApiConfig.resolveBaseUrl(defined: '', debugOverride: null, isDebug: false), throwsStateError);
  });

  group('localRedirect: no sign-in, no tokens, no carried location', () {
    final user = UserDto((b) => b
      ..id = '11111111-1111-4111-8111-111111111111'
      ..displayName = 'Mona'
      ..hasPassword = false
      ..emailVerified = false
      ..notificationsEnabled = false);
    String? go(AuthState state, String location) => localRedirect(state, Uri.parse(location));

    test('while the profile is read: only the brand-only splash', () {
      expect(go(const AuthRestoring(), '/'), Routes.splash);
      expect(go(const AuthRestoring(), Routes.splash), isNull);
      expect(go(const AuthRestoring(), '/join/ABCD2345'), Routes.splash);
    });

    test('no profile yet: the onboarding is the only reachable page, with no from= parameter', () {
      for (final path in ['/', '/groups/x', Routes.account, '/join/ABCD2345', Routes.signIn, Routes.splash]) {
        expect(go(const AuthSignedOut(), path), Routes.welcome, reason: path);
      }
      expect(go(const AuthSignedOut(), Routes.welcome), isNull);
      expect(go(const AuthSignedOut(), Routes.welcomeName), isNull);
    });

    test('profile exists: onboarding, splash and every server-only path lead to the groups list', () {
      final signedIn = AuthSignedIn(user);
      for (final path in [Routes.splash, Routes.welcome, Routes.welcomeName, '/join', '/join/ABCD2345', Routes.signIn, Routes.usernameSignIn, Routes.register, Routes.changePassword, Routes.accountSettings, '/groups/abc/join-requests']) {
        expect(go(signedIn, path), Routes.home, reason: path);
      }
      for (final path in ['/', '/groups/abc', '/groups/abc/expenses/new', Routes.account, Routes.editProfile, Routes.paymentHandles]) {
        expect(go(signedIn, path), isNull, reason: path);
      }
    });

    test('the expired-session state cannot send anyone to a sign-in page', () {
      expect(go(const AuthSessionExpired(), '/'), Routes.welcome);
    });
  });
}
