package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Base64;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Refresh-token primitives and JWT secret validation (startup fail-fast). */
class TokenPrimitivesTest {

    @Test
    void refreshTokensAreUnguessableUrlSafeAndUnique() {
        Set<String> seen = new HashSet<>();
        for (int i = 0; i < 1000; i++) {
            String token = RefreshTokens.generate();
            assertThat(token).hasSize(43).matches("[A-Za-z0-9_-]+");
            assertThat(Base64.getUrlDecoder().decode(token)).hasSize(32); // 256 bits
            seen.add(token);
        }
        assertThat(seen).hasSize(1000);
    }

    @Test
    void hashIsDeterministicSha256() {
        byte[] a = RefreshTokens.hash("abc");
        assertThat(a).hasSize(32).isEqualTo(RefreshTokens.hash("abc")).isNotEqualTo(RefreshTokens.hash("abd"));
        // Known SHA-256("abc") prefix: ba7816bf
        assertThat(a[0] & 0xff).isEqualTo(0xba);
        assertThat(a[1] & 0xff).isEqualTo(0x78);
    }

    @Test
    void jwtSecretMustBeBase64OfAtLeast32Bytes() {
        String ok = Base64.getEncoder().encodeToString(new byte[32]);
        assertThat(JwtKeys.fromBase64(ok).getEncoded()).hasSize(32);

        assertThatThrownBy(() -> JwtKeys.fromBase64(Base64.getEncoder().encodeToString(new byte[31])))
                .isInstanceOf(IllegalStateException.class).hasMessageContaining("at least 32 bytes");
        assertThatThrownBy(() -> JwtKeys.fromBase64("***not base64***")).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> JwtKeys.fromBase64(" ")).isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> JwtKeys.fromBase64(null)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void errorMessagesNeverEchoTheSecret() {
        String secret = Base64.getEncoder().encodeToString("short".getBytes());
        assertThatThrownBy(() -> JwtKeys.fromBase64(secret)).hasMessageNotContaining(secret);
    }
}
