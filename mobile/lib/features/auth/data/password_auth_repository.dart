import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// The only code that calls the username + password endpoints. Everything it throws is an [ApiFailure].
/// Sign-in and registration use the client without the bearer interceptor (no session exists yet);
/// changing the password is a call of the signed-in user.
class PasswordAuthRepository {
  PasswordAuthRepository(this._authless, this._api);

  final QesmaApi _authless;
  final QesmaApi _api;

  Future<T> _run<T>(Future<T?> Function() call) async {
    try {
      final result = await call();
      if (result == null) throw const ApiUnexpected();
      return result;
    } catch (error) {
      throw mapApiError(error);
    }
  }

  Future<AuthResponse> signIn(String username, String password) => _run(() async {
        final response = await _authless.getPasswordAuthControllerApi().signInWithPassword(
              loginRequest: LoginRequest((b) => b
                ..username = username
                ..password = password),
            );
        return response.data;
      });

  Future<AuthResponse> register(String username, String password, String? displayName) => _run(() async {
        final response = await _authless.getPasswordAuthControllerApi().registerWithPassword(
              registerRequest: RegisterRequest((b) => b
                ..username = username
                ..password = password
                ..displayName = displayName),
            );
        return response.data;
      });

  /// New tokens for this session; the server ended every other one.
  Future<TokenResponse> changePassword(String currentPassword, String newPassword) => _run(() async {
        final response = await _api.getMeControllerApi().changePassword(
              changePasswordRequest: ChangePasswordRequest((b) => b
                ..currentPassword = currentPassword
                ..newPassword = newPassword),
            );
        return response.data;
      });
}

final passwordAuthRepositoryProvider =
    Provider<PasswordAuthRepository>((ref) => PasswordAuthRepository(ref.watch(authlessApiProvider), ref.watch(qesmaApiProvider)));
