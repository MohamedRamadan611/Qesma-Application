package app.qesma.security;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.DelegatingPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * One-way, salted password hashing (BCrypt through Spring Security's own implementation, no extra dependency).
 * The stored value starts with {@code {bcrypt}}, so the algorithm can be replaced later without a migration:
 * old hashes keep verifying under their own id.
 */
@Component
public class PasswordHasher {

    private final PasswordEncoder encoder;
    private final String dummyHash;

    public PasswordHasher(AuthProperties props) {
        this.encoder = new DelegatingPasswordEncoder("bcrypt",
                Map.of("bcrypt", new BCryptPasswordEncoder(props.password().bcryptCost())));
        // Compared against when the account does not exist, so an unknown email costs the same time as a wrong password.
        this.dummyHash = encoder.encode("dummy-password-for-timing-only");
    }

    public String hash(String rawPassword) {
        return encoder.encode(rawPassword);
    }

    public boolean matches(String rawPassword, String storedHash) {
        if (rawPassword == null || rawPassword.getBytes(StandardCharsets.UTF_8).length > PasswordPolicy.MAX_BYTES) {
            return false; // BCrypt cannot read more than 72 bytes; such a password was never accepted
        }
        try {
            return encoder.matches(rawPassword, storedHash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /** Burns the same time as a real check; the result is always "no". */
    public void spendTime(String rawPassword) {
        matches(rawPassword, dummyHash);
    }
}
