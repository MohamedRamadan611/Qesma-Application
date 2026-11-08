import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/google_id_token_source.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';

import 'fake_backend.dart';

/// Stands in for the Google account picker.
class FakeGoogleSource implements GoogleIdTokenSource {
  String token = 'google-id-token-canary';
  GoogleSignInFailure? failWith;

  /// Throws this raw object (not a GoogleSignInFailure), like an unexpected plugin error.
  Object? throwRaw;
  int signIns = 0;
  int signOuts = 0;

  @override
  Future<String> signIn() async {
    signIns++;
    final raw = throwRaw;
    if (raw != null) throw raw;
    final failure = failWith;
    if (failure != null) throw failure;
    return token;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

/// The whole auth stack on top of a fake backend, a recording store and a recording log.
class AuthRig {
  AuthRig({String? storedRefresh, bool autoRestore = false}) {
    store = RecordingTokenStore(backend.events, storedRefresh);
    container = ProviderContainer(
      overrides: [
        httpAdapterProvider.overrideWithValue(backend),
        tokenStoreProvider.overrideWithValue(store),
        googleIdTokenSourceProvider.overrideWithValue(google),
        authLogProvider.overrideWithValue(log),
        autoRestoreProvider.overrideWithValue(autoRestore),
      ],
    );
    // Record every distinct state the controller passes through.
    container.listen<AuthState>(authControllerProvider, (previous, next) => states.add(next), fireImmediately: true);
  }

  final backend = FakeBackend();
  final google = FakeGoogleSource();
  final log = RecordingAuthLog();
  final List<AuthState> states = [];
  late final RecordingTokenStore store;
  late final ProviderContainer container;

  AuthController get controller => container.read(authControllerProvider.notifier);
  AuthState get state => container.read(authControllerProvider);

  /// A stored session the fake server knows (as if the app had been used before).
  Future<void> seedStoredSession() async {
    final s = backend.issueSession();
    await store.writeRefreshToken(s.refresh);
    backend.events.clear();
  }

  void dispose() => container.dispose();
}
