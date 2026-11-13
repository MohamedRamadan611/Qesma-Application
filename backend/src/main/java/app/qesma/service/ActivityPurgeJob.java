package app.qesma.service;

import app.qesma.persistence.GroupEventStore;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Deletes events older than the retention (their notifications cascade), in chunks so no single statement or
 * transaction grows large (A103). Correctness never depends on it; a failed run is retried at the next interval and
 * it is safe on several instances (plain deletes). Each chunk is its own short transaction (autocommit).
 */
@Component
public class ActivityPurgeJob {

    static final int CHUNK = 5_000;

    private static final Logger log = LoggerFactory.getLogger(ActivityPurgeJob.class);

    private final GroupEventStore events;
    private final ActivityProperties props;
    private final Clock clock;

    public ActivityPurgeJob(GroupEventStore events, ActivityProperties props, Clock clock) {
        this.events = events;
        this.props = props;
        this.clock = clock;
    }

    @Scheduled(initialDelayString = "${qesma.activity.purge-initial-delay:PT10M}",
            fixedDelayString = "${qesma.activity.purge-interval:PT6H}")
    public void scheduled() {
        runOnce();
    }

    /** One purge pass; returns how many events were removed. Public so tests can call it directly. */
    public int runOnce() {
        long started = System.nanoTime();
        var cutoff = clock.instant().minus(props.retention());
        int total = 0;
        int deleted;
        do {
            deleted = events.deleteOlderThan(cutoff, CHUNK);
            total += deleted;
        } while (deleted == CHUNK);
        long millis = (System.nanoTime() - started) / 1_000_000;
        log.atInfo().addKeyValue("event", "activity.purge").addKeyValue("deletedEvents", total)
                .addKeyValue("millis", millis)
                .log("activity.purge deletedEvents={} millis={}", total, millis);
        return total;
    }
}
