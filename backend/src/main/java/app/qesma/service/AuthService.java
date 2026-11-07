package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.User;
import app.qesma.security.AccessTokenService;
import app.qesma.security.GoogleIdTokenVerifier;
import app.qesma.security.GoogleIdTokenVerifier.AuthProviderUnavailableException;
import app.qesma.security.GoogleIdTokenVerifier.InvalidIdTokenException;
import app.qesma.security.GoogleIdentity;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

/**
 * Sign-in orchestration. Deliberately not transactional itself: the network call to Google must not hold a
 * database connection, and each database step is its own short transaction in the services it calls.
 * Logs and metrics carry user ids only, never tokens, emails or names.
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    public record Login(String accessToken, String refreshToken, User user) {
    }

    public record Refreshed(String accessToken, String refreshToken) {
    }

    private final GoogleIdTokenVerifier verifier;
    private final UserService users;
    private final RefreshTokenService refreshTokens;
    private final AccessTokenService accessTokens;
    private final MeterRegistry metrics;

    public AuthService(GoogleIdTokenVerifier verifier, UserService users, RefreshTokenService refreshTokens,
                       AccessTokenService accessTokens, MeterRegistry metrics) {
        this.verifier = verifier;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.accessTokens = accessTokens;
        this.metrics = metrics;
    }

    public Login loginWithGoogle(String idToken) {
        GoogleIdentity identity;
        try {
            identity = verifier.verify(idToken);
        } catch (InvalidIdTokenException e) {
            metrics.counter("qesma.auth.login", "result", "invalid_token").increment();
            log.atInfo().addKeyValue("event", "auth.login.failed").addKeyValue("reason", "invalid_token")
                    .log("auth.login.failed reason=invalid_token");
            throw ApiException.unauthorized();
        } catch (AuthProviderUnavailableException e) {
            metrics.counter("qesma.auth.login", "result", "provider_unavailable").increment();
            // Only the exception type: its message could echo upstream details.
            log.atWarn().addKeyValue("event", "auth.login.failed").addKeyValue("reason", "provider_unavailable")
                    .log("auth.login.failed reason=provider_unavailable cause={}", e.getCause().getClass().getSimpleName());
            throw new ApiException(ErrorCode.AUTH_PROVIDER_UNAVAILABLE, HttpStatus.SERVICE_UNAVAILABLE,
                    "Sign-in is temporarily unavailable");
        }
        User user = users.upsertGoogleUser(identity);
        String refresh = refreshTokens.issueNewFamily(user.getId());
        String access = accessTokens.issue(user.getId());
        metrics.counter("qesma.auth.login", "result", "success").increment();
        log.atInfo().addKeyValue("event", "auth.login").addKeyValue("userId", user.getId())
                .log("auth.login userId={}", user.getId());
        return new Login(access, refresh, user);
    }

    public Refreshed refresh(String rawRefreshToken) {
        RefreshTokenService.Rotation rotation = refreshTokens.rotate(rawRefreshToken);
        if (rotation.outcome() != RefreshTokenService.Outcome.ROTATED) {
            recordRefreshFailure(rotation);
            throw ApiException.unauthorized();
        }
        metrics.counter("qesma.auth.refresh", "result", "success").increment();
        log.atInfo().addKeyValue("event", "auth.refresh").addKeyValue("userId", rotation.userId())
                .log("auth.refresh userId={}", rotation.userId());
        return new Refreshed(accessTokens.issue(rotation.userId()), rotation.newRawToken());
    }

    public void logout(String rawRefreshToken) {
        refreshTokens.revokeFamilyOf(rawRefreshToken);
        metrics.counter("qesma.auth.logout").increment();
        log.atInfo().addKeyValue("event", "auth.logout").log("auth.logout");
    }

    private void recordRefreshFailure(RefreshTokenService.Rotation rotation) {
        String result = rotation.outcome().name().toLowerCase(java.util.Locale.ROOT);
        metrics.counter("qesma.auth.refresh", "result", result).increment();
        UUID userId = rotation.userId();
        if (rotation.outcome() == RefreshTokenService.Outcome.REUSED) {
            metrics.counter("qesma.auth.refresh.reuse").increment();
            log.atWarn().addKeyValue("event", "auth.refresh.reuse_detected").addKeyValue("userId", userId)
                    .log("auth.refresh.reuse_detected userId={} family revoked", userId);
        } else {
            log.atInfo().addKeyValue("event", "auth.refresh.failed").addKeyValue("reason", result)
                    .log("auth.refresh.failed reason={}", result);
        }
    }
}
