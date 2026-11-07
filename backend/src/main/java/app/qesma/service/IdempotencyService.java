package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.persistence.IdempotencyKeyStore;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Idempotency for create endpoints (spec 8.3), reusable by any create. Every method must run inside the caller's
 * transaction, so the key row and the business rows commit or roll back together (AGENTS.md invariant 6).
 *
 * <p>Protocol, in the caller's transaction: {@link #lock} first; then {@link #findReplay}; if it returns a stored
 * response, return it and write nothing; otherwise do the business write and finish with {@link #store}.
 * Only successful responses are stored, so a failed request can be retried with the same key.
 */
@Service
public class IdempotencyService {

    private static final Logger log = LoggerFactory.getLogger(IdempotencyService.class);

    /** What the endpoint answers: HTTP status and JSON body, whether fresh or replayed. */
    public record Outcome(int status, String body, boolean replayed) {
    }

    private final IdempotencyKeyStore store;
    private final IdempotencyProperties props;
    private final Clock clock;
    private final MeterRegistry metrics;

    public IdempotencyService(IdempotencyKeyStore store, IdempotencyProperties props, Clock clock,
                              MeterRegistry metrics) {
        this.store = store;
        this.props = props;
        this.clock = clock;
        this.metrics = metrics;
    }

    /** Serializes concurrent requests that carry the same key (released at commit/rollback). */
    @Transactional(propagation = Propagation.MANDATORY)
    public void lock(UUID userId, String key) {
        store.lock(userId, key);
    }

    /**
     * Same key and same request: the stored response. Same key and a different request (body, group or
     * endpoint): IDEMPOTENCY_KEY_REUSED. An expired key (older than the TTL) counts as never seen.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public Optional<Outcome> findReplay(UUID userId, String key, String endpoint, String requestHash) {
        Instant cutoff = clock.instant().minus(props.ttl());
        store.deleteIfOlderThan(userId, key, cutoff);
        Optional<IdempotencyKeyStore.StoredKey> stored = store.find(userId, key);
        if (stored.isEmpty()) {
            metrics.counter("qesma.idempotency", "result", "new").increment();
            return Optional.empty();
        }
        IdempotencyKeyStore.StoredKey row = stored.get();
        if (!row.requestHash().equals(requestHash) || !row.endpoint().equals(endpoint)) {
            metrics.counter("qesma.idempotency", "result", "reused").increment();
            log.atWarn().addKeyValue("event", "idempotency.key_reused").addKeyValue("userId", userId)
                    .log("idempotency.key_reused userId={}", userId);
            throw new ApiException(ErrorCode.IDEMPOTENCY_KEY_REUSED, HttpStatus.UNPROCESSABLE_ENTITY,
                    "This Idempotency-Key was already used with a different request");
        }
        metrics.counter("qesma.idempotency", "result", "replay").increment();
        return Optional.of(new Outcome(row.responseStatus(), row.responseBody(), true));
    }

    /** Records the successful response under the key. Call last, inside the same transaction as the write. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void store(UUID userId, String key, String endpoint, String requestHash, int status, String body) {
        store.insert(userId, key, endpoint, requestHash, status, body, clock.instant());
    }
}
