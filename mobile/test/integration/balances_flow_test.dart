import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'flows/balances_flow.dart';

/// FL7 against a REAL local backend (profile `local,fake-auth`): the spec's V1 and V2 through the
/// app's own repository and request builder: nets 100.00 / -80.00 / -20.00 and two transfers; after
/// "Asem pays Mohamed 80.00" 20.00 / 0 / -20.00 and one transfer; the idempotent replay, partial and
/// larger-than-suggested payments, delete (and the second delete), and the refusals by code.
/// Skipped unless `API_BASE_URL` is given.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('balances, suggested transfers, payments and their history against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl7-$stamp:fl7-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await runBalancesFlow(container);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
