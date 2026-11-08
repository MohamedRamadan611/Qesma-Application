import 'package:dio/dio.dart';

import 'session_manager.dart';

/// Marks a request that was already retried once after a refresh (never retried twice).
const String _retriedKey = 'qesma.retried';

/// The access-token version a request was sent with.
const String _versionKey = 'qesma.tokenVersion';

/// The session generation a request was sent under.
const String _generationKey = 'qesma.generation';

/// Attaches the bearer token and handles 401s with the single-flight refresh.
///
/// Only the API Dio carries it. `/auth/*` calls use a plain Dio, so the refresh request
/// can never recurse into this interceptor and never carries an expired bearer.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._session, required this._dio});

  final SessionManager _session;
  final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    var token = _session.accessToken;

    // Cold start: a refresh token is stored but no access token is in memory yet. Refresh
    // first instead of sending a request that is certain to be rejected.
    if (token == null && await _session.hasRefreshToken()) {
      try {
        await _session.refresh();
        token = _session.accessToken;
      } on SessionEndedException {
        handler.reject(_unauthorized(options), true);
        return;
      } on DioException catch (refreshError) {
        // Offline or rate limited: the session lives on, this request fails with that reason.
        handler.reject(_asFailureOf(options, refreshError), true);
        return;
      }
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_versionKey] = _session.tokenVersion;
      options.extra[_generationKey] = _session.generation;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final sentWithToken = options.extra.containsKey(_versionKey);
    if (err.response?.statusCode != 401 || !sentWithToken) {
      handler.next(err);
      return;
    }

    // The session this request belonged to is over (sign-out, expiry, or a new sign-in):
    // never replay it under another session's token.
    if (options.extra[_generationKey] != _session.generation) {
      handler.next(err);
      return;
    }

    if (options.extra[_retriedKey] == true) {
      // A freshly refreshed token was rejected too: stop, do not loop.
      await _session.endAfterRejectedRetry(options.extra[_generationKey] as int);
      handler.next(err);
      return;
    }

    try {
      // If another request already refreshed after this one was sent, just retry.
      if (options.extra[_versionKey] == _session.tokenVersion) {
        await _session.refresh();
      }
    } on SessionEndedException {
      handler.next(err);
      return;
    } on DioException catch (refreshError) {
      handler.next(_asFailureOf(options, refreshError));
      return;
    }

    try {
      options.extra[_retriedKey] = true;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  DioException _unauthorized(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: options, statusCode: 401),
      );

  /// The refresh attempt failed for a reason that does not end the session; surface that
  /// reason (offline, 429) to the caller of the original request.
  DioException _asFailureOf(RequestOptions options, DioException refreshError) => DioException(
        requestOptions: options,
        type: refreshError.type,
        response: refreshError.response == null
            ? null
            : Response<dynamic>(
                requestOptions: options,
                statusCode: refreshError.response!.statusCode,
                data: refreshError.response!.data,
                headers: refreshError.response!.headers,
              ),
        error: refreshError.error,
      );
}
