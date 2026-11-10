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
import 'package:qesma/features/auth/application/change_password_controller.dart';
import 'package:qesma/features/auth/application/username_auth_controller.dart';
import 'package:qesma/features/auth/data/password_auth_repository.dart';

/// Username + password sign-in against a REAL local backend (profile `local,fake-auth`): the generated client and the
/// app's own repository and controllers talk to the real server. Register, sign in, the generic refusal, a taken name,
/// registering over an existing name with a wrong password (counts toward the lockout), change password and the session
/// that continues afterwards. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  ProviderContainer newContainer(InMemoryTokenStore store) {
    final c = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(store),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('register, sign in, refusals and change password against the real backend', () async {
    final name = 'live.${DateTime.now().millisecondsSinceEpoch}';
    const password = 'correct horse battery';
    final store = InMemoryTokenStore();
    final container = newContainer(store);
    final repo = container.read(passwordAuthRepositoryProvider);

    // Registering through the app's controller signs the user in and stores only the refresh token.
    container.listen(usernameAuthControllerProvider, (_, _) {});
    await container.read(usernameAuthControllerProvider.notifier).register(name.toUpperCase(), password, 'Live Tester');
    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    final user = (state as AuthSignedIn).user;
    expect(user.username, name, reason: 'the server normalizes the name to lower case');
    expect(user.hasPassword, isTrue);
    expect(user.email, isNull);
    expect(await store.readRefreshToken(), isNotNull);
    expect((await container.read(qesmaApiProvider).getMeControllerApi().getMe()).data!.username, name);

    Future<ApiHttpFailure> refusal(Future<Object?> Function() call) async {
      try {
        await call();
      } on ApiHttpFailure catch (e) {
        return e;
      }
      throw StateError('expected a refusal');
    }

    // Wrong password and unknown name: the same generic 401.
    final wrong = await refusal(() => repo.signIn(name, 'not the password'));
    final unknown = await refusal(() => repo.signIn('nobody.${DateTime.now().millisecondsSinceEpoch}', password));
    expect(wrong.status, 401);
    expect(unknown.status, 401);
    expect(wrong.problem?.code, unknown.problem?.code);

    // A taken name with another password: 409 USERNAME_TAKEN. The same password is a retry that signs in.
    final taken = await refusal(() => repo.register(name, 'another passphrase', null));
    expect(taken.status, 409);
    expect(taken.problem?.code, ApiErrorCode.usernameTaken);
    expect((await repo.register(name, password, null)).user.id, user.id);

    // Weak password: refused by the server (the client check is only a shortcut).
    final weak = await refusal(() => repo.register('weak.${DateTime.now().millisecondsSinceEpoch}', 'password1', null));
    expect(weak.status, 422);

    // Change the password; the session continues with new tokens and the old password stops working.
    container.listen(changePasswordControllerProvider, (_, _) {});
    final before = await store.readRefreshToken();
    expect(await container.read(changePasswordControllerProvider.notifier).submit(password, 'a brand new passphrase'), isTrue);
    expect(await store.readRefreshToken(), isNot(before));
    expect((await container.read(qesmaApiProvider).getMeControllerApi().getMe()).data!.id, user.id, reason: 'the new tokens work');
    expect((await refusal(() => repo.signIn(name, password))).status, 401);
    expect((await repo.signIn(name, 'a brand new passphrase')).user.id, user.id);

    // A wrong current password is refused without ending the session.
    expect(await container.read(changePasswordControllerProvider.notifier).submit('wrong current', 'yet another passphrase'), isFalse);
    expect(container.read(changePasswordControllerProvider).error, PasswordChangeError.refused);
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
