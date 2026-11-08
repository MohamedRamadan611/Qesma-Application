import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException, SocketException;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:qesma/core/auth/token_store.dart';

/// How the next `/auth/refresh` call should misbehave.
/// How the next `/auth/google` call should fail.
enum LoginFault { none, unauthorized, rateLimited, providerUnavailable, connectionRefused }

enum RefreshFault { none, connectionRefused, connectTimeout, closedAfterSend, receiveTimeout, serverError, rateLimited }

/// A fake of the backend's auth behaviour (ADR-002), good enough to prove the client's
/// refresh protocol: access tokens that expire, refresh tokens that rotate on every use and
/// reuse of an old one that revokes the whole session family.
class FakeBackend implements HttpClientAdapter {
  FakeBackend({this.refreshDelay = const Duration(milliseconds: 20)});

  /// How long a refresh takes, so parallel callers really overlap.
  final Duration refreshDelay;

  /// Everything that happened, in order (requests, refresh results). Tests assert on it.
  final List<String> events = [];

  /// Every refresh token the server received, in order.
  final List<String> refreshTokensReceived = [];

  int apiRequests = 0;
  int unauthorizedResponses = 0;
  bool familyRevoked = false;

  RefreshFault nextRefreshFault = RefreshFault.none;
  LoginFault nextLoginFault = LoginFault.none;
  bool logoutFails = false;

  /// How long protected endpoints take to answer; the token is checked AFTER this delay,
  /// so a request can be rejected long after it was sent.
  Duration apiDelay = Duration.zero;
  bool alwaysRejectApi = false; // simulates a server that rejects even fresh access tokens

  final Set<String> _validAccess = {};
  final Set<String> _usedRefresh = {};
  String? _currentRefresh;
  int _counter = 0;

  /// Issues a session like `POST /auth/google` and returns its tokens.
  ({String access, String refresh}) issueSession() {
    familyRevoked = false;
    return _rotate();
  }

  /// Makes every issued access token invalid, as if 15 minutes had passed.
  void expireAccessTokens() => _validAccess.clear();

  ({String access, String refresh}) _rotate() {
    _counter++;
    final access = 'access-$_counter';
    final refresh = 'refresh-$_counter';
    _validAccess.add(access);
    if (_currentRefresh != null) _usedRefresh.add(_currentRefresh!);
    _currentRefresh = refresh;
    return (access: access, refresh: refresh);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path;
    if (path.endsWith('/auth/refresh')) return _refresh(options, requestStream);
    if (path.endsWith('/auth/logout')) {
      if (logoutFails) {
        throw DioException.connectionError(requestOptions: options, reason: 'down', error: const SocketException('down'));
      }
      events.add('logout');
      return _json(204, '');
    }
    if (path.endsWith('/auth/google')) {
      await _body(options, requestStream);
      final fault = nextLoginFault;
      nextLoginFault = LoginFault.none;
      switch (fault) {
        case LoginFault.unauthorized:
          return _json(401, _problem('UNAUTHORIZED', 401));
        case LoginFault.rateLimited:
          return _json(429, _problem('RATE_LIMITED', 429));
        case LoginFault.providerUnavailable:
          return _json(503, _problem('AUTH_PROVIDER_UNAVAILABLE', 503));
        case LoginFault.connectionRefused:
          throw DioException.connectionError(requestOptions: options, reason: 'refused', error: const SocketException('refused'));
        case LoginFault.none:
          break;
      }
      final session = issueSession();
      events.add('google-login');
      return _json(
        200,
        jsonEncode({
          'accessToken': session.access,
          'refreshToken': session.refresh,
          'user': {'id': 'u1', 'displayName': 'Test User', 'email': 'test@example.com'},
        }),
      );
    }

    // Any other endpoint is protected.
    apiRequests++;
    if (apiDelay > Duration.zero) await Future<void>.delayed(apiDelay);
    final auth = options.headers['Authorization'] as String?;
    final token = auth != null && auth.startsWith('Bearer ') ? auth.substring(7) : null;
    if (alwaysRejectApi || token == null || !_validAccess.contains(token)) {
      unauthorizedResponses++;
      events.add('api-401 $path');
      return _json(401, _problem('UNAUTHORIZED', 401));
    }
    events.add('api-200 $path');
    if (path.endsWith('/me')) {
      return _json(200, jsonEncode({'id': 'u1', 'displayName': 'Test User', 'email': 'test@example.com'}));
    }
    return _json(200, jsonEncode({'ok': true}));
  }

  Future<ResponseBody> _refresh(RequestOptions options, Stream<Uint8List>? requestStream) async {
    final fault = nextRefreshFault;
    nextRefreshFault = RefreshFault.none;
    final body = jsonDecode(await _body(options, requestStream)) as Map<String, dynamic>;
    final sent = body['refreshToken'] as String;

    switch (fault) {
      case RefreshFault.connectionRefused:
        // Never reached the server: nothing is recorded.
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
          error: const SocketException('Connection refused'),
        );
      case RefreshFault.connectTimeout:
        throw DioException.connectionTimeout(requestOptions: options, timeout: const Duration(seconds: 10));
      case RefreshFault.rateLimited:
        events.add('refresh-429');
        return _json(429, _problem('RATE_LIMITED', 429));
      case RefreshFault.none:
      case RefreshFault.closedAfterSend:
      case RefreshFault.receiveTimeout:
      case RefreshFault.serverError:
        break;
    }

    // The server received it from here on.
    refreshTokensReceived.add(sent);
    events.add('refresh-received $sent');
    await Future<void>.delayed(refreshDelay);

    ({String access, String refresh})? rotated;
    if (familyRevoked || _usedRefresh.contains(sent)) {
      familyRevoked = true;
      _validAccess.clear();
      _currentRefresh = null;
    } else if (sent == _currentRefresh) {
      rotated = _rotate(); // rotation happens even if the response is then lost
    }

    switch (fault) {
      case RefreshFault.closedAfterSend:
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'closed',
          error: const HttpException('Connection closed before full header was received'),
        );
      case RefreshFault.receiveTimeout:
        throw DioException.receiveTimeout(requestOptions: options, timeout: const Duration(seconds: 20));
      case RefreshFault.serverError:
        events.add('refresh-500');
        return _json(500, _problem('INTERNAL_ERROR', 500));
      default:
        break;
    }

    if (rotated == null) {
      events.add('refresh-401 $sent');
      return _json(401, _problem('UNAUTHORIZED', 401));
    }
    events.add('refresh-ok ${rotated.refresh}');
    return _json(200, jsonEncode({'accessToken': rotated.access, 'refreshToken': rotated.refresh}));
  }

  Future<String> _body(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream == null) return jsonEncode(options.data ?? {});
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  String _problem(String code, int status) => jsonEncode({
        'type': 'https://qesma.app/problems/x',
        'title': 'x',
        'status': status,
        'code': code,
        'requestId': 'req-$status',
      });

  ResponseBody _json(int status, String body) => ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: [status == 204 ? 'text/plain' : 'application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// A token store that writes into the same event log as the fake backend, so tests can
/// assert the order "refresh response, then store write, then retried requests".
class RecordingTokenStore extends InMemoryTokenStore {
  RecordingTokenStore(this.events, [super.initial]);

  final List<String> events;
  bool failNextWrite = false;
  Duration writeDelay = Duration.zero;

  @override
  Future<void> writeRefreshToken(String token) async {
    if (writeDelay > Duration.zero) await Future<void>.delayed(writeDelay);
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('storage failure');
    }
    events.add('store-write $token');
    await super.writeRefreshToken(token);
  }

  @override
  Future<void> clear() async {
    events.add('store-clear');
    await super.clear();
  }
}
