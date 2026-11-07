package app.qesma.service;

import app.qesma.persistence.IdempotencyKeyStore;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Deletes idempotency keys older than the TTL (spec 8.3). Correctness never depends on this job: reads already
 * ignore expired keys. It only keeps the table small. Safe to run on several instances (a plain DELETE).
 */
@Component
public class IdempotencyCleanupJob {

    private static final Logger log = LoggerFactory.getLogger(IdempotencyCleanupJob.class);

    private final IdempotencyKeyStore store;
    private final IdempotencyProperties props;
    private final Clock clock;

    public IdempotencyCleanupJob(IdempotencyKeyStore store, IdempotencyProperties props, Clock clock) {
        this.store = store;
        this.props = props;
        this.clock = clock;
    }

    @Scheduled(initialDelayString = "${qesma.idempotency.cleanup-initial-delay:PT5M}",
            fixedDelayString = "${qesma.idempotency.cleanup-interval:PT1H}")
    public void scheduled() {
        runOnce();
    }

    /** One cleanup pass; returns how many keys were removed. Public so tests can call it directly. */
    @Transactional
    public int runOnce() {
        long started = System.nanoTime();
        int deleted = store.deleteOlderThan(clock.instant().minus(props.ttl()));
        long millis = (System.nanoTime() - started) / 1_000_000;
        log.atInfo().addKeyValue("event", "idempotency.cleanup").addKeyValue("deleted", deleted)
                .addKeyValue("millis", millis).log("idempotency.cleanup deleted={} millis={}", deleted, millis);
        return deleted;
    }
}
