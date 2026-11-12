package app.qesma.service;

import app.qesma.api.ApiException;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Caps how many lookups per user may find no usable invite (unknown, expired, revoked) in a window, so one account
 * cannot scan the code space. Fixed window, in memory: it resets on restart and is not shared between instances
 * (the same accepted limits as the auth limiter, Phase 1 runs one instance). The per-IP limit is a servlet filter.
 */
@Component
public class InviteAttemptLimiter {

    private static final int EVICTION_THRESHOLD = 10_000;

    private record Window(long startMillis, int failures) {
    }

    private final int max;
    private final long windowMillis;
    private final Clock clock;
    private final MeterRegistry metrics;
    private final Map<UUID, Window> windows = new ConcurrentHashMap<>();

    public InviteAttemptLimiter(InviteProperties props, Clock clock, MeterRegistry metrics) {
        this.max = props.failedLookups().max();
        this.windowMillis = props.failedLookups().window().toMillis();
        this.clock = clock;
        this.metrics = metrics;
    }

    /** 429 once the user used up their failed lookups in the current window. */
    public void check(UUID userId) {
        Window w = windows.get(userId);
        long now = clock.millis();
        if (w != null && now - w.startMillis() < windowMillis && w.failures() >= max) {
            metrics.counter("qesma.invite.rate_limited", "scope", "user").increment();
            throw ApiException.tooManyRequests("Too many attempts, try again later");
        }
    }

    public void recordFailure(UUID userId) {
        long now = clock.millis();
        if (windows.size() > EVICTION_THRESHOLD) {
            windows.values().removeIf(w -> now - w.startMillis() >= windowMillis);
        }
        windows.compute(userId, (id, w) -> w == null || now - w.startMillis() >= windowMillis
                ? new Window(now, 1) : new Window(w.startMillis(), w.failures() + 1));
    }
}
