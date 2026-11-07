package app.qesma.security;

import java.util.Base64;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

/** Builds the HS256 signing key from configuration and rejects weak or malformed secrets at startup. */
public final class JwtKeys {

    /** 256 bits, the minimum for HS256. */
    public static final int MIN_SECRET_BYTES = 32;

    private JwtKeys() {
    }

    public static SecretKey fromBase64(String base64Secret) {
        if (base64Secret == null || base64Secret.isBlank()) {
            throw new IllegalStateException("qesma.auth.jwt-secret (QESMA_JWT_SECRET) is not set");
        }
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(base64Secret.trim());
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("qesma.auth.jwt-secret must be base64 (e.g. openssl rand -base64 32)");
        }
        if (bytes.length < MIN_SECRET_BYTES) {
            throw new IllegalStateException(
                    "qesma.auth.jwt-secret must decode to at least " + MIN_SECRET_BYTES + " bytes");
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }
}
