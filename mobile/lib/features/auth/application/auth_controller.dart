import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_log.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/google_id_token_source.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import 'auth_state.dart';

/// Tests switch this off to drive [AuthController.restore] themselves.
final autoRestoreProvider = Provider<bool>((ref) => true);

/// Owns [AuthState] and the sign-in / restore / sign-out flows.
///
/// Tokens live in the [SessionManager]; this class never holds or logs one. The generated
/// models returned by the API are used locally and dropped (their `toString` prints every
/// field, tokens included).
class AuthController extends Notifier<AuthState> {
  late final SessionManager _session = ref.read(sessionManagerProvider);
  late final AuthLog _log = ref.read(authLogProvider);

  @override
  AuthState build() {
    _session.onSessionEnded = _onSessionEnded;
    ref.onDispose(() => _session.onSessionEnded = null);
    // Start looking for a stored session as soon as the app is up.
    if (ref.read(autoRestoreProvider)) scheduleMicrotask(restore);
    return const AuthRestoring();
  }

  /// Looks for a stored session and, if there is one, proves it with `GET /me`
  /// (the interceptor refreshes the access token first). Safe to call again to retry.
  Future<void> restore() async {
    _log.event(AuthEvent.restoreStart);
    state = const AuthRestoring();

    if (!await _session.hasRefreshToken()) {
      _log.event(AuthEvent.restoreSignedOut);
      state = const AuthSignedOut();
      return;
    }

    try {
      final response = await ref.read(qesmaApiProvider).getMeControllerApi().getMe();
      final user = response.data;
      if (user == null) throw StateError('empty /me response');
      _log.event(AuthEvent.restoreOk);
      state = AuthSignedIn(user);
    } catch (error) {
      // The session may already have ended (callback moved us to signed out): keep that.
      if (state is! AuthRestoring) return;
      final failure = mapApiError(error);
      _log.event(AuthEvent.restoreOffline, status: (failure is ApiHttpFailure) ? failure.status : null);
      state = AuthRestoreFailed(failure);
    }
  }

  /// Google account picker, then the exchange. Works from the sign-in screen and from the
  /// session-expired dialog.
  Future<void> signInWithGoogle() async {
    if (_isBusy) return;
    final expired = state is AuthSessionExpired;
    _setBusy(expired);
    _log.event(AuthEvent.signInStart);
    try {
      final idToken = await ref.read(googleIdTokenSourceProvider).signIn();
      await _exchange(idToken, wasExpired: expired);
    } on GoogleSignInFailure catch (failure) {
      final error = switch (failure.kind) {
        GoogleFailureKind.cancelled => SignInError.cancelled,
        GoogleFailureKind.notConfigured => SignInError.notConfigured,
        GoogleFailureKind.unavailable => SignInError.providerUnavailable,
        GoogleFailureKind.failed => SignInError.failed,
      };
      _signInFailed(error, wasExpired: expired, kind: failure.kind);
    } catch (_) {
      // Whatever else a source throws must not leave the state stuck on "signing in".
      _signInFailed(SignInError.failed, wasExpired: expired);
    }
  }

  /// Exchanges an ID token directly. Used by the debug-only fake sign-in against a backend
  /// running the `fake-auth` profile.
  Future<void> signInWithIdToken(String idToken) async {
    if (_isBusy) return;
    final expired = state is AuthSessionExpired;
    _setBusy(expired);
    _log.event(AuthEvent.signInStart);
    await _exchange(idToken, wasExpired: expired);
  }

  Future<void> _exchange(String idToken, {required bool wasExpired}) async {
    try {
      final response = await ref.read(authlessApiProvider).getAuthControllerApi().signInWithGoogle(
            googleLoginRequest: GoogleLoginRequest((b) => b.idToken = idToken),
          );
      final auth = response.data;
      if (auth == null) throw StateError('empty sign-in response');
      await _session.startSession(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      _log.event(AuthEvent.signInOk);
      state = AuthSignedIn(auth.user);
    } catch (error) {
      final failure = mapApiError(error);
      final signInError = switch (failure) {
        ApiNoConnection() || ApiTimeout() => SignInError.offline,
        ApiHttpFailure(:final problem?) when problem.code == ApiErrorCode.rateLimited => SignInError.rateLimited,
        ApiHttpFailure(:final problem?) when problem.code == ApiErrorCode.authProviderUnavailable =>
          SignInError.providerUnavailable,
        _ => SignInError.failed,
      };
      _signInFailed(signInError, wasExpired: wasExpired, status: failure is ApiHttpFailure ? failure.status : null);
    }
  }

  void _signInFailed(SignInError error, {required bool wasExpired, GoogleFailureKind? kind, int? status}) {
    _log.event(error == SignInError.cancelled ? AuthEvent.signInCancelled : AuthEvent.signInFailed, kind: kind ?? error, status: status);
    state = wasExpired ? AuthSessionExpired(error: error) : AuthSignedOut(error: error);
  }

  /// Signs out: local wipe first (the UI moves on immediately), then best-effort server
  /// logout and Google sign-out. Never fails.
  Future<void> signOut() async {
    _log.event(AuthEvent.signOut);
    final refreshToken = await _session.signOut();
    state = const AuthSignedOut();
    if (refreshToken != null) {
      try {
        await ref
            .read(authlessApiProvider)
            .getAuthControllerApi()
            .signOut(refreshRequest: RefreshRequest((b) => b.refreshToken = refreshToken))
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best effort: the refresh token is already gone from this device and expires server-side.
      }
    }
    await ref.read(googleIdTokenSourceProvider).signOut();
  }

  /// "Back to the start" in the session-expired dialog.
  void leaveExpiredSession() {
    if (state is AuthSessionExpired) state = const AuthSignedOut();
  }

  bool get _isBusy => state is AuthSigningIn || (state is AuthSessionExpired && (state as AuthSessionExpired).busy);

  void _setBusy(bool expired) => state = expired ? const AuthSessionExpired(busy: true) : const AuthSigningIn();

  void _onSessionEnded(SessionEndReason reason) {
    switch (state) {
      case AuthRestoring() || AuthRestoreFailed():
        state = const AuthSignedOut(); // cold start with an unusable session: no dialog
      case AuthSignedIn():
        state = const AuthSessionExpired();
      case AuthSigningIn() || AuthSignedOut() || AuthSessionExpired():
        break;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Used by DioException consumers that want to know if a failure was the session ending.
bool isUnauthorized(Object error) => error is DioException && error.response?.statusCode == 401;
