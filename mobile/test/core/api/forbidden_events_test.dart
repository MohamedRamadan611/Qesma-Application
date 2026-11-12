import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/forbidden_events.dart';

const _gid = '2bf36db7-e9e8-4b12-a206-878f0b5c934c';

/// Answers every request with the given status.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString('{"code":"FORBIDDEN","status":$status}', status,
        headers: {Headers.contentTypeHeader: ['application/problem+json']});
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, List<String> reports) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test', validateStatus: (s) => s != null && s >= 200 && s < 300))
    ..httpClientAdapter = _StatusAdapter(status)
    ..interceptors.add(ForbiddenRefreshInterceptor(reports.add));
  return dio;
}

void main() {
  group('groupIdOfPath', () {
    test('finds the group id in group-scoped paths', () {
      expect(groupIdOfPath('/api/v1/groups/$_gid'), _gid);
      expect(groupIdOfPath('/api/v1/groups/$_gid/expenses'), _gid);
      expect(groupIdOfPath('/api/v1/groups/$_gid/members/abc'), _gid);
      expect(groupIdOfPath('/groups/g1'), 'g1', reason: 'also the app route');
      expect(groupIdOfPath('/groups/g1?tab=members'), 'g1');
    });

    test('is null for anything else', () {
      expect(groupIdOfPath('/api/v1/groups'), isNull);
      expect(groupIdOfPath('/api/v1/me'), isNull);
      expect(groupIdOfPath('/api/v1/invites/ABCD2345'), isNull);
    });
  });

  group('ForbiddenRefreshInterceptor', () {
    test('a 403 on a group path reports that group once and the caller still gets the same failure', () async {
      final reports = <String>[];
      final dio = _dio(403, reports);
      Object? error;
      try {
        await dio.get<dynamic>('/api/v1/groups/$_gid/expenses');
      } on DioException catch (e) {
        error = e;
      }
      expect(reports, [_gid]);
      expect(error, isA<DioException>().having((e) => e.response?.statusCode, 'status', 403));
    });

    test('other statuses and other paths report nothing', () async {
      final reports = <String>[];
      for (final (status, path) in [(404, '/api/v1/groups/$_gid'), (409, '/api/v1/groups/$_gid/members'), (403, '/api/v1/me'), (403, '/api/v1/invites/ABCD2345')]) {
        final dio = _dio(status, reports);
        await dio.get<dynamic>(path).then((_) {}, onError: (_) {});
      }
      expect(reports, isEmpty);
    });
  });

  group('ForbiddenEvents', () {
    test('two reports for the same group are two different events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(forbiddenEventsProvider.notifier);
      expect(container.read(forbiddenEventsProvider), isNull);
      notifier.report('g1');
      final first = container.read(forbiddenEventsProvider)!;
      notifier.report('g1');
      final second = container.read(forbiddenEventsProvider)!;
      expect(first.gid, second.gid);
      expect(second.sequence, greaterThan(first.sequence));
    });
  });
}
