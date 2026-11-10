import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/profile/application/update_profile_controller.dart';
import 'package:qesma/features/profile/data/profile_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL8 against a REAL local backend (profile `local,fake-auth`): the display name is changed with
/// `PATCH /me` (trimmed) and read back, an empty or 61-character name is refused as
/// VALIDATION_ERROR, and after sign out the old refresh token no longer works.
/// Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('edit profile and sign out against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final store = InMemoryTokenStore();
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(store),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl8-$stamp:fl8-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    final repo = container.read(profileRepositoryProvider);
    final api = container.read(qesmaApiProvider);

    final updated = await repo.updateName('Mohamed Ramadan');
    expect(updated.displayName, 'Mohamed Ramadan');
    expect((await api.getMeControllerApi().getMe()).data!.displayName, 'Mohamed Ramadan', reason: 'GET /me agrees');

    // The controller path: the signed-in user is replaced with what the server stored.
    container.listen(updateProfileControllerProvider, (_, _) {});
    final controller = container.read(updateProfileControllerProvider.notifier);
    controller.setName('  محمد رمضان  ');
    expect(await controller.save(), isTrue);
    expect((container.read(authControllerProvider) as AuthSignedIn).user.displayName, 'محمد رمضان');

    Future<ApiErrorCode?> refused(String name) async {
      try {
        await repo.updateName(name);
      } catch (e) {
        return (e as ApiHttpFailure).problem?.code;
      }
      return null;
    }

    expect(await refused('a' * 61), ApiErrorCode.validationError);
    expect(await refused('   '), ApiErrorCode.validationError);

    // Sign out: the local wipe, and the old refresh token is revoked on the server.
    final oldRefresh = await store.readRefreshToken();
    expect(oldRefresh, isNotNull);
    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    expect(await store.readRefreshToken(), isNull);
    Object? error;
    try {
      await container.read(authlessApiProvider).getAuthControllerApi().refreshSession(refreshRequest: RefreshRequest((b) => b.refreshToken = oldRefresh));
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull, reason: 'a signed-out refresh token must not work again');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
