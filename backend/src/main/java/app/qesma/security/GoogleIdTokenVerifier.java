package app.qesma.security;

/** Verifies a Google ID token. An interface so tests and the local profile can use a fake. */
public interface GoogleIdTokenVerifier {

    /**
     * @throws InvalidIdTokenException           the token is not acceptable (the reason is deliberately not exposed)
     * @throws AuthProviderUnavailableException  Google's signing keys could not be retrieved
     */
    GoogleIdentity verify(String idToken);

    /** The token failed verification. Carries no detail so nothing can leak to a client. */
    class InvalidIdTokenException extends RuntimeException {
        private static final long serialVersionUID = 1L;

        public InvalidIdTokenException() {
            super("Invalid ID token", null, false, false);
        }
    }

    /** Google could not be reached to fetch signing keys; not the caller's fault. */
    class AuthProviderUnavailableException extends RuntimeException {
        private static final long serialVersionUID = 1L;

        public AuthProviderUnavailableException(Throwable cause) {
            super("Identity provider unavailable", cause);
        }
    }
}
