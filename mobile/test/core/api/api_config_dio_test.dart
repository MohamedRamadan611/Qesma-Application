import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/api_config.dart';
import 'package:qesma/core/api/dio_factory.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';

/// Answers every request with a canned response and records what it saw.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body, {this.contentType = 'application/problem+json'});

  final int status;
  final String body;
  final String contentType;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [contentType],
      'x-request-id': ['req-123'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiConfig.resolveBaseUrl', () {
    test('debug falls back to the emulator host alias', () {
      expect(ApiConfig.resolveBaseUrl(defined: '', debugOverride: null, isDebug: true), 'http://10.0.2.2:8080');
    });

    test('a defined URL wins over the fallback, a debug override wins over both; trailing slash is dropped', () {
      expect(ApiConfig.resolveBaseUrl(defined: 'http://192.168.1.5:18080/', debugOverride: null, isDebug: true),
          'http://192.168.1.5:18080');
      expect(
          ApiConfig.resolveBaseUrl(defined: 'https://api.example.com', debugOverride: 'http://10.0.2.2:18080', isDebug: true),
          'http://10.0.2.2:18080');
    });

    test('release needs an https URL and ignores debug overrides', () {
      expect(() => ApiConfig.resolveBaseUrl(defined: '', debugOverride: null, isDebug: false), throwsStateError);
      expect(() => ApiConfig.resolveBaseUrl(defined: 'http://api.example.com', debugOverride: null, isDebug: false),
          throwsStateError);
      expect(
          ApiConfig.resolveBaseUrl(defined: 'https://api.example.com', debugOverride: 'http://10.0.2.2:8080', isDebug: false),
          'https://api.example.com');
    });
  });

  group('createDio + generated client', () {
    test('getMe goes to <origin>/api/v1/me with Accept: application/json and no auth header', () async {
      final adapter = _FakeAdapter(
        200,
        jsonEncode({'id': '11111111-1111-1111-1111-111111111111', 'displayName': 'Ali', 'email': 'a@example.com', 'hasPassword': false, 'emailVerified': false}),
        contentType: 'application/json',
      );
      final dio = createDio(baseUrl: 'http://10.0.2.2:8080', adapter: adapter);
      final api = createApi(dio);

      await api.getMeControllerApi().getMe();

      final request = adapter.requests.single;
      expect(request.uri.toString(), 'http://10.0.2.2:8080/api/v1/me');
      expect(request.method, 'GET');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers.containsKey('Authorization'), isFalse, reason: 'auth is FL2');
    });

    test('a 404 problem+json body surfaces as ApiHttpFailure with the typed code', () async {
      final adapter = _FakeAdapter(
        404,
        '{"type":"https://qesma.app/problems/not-found","title":"Resource not found","status":404,'
        '"instance":"/api/v1/groups/x","code":"NOT_FOUND","requestId":"r-9"}',
      );
      final api = createApi(createDio(baseUrl: 'http://localhost', adapter: adapter));

      Object? caught;
      try {
        await api.getGroupControllerApi().getGroup(gid: 'x');
      } catch (e) {
        caught = e;
      }

      final failure = mapApiError(caught!);
      expect(failure, isA<ApiHttpFailure>());
      expect(failure.retryable, isFalse);
      expect(failure.problem!.code, ApiErrorCode.notFound);
      expect(failure.problem!.requestId, 'r-9');
    });

    test('the request logger writes method, path and status only, never headers or query', () async {
      final lines = <String>[];
      final adapter = _FakeAdapter(401, '{"code":"UNAUTHORIZED","status":401}');
      final dio = createDio(
        baseUrl: 'http://localhost',
        adapter: adapter,
        interceptors: [
          InterceptorsWrapper(onRequest: (o, h) {
            o.headers['Authorization'] = 'Bearer SECRET-TOKEN';
            h.next(o);
          }),
          RequestLogInterceptor(sink: lines.add),
        ],
      );

      await expectLater(dio.get<dynamic>('/api/v1/groups', queryParameters: {'page': 0}), throwsA(isA<DioException>()));

      expect(lines, ['GET /api/v1/groups -> 401 [req-123]']);
      expect(lines.join(), isNot(contains('SECRET-TOKEN')));
    });
  });
}
