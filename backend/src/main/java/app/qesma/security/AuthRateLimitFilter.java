package app.qesma.security;

import app.qesma.api.ErrorCode;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Fixed-window, per-client-IP limiter for {@code /api/v1/auth/**}.
 *
 * <p>Limitations (accepted for one instance in Phase 1): state is in memory, so it resets on restart and is
 * not shared between instances; behind a reverse proxy the proxy must supply the real client address
 * (forwarded headers) or all clients share one bucket.
 */
public class AuthRateLimitFilter extends OncePerRequestFilter {

    static final String PROTECTED_PREFIX = "/api/v1/auth/";
    private static final int EVICTION_THRESHOLD = 10_000;
    private static final Logger log = LoggerFactory.getLogger(AuthRateLimitFilter.class);

    private final int maxRequests;
    private final long windowMillis;
    private final Clock clock;
    private final ProblemJsonWriter problems;
    private final MeterRegistry metrics;
    private final Map<String, Window> windows = new ConcurrentHashMap<>();

    public AuthRateLimitFilter(AuthProperties.RateLimit limit, Clock clock, ProblemJsonWriter problems,
                               MeterRegistry metrics) {
        this.maxRequests = limit.maxRequests();
        this.windowMillis = limit.window().toMillis();
        this.clock = clock;
        this.problems = problems;
        this.metrics = metrics;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith(PROTECTED_PREFIX);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        long now = clock.millis();
        if (windows.size() > EVICTION_THRESHOLD) {
            windows.values().removeIf(w -> now - w.startMillis >= windowMillis);
        }
        Window window = windows.compute(request.getRemoteAddr(), (ip, current) ->
                current == null || now - current.startMillis >= windowMillis
                        ? new Window(now, 1)
                        : new Window(current.startMillis, current.count + 1));
        if (window.count > maxRequests) {
            long retryAfterSeconds = Math.max(1, Duration.ofMillis(window.startMillis + windowMillis - now).toSeconds());
            metrics.counter("qesma.auth.rate_limited").increment();
            log.atWarn().addKeyValue("event", "auth.rate_limited").log("auth.rate_limited");
            response.setHeader("Retry-After", Long.toString(retryAfterSeconds));
            problems.write(response, HttpStatus.TOO_MANY_REQUESTS, ErrorCode.RATE_LIMITED, "Too many requests");
            return;
        }
        chain.doFilter(request, response);
    }

    private record Window(long startMillis, int count) {
    }
}
