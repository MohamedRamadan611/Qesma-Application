import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../api/dio_factory.dart';
import 'auth_interceptor.dart';
import 'auth_log.dart';
import 'google_id_token_source.dart';
import 'session_manager.dart';
import 'token_store.dart';

/// Lets tests replace the network with a fake server. Null = the real adapter.
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

final authLogProvider = Provider<AuthLog>((ref) => const DebugAuthLog());

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final googleIdTokenSourceProvider = Provider<GoogleIdTokenSource>((ref) => PlayGoogleIdTokenSource());

/// Dio WITHOUT the auth interceptor: used for `/auth/*` only, so the refresh request can
/// never recurse into the interceptor and never carries a bearer token.
final authlessDioProvider = Provider<Dio>((ref) => createDio(adapter: ref.watch(httpAdapterProvider), interceptors: [RequestLogInterceptor()]));

final authlessApiProvider = Provider<QesmaApi>((ref) => createApi(ref.watch(authlessDioProvider)));

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final authApi = ref.watch(authlessApiProvider).getAuthControllerApi();
  return SessionManager(
    store: ref.watch(tokenStoreProvider),
    log: ref.watch(authLogProvider),
    refreshCall: (refreshToken) async {
      final response = await authApi.refreshSession(
        refreshRequest: RefreshRequest((b) => b.refreshToken = refreshToken),
      );
      final body = response.data;
      if (body == null) throw StateError('empty refresh response');
      return (accessToken: body.accessToken, refreshToken: body.refreshToken);
    },
  );
});

/// The Dio every feature uses: bearer token, 401 handling, request log.
final apiDioProvider = Provider<Dio>((ref) {
  final dio = createDio(adapter: ref.watch(httpAdapterProvider));
  dio.interceptors.addAll([
    AuthInterceptor(session: ref.watch(sessionManagerProvider), dio: dio),
    RequestLogInterceptor(),
  ]);
  return dio;
});

/// The generated client for everything except `/auth/*`.
final qesmaApiProvider = Provider<QesmaApi>((ref) => createApi(ref.watch(apiDioProvider)));
