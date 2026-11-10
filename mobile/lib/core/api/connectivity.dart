import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the last request that reached a verdict got an answer from the server. No connectivity
/// package: the app is online-only, so what matters is whether the API answers, not what the radio
/// says. Starts online; a failed connection flips it, any HTTP response (even a 4xx) flips it back.
class ConnectivityController extends Notifier<bool> {
  @override
  bool build() => true;

  void report({required bool online}) {
    if (state != online) state = online;
  }
}

final connectivityProvider = NotifierProvider<ConnectivityController, bool>(ConnectivityController.new);

/// True when [error] means "the server could not be reached" (not a cancel, not a bad certificate).
bool isUnreachable(DioException error) =>
    error.response == null &&
    (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout);

/// Reports reachability from real traffic. Never reads or logs a request or a response body.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._report);

  final void Function(bool online) _report;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _report(true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _report(true);
    } else if (isUnreachable(err)) {
      _report(false);
    }
    handler.next(err);
  }
}
