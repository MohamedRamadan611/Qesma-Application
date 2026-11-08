import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma_api/qesma_api.dart';

void main() {
  final user = UserDto((b) => b
    ..id = 'u1'
    ..displayName = 'Test');

  String? go(AuthState state, String location) => authRedirect(state, Uri.parse(location));

  group('while the session is being restored', () {
    for (final state in <AuthState>[const AuthRestoring(), const AuthRestoreFailed(ApiNoConnection())]) {
      test('${state.runtimeType}: every protected location goes to the splash, remembering where the user wanted to go', () {
        expect(go(state, '/'), '/splash');
        expect(go(state, '/groups/abc'), '/splash?from=%2Fgroups%2Fabc');
        expect(go(state, '/groups/abc?tab=balances'), '/splash?from=%2Fgroups%2Fabc%3Ftab%3Dbalances');
      });

      test('${state.runtimeType}: the splash itself stays; welcome and sign-in wait behind it', () {
        expect(go(state, '/splash'), isNull);
        expect(go(state, '/welcome'), '/splash');
        expect(go(state, '/sign-in?from=%2Fgroups'), '/splash?from=%2Fgroups');
      });
    }
  });

  group('signed out', () {
    const out = AuthSignedOut();
    test('the splash moves on to the welcome screen, carrying the wanted location', () {
      expect(go(out, '/splash'), '/welcome');
      expect(go(out, '/splash?from=%2Fgroups%2Fabc'), '/welcome?from=%2Fgroups%2Fabc');
    });

    test('welcome and sign-in are reachable', () {
      expect(go(out, '/welcome'), isNull);
      expect(go(out, '/sign-in'), isNull);
    });

    test('everything else is sent to the welcome screen', () {
      expect(go(out, '/'), '/welcome');
      expect(go(out, '/groups'), '/welcome?from=%2Fgroups');
      expect(go(out, '/groups/abc/expenses'), '/welcome?from=%2Fgroups%2Fabc%2Fexpenses');
    });
  });

  group('signed in', () {
    final signedIn = AuthSignedIn(user);

    test('the auth screens lead back to where the user was going, or home', () {
      expect(go(signedIn, '/splash'), '/');
      expect(go(signedIn, '/splash?from=%2Fgroups%2Fabc'), '/groups/abc');
      expect(go(signedIn, '/welcome'), '/');
      expect(go(signedIn, '/sign-in?from=%2Fgroups'), '/groups');
    });

    test('app screens are reachable', () {
      expect(go(signedIn, '/'), isNull);
      expect(go(signedIn, '/groups/abc'), isNull);
    });
  });

  test('during sign-in and while the expiry dialog is up nothing moves', () {
    for (final state in <AuthState>[const AuthSigningIn(), const AuthSessionExpired(), const AuthSessionExpired(busy: true)]) {
      expect(go(state, '/groups/abc'), isNull);
      expect(go(state, '/sign-in'), isNull);
    }
  });

  group('the return location cannot become an open redirect', () {
    final signedIn = AuthSignedIn(user);

    test('safeReturnLocation accepts in-app paths only', () {
      expect(safeReturnLocation('/groups/abc'), '/groups/abc');
      expect(safeReturnLocation('/groups?x=1'), '/groups?x=1');
      for (final bad in <String?>[
        null,
        '',
        'groups',
        '//evil.example/path',
        'https://evil.example',
        'http://evil.example/a',
        'javascript:alert(1)',
        r'/\evil.example',
        '/ok\u0000bad',
        '/welcome',
        '/sign-in',
        '/splash',
        '/${'a' * 400}',
      ]) {
        expect(safeReturnLocation(bad), isNull, reason: '$bad');
      }
    });

    test('a hostile from value is ignored after sign-in', () {
      expect(go(signedIn, '/sign-in?from=%2F%2Fevil.example'), '/');
      expect(go(signedIn, '/sign-in?from=https%3A%2F%2Fevil.example'), '/');
      expect(go(signedIn, '/welcome?from=javascript%3Aalert(1)'), '/');
    });

    test('a hostile from value is not carried forward while signed out', () {
      expect(go(const AuthSignedOut(), '/splash?from=%2F%2Fevil.example'), '/welcome');
    });
  });
}
