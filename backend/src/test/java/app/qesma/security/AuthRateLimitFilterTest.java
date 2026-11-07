package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class AuthRateLimitFilterTest {

    /** Hand-advanced clock so window behaviour is deterministic. */
    static final class MutableClock extends Clock {
        private Instant now = Instant.parse("2026-01-01T00:00:00Z");

        void advance(Duration d) {
            now = now.plus(d);
        }

        @Override
        public java.time.ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    private MutableClock clock;
    private AuthRateLimitFilter filter;

    @BeforeEach
    void setUp() {
        clock = new MutableClock();
        filter = new AuthRateLimitFilter(new AuthProperties.RateLimit(3, Duration.ofMinutes(1)), clock,
                new ProblemJsonWriter(new ObjectMapper()), new SimpleMeterRegistry());
    }

    private MockHttpServletResponse call(String path, String ip) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", path);
        request.setRemoteAddr(ip);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }

    @Test
    void allowsUpToTheLimitThenAnswers429WithRetryAfter() throws Exception {
        for (int i = 0; i < 3; i++) {
            assertThat(call("/api/v1/auth/google", "1.1.1.1").getStatus()).isEqualTo(200);
        }
        MockHttpServletResponse blocked = call("/api/v1/auth/google", "1.1.1.1");
        assertThat(blocked.getStatus()).isEqualTo(429);
        assertThat(blocked.getContentType()).startsWith("application/problem+json");
        assertThat(blocked.getContentAsString()).contains("\"code\":\"RATE_LIMITED\"");
        assertThat(Long.parseLong(blocked.getHeader("Retry-After"))).isBetween(1L, 60L);
    }

    @Test
    void windowResetsAfterItElapses() throws Exception {
        for (int i = 0; i < 4; i++) {
            call("/api/v1/auth/refresh", "1.1.1.1");
        }
        assertThat(call("/api/v1/auth/refresh", "1.1.1.1").getStatus()).isEqualTo(429);
        clock.advance(Duration.ofSeconds(61));
        assertThat(call("/api/v1/auth/refresh", "1.1.1.1").getStatus()).isEqualTo(200);
    }

    @Test
    void clientsAreCountedIndependentlyAndAllAuthPathsShareOneBucket() throws Exception {
        call("/api/v1/auth/google", "1.1.1.1");
        call("/api/v1/auth/refresh", "1.1.1.1");
        call("/api/v1/auth/logout", "1.1.1.1");
        assertThat(call("/api/v1/auth/google", "1.1.1.1").getStatus()).isEqualTo(429);
        assertThat(call("/api/v1/auth/google", "2.2.2.2").getStatus()).isEqualTo(200);
    }

    @Test
    void nonAuthPathsAreNeverLimited() throws Exception {
        for (int i = 0; i < 20; i++) {
            assertThat(call("/api/v1/me", "1.1.1.1").getStatus()).isEqualTo(200);
        }
    }
}
