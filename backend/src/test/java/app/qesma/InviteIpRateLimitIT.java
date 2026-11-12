package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/** B11: the per-IP window on /api/v1/invites/** is its own filter instance next to the auth one. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {"qesma.invites.rate-limit.max-requests=4", "qesma.invites.failed-lookups.max=1000"})
class InviteIpRateLimitIT extends AbstractApiIT {

    @Test
    void theFifthRequestInTheWindowIs429WithRetryAfterAndOtherPathsAreUnaffected() throws Exception {
        Session user = newUser();
        for (int i = 0; i < 4; i++) {
            assertThat(status(call(GET, "/api/v1/invites/ZZZZZZZ" + i, user, null))).isEqualTo(404);
        }
        MvcResult limited = call(GET, "/api/v1/invites/ZZZZZZZ9", user, null);
        assertThat(status(limited)).isEqualTo(429);
        assertThat(limited.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(code(limited)).isEqualTo("RATE_LIMITED");
        assertThat(limited.getResponse().getHeader("Retry-After")).isNotBlank();
        assertThat(status(call(GET, "/api/v1/groups", user, null))).as("other paths are not limited").isEqualTo(200);
        assertThat(status(call(GET, "/api/v1/me", user, null))).isEqualTo(200);
    }
}
