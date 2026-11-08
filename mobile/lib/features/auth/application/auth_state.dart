import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';

/// Why a sign-in attempt did not produce a session (drives the message under the button).
enum SignInError {
  /// The user closed the Google picker. Shown as nothing.
  cancelled,
  failed,
  rateLimited,
  providerUnavailable,
  offline,
  notConfigured,
}

/// Where the user stands. Only this state decides which screens are reachable.
///
/// `toString` is deliberately minimal: a state must never print the user's name, e-mail
/// or anything token-like if it ends up in a log or an assertion message.
sealed class AuthState {
  const AuthState();

  @override
  String toString() => runtimeType.toString();
}

/// App just started; looking for a stored session.
final class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// A stored session exists but the server could not be reached (or answered 5xx/429).
/// The session is kept; the splash screen offers a retry.
final class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.failure);

  final ApiFailure failure;
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.error});

  /// Result of the last sign-in attempt, if it failed.
  final SignInError? error;
}

final class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final UserDto user;
}

/// The session ended while the user was using the app (dialog over the current screen).
final class AuthSessionExpired extends AuthState {
  const AuthSessionExpired({this.busy = false, this.error});

  /// A sign-in from the dialog is in progress.
  final bool busy;
  final SignInError? error;
}
