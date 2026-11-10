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
 * @param password        email + password sign-in settings (ADR-007)
 */
@ConfigurationProperties("qesma.auth")
public record AuthProperties(
        String jwtSecret,
        @DefaultValue List<String> googleClientIds,
        @DefaultValue("15m") Duration accessTokenTtl,
        @DefaultValue("30d") Duration refreshTokenTtl,
        @DefaultValue("https://www.googleapis.com/oauth2/v3/certs") String googleJwkSetUri,
        @DefaultValue RateLimit rateLimit,
        @DefaultValue Password password) {

    /**
     * Email + password sign-in. {@code bcryptCost} is the work factor of the hash; {@code lockoutThreshold} consecutive
     * failures lock one account for {@code lockoutDuration}; the emailed links expire after the given times;
     * {@code publicBaseUrl} is the start of the links in those emails.
     */
    public record Password(
            @DefaultValue("12") int bcryptCost,
            @DefaultValue("5") int lockoutThreshold,
            @DefaultValue("15m") Duration lockoutDuration,
            @DefaultValue("24h") Duration verifyTokenTtl,
            @DefaultValue("30m") Duration resetTokenTtl,
            @DefaultValue("https://qesma.app") String publicBaseUrl) {
    }

    /** In-memory limiter for {@code /api/v1/auth/**}: at most {@code maxRequests} per client IP per window. */
    public record RateLimit(@DefaultValue("10") int maxRequests, @DefaultValue("1m") Duration window) {
    }
}
