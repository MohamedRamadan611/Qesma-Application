import 'dart:async';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/profile/data/profile_repository.dart';
import '../errors/api_failure.dart';
import 'auth_providers.dart';

/// The "session" of local mode (STANDALONE_SPEC 2/3.6): there is no sign-in, only whether the one `local_profile`
/// exists yet. `GET /me` answered by the local backend: 200 -> [AuthSignedIn]; 401 (no profile yet) ->
/// [AuthSignedOut], which the local router reads as "show the onboarding". It never emits the session-expired,
/// signing-in or restore-failed states and it touches no token storage.
class LocalAuthController extends AuthController {
  @override
  AuthState build() {
    scheduleMicrotask(restore);
    return const AuthRestoring();
  }

  @override
  Future<void> restore() async {
    try {
      final user = (await ref.read(qesmaApiProvider).getMeControllerApi().getMe()).data;
      if (!ref.mounted) return;
      state = user == null ? const AuthSignedOut() : AuthSignedIn(user);
    } catch (_) {
      // A missing profile (401) and an unreadable database both lead to the onboarding; nothing is swallowed
      // silently for the second case because creating the profile will then fail visibly.
      if (ref.mounted) state = const AuthSignedOut();
    }
  }

  /// Onboarding: `PATCH /me` creates the profile. Returns null on success, the failure otherwise (the form stays).
  Future<ApiFailure?> createProfile(String displayName) async {
    try {
      final user = await ref.read(profileRepositoryProvider).updateName(displayName);
      if (ref.mounted) state = AuthSignedIn(user);
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }
}
