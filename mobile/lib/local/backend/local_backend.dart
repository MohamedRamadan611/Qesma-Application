import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../db/local_database.dart';
import '../service/idempotency_service.dart';
import '../service/local_context.dart';
import 'local_log.dart';
import 'router.dart';

/// The `/api/v1` contract served in-process from SQLite with the Dart engine (ADR-011, STANDALONE_SPEC 3-4).
/// Plugged into `httpAdapterProvider`, it lets the unchanged repositories, DTOs and generated client run without a
/// server: same endpoints, status codes, headers (`ETag`, `Location`, `Idempotency-Replayed`, `x-request-id`) and
/// Problem JSON as the Java backend.
///
/// Idempotency keys older than 24 hours are purged once at start; the first request waits for that purge.
final class LocalBackend implements HttpClientAdapter {
  LocalBackend(
    LocalDatabase db, {
    int Function()? clock,
    String Function()? newId,
    LocalFailureLog failureLog = debugLocalFailureLog,
  }) : this._(LocalContext(db, clock: clock, newId: newId), failureLog);

  LocalBackend._(this._ctx, LocalFailureLog failureLog) : _router = LocalRouter(_ctx, failureLog: failureLog) {
    _started = IdempotencyService(_ctx).purgeExpired();
  }

  final LocalContext _ctx;
  final LocalRouter _router;
  late final Future<int> _started;

  static const String _prefix = '/api/v1';

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await _started;
    final requestId = _ctx.newId();
    final uri = options.uri;
    final path = uri.path;
    final LocalResponse response;
    if (!path.startsWith('$_prefix/') && path != _prefix) {
      response = await _router.handle(LocalRequest(
        method: options.method.toUpperCase(),
        path: '/__outside_api__',
        query: const {},
        headers: const {},
        body: null,
        requestId: requestId,
      ));
    } else {
      response = await _router.handle(LocalRequest(
        method: options.method.toUpperCase(),
        path: path.substring(_prefix.length),
        query: uri.queryParametersAll,
        headers: {for (final e in options.headers.entries) e.key.toLowerCase(): '${e.value}'},
        body: await _readBody(options, requestStream),
        requestId: requestId,
      ));
    }
    return ResponseBody.fromString(
      response.body ?? '',
      response.status,
      headers: {
        if (response.body != null)
          Headers.contentTypeHeader: [response.problem ? 'application/problem+json' : Headers.jsonContentType],
        'x-request-id': [requestId],
        for (final e in response.headers.entries) e.key: [e.value],
      },
    );
  }

  static Future<String?> _readBody(RequestOptions options, Stream<Uint8List>? stream) async {
    if (stream != null) {
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in stream) {
        bytes.add(chunk);
      }
      return utf8.decode(bytes.takeBytes(), allowMalformed: false);
    }
    final data = options.data;
    if (data == null) return null;
    if (data is String) return data;
    return jsonEncode(data);
  }

  @override
  void close({bool force = false}) {}
}
