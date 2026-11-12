package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/** B11: guessing codes is limited per client IP and, for lookups that find nothing, per user. Tiny limits keep it fast. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {"qesma.invites.rate-limit.max-requests=1000", "qesma.invites.failed-lookups.max=3"})
class InviteRateLimitIT extends AbstractApiIT {

    @Test
    void afterThreeFailedLookupsAUserIsLimitedEvenForAValidCodeUntilTheWindowPasses() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Limits " + UUID.randomUUID()).get("id").asText();
        String valid = body(call(POST, "/api/v1/groups/" + gid + "/invites", owner, Map.of(), "Idempotency-Key",
                UUID.randomUUID().toString())).get("code").asText();
        Session scanner = newUser();

        for (int i = 0; i < 3; i++) {
            assertThat(status(call(GET, "/api/v1/invites/ZZZZZZZ" + i, scanner, null))).isEqualTo(404);
        }
        MvcResult limited = call(GET, "/api/v1/invites/" + valid, scanner, null);
        assertThat(status(limited)).isEqualTo(429);
        assertThat(code(limited)).isEqualTo("RATE_LIMITED");
        assertThat(status(call(POST, "/api/v1/invites/" + valid + "/join", scanner, Map.of("newMemberName", "Nope"),
                "Idempotency-Key", UUID.randomUUID().toString()))).as("join is limited too").isEqualTo(429);

        assertThat(status(call(GET, "/api/v1/invites/" + valid, newUser(), null)))
                .as("another user is not affected").isEqualTo(200);
        assertThat(status(call(GET, "/api/v1/invites/" + valid, owner, null)))
                .as("successful lookups are not counted").isEqualTo(200);
    }
}
