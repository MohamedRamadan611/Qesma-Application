import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'flows/expenses_flow.dart';

/// FL4 against a REAL local backend (profile `local,fake-auth`): list paging, the date and
/// member filters, details with ETag, history, delete with If-Match, a real 409 and 404.
/// Skipped unless `API_BASE_URL` is given (see auth_flow_test.dart). The expenses are created
/// through the generated client in the test's own setup (the app has no add screen until FL5).
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('expenses against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl4-$stamp:fl4-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await runExpensesFlow(container);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
