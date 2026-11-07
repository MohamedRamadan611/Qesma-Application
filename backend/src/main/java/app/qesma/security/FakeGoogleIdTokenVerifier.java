package app.qesma.security;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * LOCAL AND TEST ONLY (profile {@code fake-auth}). Accepts tokens of the form
 * {@code fake:<subject>:<email>:<name>}; the email and name parts may be empty. Never active with {@code prod}
 * (see {@link FakeAuthProdGuard}).
 */
@Component
@Profile("fake-auth")
public class FakeGoogleIdTokenVerifier implements GoogleIdTokenVerifier {

    @Override
    public GoogleIdentity verify(String idToken) {
        if (idToken == null || !idToken.startsWith("fake:")) {
            throw new InvalidIdTokenException();
        }
        String[] parts = idToken.split(":", 4);
        if (parts.length < 2 || parts[1].isBlank()) {
            throw new InvalidIdTokenException();
        }
        String email = parts.length > 2 && !parts[2].isBlank() ? parts[2] : null;
        String name = parts.length > 3 && !parts[3].isBlank() ? parts[3] : null;
        return new GoogleIdentity(parts[1], email, name);
    }
}
