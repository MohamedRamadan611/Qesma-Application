import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_interceptor.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/session_manager.dart';

import '../../support/fake_backend.dart';

/// A session core wired to the fake backend: authless Dio for /auth/*, API Dio with the
/// interceptor, a store that logs into the same event list as the server.
class Rig {
  Rig({String? initialRefresh}) {
    store = RecordingTokenStore(backend.events, initialRefresh);
    authless = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = backend;
    api = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = backend;
    session = SessionManager(
      store: store,
      log: log,
      refreshCall: (refreshToken) async {
        final response = await authless.post<Map<String, dynamic>>('/api/v1/auth/refresh', data: {'refreshToken': refreshToken});
        final body = response.data!;
        return (accessToken: body['accessToken'] as String, refreshToken: body['refreshToken'] as String);
      },
    )..onSessionEnded = ended.add;
    api.interceptors.add(AuthInterceptor(session: session, dio: api));
  }

  final backend = FakeBackend();
  final log = RecordingAuthLog();
  final List<SessionEndReason> ended = [];
  late final RecordingTokenStore store;
  late final Dio authless;
  late final Dio api;
  late final SessionManager session;

  /// Signs in like POST /auth/google and installs the session.
  Future<void> signIn() async {
    final s = backend.issueSession();
    await session.startSession(accessToken: s.access, refreshToken: s.refresh);
  }

  Future<Response<dynamic>> get([String path = '/api/v1/groups']) => api.get<dynamic>(path);

  /// Runs [call] and returns the DioException it throws (fails the test if it succeeds).
  Future<DioException> failure(Future<Object?> call) async {
    try {
      await call;
    } on DioException catch (e) {
      return e;
    }
    fail('expected the request to fail');
  }
}

void main() {
  group('single-flight refresh', () {
    test('10 parallel requests with an expired access token cause exactly ONE refresh and all succeed', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();

      final responses = await Future.wait([for (var i = 0; i < 10; i++) rig.get('/api/v1/groups?n=$i')]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(rig.backend.refreshTokensReceived, hasLength(1), reason: 'one refresh for ten 401s');
      expect(rig.backend.events.where((e) => e.startsWith('refresh-ok')), hasLength(1));
      expect(rig.ended, isEmpty);
    });

    test('cold start: a stored refresh token and no access token refresh first, without a wasted 401', () async {
      final rig = Rig();
      final s = rig.backend.issueSession(); // a session the server knows...
      await rig.store.writeRefreshToken(s.refresh); // ...whose refresh token survived the app restart
      rig.backend.events.clear();

      final response = await rig.get('/api/v1/me');

      expect(response.statusCode, 200);
      expect(rig.backend.unauthorizedResponses, 0, reason: 'refreshed proactively, no 401 round trip');
      expect(rig.backend.refreshTokensReceived, hasLength(1));
    });
  });

  group('refresh token rotation is respected', () {
    test('five refresh rounds never send the same refresh token twice', () async {
      final rig = Rig();
      await rig.signIn();
      for (var i = 0; i < 5; i++) {
        rig.backend.expireAccessTokens();
        await rig.get();
      }
      final sent = rig.backend.refreshTokensReceived;
      expect(sent, hasLength(5));
      expect(sent.toSet(), hasLength(5), reason: 'a reused refresh token would end the session on the server: $sent');
      expect(rig.backend.familyRevoked, isFalse);
    });

    test('the new refresh token is saved BEFORE any retried request is sent', () async {
      final rig = Rig();
      await rig.signIn();
      rig.store.writeDelay = const Duration(milliseconds: 60); // makes a missing await visible
      rig.backend.expireAccessTokens();

      await Future.wait([for (var i = 0; i < 5; i++) rig.get()]);

      final events = rig.backend.events;
      final refreshOk = events.indexWhere((e) => e.startsWith('refresh-ok'));
      final stored = events.indexWhere((e) => e.startsWith('store-write refresh-2'));
      final firstRetry = events.indexWhere((e) => e.startsWith('api-200'), refreshOk);
      expect(stored, greaterThan(refreshOk));
      expect(firstRetry, greaterThan(stored), reason: 'a retry started before the new token was persisted: $events');
    });
  });

  group('failures', () {
    test('rejected refresh (401): the session ends ONCE, every pending request fails, storage is wiped', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();
      await rig.store.writeRefreshToken('bogus-token'); // the server does not know it

      final results = await Future.wait([for (var i = 0; i < 10; i++) rig.failure(rig.get())]);

      expect(results.map((e) => e.response?.statusCode), everyElement(401));
      expect(rig.ended, [SessionEndReason.refreshRejected], reason: 'session-expired must be raised exactly once');
      expect(await rig.store.readRefreshToken(), isNull);
      expect(rig.session.accessToken, isNull);
      expect(rig.backend.refreshTokensReceived, ['bogus-token']);
    });

    for (final fault in [RefreshFault.connectionRefused, RefreshFault.connectTimeout]) {
      test('${fault.name}: the request provably never reached the server, so token and session are kept', () async {
        final rig = Rig();
        await rig.signIn();
        rig.backend.expireAccessTokens();
        rig.backend.nextRefreshFault = fault;

        final error = await rig.failure(rig.get());

        expect(error.type, anyOf(DioExceptionType.connectionError, DioExceptionType.connectionTimeout));
        expect(rig.ended, isEmpty);
        expect(await rig.store.readRefreshToken(), 'refresh-1');
        expect(rig.backend.refreshTokensReceived, isEmpty);

        // Network is back: the SAME token is used, once, and works.
        final ok = await rig.get();
        expect(ok.statusCode, 200);
        expect(rig.backend.refreshTokensReceived, ['refresh-1']);
      });
    }

    test('429 on refresh: the rate limiter ran first, token intact, session alive, caller sees the 429', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();
      rig.backend.nextRefreshFault = RefreshFault.rateLimited;

      final error = await rig.failure(rig.get());

      expect(error.response?.statusCode, 429);
      expect(rig.ended, isEmpty);
      expect(await rig.store.readRefreshToken(), 'refresh-1');
      expect((await rig.get()).statusCode, 200);
    });

    // Decision A4 (agreed): these failures do not prove the token was spent, so the session is KEPT
    // and the request fails with a retryable error; the same token works on the next attempt.
    for (final fault in [RefreshFault.gateway502, RefreshFault.gateway503, RefreshFault.gateway504, RefreshFault.badCertificate, RefreshFault.cancelled]) {
      test('${fault.name}: the session is kept and the refresh token is still usable (A4)', () async {
        final rig = Rig();
        await rig.signIn();
        rig.backend.expireAccessTokens();
        rig.backend.nextRefreshFault = fault;

        await rig.failure(rig.get());

        expect(rig.ended, isEmpty, reason: 'no session end');
        expect(await rig.store.readRefreshToken(), 'refresh-1', reason: 'the token was not spent');

        // The failed attempt never reached the backend, so only the successful retry is recorded.
        expect((await rig.get()).statusCode, 200);
        expect(rig.backend.refreshTokensReceived, ['refresh-1']);
      });
    }

    for (final fault in [RefreshFault.closedAfterSend, RefreshFault.receiveTimeout, RefreshFault.serverError]) {
      test('${fault.name}: outcome unknown, so the token is treated as spent and NEVER sent again', () async {
        final rig = Rig();
        await rig.signIn();
        rig.backend.expireAccessTokens();
        rig.backend.nextRefreshFault = fault;

        await rig.failure(rig.get());

        expect(rig.ended, [SessionEndReason.refreshAmbiguous]);
        expect(await rig.store.readRefreshToken(), isNull);
        expect(rig.backend.refreshTokensReceived, ['refresh-1']);

        // Further requests cannot resurrect it: no token, no refresh attempt.
        await rig.failure(rig.get());
        expect(rig.backend.refreshTokensReceived, ['refresh-1'], reason: 'the spent token must not be resent');
      });
    }

    test('a request rejected again right after a good refresh does not loop and ends the session', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.alwaysRejectApi = true;

      final error = await rig.failure(rig.get());

      expect(error.response?.statusCode, 401);
      expect(rig.backend.refreshTokensReceived, hasLength(1), reason: 'refreshed once, retried once, then stopped');
      expect(rig.backend.apiRequests, 2);
      expect(rig.ended, [SessionEndReason.retryRejected]);
    });

    test('if the new refresh token cannot be saved the old one is useless: the session ends', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();
      rig.store.failNextWrite = true;

      await rig.failure(rig.get());

      expect(rig.ended, [SessionEndReason.storageFailed]);
      expect(await rig.store.readRefreshToken(), isNull);
    });

    test('an unauthenticated 401 (never signed in) does not start a refresh', () async {
      final rig = Rig();
      await rig.failure(rig.get());
      expect(rig.backend.refreshTokensReceived, isEmpty);
      expect(rig.ended, isEmpty);
    });
  });

  group('sign-out races', () {
    test('a refresh that finishes AFTER sign-out is discarded and writes nothing', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();

      final request = rig.failure(rig.get()); // starts the refresh (server takes 20 ms)
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final token = await rig.session.signOut();
      await request;

      expect(token, 'refresh-1');
      expect(await rig.store.readRefreshToken(), isNull, reason: 'the late refresh must not resurrect the session');
      expect(rig.session.accessToken, isNull);
      expect(rig.ended, isEmpty, reason: 'signing out is not an unexpected end');
      expect(rig.backend.events.where((e) => e.startsWith('store-write refresh-2')), isEmpty);
    });

    test('sign-out while the new token is being written leaves nothing behind', () async {
      final rig = Rig();
      await rig.signIn();
      rig.store.writeDelay = const Duration(milliseconds: 80);
      rig.backend.expireAccessTokens();

      final request = rig.failure(rig.get());
      await Future<void>.delayed(const Duration(milliseconds: 50)); // refresh response is in, write is running
      await rig.session.signOut();
      await request;

      expect(await rig.store.readRefreshToken(), isNull);
      expect(rig.session.accessToken, isNull);
    });

    test('signOut returns the stored token for the best-effort server logout and wipes everything', () async {
      final rig = Rig();
      await rig.signIn();
      expect(await rig.session.signOut(), 'refresh-1');
      expect(await rig.store.readRefreshToken(), isNull);
      expect(rig.session.accessToken, isNull);
      expect(await rig.session.hasRefreshToken(), isFalse);
    });

    test('a new sign-in after an ended session works and gets a fresh generation', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();
      await rig.store.writeRefreshToken('bogus');
      await rig.failure(rig.get());
      expect(rig.ended, hasLength(1));

      await rig.signIn();
      expect((await rig.get()).statusCode, 200);
      rig.backend.expireAccessTokens();
      expect((await rig.get()).statusCode, 200);
      expect(rig.ended, hasLength(1));
    });
  });

  group('answers that arrive after the session changed', () {
    test('a late 401 after sign-out and a NEW sign-in is not replayed and does not touch the new session', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.apiDelay = const Duration(milliseconds: 60);

      final late = rig.failure(rig.get()); // sent with session 1's token
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await rig.session.signOut();
      rig.backend.expireAccessTokens(); // session 1's token is now invalid
      await rig.signIn(); // session 2
      final newAccess = rig.session.accessToken;
      final error = await late;

      expect(error.response?.statusCode, 401);
      expect(rig.backend.apiRequests, 1, reason: 'the old request must not be replayed under the new session');
      expect(rig.ended, isEmpty, reason: 'no second expiry');
      expect(rig.session.accessToken, newAccess);
      expect(await rig.store.readRefreshToken(), isNotNull, reason: 'the new session must not be wiped');
    });

    test('a late 401 after the session already ended does not end anything again', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.apiDelay = const Duration(milliseconds: 60);
      rig.backend.expireAccessTokens();
      await rig.store.writeRefreshToken('bogus');

      // Two requests: the first ends the session; the second's 401 arrives later.
      final first = rig.failure(rig.get());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = rig.failure(rig.get());
      await Future.wait([first, second]);

      expect(rig.ended, hasLength(1));
    });
  });

  group('logging', () {
    test('no log line contains a token, even across success and every failure path', () async {
      final rig = Rig();
      await rig.signIn();
      rig.backend.expireAccessTokens();
      await rig.get(); // success
      rig.backend.expireAccessTokens();
      rig.backend.nextRefreshFault = RefreshFault.receiveTimeout;
      await rig.failure(rig.get()); // ambiguous

      expect(rig.log.lines, isNotEmpty);
      for (final line in rig.log.lines) {
        expect(line, isNot(contains('access-')), reason: line);
        expect(line, isNot(contains('refresh-')), reason: line);
        expect(line, matches(RegExp(r'^auth\.[a-zA-Z]+( kind=\w+)?( status=\d+)?$')), reason: 'only enums and codes: $line');
      }
    });
  });
}
