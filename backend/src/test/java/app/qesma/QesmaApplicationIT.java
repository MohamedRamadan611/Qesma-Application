package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** Smoke test against a real PostgreSQL (Testcontainers): context, Flyway, health, error shape. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
class QesmaApplicationIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16.6-alpine");

    @Autowired
    TestRestTemplate rest;

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    ObjectMapper mapper;

    @Test
    void flywayAppliedBaseline() {
        Integer applied = jdbc.queryForObject(
                "SELECT count(*) FROM flyway_schema_history WHERE version = '1' AND success", Integer.class);
        assertThat(applied).isEqualTo(1);
    }

    @Test
    void healthIsUpWithDatabaseCheckAndRequestIdHeader() throws Exception {
        ResponseEntity<String> res = rest.getForEntity("/actuator/health", String.class);

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode body = mapper.readTree(res.getBody());
        assertThat(body.get("status").asText()).isEqualTo("UP");
        assertThat(res.getHeaders().getFirst("X-Request-Id")).isNotBlank();
    }

    @Test
    void unauthenticatedRequestGetsProblemJsonWithoutStackTrace() throws Exception {
        ResponseEntity<String> res = rest.getForEntity("/api/v1/anything", String.class);

        assertThat(res.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(res.getHeaders().getContentType()).isEqualTo(MediaType.APPLICATION_PROBLEM_JSON);
        JsonNode body = mapper.readTree(res.getBody());
        assertThat(body.get("code").asText()).isEqualTo("UNAUTHORIZED");
        assertThat(res.getBody()).doesNotContain("Exception").doesNotContain("\tat ");
    }

    @Test
    void inboundRequestIdIsEchoedAndUnsafeOneIsReplaced() {
        var headers = new org.springframework.http.HttpHeaders();
        headers.set("X-Request-Id", "abc-123");
        ResponseEntity<String> ok = rest.exchange("/actuator/health", org.springframework.http.HttpMethod.GET,
                new org.springframework.http.HttpEntity<>(headers), String.class);
        assertThat(ok.getHeaders().getFirst("X-Request-Id")).isEqualTo("abc-123");

        headers.set("X-Request-Id", "bad id with spaces");
        ResponseEntity<String> replaced = rest.exchange("/actuator/health", org.springframework.http.HttpMethod.GET,
                new org.springframework.http.HttpEntity<>(headers), String.class);
        assertThat(replaced.getHeaders().getFirst("X-Request-Id")).isNotEqualTo("bad id with spaces").isNotBlank();
    }
}
