import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

import 'api_problem.dart';

/// What can go wrong when calling the backend, as a closed set the UI can switch on.
sealed class ApiFailure implements Exception {
  const ApiFailure();

  /// True when repeating the identical request may succeed (and, for creates, must
  /// reuse the same Idempotency-Key): timeouts, no connection and 5xx.
  bool get retryable;

  /// The problem document if the server sent one.
  ApiProblem? get problem => null;
}

/// The request took too long; the outcome on the server is unknown.
final class ApiTimeout extends ApiFailure {
  const ApiTimeout();
  @override
  bool get retryable => true;
}

/// No usable network path to the server.
final class ApiNoConnection extends ApiFailure {
  const ApiNoConnection();
  @override
  bool get retryable => true;
}

/// The caller cancelled the request.
final class ApiCancelled extends ApiFailure {
  const ApiCancelled();
  @override
  bool get retryable => false;
}

/// The server answered with a non-success status.
final class ApiHttpFailure extends ApiFailure {
  const ApiHttpFailure({required this.status, this.problem});

  final int status;

  @override
  final ApiProblem? problem;

  @override
  bool get retryable => status >= 500;
}

/// Anything else (unreadable response, certificate problem, programming error).
final class ApiUnexpected extends ApiFailure {
  const ApiUnexpected();
  @override
  bool get retryable => false;
}

/// Maps any thrown error to an [ApiFailure]. Never exposes stack traces or bodies.
ApiFailure mapApiError(Object error) {
  if (error is ApiFailure) return error;
  if (error is! DioException) return const ApiUnexpected();
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiTimeout();
    case DioExceptionType.connectionError:
      return const ApiNoConnection();
    case DioExceptionType.cancel:
      return const ApiCancelled();
    case DioExceptionType.badResponse:
      final response = error.response;
      final status = response?.statusCode ?? 0;
      return ApiHttpFailure(
        status: status,
        problem: ApiProblem.tryParse(response?.data, fallbackStatus: status),
      );
    case DioExceptionType.badCertificate:
    case DioExceptionType.transformTimeout:
      return const ApiUnexpected();
    case DioExceptionType.unknown:
      return error.error is SocketException ? const ApiNoConnection() : const ApiUnexpected();
  }
}
