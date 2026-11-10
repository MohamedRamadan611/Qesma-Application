import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../data/password_auth_repository.dart';
import 'auth_controller.dart';
import 'password_rules.dart';

/// Why a username sign-in or registration did not go through (drives the message on the form).
enum UsernameAuthError { invalidUsername, passwordShort, passwordLong, wrongCredentials, usernameTaken, passwordRejected, rateLimited, offline, failed }

/// Maps a failure of the email endpoints to what the form says. A sign-in refusal never says which part was wrong.
UsernameAuthError usernameAuthErrorFor(ApiFailure failure, {required bool register}) {
  if (failure is ApiNoConnection || failure is ApiTimeout) return UsernameAuthError.offline;
  if (failure is ApiHttpFailure) {
    final code = failure.problem?.code;
    if (code == ApiErrorCode.rateLimited || failure.status == 429) return UsernameAuthError.rateLimited;
    if (code == ApiErrorCode.usernameTaken) return UsernameAuthError.usernameTaken;
    if (failure.status == 401) return UsernameAuthError.wrongCredentials;
    if (failure.status == 422 && register) return UsernameAuthError.passwordRejected;
  }
  return UsernameAuthError.failed;
}

class UsernameAuthState {
  const UsernameAuthState({this.submitting = false, this.error});

  final bool submitting;
  final UsernameAuthError? error;

  // Never prints the typed email or password.
  @override
  String toString() => 'UsernameAuthState(submitting: $submitting, error: $error)';
}

/// The username sign-in and registration forms. The typed password lives only in the text field and in the request;
/// it is not kept here, not logged, and not stored (only the refresh token the server returns is).
class UsernameAuthController extends Notifier<UsernameAuthState> {
  @override
  UsernameAuthState build() => const UsernameAuthState();

  void clearError() {
    if (state.error != null) state = const UsernameAuthState();
  }

  Future<void> signIn(String username, String password) async {
    if (state.submitting) return;
    // Only "something was typed": the registration shape rule must not block accounts made before usernames existed.
    if (username.trim().isEmpty) return _fail(UsernameAuthError.invalidUsername);
    if (password.isEmpty) return _fail(UsernameAuthError.wrongCredentials);
    await _run(register: false, call: (repo) => repo.signIn(username.trim(), password));
  }

  Future<void> register(String username, String password, String name) async {
    if (state.submitting) return;
    if (!PasswordRules.usernameLooksValid(username)) return _fail(UsernameAuthError.invalidUsername);
    if (PasswordRules.tooShort(password)) return _fail(UsernameAuthError.passwordShort);
    if (PasswordRules.tooLong(password)) return _fail(UsernameAuthError.passwordLong);
    final display = name.trim();
    await _run(register: true, call: (repo) => repo.register(username.trim(), password, display.isEmpty ? null : display));
  }

  void _fail(UsernameAuthError error) => state = UsernameAuthState(error: error);

  Future<void> _run({required bool register, required Future<AuthResponse> Function(PasswordAuthRepository) call}) async {
    state = const UsernameAuthState(submitting: true);
    try {
      final auth = await call(ref.read(passwordAuthRepositoryProvider));
      await ref.read(authControllerProvider.notifier).startPasswordSession(auth);
      if (ref.mounted) state = const UsernameAuthState();
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = UsernameAuthState(error: usernameAuthErrorFor(failure, register: register));
    } catch (_) {
      // Anything else (for example secure storage refusing the token) must not leave the form stuck on "submitting".
      if (ref.mounted) state = const UsernameAuthState(error: UsernameAuthError.failed);
    }
  }
}

final usernameAuthControllerProvider = NotifierProvider.autoDispose<UsernameAuthController, UsernameAuthState>(UsernameAuthController.new);
