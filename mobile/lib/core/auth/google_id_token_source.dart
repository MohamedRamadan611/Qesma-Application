import 'package:google_sign_in/google_sign_in.dart';

/// Why getting a Google ID token failed. Never carries the plugin's own message: it can
/// contain account details, and the user does not need it.
enum GoogleFailureKind {
  /// The user closed the Google account picker. Not an error to show.
  cancelled,

  /// `GOOGLE_SERVER_CLIENT_ID` is missing or the Google Cloud setup is wrong.
  notConfigured,

  /// Google Play services or the account UI is unavailable right now.
  unavailable,

  /// Anything else.
  failed,
}

class GoogleSignInFailure implements Exception {
  const GoogleSignInFailure(this.kind);

  final GoogleFailureKind kind;

  @override
  String toString() => 'GoogleSignInFailure(${kind.name})';
}

/// Source of the Google ID token that `POST /auth/google` exchanges for a session.
/// Behind an interface so tests and the debug fake sign-in do not need the plugin.
abstract interface class GoogleIdTokenSource {
  /// Shows Google's account picker and returns the ID token.
  /// Throws [GoogleSignInFailure].
  Future<String> signIn();

  /// Forgets the Google account on this device (best effort, never throws), so the next
  /// sign-in shows the account picker again.
  Future<void> signOut();
}

/// google_sign_in 7.x (Credential Manager on Android).
///
/// The ID token's audience is [serverClientId], the **Web** OAuth client id, which must be
/// listed in the backend's `GOOGLE_CLIENT_IDS`. Pass it with
/// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
class PlayGoogleIdTokenSource implements GoogleIdTokenSource {
  PlayGoogleIdTokenSource({this._serverClientId = const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')});

  final String _serverClientId;
  Future<void>? _initialized;

  /// `initialize` must be called and awaited exactly once before any other call.
  Future<void> _ensureInitialized() {
    if (_serverClientId.isEmpty) throw const GoogleSignInFailure(GoogleFailureKind.notConfigured);
    return _initialized ??= GoogleSignIn.instance.initialize(serverClientId: _serverClientId).catchError((Object _) {
      _initialized = null; // allow a retry
      throw const GoogleSignInFailure(GoogleFailureKind.failed);
    });
  }

  @override
  Future<String> signIn() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleSignInFailure(GoogleFailureKind.unavailable);
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      // Never interpolate or log the authentication object: its toString prints the token.
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) throw const GoogleSignInFailure(GoogleFailureKind.failed);
      return idToken;
    } on GoogleSignInFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw GoogleSignInFailure(switch (e.code) {
        GoogleSignInExceptionCode.canceled => GoogleFailureKind.cancelled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          GoogleFailureKind.notConfigured,
        GoogleSignInExceptionCode.interrupted || GoogleSignInExceptionCode.uiUnavailable => GoogleFailureKind.unavailable,
        _ => GoogleFailureKind.failed,
      });
    } catch (_) {
      // PlatformException or anything else from the plugin: a generic failure, never a stuck spinner.
      throw const GoogleSignInFailure(GoogleFailureKind.failed);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_serverClientId.isEmpty) return;
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best effort.
    }
  }
}
