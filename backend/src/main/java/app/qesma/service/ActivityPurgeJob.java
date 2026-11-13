package app.qesma.service;

import app.qesma.persistence.GroupEventStore;
import app.qesma.persistence.RemindLogStore;
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
    static final java.time.Duration REMIND_MIN_RETENTION = java.time.Duration.ofDays(7);

    private static final Logger log = LoggerFactory.getLogger(ActivityPurgeJob.class);

    private final GroupEventStore events;
    private final RemindLogStore remindLog;
    private final RemindProperties remindProps;
    private final ActivityProperties props;
    private final Clock clock;

    public ActivityPurgeJob(GroupEventStore events, RemindLogStore remindLog, RemindProperties remindProps,
                            ActivityProperties props, Clock clock) {
        this.remindLog = remindLog;
        this.remindProps = remindProps;
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
        // B16: the Remind log only matters within its window; keep at least 7 days for support
        java.time.Duration remindKeep = remindProps.window().compareTo(REMIND_MIN_RETENTION) > 0 ? remindProps.window()
                : REMIND_MIN_RETENTION;
        int reminders = remindLog.purgeOlderThan(clock.instant().minus(remindKeep));
        long millis = (System.nanoTime() - started) / 1_000_000;
        log.atInfo().addKeyValue("event", "activity.purge").addKeyValue("deletedEvents", total)
                .addKeyValue("deletedReminders", reminders).addKeyValue("millis", millis)
                .log("activity.purge deletedEvents={} deletedReminders={} millis={}", total, reminders, millis);
        return total;
    }
}
