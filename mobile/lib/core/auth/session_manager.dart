import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

import 'auth_log.dart';
import 'token_store.dart';

/// Result of a refresh call, kept independent of the generated client.
typedef TokenPair = ({String accessToken, String refreshToken});

/// Calls `POST /auth/refresh`. Must use a Dio WITHOUT the auth interceptor.
typedef RefreshCall = Future<TokenPair> Function(String refreshToken);

/// Why a session ended without the user asking for it.
enum SessionEndReason {
  /// The server said the refresh token is invalid, expired or revoked (401).
  refreshRejected,

  /// The refresh request may or may not have been processed; the token is treated as spent.
  refreshAmbiguous,

  /// The new refresh token could not be saved, so the old (now rotated) one is useless.
  storageFailed,

  /// No refresh token is stored.
  noRefreshToken,

  /// A request was retried with a freshly refreshed access token and was rejected again.
  retryRejected,
}

/// The session is over: the caller must not retry anything.
class SessionEndedException implements Exception {
  const SessionEndedException(this.reason);

  final SessionEndReason reason;

  @override
  String toString() => 'SessionEndedException(${reason.name})';
}

/// True when [error] proves the request never reached the server, so the refresh token
/// cannot have been consumed and may be kept for a later attempt.
///
/// Dio reports "connection closed before full header was received" as `connectionError`
/// too, but that happens AFTER the request was sent: only a `SocketException` at the
/// connection stage (refused, no route, DNS) or a connect timeout is proof.
bool provablyNotSent(DioException error) =>
    error.type == DioExceptionType.connectionTimeout ||
    (error.type == DioExceptionType.connectionError && error.error is SocketException);

/// Owns the tokens and the refresh protocol (ADR-002).
///
/// The backend rotates the refresh token on every use and treats reuse of an old one as
/// theft (the whole session family is revoked). Therefore:
/// * [refresh] is **single-flight**: any number of callers share one request;
/// * the new refresh token is **saved before** anyone is told the refresh succeeded;
/// * a refresh token that may have been sent is **never sent again**;
/// * a [_generation] counter makes results of an older session unable to write anything
///   after sign-out or expiry.
///
/// Pure Dart: no Flutter, no generated client (the refresh call is injected).
class SessionManager {
  SessionManager({required this._store, required this._refreshCall, AuthLog? log}) : _log = log ?? const DebugAuthLog();

  final TokenStore _store;
  final RefreshCall _refreshCall;
  final AuthLog _log;

  String? _accessToken;
  int _tokenVersion = 0;
  int _generation = 0;
  Future<void>? _inFlight;

  /// Called once per session when it ends without the user's request.
  void Function(SessionEndReason reason)? onSessionEnded;

  /// The current access token (memory only), or null.
  String? get accessToken => _accessToken;

  /// Changes every time a new access token is installed; requests remember the version
  /// they were sent with so a late 401 can tell "already refreshed" from "needs refresh".
  int get tokenVersion => _tokenVersion;

  /// Identifies the session (sign-in) a request belongs to. Changes on sign-in, sign-out and
  /// session end, so a late answer to a request of an older session can be told apart.
  int get generation => _generation;

  /// True when there is something to refresh with.
  Future<bool> hasRefreshToken() async => await _store.readRefreshToken() != null;

  /// Installs the tokens of a fresh sign-in (a new session generation).
  Future<void> startSession({required String accessToken, required String refreshToken}) async {
    _generation++;
    await _store.writeRefreshToken(refreshToken);
    _install(accessToken);
  }

  /// Refreshes the access token. Concurrent callers share the same request.
  ///
  /// Throws [SessionEndedException] when the session is over, or the original
  /// [DioException] when the refresh could not be attempted or was refused without
  /// consuming the token (offline, rate limited): the session is still alive then.
  Future<void> refresh() {
    final generation = _generation;
    return _inFlight ??= _doRefresh(generation).whenComplete(() => _inFlight = null);
  }

  Future<void> _doRefresh(int generation) async {
    _log.event(AuthEvent.refreshStart);

    final String? refreshToken;
    try {
      refreshToken = await _store.readRefreshToken();
    } catch (_) {
      await _end(generation, SessionEndReason.storageFailed);
      throw const SessionEndedException(SessionEndReason.storageFailed);
    }
    if (refreshToken == null) {
      await _end(generation, SessionEndReason.noRefreshToken);
      throw const SessionEndedException(SessionEndReason.noRefreshToken);
    }

    final TokenPair pair;
    try {
      pair = await _refreshCall(refreshToken);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        _log.event(AuthEvent.refreshFailed, kind: _Failure.rejected, status: status);
        await _end(generation, SessionEndReason.refreshRejected);
        throw const SessionEndedException(SessionEndReason.refreshRejected);
      }
      if (status == 429) {
        // Rejected by the rate limiter before the service ran: the token is intact.
        _log.event(AuthEvent.refreshFailed, kind: _Failure.rateLimited, status: status);
        rethrow;
      }
      if (provablyNotSent(e)) {
        _log.event(AuthEvent.refreshFailed, kind: _Failure.notSent);
        rethrow;
      }
      _log.event(AuthEvent.refreshFailed, kind: _Failure.ambiguous, status: status);
      await _end(generation, SessionEndReason.refreshAmbiguous);
      throw const SessionEndedException(SessionEndReason.refreshAmbiguous);
    } catch (_) {
      // Unreadable body or a programming error after the request went out: spent as well.
      _log.event(AuthEvent.refreshFailed, kind: _Failure.ambiguous);
      await _end(generation, SessionEndReason.refreshAmbiguous);
      throw const SessionEndedException(SessionEndReason.refreshAmbiguous);
    }

    // The session may have been signed out or replaced while the request was in flight.
    if (generation != _generation) {
      _log.event(AuthEvent.refreshFailed, kind: _Failure.stale);
      throw const SessionEndedException(SessionEndReason.refreshRejected);
    }

    // Persist the NEW refresh token before anyone can use the new access token.
    try {
      await _store.writeRefreshToken(pair.refreshToken);
    } catch (_) {
      await _end(generation, SessionEndReason.storageFailed);
      throw const SessionEndedException(SessionEndReason.storageFailed);
    }
    if (generation != _generation) {
      // Signed out during the write: do not leave a token behind.
      await _store.clear();
      _log.event(AuthEvent.refreshFailed, kind: _Failure.stale);
      throw const SessionEndedException(SessionEndReason.refreshRejected);
    }

    _install(pair.accessToken);
    _log.event(AuthEvent.refreshOk);
  }

  /// Ends the session because a request was rejected right after a successful refresh.
  /// Only ends the session the rejected request belonged to ([generation]); a newer session is untouched.
  Future<void> endAfterRejectedRetry(int generation) => _end(generation, SessionEndReason.retryRejected);

  /// The user signed out. Returns the refresh token that was stored (for a best-effort
  /// server logout) and wipes everything. Later results of older refreshes are discarded.
  Future<String?> signOut() async {
    _generation++;
    _accessToken = null;
    _tokenVersion++;
    final token = await _store.readRefreshToken();
    await _store.clear();
    return token;
  }

  /// Wipes everything without notifying (used when restore finds an unusable session).
  Future<void> wipe() async {
    _generation++;
    _accessToken = null;
    _tokenVersion++;
    await _store.clear();
  }

  void _install(String accessToken) {
    _accessToken = accessToken;
    _tokenVersion++;
  }

  /// Ends the session of [generation] exactly once: later calls for the same generation
  /// (several parallel failures) do nothing.
  Future<void> _end(int generation, SessionEndReason reason) async {
    if (generation != _generation) return;
    _generation++;
    _accessToken = null;
    _tokenVersion++;
    await _store.clear();
    _log.event(AuthEvent.sessionEnded, kind: reason);
    onSessionEnded?.call(reason);
  }
}

/// Log-only classification of refresh failures (never shown to users).
enum _Failure { rejected, rateLimited, notSent, ambiguous, stale }
