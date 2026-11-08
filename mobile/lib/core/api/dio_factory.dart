import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:qesma_api/qesma_api.dart';

import 'api_config.dart';

/// Builds the one [Dio] used for every backend call.
///
/// Auth (bearer token, refresh single-flight) is added by FL2 through [interceptors];
/// nothing here knows about tokens.
Dio createDio({
  String? baseUrl,
  List<Interceptor> interceptors = const [],
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {Headers.acceptHeader: Headers.jsonContentType},
      // Non-2xx must throw so every failure goes through mapApiError.
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.addAll(interceptors);
  return dio;
}

/// The generated client on top of [dio]. Its own default auth interceptors are disabled
/// (`interceptors: []`): authentication is ours.
QesmaApi createApi(Dio dio) => QesmaApi(dio: dio, interceptors: const []);

/// Logs `METHOD path -> status [requestId]` in debug builds only. Never logs headers
/// (Authorization), query strings, bodies or anything personal (SCREEN_MAP rule 9).
class RequestLogInterceptor extends Interceptor {
  RequestLogInterceptor({void Function(String line)? sink}) : _sink = sink ?? _debugSink;

  final void Function(String line) _sink;

  static void _debugSink(String line) {
    if (kDebugMode) debugPrint(line);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode, response.headers.value('x-request-id'));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, err.response?.headers.value('x-request-id'));
    handler.next(err);
  }

  void _log(RequestOptions request, int? status, String? requestId) {
    final id = requestId == null ? '' : ' [$requestId]';
    _sink('${request.method} ${request.uri.path} -> ${status ?? 'no response'}$id');
  }
}
