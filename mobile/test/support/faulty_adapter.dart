import 'dart:typed_data';

import 'package:dio/dio.dart';

/// What [FaultyAdapter] does to one request.
enum Fault {
  /// The request reaches the server and is PROCESSED, but the response never arrives (the classic lost response on a bad
  /// connection): the caller sees a connection error.
  dropResponse,

  /// The request is replaced with a stale bearer token so the real server answers 401 (an expired access token).
  expiredToken,

  /// The request never leaves the phone (offline): a connection error without touching the server.
  offline,
}

/// Wraps the REAL network adapter and injects faults for FL9's real-backend scenarios, so the app's own interceptors,
/// repositories and idempotency code run unchanged against a real server. Test support only (never in `lib/`).
class FaultyAdapter implements HttpClientAdapter {
  FaultyAdapter(this._inner, {this.decide});

  final HttpClientAdapter _inner;

  /// Returns the fault for a request, or null to pass it through. Called once per request that reaches the adapter.
  Fault? Function(RequestOptions options)? decide;

  /// "METHOD /path" of every request that reached the adapter, in order (before faults are applied).
  final List<String> requests = [];

  /// Idempotency keys of every POST that reached the adapter (to assert that a retry reuses the key).
  final List<String> idempotencyKeys = [];

  int count(bool Function(String line) test) => requests.where(test).length;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add('${options.method} ${options.uri.path}');
    final key = options.headers['Idempotency-Key'];
    if (key is String) idempotencyKeys.add(key);

    switch (decide?.call(options)) {
      case Fault.offline:
        throw DioException.connectionError(requestOptions: options, reason: 'FaultyAdapter: offline');
      case Fault.expiredToken:
        options.headers['Authorization'] = 'Bearer expired.token.value';
        return _inner.fetch(options, requestStream, cancelFuture);
      case Fault.dropResponse:
        final response = await _inner.fetch(options, requestStream, cancelFuture);
        await response.stream.drain<void>(); // the server answered; the phone never saw it
        throw DioException.connectionError(requestOptions: options, reason: 'FaultyAdapter: response lost');
      case null:
        return _inner.fetch(options, requestStream, cancelFuture);
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
