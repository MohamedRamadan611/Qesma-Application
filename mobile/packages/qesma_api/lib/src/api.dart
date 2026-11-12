//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:built_value/serializer.dart';
import 'package:qesma_api/src/serializers.dart';
import 'package:qesma_api/src/auth/api_key_auth.dart';
import 'package:qesma_api/src/auth/basic_auth.dart';
import 'package:qesma_api/src/auth/bearer_auth.dart';
import 'package:qesma_api/src/auth/oauth.dart';
import 'package:qesma_api/src/api/auth_controller_api.dart';
import 'package:qesma_api/src/api/balance_controller_api.dart';
import 'package:qesma_api/src/api/expense_controller_api.dart';
import 'package:qesma_api/src/api/group_controller_api.dart';
import 'package:qesma_api/src/api/invite_controller_api.dart';
import 'package:qesma_api/src/api/join_controller_api.dart';
import 'package:qesma_api/src/api/join_request_controller_api.dart';
import 'package:qesma_api/src/api/me_controller_api.dart';
import 'package:qesma_api/src/api/member_controller_api.dart';
import 'package:qesma_api/src/api/password_auth_controller_api.dart';
import 'package:qesma_api/src/api/settlement_controller_api.dart';

class QesmaApi {
  static const String basePath = r'http://localhost';

  final Dio dio;
  final Serializers serializers;

  QesmaApi({
    Dio? dio,
    Serializers? serializers,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : this.serializers = serializers ?? standardSerializers,
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AuthControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthControllerApi getAuthControllerApi() {
    return AuthControllerApi(dio, serializers);
  }

  /// Get BalanceControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BalanceControllerApi getBalanceControllerApi() {
    return BalanceControllerApi(dio, serializers);
  }

  /// Get ExpenseControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ExpenseControllerApi getExpenseControllerApi() {
    return ExpenseControllerApi(dio, serializers);
  }

  /// Get GroupControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  GroupControllerApi getGroupControllerApi() {
    return GroupControllerApi(dio, serializers);
  }

  /// Get InviteControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  InviteControllerApi getInviteControllerApi() {
    return InviteControllerApi(dio, serializers);
  }

  /// Get JoinControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  JoinControllerApi getJoinControllerApi() {
    return JoinControllerApi(dio, serializers);
  }

  /// Get JoinRequestControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  JoinRequestControllerApi getJoinRequestControllerApi() {
    return JoinRequestControllerApi(dio, serializers);
  }

  /// Get MeControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MeControllerApi getMeControllerApi() {
    return MeControllerApi(dio, serializers);
  }

  /// Get MemberControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MemberControllerApi getMemberControllerApi() {
    return MemberControllerApi(dio, serializers);
  }

  /// Get PasswordAuthControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PasswordAuthControllerApi getPasswordAuthControllerApi() {
    return PasswordAuthControllerApi(dio, serializers);
  }

  /// Get SettlementControllerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SettlementControllerApi getSettlementControllerApi() {
    return SettlementControllerApi(dio, serializers);
  }
}
