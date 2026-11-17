import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'flows/groups_flow.dart';

/// FL3 against a REAL local backend (profile `local,fake-auth`): create, paging, ETag/If-Match,
/// a real VERSION_CONFLICT, members, deletes. Skipped unless `API_BASE_URL` is given (see
/// auth_flow_test.dart). Uses a unique fake user so it never touches the seed data.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('groups and members against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl3-$stamp:fl3-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await runGroupsFlow(container);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
