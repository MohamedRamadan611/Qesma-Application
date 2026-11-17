import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'flows/expense_form_flow.dart';

/// FL5 against a REAL local backend (profile `local,fake-auth`): the requests the add/edit form
/// builds are accepted by the real server and return the numbers the UI relies on: the preview
/// (EQUAL among three, with and without payers, with the placeholder title), create with an
/// Idempotency-Key (and its replay), key reuse with another body, edit with If-Match and the
/// explicit participant list, and a stale edit. Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('the add/edit form\'s requests against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl5-$stamp:fl5-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await runExpenseFormFlow(container);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
