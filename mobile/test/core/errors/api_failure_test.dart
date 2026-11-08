import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';

// Bodies copied from a running backend (local,fake-auth) on 2026-11-08.
const _notFound =
    '{"type":"https://qesma.app/problems/not-found","title":"Resource not found","status":404,'
    '"instance":"/api/v1/groups/00000000-0000-0000-0000-000000000000","code":"NOT_FOUND",'
    '"requestId":"1baa356e-c91c-4e28-8d89-6cb0bfd399d3"}';
const _validation =
    '{"type":"https://qesma.app/problems/validation-error","title":"name must not be blank","status":422,'
    '"instance":"/api/v1/groups","code":"VALIDATION_ERROR","requestId":"880c9476-6788-4ad5-a104-d721303361b1"}';
const _unauthorized =
    '{"type":"https://qesma.app/problems/unauthorized","title":"Authentication required","status":401,'
    '"code":"UNAUTHORIZED","requestId":"f60f86f9-9619-4357-988a-9e83de6e41b8"}';

// Same envelope, other codes (shape identical to the captured ones above).
String _problem(String code, int status) =>
    '{"type":"https://qesma.app/problems/x","title":"t","status":$status,"instance":"/i","code":"$code","requestId":"r-1"}';

DioException _response(int status, Object? data, {String contentType = 'application/problem+json'}) {
  final options = RequestOptions(path: '/api/v1/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap({
        Headers.contentTypeHeader: [contentType],
      }),
    ),
  );
}

void main() {
  group('ApiProblem.tryParse', () {
    test('parses real backend bodies, as decoded maps and as raw strings', () {
      for (final body in [_notFound, jsonDecode(_notFound)]) {
        final p = ApiProblem.tryParse(body, fallbackStatus: 0)!;
        expect(p.code, ApiErrorCode.notFound);
        expect(p.status, 404);
        expect(p.requestId, '1baa356e-c91c-4e28-8d89-6cb0bfd399d3');
      }
      expect(ApiProblem.tryParse(_validation, fallbackStatus: 0)!.code, ApiErrorCode.validationError);
      expect(ApiProblem.tryParse(_unauthorized, fallbackStatus: 0)!.code, ApiErrorCode.unauthorized);
    });

    test('every code of the contract maps to its enum value', () {
      const codes = {
        'VALIDATION_ERROR': ApiErrorCode.validationError,
        'PAYERS_TOTAL_MISMATCH': ApiErrorCode.payersTotalMismatch,
        'SPLIT_TOTAL_MISMATCH': ApiErrorCode.splitTotalMismatch,
        'MEMBER_NOT_IN_GROUP': ApiErrorCode.memberNotInGroup,
        'IDEMPOTENCY_KEY_REUSED': ApiErrorCode.idempotencyKeyReused,
        'DUPLICATE_MEMBER_NAME': ApiErrorCode.duplicateMemberName,
        'MEMBER_HAS_TRANSACTIONS': ApiErrorCode.memberHasTransactions,
        'OWNER_MEMBER_PROTECTED': ApiErrorCode.ownerMemberProtected,
        'VERSION_CONFLICT': ApiErrorCode.versionConflict,
        'GROUP_NOT_EMPTY': ApiErrorCode.groupNotEmpty,
        'NOT_FOUND': ApiErrorCode.notFound,
        'UNAUTHORIZED': ApiErrorCode.unauthorized,
        'INTERNAL_ERROR': ApiErrorCode.internalError,
        'RATE_LIMITED': ApiErrorCode.rateLimited,
        'AUTH_PROVIDER_UNAVAILABLE': ApiErrorCode.authProviderUnavailable,
      };
      codes.forEach((wire, code) {
        expect(ApiProblem.tryParse(_problem(wire, 409), fallbackStatus: 0)!.code, code, reason: wire);
        expect(code.wire, wire);
      });
    });

    test('an unknown future code is kept raw and maps to unknown', () {
      final p = ApiProblem.tryParse(_problem('SOMETHING_NEW', 418), fallbackStatus: 0)!;
      expect(p.code, ApiErrorCode.unknown);
      expect(p.rawCode, 'SOMETHING_NEW');
    });

    test('non-problem bodies give null', () {
      for (final body in <Object?>[
        null,
        '',
        '<html><body>502 Bad Gateway</body></html>',
        '[1,2]',
        '{"message":"x"}',
        '{"code":5}',
        42,
      ]) {
        expect(ApiProblem.tryParse(body, fallbackStatus: 502), isNull, reason: '$body');
      }
    });

    test('a missing status falls back to the response status', () {
      expect(ApiProblem.tryParse('{"code":"NOT_FOUND"}', fallbackStatus: 404)!.status, 404);
    });
  });

  group('mapApiError', () {
    test('timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final f = mapApiError(DioException(requestOptions: RequestOptions(path: '/'), type: type));
        expect(f, isA<ApiTimeout>());
        expect(f.retryable, isTrue);
      }
    });

    test('no connection, from connectionError and from a SocketException', () {
      final a = mapApiError(DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError));
      final b = mapApiError(DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.unknown,
        error: const SocketException('down'),
      ));
      expect(a, isA<ApiNoConnection>());
      expect(b, isA<ApiNoConnection>());
      expect(a.retryable && b.retryable, isTrue);
    });

    test('cancel is not retryable', () {
      final f = mapApiError(DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.cancel));
      expect(f, isA<ApiCancelled>());
      expect(f.retryable, isFalse);
    });

    test('4xx with a problem body is definitive and carries the code', () {
      final f = mapApiError(_response(409, jsonDecode(_problem('VERSION_CONFLICT', 409))));
      expect(f, isA<ApiHttpFailure>());
      expect(f.retryable, isFalse);
      expect(f.problem!.code, ApiErrorCode.versionConflict);
    });

    test('5xx with an HTML body is retryable and has no problem', () {
      final f = mapApiError(_response(502, '<html>Bad Gateway</html>', contentType: 'text/html'));
      expect(f, isA<ApiHttpFailure>());
      expect(f.retryable, isTrue);
      expect(f.problem, isNull);
    });

    test('5xx with a problem body keeps the code', () {
      final f = mapApiError(_response(500, jsonDecode(_problem('INTERNAL_ERROR', 500))));
      expect(f.retryable, isTrue);
      expect(f.problem!.code, ApiErrorCode.internalError);
      expect(f.problem!.requestId, 'r-1');
    });

    test('anything else is unexpected and not retryable; failures pass through', () {
      expect(mapApiError(StateError('boom')), isA<ApiUnexpected>());
      expect(mapApiError(const FormatException('bad')).retryable, isFalse);
      const timeout = ApiTimeout();
      expect(identical(mapApiError(timeout), timeout), isTrue);
    });
  });
}
