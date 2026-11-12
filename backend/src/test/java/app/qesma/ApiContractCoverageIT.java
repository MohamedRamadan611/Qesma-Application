package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import app.qesma.api.ErrorCode;
import app.qesma.api.OpenApiConfig;
import app.qesma.persistence.IdempotencyKeyStore;
import app.qesma.security.GoogleIdTokenVerifier;
import app.qesma.service.MailSender;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import org.mockito.ArgumentCaptor;
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
    @MockitoSpyBean MailSender mailSender;

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

    /** The token of an emailed link ("...?token=abc"). */
    private static String tokenOf(String link) {
        return link.substring(link.indexOf("token=") + "token=".length());
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

        // ---- email + password accounts (ADR-007) ------------------------------------------------------------------
        String pwName = "walk-" + UUID.randomUUID().toString().substring(0, 12);
        String pwEmail = pwName + "@example.com";
        String pwSecret = "a long walking passphrase";
        MvcResult registered = hit(POST, "/api/v1/auth/register", null, Map.of("username", pwName, "password", pwSecret));
        assertThat(status(registered)).isEqualTo(201);
        Session pw = new Session(body(registered).get("accessToken").asText(), UUID.fromString(body(registered).get("user").get("id").asText()));
        assertThat(status(hit(POST, "/api/v1/auth/login", null, Map.of("username", pwName, "password", pwSecret)))).isEqualTo(200);
        jdbc.update("update users set email = ? where auth_provider = 'PASSWORD' and auth_subject = ?", pwEmail, pwName);   // recovery by email is on hold: give the account an address for the emailed-link calls
        ArgumentCaptor<String> verifyLink = ArgumentCaptor.forClass(String.class);
        assertThat(status(hit(POST, "/api/v1/auth/email/verify/resend", pw, null))).isEqualTo(204);
        verify(mailSender, atLeastOnce()).sendVerification(org.mockito.ArgumentMatchers.eq(pwEmail), verifyLink.capture());
        assertThat(status(hit(POST, "/api/v1/auth/email/verify/resend", pw, null))).isEqualTo(204);
        assertThat(status(hit(POST, "/api/v1/auth/email/verify", null, Map.of("token", tokenOf(verifyLink.getAllValues().get(0)))))).isEqualTo(422);   // replaced by the resend
        verify(mailSender, org.mockito.Mockito.atLeast(2)).sendVerification(org.mockito.ArgumentMatchers.eq(pwEmail), verifyLink.capture());
        String lastVerify = verifyLink.getAllValues().get(verifyLink.getAllValues().size() - 1);
        assertThat(status(hit(POST, "/api/v1/auth/email/verify", null, Map.of("token", tokenOf(lastVerify))))).isEqualTo(204);
        assertThat(status(hit(POST, "/api/v1/auth/password/forgot", null, Map.of("email", pwEmail)))).isEqualTo(204);
        ArgumentCaptor<String> resetLink = ArgumentCaptor.forClass(String.class);
        verify(mailSender, atLeastOnce()).sendPasswordReset(org.mockito.ArgumentMatchers.eq(pwEmail), resetLink.capture());
        assertThat(status(hit(POST, "/api/v1/auth/password/reset", null,
                Map.of("token", tokenOf(resetLink.getValue()), "newPassword", "another walking passphrase")))).isEqualTo(204);
        MvcResult pwLogin = hit(POST, "/api/v1/auth/login", null, Map.of("username", pwName, "password", "another walking passphrase"));
        assertThat(status(pwLogin)).isEqualTo(200);
        Session pw2 = new Session(body(pwLogin).get("accessToken").asText(), pw.userId());
        assertThat(status(hit(POST, "/api/v1/me/password", pw2,
                Map.of("currentPassword", "another walking passphrase", "newPassword", "a third walking passphrase")))).isEqualTo(200);
        expect(hit(POST, "/api/v1/auth/register", null, Map.of("username", pwName, "password", "someone else's passphrase")), 409,
                ErrorCode.USERNAME_TAKEN);

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
        // a plain MEMBER may read but not edit the group: 403 FORBIDDEN (B10, A65)
        Session plain = newUser();
        linkUser(g.substring(g.lastIndexOf('/') + 1), plain, "MEMBER", "ACTIVE", "Plain");
        expect(hit(PATCH, g, plain, Map.of("name", "Nope"), "If-Match", "\"1\""), 403, ErrorCode.FORBIDDEN);
        // ---- invitations and join (B11) -------------------------------------------------------------------------------
        MvcResult inv = hit(POST, g + "/invites", me, Map.of("expiresInDays", 7), "Idempotency-Key", key());
        assertThat(status(inv)).isEqualTo(201);
        String invId = body(inv).get("id").asText();
        String invCode = body(inv).get("code").asText();
        assertThat(status(hit(GET, g + "/invites", me, null))).isEqualTo(200);
        Session joiner = newUser();
        assertThat(status(hit(GET, "/api/v1/invites/" + invCode, joiner, null))).isEqualTo(200);
        MvcResult joined = hit(POST, "/api/v1/invites/" + invCode + "/join", joiner, Map.of("newMemberName", "Joiner"),
                "Idempotency-Key", key());
        assertThat(status(joined)).isEqualTo(201);
        String joinerMember = body(joined).get("member").get("id").asText();
        expect(hit(POST, "/api/v1/invites/" + invCode + "/join", joiner, Map.of("newMemberName", "Joiner2"),
                "Idempotency-Key", key()), 409, ErrorCode.ALREADY_MEMBER);
        expect(hit(POST, "/api/v1/invites/" + invCode + "/join", newUser(), Map.of("claimMemberId", joinerMember),
                "Idempotency-Key", key()), 409, ErrorCode.MEMBER_ALREADY_CLAIMED);
        expect(hit(GET, "/api/v1/invites/ZZZZZZZZ", joiner, null), 404, ErrorCode.NOT_FOUND);
        String revokedCode = body(hit(POST, g + "/invites", me, Map.of(), "Idempotency-Key", key())).get("code").asText();
        String revokedId = jdbc.queryForObject("select id::text from group_invites where code = ?", String.class, revokedCode);
        assertThat(status(hit(DELETE, g + "/invites/" + revokedId, me, null))).isEqualTo(204);
        expect(hit(GET, "/api/v1/invites/" + revokedCode, newUser(), null), 410, ErrorCode.INVITE_REVOKED);
        String expiredCode = body(hit(POST, g + "/invites", me, Map.of(), "Idempotency-Key", key())).get("code").asText();
        jdbc.update("update group_invites set created_at = now() - interval '2 days', expires_at = now() - interval '1 day' "
                + "where code = ?", expiredCode);
        expect(hit(GET, "/api/v1/invites/" + expiredCode, newUser(), null), 410, ErrorCode.INVITE_EXPIRED);
        String approvalCode = body(hit(POST, g + "/invites", me, Map.of("requiresApproval", true), "Idempotency-Key", key()))
                .get("code").asText();
        MvcResult pending = hit(POST, "/api/v1/invites/" + approvalCode + "/join", newUser(), Map.of("newMemberName", "Asks"),
                "Idempotency-Key", key());
        assertThat(status(pending)).isEqualTo(202);
        MvcResult pending2 = hit(POST, "/api/v1/invites/" + approvalCode + "/join", newUser(), Map.of("newMemberName", "Asks Too"),
                "Idempotency-Key", key());
        assertThat(status(hit(GET, g + "/join-requests", me, null))).isEqualTo(200);
        assertThat(status(hit(POST, g + "/join-requests/" + body(pending).get("requestId").asText() + "/approve", me, null)))
                .isEqualTo(200);
        assertThat(status(hit(POST, g + "/join-requests/" + body(pending2).get("requestId").asText() + "/reject", me, null)))
                .isEqualTo(200);
        assertThat(status(hit(POST, g + "/members/" + joinerMember + "/unlink", me, null))).isEqualTo(204);
        assertThat(invId).isNotBlank();

        // ---- member lifecycle (B12): leave, MEMBER_INACTIVE, OWNER_MUST_TRANSFER, transfer-ownership ---------------------
        String g2 = body(hit(POST, "/api/v1/groups", me, Map.of("name", "Lifecycle", "type", "TRIP"))).get("id").asText();
        String g2Path = "/api/v1/groups/" + g2;
        String g2Ghost = body(hit(POST, g2Path + "/members", me, Map.of("displayName", "Ghost"))).get("id").asText();
        Session leaver = newUser();
        linkUser(g2, leaver, "MEMBER", "ACTIVE", "Leaver");
        expect(hit(POST, g2Path + "/leave", me, null), 409, ErrorCode.OWNER_MUST_TRANSFER);
        assertThat(status(hit(POST, g2Path + "/leave", leaver, null))).isEqualTo(204);
        String leaverMember = jdbc.queryForObject("select id::text from members where group_id = ?::uuid and user_id = ?",
                String.class, g2, leaver.userId());
        expect(hit(POST, g2Path + "/expenses", me, equalBody("Late", 100, null, leaverMember, 100L),
                "Idempotency-Key", key()), 422, ErrorCode.MEMBER_INACTIVE);
        Session heir = newUser();
        String heirMember = linkUser(g2, heir, "ADMIN", "ACTIVE", "Heir");
        assertThat(status(hit(POST, g2Path + "/transfer-ownership", me, Map.of("toMemberId", heirMember)))).isEqualTo(204);
        assertThat(g2Ghost).isNotBlank();

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
        // operation ids become method names of the generated client: meaningful, unique, no springdoc "_1" suffixes
        List<String> operationIds = new ArrayList<>();
        doc.get("paths").forEach(item -> item.forEach(op -> operationIds.add(op.get("operationId").asText())));
        assertThat(operationIds).hasSize(documented.size()).doesNotHaveDuplicates()
                .allMatch(id -> id.matches("[a-z][A-Za-z]+"), "camelCase without numeric suffix");
        assertThat(new TreeSet<>(operationIds)).isEqualTo(new TreeSet<>(OpenApiConfig.OPERATION_IDS.values()));
        for (ErrorCode code : ErrorCode.values()) {
            assertThat(errors).as("error code never produced by a real response").containsKey(code.name());
        }
        assertThat(errors.get("VERSION_CONFLICT")).containsExactly(409);
        assertThat(errors.get("USERNAME_TAKEN")).containsExactly(409);
        assertThat(errors.get("RATE_LIMITED")).containsExactly(429);
        assertThat(errors.get("AUTH_PROVIDER_UNAVAILABLE")).containsExactly(503);
        assertThat(errors.get("INTERNAL_ERROR")).containsExactly(500);
        assertThat(errors.get("NOT_FOUND")).containsExactly(404);
        assertThat(errors.get("UNAUTHORIZED")).containsExactly(401);
        System.out.println("CONTRACT operations covered: " + documented.size() + ", error codes produced: " + errors.keySet());
    }
}
