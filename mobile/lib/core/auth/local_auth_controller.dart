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
  ///
  /// [instapay] / [wallet] are the optional payment details (already normalised by the screen). They are saved right
  /// after the profile exists and before the session state flips (which moves the router away from the onboarding).
  /// A failure to save them never blocks onboarding: they can be added later under Account.
  Future<ApiFailure?> createProfile(String displayName, {String? instapay, String? wallet}) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.updateName(displayName);
      if (instapay != null || wallet != null) {
        try {
          await repo.savePaymentHandles(instapay: instapay, wallet: wallet);
        } on ApiFailure {
          // Optional extras; the profile itself was created.
        }
      }
      if (ref.mounted) state = AuthSignedIn(user);
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }
}
