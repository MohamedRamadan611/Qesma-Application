package app.qesma.service;

import app.qesma.domain.RefreshToken;
import app.qesma.persistence.RefreshTokenRepository;
import app.qesma.security.AuthProperties;
import app.qesma.security.RefreshTokens;
import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Rotating refresh tokens. Each login starts a "family"; every use replaces the token with a new one in the
 * same family. Presenting an already-rotated token means it leaked or was replayed: the whole family is revoked.
 */
@Service
public class RefreshTokenService {

    public enum Outcome { ROTATED, UNKNOWN, EXPIRED, REVOKED, REUSED }

    /** {@code userId} is known for every outcome except UNKNOWN; {@code newRawToken} only for ROTATED. */
    public record Rotation(Outcome outcome, UUID userId, String newRawToken) {
    }

    private final RefreshTokenRepository tokens;
    private final AuthProperties props;
    private final Clock clock;

    public RefreshTokenService(RefreshTokenRepository tokens, AuthProperties props, Clock clock) {
        this.tokens = tokens;
        this.props = props;
        this.clock = clock;
    }

    /** Starts a new login session and returns its first raw token (shown once, never stored). */
    @Transactional
    public String issueNewFamily(UUID userId) {
        return insert(userId, UUID.randomUUID(), clock.instant()).raw();
    }

    /**
     * Exchanges a refresh token for a new one. Failures are returned, not thrown, so that the family
     * revocation done on reuse commits instead of rolling back with an exception.
     */
    @Transactional
    public Rotation rotate(String rawToken) {
        Instant now = clock.instant();
        Optional<RefreshToken> found = tokens.findByTokenHashForUpdate(RefreshTokens.hash(rawToken));
        if (found.isEmpty()) {
            return new Rotation(Outcome.UNKNOWN, null, null);
        }
        RefreshToken old = found.get();
        if (old.getRevokedAt() != null) {
            if (old.getReplacedById() != null) { // already rotated once: replay or leak
                tokens.revokeFamily(old.getFamilyId(), now);
                return new Rotation(Outcome.REUSED, old.getUserId(), null);
            }
            return new Rotation(Outcome.REVOKED, old.getUserId(), null); // logged out or family already killed
        }
        if (!old.getExpiresAt().isAfter(now)) {
            return new Rotation(Outcome.EXPIRED, old.getUserId(), null);
        }
        Inserted next = insert(old.getUserId(), old.getFamilyId(), now);
        old.rotateTo(next.id(), now);
        return new Rotation(Outcome.ROTATED, old.getUserId(), next.raw());
    }

    /** Ends the login session the token belongs to. Idempotent; unknown tokens are silently ignored. */
    @Transactional
    public void revokeFamilyOf(String rawToken) {
        tokens.findByTokenHashForUpdate(RefreshTokens.hash(rawToken))
                .ifPresent(t -> tokens.revokeFamily(t.getFamilyId(), clock.instant()));
    }

    private Inserted insert(UUID userId, UUID familyId, Instant now) {
        String raw = RefreshTokens.generate();
        UUID id = UUID.randomUUID();
        tokens.save(new RefreshToken(id, userId, familyId, RefreshTokens.hash(raw), now,
                now.plus(props.refreshTokenTtl())));
        return new Inserted(id, raw);
    }

    private record Inserted(UUID id, String raw) {
    }
}
