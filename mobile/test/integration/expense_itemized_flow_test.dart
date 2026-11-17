import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'flows/expense_itemized_flow.dart';

/// FL6 against a REAL local backend (profile `local,fake-auth`): the restaurant-bill requests the
/// editor builds are accepted by the real server and answered with the spec's numbers (V5-V8), a
/// bill is created (and replayed), read back into the form, edited with `If-Match`, and a stale
/// edit is refused. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('the restaurant-bill editor\'s requests against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl6-$stamp:fl6-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await runExpenseItemizedFlow(container);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
