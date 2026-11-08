import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for AuthControllerApi
void main() {
  final instance = QesmaApi().getAuthControllerApi();

  group(AuthControllerApi, () {
    //Future<TokenResponse> refreshSession(RefreshRequest refreshRequest) async
    test('test refreshSession', () async {
      // TODO
    });

    //Future<AuthResponse> signInWithGoogle(GoogleLoginRequest googleLoginRequest) async
    test('test signInWithGoogle', () async {
      // TODO
    });

    //Future signOut(RefreshRequest refreshRequest) async
    test('test signOut', () async {
      // TODO
    });

  });
}
