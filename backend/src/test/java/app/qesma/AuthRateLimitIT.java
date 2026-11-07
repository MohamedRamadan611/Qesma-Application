package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/** The limiter wired into the real filter chain, with a tiny limit so the test stays fast. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "qesma.auth.rate-limit.max-requests=3")
class AuthRateLimitIT extends AbstractIntegrationTest {

    @Autowired MockMvc mvc;

    @Test
    void fourthAuthRequestInTheWindowIs429WithRetryAfterAndOtherPathsAreUnaffected() throws Exception {
        for (int i = 0; i < 3; i++) {
            MvcResult r = mvc.perform(post("/api/v1/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                    .content("{\"refreshToken\":\"nope\"}")).andReturn();
            assertThat(r.getResponse().getStatus()).isEqualTo(401);
        }
        MvcResult limited = mvc.perform(post("/api/v1/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                .content("{\"refreshToken\":\"nope\"}")).andReturn();

        assertThat(limited.getResponse().getStatus()).isEqualTo(429);
        assertThat(limited.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(limited.getResponse().getContentAsString()).contains("RATE_LIMITED");
        assertThat(limited.getResponse().getHeader("Retry-After")).isNotBlank();

        assertThat(mvc.perform(get("/actuator/health")).andReturn().getResponse().getStatus()).isEqualTo(200);
        assertThat(mvc.perform(get("/api/v1/me")).andReturn().getResponse().getStatus()).isEqualTo(401);
    }
}
