import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for PasswordAuthControllerApi
void main() {
  final instance = QesmaApi().getPasswordAuthControllerApi();

  group(PasswordAuthControllerApi, () {
    //Future forgotPassword(ForgotPasswordRequest forgotPasswordRequest) async
    test('test forgotPassword', () async {
      // TODO
    });

    //Future<AuthResponse> registerWithPassword(RegisterRequest registerRequest) async
    test('test registerWithPassword', () async {
      // TODO
    });

    //Future resendEmailVerification() async
    test('test resendEmailVerification', () async {
      // TODO
    });

    //Future resetPassword(ResetPasswordRequest resetPasswordRequest) async
    test('test resetPassword', () async {
      // TODO
    });

    //Future<AuthResponse> signInWithPassword(LoginRequest loginRequest) async
    test('test signInWithPassword', () async {
      // TODO
    });

    //Future verifyEmail(VerifyEmailRequest verifyEmailRequest) async
    test('test verifyEmail', () async {
      // TODO
    });

  });
}
