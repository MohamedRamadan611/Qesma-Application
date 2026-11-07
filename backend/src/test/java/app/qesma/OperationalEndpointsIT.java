package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.jdbc.DataSourceHealthIndicator;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalManagementPort;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

/**
 * What an operator and a client see on the wire, against a real server: probes and metrics on the internal management
 * port only, readiness that really depends on the database, RED metrics per endpoint, request ids, security headers,
 * no CORS and no server banner. The management settings below mirror application-prod.yml.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {
        "management.server.port=0",
        "management.endpoints.web.exposure.include=health,info,metrics",
        "management.metrics.distribution.percentiles-histogram.http.server.requests=true"})
class OperationalEndpointsIT extends AbstractIntegrationTest {

    @LocalServerPort int port;
    @LocalManagementPort int managementPort;
    @MockitoBean(name = "dbHealthIndicator") DataSourceHealthIndicator database;

    @Value("${spring.application.name}") String application;

    private final HttpClient http = HttpClient.newHttpClient();
    private final ObjectMapper json = new ObjectMapper();

    private void up() {
        when(database.health()).thenReturn(Health.up().build());
        when(database.getHealth(anyBoolean())).thenReturn(Health.up().build());
    }

    private void down() {
        when(database.health()).thenReturn(Health.down().build());
        when(database.getHealth(anyBoolean())).thenReturn(Health.down().build());
    }

    private HttpResponse<String> send(HttpRequest request) throws Exception {
        return http.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> get(int onPort, String path, String... headers) throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder(URI.create("http://localhost:" + onPort + path)).GET();
        for (int i = 0; i + 1 < headers.length; i += 2) {
            b.header(headers[i], headers[i + 1]);
        }
        return send(b.build());
    }

    private HttpResponse<String> postJson(String path, String body, String... headers) throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body));
        for (int i = 0; i + 1 < headers.length; i += 2) {
            b.header(headers[i], headers[i + 1]);
        }
        return send(b.build());
    }

    @Test
    void probesAndMetricsLiveOnTheManagementPortOnly() throws Exception {
        up();

        assertThat(get(managementPort, "/actuator/health/liveness").statusCode()).isEqualTo(200);
        HttpResponse<String> readiness = get(managementPort, "/actuator/health/readiness");
        assertThat(readiness.statusCode()).isEqualTo(200);
        assertThat(json.readTree(readiness.body()).get("status").asText()).isEqualTo("UP");
        assertThat(get(managementPort, "/actuator/metrics").statusCode()).isEqualTo(200);

        // the public port serves the API only: no actuator endpoints, not even for an authenticated caller
        assertThat(get(port, "/actuator/metrics").statusCode()).isIn(401, 404);
        assertThat(get(port, "/actuator/health/readiness").statusCode()).isIn(401, 404);
    }

    @Test
    void readinessGoesDownWhenTheDatabaseIsUnhealthyAndLivenessStaysUp() throws Exception {
        down();

        HttpResponse<String> readiness = get(managementPort, "/actuator/health/readiness");
        assertThat(readiness.statusCode()).isEqualTo(503);
        assertThat(json.readTree(readiness.body()).get("status").asText()).isEqualTo("DOWN");
        assertThat(get(managementPort, "/actuator/health/liveness").statusCode()).isEqualTo(200);
    }

    @Test
    void everyEndpointIsMeasuredWithRateErrorsAndDurationByUriTemplate() throws Exception {
        up();
        postJson("/api/v1/auth/google", "{\"idToken\":\"fake:red:red@example.com:Red\"}");
        postJson("/api/v1/auth/google", "{\"idToken\":\"garbage\"}");              // a 401 for the error rate
        get(port, "/api/v1/groups/00000000-0000-0000-0000-000000000001/balances"); // 401 without a token

        JsonNode metric = json.readTree(get(managementPort, "/actuator/metrics/http.server.requests").body());
        assertThat(metric.get("name").asText()).isEqualTo("http.server.requests");
        assertThat(metric.toString()).contains("COUNT").contains("TOTAL_TIME").contains("MAX");
        JsonNode uriTag = null;
        for (JsonNode tag : metric.get("availableTags")) {
            if (tag.get("tag").asText().equals("uri")) {
                uriTag = tag;
            }
        }
        assertThat(uriTag).isNotNull();
        assertThat(uriTag.get("values").toString()).contains("/api/v1/auth/google");     // a template, not raw ids
        String errors = get(managementPort, "/actuator/metrics/http.server.requests?tag=status:401").body();
        assertThat(json.readTree(errors).get("measurements").get(0).get("value").asDouble()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void everyResponseCarriesARequestIdAndASafeInboundOneIsEchoed() throws Exception {
        HttpResponse<String> generated = postJson("/api/v1/auth/google", "{\"idToken\":\"nope\"}");
        assertThat(generated.headers().firstValue("X-Request-Id")).isPresent();
        HttpResponse<String> echoed = postJson("/api/v1/auth/google", "{\"idToken\":\"nope\"}",
                "X-Request-Id", "client-req-123");
        assertThat(echoed.headers().firstValue("X-Request-Id")).hasValue("client-req-123");
        assertThat(json.readTree(echoed.body()).get("requestId").asText()).isEqualTo("client-req-123");
        HttpResponse<String> unsafe = postJson("/api/v1/auth/google", "{\"idToken\":\"nope\"}",
                "X-Request-Id", "bad id with spaces <script>");
        assertThat(unsafe.headers().firstValue("X-Request-Id").orElseThrow()).doesNotContain("script");
    }

    @Test
    void responsesCarrySecurityHeadersAndNothingAdvertisesTheServerOrAllowsOtherOrigins() throws Exception {
        HttpResponse<String> unauthorized = get(port, "/api/v1/groups");
        assertThat(unauthorized.headers().firstValue("X-Content-Type-Options")).hasValue("nosniff");
        assertThat(unauthorized.headers().firstValue("Cache-Control").orElse("")).contains("no-store");
        assertThat(unauthorized.headers().firstValue("X-Frame-Options")).isPresent();
        assertThat(unauthorized.headers().firstValue("Server")).as("no server banner").isEmpty();
        assertThat(unauthorized.headers().firstValue("Content-Type").orElse("")).startsWith("application/problem+json");
        assertThat(unauthorized.body()).doesNotContain("Exception").doesNotContain("at app.qesma");

        HttpResponse<String> cors = get(port, "/api/v1/groups", "Origin", "https://evil.example");
        assertThat(cors.headers().firstValue("Access-Control-Allow-Origin")).isEmpty();
        HttpResponse<String> preflight = send(HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1/groups"))
                .header("Origin", "https://evil.example").header("Access-Control-Request-Method", "POST")
                .method("OPTIONS", HttpRequest.BodyPublishers.noBody()).build());
        assertThat(preflight.headers().firstValue("Access-Control-Allow-Origin")).isEmpty();
    }
}
