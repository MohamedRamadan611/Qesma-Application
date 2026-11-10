import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../data/password_auth_repository.dart';
import 'auth_controller.dart';
import 'password_rules.dart';

enum PasswordChangeError { currentEmpty, newShort, newLong, refused, rateLimited, offline, failed }

class ChangePasswordState {
  const ChangePasswordState({this.submitting = false, this.error});

  final bool submitting;
  final PasswordChangeError? error;

  @override
  String toString() => 'ChangePasswordState(submitting: $submitting, error: $error)';
}

/// Changes the signed-in user's password. On success the server ended every other session and this one
/// receives fresh tokens, which replace the stored ones.
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  void clearError() {
    if (state.error != null) state = const ChangePasswordState();
  }

  /// True when the password was changed.
  Future<bool> submit(String current, String next) async {
    if (state.submitting) return false;
    if (current.isEmpty) return _fail(PasswordChangeError.currentEmpty);
    if (PasswordRules.tooShort(next)) return _fail(PasswordChangeError.newShort);
    if (PasswordRules.tooLong(next)) return _fail(PasswordChangeError.newLong);
    state = const ChangePasswordState(submitting: true);
    try {
      final tokens = await ref.read(passwordAuthRepositoryProvider).changePassword(current, next);
      await ref.read(authControllerProvider.notifier).replaceTokens(tokens);
      if (ref.mounted) state = const ChangePasswordState();
      return true;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return false;
      final error = switch (failure) {
        ApiNoConnection() || ApiTimeout() => PasswordChangeError.offline,
        ApiHttpFailure(status: 429) => PasswordChangeError.rateLimited,
        ApiHttpFailure(status: 422) => PasswordChangeError.refused,
        _ => PasswordChangeError.failed,
      };
      state = ChangePasswordState(error: error);
      return false;
    }
  }

  bool _fail(PasswordChangeError error) {
    state = ChangePasswordState(error: error);
    return false;
  }
}

final changePasswordControllerProvider = NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(ChangePasswordController.new);
