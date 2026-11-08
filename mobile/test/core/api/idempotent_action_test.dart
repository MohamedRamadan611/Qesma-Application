import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/errors/api_failure.dart';

DioException _http(int status) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: status),
    );

DioException _of(DioExceptionType type) => DioException(requestOptions: RequestOptions(path: '/x'), type: type);

void main() {
  late int counter;
  late IdempotentAction action;

  setUp(() {
    counter = 0;
    action = IdempotentAction(newKey: () => 'key-${++counter}');
  });

  test('first send gets a new key and the key is forgotten after success', () async {
    final seen = <String>[];
    await action.run({'a': 1}, (key) async => seen.add(key));
    expect(seen, ['key-1']);
    expect(action.currentKey, isNull);
    await action.run({'a': 1}, (key) async => seen.add(key));
    expect(seen, ['key-1', 'key-2'], reason: 'a finished action must never reuse its key');
  });

  for (final entry in <String, Object>{
    'timeout': _of(DioExceptionType.receiveTimeout),
    'no connection': _of(DioExceptionType.connectionError),
    '502': _http(502),
    '500': _http(500),
  }.entries) {
    test('${entry.key}: the same body retries with the SAME key', () async {
      final seen = <String>[];
      await expectLater(action.run({'a': 1}, (key) async {
        seen.add(key);
        throw entry.value;
      }), throwsA(isA<ApiFailure>()));
      await action.run({'a': 1}, (key) async => seen.add(key));
      expect(seen, ['key-1', 'key-1']);
    });
  }

  test('map key order does not make a different body', () async {
    final seen = <String>[];
    await expectLater(action.run({'a': 1, 'b': [1, 2], 'c': {'x': 1, 'y': 2}}, (key) async {
      seen.add(key);
      throw _of(DioExceptionType.connectionTimeout);
    }), throwsA(isA<ApiTimeout>()));
    await action.run({'c': {'y': 2, 'x': 1}, 'b': [1, 2], 'a': 1}, (key) async => seen.add(key));
    expect(seen, ['key-1', 'key-1']);
  });

  test('a changed body after an unknown outcome gets a NEW key', () async {
    final seen = <String>[];
    await expectLater(action.run({'amount': 100}, (key) async {
      seen.add(key);
      throw _of(DioExceptionType.receiveTimeout);
    }), throwsA(isA<ApiTimeout>()));
    await action.run({'amount': 200}, (key) async => seen.add(key));
    expect(seen, ['key-1', 'key-2']);
  });

  for (final status in [400, 404, 409, 422]) {
    test('definitive $status clears the key so the next attempt starts fresh', () async {
      final seen = <String>[];
      await expectLater(action.run({'a': 1}, (key) async {
        seen.add(key);
        throw _http(status);
      }), throwsA(isA<ApiHttpFailure>().having((f) => f.retryable, 'retryable', false)));
      expect(action.currentKey, isNull);
      await action.run({'a': 1}, (key) async => seen.add(key));
      expect(seen, ['key-1', 'key-2']);
    });
  }

  test('reset() forgets a pending key', () async {
    await expectLater(action.run({'a': 1}, (key) async => throw _of(DioExceptionType.receiveTimeout)),
        throwsA(isA<ApiTimeout>()));
    expect(action.currentKey, 'key-1');
    action.reset();
    expect(action.currentKey, isNull);
  });

  test('canonicalJson sorts keys recursively', () {
    expect(canonicalJson({'b': 1, 'a': {'d': 1, 'c': [3, 2]}}), '{"a":{"c":[3,2],"d":1},"b":1}');
  });
}
