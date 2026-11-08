import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/google_id_token_source.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/features/auth/application/auth_state.dart';

import '../../support/auth_rig.dart';
import '../../support/fake_backend.dart';

void main() {
  late AuthRig rig;
  tearDown(() => rig.dispose());

  group('restore', () {
    test('no stored session: signed out, no network call', () async {
      rig = AuthRig();
      await rig.controller.restore();
      expect(rig.state, isA<AuthSignedOut>());
      expect(rig.backend.apiRequests, 0);
      expect(rig.log.lines, ['auth.restoreStart', 'auth.restoreSignedOut']);
    });

    test('a valid stored session restores through GET /me with one proactive refresh', () async {
      rig = AuthRig();
      await rig.seedStoredSession();
      await rig.controller.restore();

      expect(rig.state, isA<AuthSignedIn>());
      expect((rig.state as AuthSignedIn).user.displayName, 'Test User');
      expect(rig.backend.unauthorizedResponses, 0);
      expect(rig.backend.refreshTokensReceived, hasLength(1));
    });

    test('offline at launch: the session is kept and a retry succeeds with the SAME refresh token', () async {
      rig = AuthRig();
      await rig.seedStoredSession();
      rig.backend.nextRefreshFault = RefreshFault.connectionRefused;

      await rig.controller.restore();
      expect(rig.state, isA<AuthRestoreFailed>());
      expect((rig.state as AuthRestoreFailed).failure, isA<ApiNoConnection>());
      expect(await rig.store.readRefreshToken(), 'refresh-1');

      await rig.controller.restore();
      expect(rig.state, isA<AuthSignedIn>());
      expect(rig.backend.refreshTokensReceived, ['refresh-1']);
    });

    test('an expired or revoked stored session goes quietly to signed out (no dialog) and is wiped', () async {
      rig = AuthRig();
      await rig.seedStoredSession();
      await rig.store.writeRefreshToken('bogus');

      await rig.controller.restore();

      expect(rig.state, isA<AuthSignedOut>());
      expect(rig.states.whereType<AuthSessionExpired>(), isEmpty);
      expect(await rig.store.readRefreshToken(), isNull);
    });

    test('automatic restore on start-up', () async {
      rig = AuthRig(autoRestore: true);
      await rig.seedStoredSession();
      expect(rig.state, isA<AuthRestoring>());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(rig.state, isA<AuthSignedIn>());
    });
  });

  group('sign in', () {
    test('Google sign-in: signed in, refresh token stored, API calls work with the new session', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();

      expect(rig.state, isA<AuthSignedIn>());
      expect(rig.google.signIns, 1);
      expect(await rig.store.readRefreshToken(), 'refresh-1');
      final me = await rig.container.read(qesmaApiProvider).getMeControllerApi().getMe();
      expect(me.data!.id, 'u1');
      expect(rig.states.whereType<AuthSigningIn>(), isNotEmpty);
    });

    test('the debug fake sign-in exchanges a token directly', () async {
      rig = AuthRig();
      await rig.controller.signInWithIdToken('fake:dahab:mohamed@example.com:محمد');
      expect(rig.state, isA<AuthSignedIn>());
      expect(rig.google.signIns, 0, reason: 'Google is not involved');
    });

    test('cancelling the Google picker is not an error', () async {
      rig = AuthRig();
      rig.google.failWith = const GoogleSignInFailure(GoogleFailureKind.cancelled);
      await rig.controller.signInWithGoogle();
      expect((rig.state as AuthSignedOut).error, SignInError.cancelled);
      expect(rig.backend.events, isEmpty);
    });

    final cases = <String, ({void Function(AuthRig) arrange, SignInError expected})>{
      'backend 401 (token rejected)': (arrange: (r) => r.backend.nextLoginFault = LoginFault.unauthorized, expected: SignInError.failed),
      'backend 429': (arrange: (r) => r.backend.nextLoginFault = LoginFault.rateLimited, expected: SignInError.rateLimited),
      'backend 503': (arrange: (r) => r.backend.nextLoginFault = LoginFault.providerUnavailable, expected: SignInError.providerUnavailable),
      'no network': (arrange: (r) => r.backend.nextLoginFault = LoginFault.connectionRefused, expected: SignInError.offline),
      'Google not configured': (
        arrange: (r) => r.google.failWith = const GoogleSignInFailure(GoogleFailureKind.notConfigured),
        expected: SignInError.notConfigured,
      ),
      'Google unavailable': (
        arrange: (r) => r.google.failWith = const GoogleSignInFailure(GoogleFailureKind.unavailable),
        expected: SignInError.providerUnavailable,
      ),
      'Google failed': (arrange: (r) => r.google.failWith = const GoogleSignInFailure(GoogleFailureKind.failed), expected: SignInError.failed),
    };
    cases.forEach((name, c) {
      test('$name leaves the user signed out with the right error and nothing stored', () async {
        rig = AuthRig();
        c.arrange(rig);
        await rig.controller.signInWithGoogle();
        expect(rig.state, isA<AuthSignedOut>());
        expect((rig.state as AuthSignedOut).error, c.expected);
        expect(await rig.store.readRefreshToken(), isNull);
      });
    });

    test('an unexpected plugin error does not leave the screen stuck on "signing in"', () async {
      rig = AuthRig();
      rig.google.throwRaw = StateError('plugin exploded');
      await rig.controller.signInWithGoogle();
      expect(rig.state, isA<AuthSignedOut>());
      expect((rig.state as AuthSignedOut).error, SignInError.failed);

      rig.google.throwRaw = null; // and the user can simply try again
      await rig.controller.signInWithGoogle();
      expect(rig.state, isA<AuthSignedIn>());
    });

    test('a second tap while signing in is ignored (no double sign-in)', () async {
      rig = AuthRig();
      final first = rig.controller.signInWithGoogle();
      final second = rig.controller.signInWithGoogle();
      await Future.wait([first, second]);
      expect(rig.google.signIns, 1);
      expect(rig.state, isA<AuthSignedIn>());
    });
  });

  group('sign out', () {
    test('wipes storage, signs out of Google, calls the server logout, ends signed out', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      await rig.controller.signOut();

      expect(rig.state, isA<AuthSignedOut>());
      expect((rig.state as AuthSignedOut).error, isNull);
      expect(await rig.store.readRefreshToken(), isNull);
      expect(rig.google.signOuts, 1);
      expect(rig.backend.events, contains('logout'));
    });

    test('still signs out locally when the server cannot be reached', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      rig.backend.logoutFails = true;

      await rig.controller.signOut();

      expect(rig.state, isA<AuthSignedOut>());
      expect(await rig.store.readRefreshToken(), isNull);
      expect(rig.google.signOuts, 1);
    });

    test('after sign-out nothing from the old session is used: a later restore finds nothing', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      await rig.controller.signOut();
      rig.backend.events.clear();
      await rig.controller.restore();
      expect(rig.state, isA<AuthSignedOut>());
      expect(rig.backend.events, isEmpty);
    });
  });

  group('session expiry mid-use', () {
    Future<DioException> breakSession(AuthRig r) async {
      r.backend.expireAccessTokens();
      await r.store.writeRefreshToken('bogus'); // the server will refuse it
      try {
        await r.container.read(qesmaApiProvider).getMeControllerApi().getMe();
      } on DioException catch (e) {
        return e;
      }
      fail('expected the call to fail');
    }

    test('ten parallel calls end the session ONCE: one session-expired state', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      rig.backend.expireAccessTokens();
      await rig.store.writeRefreshToken('bogus');

      final api = rig.container.read(qesmaApiProvider).getMeControllerApi();
      await Future.wait([
        for (var i = 0; i < 10; i++) api.getMe().then<Object?>((_) => null).catchError((Object _) => null),
      ]);

      expect(rig.states.whereType<AuthSessionExpired>(), hasLength(1));
      expect(rig.state, isA<AuthSessionExpired>());
    });

    test('signing in again from the expired state returns to signed in', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      await breakSession(rig);
      expect(rig.state, isA<AuthSessionExpired>());

      final pending = rig.controller.signInWithGoogle();
      expect(rig.state, isA<AuthSessionExpired>());
      expect((rig.state as AuthSessionExpired).busy, isTrue);
      await pending;
      expect(rig.state, isA<AuthSignedIn>());
    });

    test('a failed sign-in from the expired state stays expired and shows the error', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      await breakSession(rig);
      rig.backend.nextLoginFault = LoginFault.rateLimited;

      await rig.controller.signInWithGoogle();

      final state = rig.state as AuthSessionExpired;
      expect(state.busy, isFalse);
      expect(state.error, SignInError.rateLimited);
    });

    test('"back to the start" goes to signed out', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      await breakSession(rig);
      rig.controller.leaveExpiredSession();
      expect(rig.state, isA<AuthSignedOut>());
      expect(await rig.store.readRefreshToken(), isNull);
    });
  });

  group('secrets', () {
    test('states never print the user, e-mail or any token', () async {
      rig = AuthRig();
      await rig.controller.signInWithGoogle();
      for (final state in rig.states) {
        final text = state.toString();
        expect(text, isNot(contains('Test User')));
        expect(text, isNot(contains('example.com')));
        expect(text, isNot(contains('access-')));
        expect(text, isNot(contains('refresh-')));
      }
    });

    test('no log line holds a token, the Google token, the e-mail or the name, across every flow', () async {
      rig = AuthRig();
      await rig.seedStoredSession();
      await rig.controller.restore(); // restore
      await rig.controller.signOut(); // sign out
      await rig.controller.signInWithGoogle(); // sign in
      rig.backend.expireAccessTokens();
      await rig.store.writeRefreshToken('bogus-canary-token');
      try {
        await rig.container.read(qesmaApiProvider).getMeControllerApi().getMe(); // expiry
      } on DioException {
        // expected
      }

      expect(rig.log.lines, isNotEmpty);
      for (final line in rig.log.lines) {
        for (final secret in ['access-', 'refresh-', 'google-id-token-canary', 'bogus-canary-token', 'example.com', 'Test User']) {
          expect(line, isNot(contains(secret)), reason: line);
        }
      }
    });
  });
}
