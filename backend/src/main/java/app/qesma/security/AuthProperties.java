package app.qesma.security;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Authentication settings ({@code qesma.auth.*}). Secrets come from the environment only.
 *
 * @param jwtSecret       base64 of at least 32 random bytes (HS256 key for our access tokens)
 * @param googleClientIds accepted OAuth client ids (the {@code aud} of Google ID tokens)
 */
@ConfigurationProperties("qesma.auth")
public record AuthProperties(
        String jwtSecret,
        @DefaultValue List<String> googleClientIds,
        @DefaultValue("15m") Duration accessTokenTtl,
        @DefaultValue("30d") Duration refreshTokenTtl,
        @DefaultValue("https://www.googleapis.com/oauth2/v3/certs") String googleJwkSetUri,
        @DefaultValue RateLimit rateLimit) {

    /** In-memory limiter for {@code /api/v1/auth/**}: at most {@code maxRequests} per client IP per window. */
    public record RateLimit(@DefaultValue("10") int maxRequests, @DefaultValue("1m") Duration window) {
    }
}
