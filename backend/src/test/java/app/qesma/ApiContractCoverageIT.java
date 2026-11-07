package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import app.qesma.api.ErrorCode;
import app.qesma.persistence.IdempotencyKeyStore;
import app.qesma.security.GoogleIdTokenVerifier;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.web.servlet.HandlerMapping;

/**
 * Acceptance criterion 2 (spec 10): contract tests cover every endpoint and every error code. One scripted walk through
 * the whole API; every call is recorded by the route template that served it. The test fails if an operation of the
 * generated OpenAPI document was never answered successfully, or if an error code was never produced by a real
 * response (with the documented status).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {"springdoc.api-docs.enabled=true", "qesma.auth.rate-limit.max-requests=40"})
class ApiContractCoverageIT extends AbstractApiIT {

    @MockitoSpyBean GoogleIdTokenVerifier verifier;
    @MockitoSpyBean IdempotencyKeyStore keyStore;

    /** "METHOD template" of operations that answered 2xx. */
    private final Set<String> succeeded = new TreeSet<>();
    /** code -> statuses seen on real responses. */
    private final Map<String, Set<Integer>> errors = new LinkedHashMap<>();
    /** "METHOD template" -> the 2xx statuses the real responses used. */
    private final Map<String, Set<Integer>> successStatuses = new TreeMap<>();

    private MvcResult hit(HttpMethod method, String url, Session as, Object body, String... headers) throws Exception {
        MvcResult r = call(method, url, as, body, headers);
        String template = (String) r.getRequest().getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        int status = status(r);
        if (status >= 200 && status < 300 && template != null) {
            succeeded.add(method.name() + " " + template);
            successStatuses.computeIfAbsent(method.name() + " " + template, k -> new TreeSet<>()).add(status);
        }
        if (status >= 400 && r.getResponse().getContentType() != null
                && r.getResponse().getContentType().startsWith("application/problem+json")) {
            errors.computeIfAbsent(code(r), c -> new TreeSet<>()).add(status);
        }
        return r;
    }

    private void expect(MvcResult r, int status, ErrorCode code) throws Exception {
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(status);
        assertThat(code(r)).isEqualTo(code.name());
    }

    private static String key() {
        return UUID.randomUUID().toString();
    }

    @Test
    void everyOperationAnswersSuccessfullyAndEveryErrorCodeIsProducedByARealResponse() throws Exception {
        // ---- auth and profile -------------------------------------------------------------------------------
        String sub = "walk-" + UUID.randomUUID();
        MvcResult login = hit(POST, "/api/v1/auth/google", null, Map.of("idToken", "fake:" + sub + ":w@example.com:Walker"));
        assertThat(status(login)).isEqualTo(200);
        Session me = new Session(body(login).get("accessToken").asText(), UUID.fromString(body(login).get("user").get("id").asText()));
        String refresh = body(login).get("refreshToken").asText();
        assertThat(status(hit(GET, "/api/v1/me", me, null))).isEqualTo(200);
        assertThat(status(hit(PATCH, "/api/v1/me", me, Map.of("displayName", "Walker 2")))).isEqualTo(200);
        MvcResult refreshed = hit(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", refresh));
        assertThat(status(refreshed)).isEqualTo(200);
        assertThat(status(hit(POST, "/api/v1/auth/logout", null,
                Map.of("refreshToken", body(refreshed).get("refreshToken").asText())))).isEqualTo(204);

        // ---- groups and members -------------------------------------------------------------------------------
        MvcResult group = hit(POST, "/api/v1/groups", me, Map.of("name", "Walk", "type", "TRIP"));
        assertThat(status(group)).isEqualTo(201);
        String gid = body(group).get("id").asText();
        String ownerMember = body(group).get("members").get(0).get("id").asText();   // B9: the creator is member #1
        String g = "/api/v1/groups/" + gid;
        assertThat(status(hit(GET, "/api/v1/groups", me, null))).isEqualTo(200);
        assertThat(status(hit(GET, g, me, null))).isEqualTo(200);
        MvcResult patched = hit(PATCH, g, me, Map.of("name", "Walk 2"), "If-Match", "\"1\"");
        assertThat(status(patched)).isEqualTo(200);
        String a = body(hit(POST, g + "/members", me, Map.of("displayName", "A"))).get("id").asText();
        String b = body(hit(POST, g + "/members", me, Map.of("displayName", "B"))).get("id").asText();
        String c = body(hit(POST, g + "/members", me, Map.of("displayName", "C"))).get("id").asText();
        assertThat(status(hit(PATCH, g + "/members/" + c, me, Map.of("displayName", "C2")))).isEqualTo(200);
        assertThat(status(hit(DELETE, g + "/members/" + c, me, null))).isEqualTo(204);

        // ---- expenses ---------------------------------------------------------------------------------------------
        assertThat(status(hit(POST, g + "/expenses/preview", me, equalBody("P", 1000, null, a, 1000L)))).isEqualTo(200);
        JsonNode expense = body(hit(POST, g + "/expenses", me, equalBody("Dinner", 3000, null, a, 3000L),
                "Idempotency-Key", key()));
        String eid = expense.get("id").asText();
        assertThat(status(hit(GET, g + "/expenses", me, null))).isEqualTo(200);
        assertThat(status(hit(GET, g + "/expenses/" + eid, me, null))).isEqualTo(200);
        assertThat(status(hit(PUT, g + "/expenses/" + eid, me, equalBody("Dinner 2", 4000, null, a, 4000L),
                "If-Match", "\"1\""))).isEqualTo(200);
        assertThat(status(hit(GET, g + "/expenses/" + eid + "/revisions", me, null))).isEqualTo(200);
        String doomed = body(hit(POST, g + "/expenses", me, equalBody("Doomed", 1000, null, b, 1000L),
                "Idempotency-Key", key())).get("id").asText();
        assertThat(status(hit(DELETE, g + "/expenses/" + doomed, me, null, "If-Match", "\"1\""))).isEqualTo(204);

        // ---- settlements and balances ----------------------------------------------------------------------------
        Map<String, Object> pay = Map.of("fromMemberId", b, "toMemberId", a, "amountMinor", 500L, "settledOn", "2026-10-20");
        String sid = body(hit(POST, g + "/settlements", me, pay, "Idempotency-Key", key())).get("id").asText();
        assertThat(status(hit(GET, g + "/settlements", me, null))).isEqualTo(200);
        assertThat(status(hit(GET, g + "/balances", me, null))).isEqualTo(200);
        assertThat(status(hit(DELETE, g + "/settlements/" + sid, me, null))).isEqualTo(204);

        // ---- every error code, on a real response ------------------------------------------------------------
        expect(hit(POST, "/api/v1/groups", me, Map.of("name", " ", "type", "TRIP")), 422, ErrorCode.VALIDATION_ERROR);
        expect(hit(POST, g + "/expenses", me, equalBody("X", 100, null, a, 99L), "Idempotency-Key", key()), 422,
                ErrorCode.PAYERS_TOTAL_MISMATCH);
        expect(hit(POST, g + "/expenses", me, exactBody("X", 100, List.of(a, 40L, b, 40L), a, 100L),
                "Idempotency-Key", key()), 422, ErrorCode.SPLIT_TOTAL_MISMATCH);
        expect(hit(POST, g + "/expenses", me, equalBody("X", 100, null, UUID.randomUUID().toString(), 100L),
                "Idempotency-Key", key()), 422, ErrorCode.MEMBER_NOT_IN_GROUP);
        String reused = key();
        hit(POST, g + "/expenses", me, equalBody("Once", 100, null, a, 100L), "Idempotency-Key", reused);
        expect(hit(POST, g + "/expenses", me, equalBody("Twice", 200, null, a, 200L), "Idempotency-Key", reused), 422,
                ErrorCode.IDEMPOTENCY_KEY_REUSED);
        expect(hit(POST, g + "/members", me, Map.of("displayName", "a")), 409, ErrorCode.DUPLICATE_MEMBER_NAME);
        expect(hit(DELETE, g + "/members/" + a, me, null), 409, ErrorCode.MEMBER_HAS_TRANSACTIONS);
        expect(hit(DELETE, g + "/members/" + ownerMember, me, null), 409, ErrorCode.OWNER_MEMBER_PROTECTED);
        expect(hit(PATCH, g, me, Map.of("name", "Stale"), "If-Match", "\"1\""), 409, ErrorCode.VERSION_CONFLICT);
        expect(hit(DELETE, g, me, null), 409, ErrorCode.GROUP_NOT_EMPTY);
        String empty = body(hit(POST, "/api/v1/groups", me, Map.of("name", "Empty", "type", "OTHER"))).get("id").asText();
        assertThat(status(hit(DELETE, "/api/v1/groups/" + empty, me, null))).isEqualTo(204);
        expect(hit(GET, "/api/v1/groups/" + UUID.randomUUID(), me, null), 404, ErrorCode.NOT_FOUND);
        expect(hit(GET, "/api/v1/me", null, null), 401, ErrorCode.UNAUTHORIZED);

        doThrow(new GoogleIdTokenVerifier.AuthProviderUnavailableException(new RuntimeException("jwks down")))
                .when(verifier).verify("provider-down");
        expect(hit(POST, "/api/v1/auth/google", null, Map.of("idToken", "provider-down")), 503,
                ErrorCode.AUTH_PROVIDER_UNAVAILABLE);

        doThrow(new IllegalStateException("simulated failure")).when(keyStore)
                .insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());
        expect(hit(POST, g + "/expenses", me, equalBody("Boom", 100, null, a, 100L), "Idempotency-Key", key()), 500,
                ErrorCode.INTERNAL_ERROR);
        doCallRealMethod().when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());

        MvcResult limited = null;
        for (int i = 0; i < 80 && limited == null; i++) {
            MvcResult r = hit(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", "not-a-token-" + i));
            if (status(r) == 429) {
                limited = r;
            }
        }
        assertThat(limited).as("the auth rate limit eventually answers 429").isNotNull();
        expect(limited, 429, ErrorCode.RATE_LIMITED);

        // ---- the report ---------------------------------------------------------------------------------------------
        JsonNode doc = json.readTree(mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .get("/v3/api-docs")).andReturn().getResponse().getContentAsString());
        Set<String> documented = new TreeSet<>();
        Iterator<Map.Entry<String, JsonNode>> paths = doc.get("paths").fields();
        while (paths.hasNext()) {
            Map.Entry<String, JsonNode> path = paths.next();
            path.getValue().fieldNames().forEachRemaining(m -> documented.add(m.toUpperCase() + " " + path.getKey()));
        }
        assertThat(succeeded).as("operations that never answered 2xx in this walk").containsAll(documented);
        // the declared success statuses must be the real ones, per operation (review B9: the document once said 200 for 201/204)
        Iterator<Map.Entry<String, JsonNode>> declaredPaths = doc.get("paths").fields();
        while (declaredPaths.hasNext()) {
            Map.Entry<String, JsonNode> path = declaredPaths.next();
            Iterator<Map.Entry<String, JsonNode>> ops = path.getValue().fields();
            while (ops.hasNext()) {
                Map.Entry<String, JsonNode> op = ops.next();
                Set<Integer> declared = new TreeSet<>();
                op.getValue().get("responses").fieldNames().forEachRemaining(code -> {
                    if (code.startsWith("2")) {
                        declared.add(Integer.parseInt(code));
                    }
                });
                String key = op.getKey().toUpperCase() + " " + path.getKey();
                assertThat(successStatuses.get(key)).as("real success statuses of " + key + " vs declared " + declared)
                        .isEqualTo(declared);
            }
        }
        for (ErrorCode code : ErrorCode.values()) {
            assertThat(errors).as("error code never produced by a real response").containsKey(code.name());
        }
        assertThat(errors.get("VERSION_CONFLICT")).containsExactly(409);
        assertThat(errors.get("RATE_LIMITED")).containsExactly(429);
        assertThat(errors.get("AUTH_PROVIDER_UNAVAILABLE")).containsExactly(503);
        assertThat(errors.get("INTERNAL_ERROR")).containsExactly(500);
        assertThat(errors.get("NOT_FOUND")).containsExactly(404);
        assertThat(errors.get("UNAUTHORIZED")).containsExactly(401);
        System.out.println("CONTRACT operations covered: " + documented.size() + ", error codes produced: " + errors.keySet());
    }
}
