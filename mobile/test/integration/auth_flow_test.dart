import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/dev_settings.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma_api/qesma_api.dart';

/// Runs the REAL auth flow against a REAL local backend (profile `local,fake-auth`).
/// Skipped unless `API_BASE_URL` is given:
///
///   flutter test test/integration --dart-define=API_BASE_URL=http://localhost:18080
///
/// (On Git Bash for Windows prefix with `MSYS_NO_PATHCONV=1` if the URL looks like a path.)
/// The backend limits `/auth/**` to 10 requests per minute per IP, so this file stays well
/// under that; if you re-run it repeatedly, wait a minute.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL (see the doc comment) to run against a local backend' : null;

  setUpAll(() {
    // flutter_test blocks real HTTP by default (every request answers 400).
    HttpOverrides.global = null;
  });

  late ProviderContainer container;
  late InMemoryTokenStore store;

  setUp(() {
    store = InMemoryTokenStore();
    container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        autoRestoreProvider.overrideWithValue(false),
        authLogProvider.overrideWithValue(RecordingAuthLog()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('login, GET /me, refresh rotation, reuse detection and logout against the real backend', () async {
    final controller = container.read(authControllerProvider.notifier);

    // 1. Login with the fake-auth token (what the debug sign-in button sends).
    await controller.signInWithIdToken(DevSettings.fakeToken);
    expect(container.read(authControllerProvider), isA<AuthSignedIn>(), reason: 'is the backend running with local,fake-auth?');
    final first = await store.readRefreshToken();
    expect(first, isNotNull);

    // 2. The API Dio: build one against the same base URL and run GET /me.
    final api = container.read(qesmaApiProvider); // real providers: base URL comes from the same API_BASE_URL define
    final me = await api.getMeControllerApi().getMe();
    expect(me.data!.displayName, isNotEmpty);

    // 3. Force a refresh through the session manager: the refresh token must ROTATE.
    await container.read(sessionManagerProvider).refresh();
    final second = await store.readRefreshToken();
    expect(second, isNot(first), reason: 'the backend rotates the refresh token on every use');
    expect((await api.getMeControllerApi().getMe()).statusCode, 200);

    // 4. Reuse of the OLD refresh token must be refused (and revokes the session family).
    final authApi = container.read(authlessApiProvider).getAuthControllerApi();
    await expectLater(
      authApi.refreshSession(refreshRequest: RefreshRequest((b) => b.refreshToken = first!)),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );

    // 5. Because the family was revoked, the newest token is dead as well.
    await expectLater(
      authApi.refreshSession(refreshRequest: RefreshRequest((b) => b.refreshToken = second!)),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );

    // 6. Logout is accepted for any token (always 204) and wipes the device.
    await controller.signOut();
    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    expect(await store.readRefreshToken(), isNull);
  }, skip: skip);

  test('a bad token is refused with 401 and leaves the user signed out', () async {
    final controller = container.read(authControllerProvider.notifier);
    await controller.signInWithIdToken('not-a-valid-token');
    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedOut>());
    expect((state as AuthSignedOut).error, SignInError.failed);
    expect(await store.readRefreshToken(), isNull);
  }, skip: skip);
}

