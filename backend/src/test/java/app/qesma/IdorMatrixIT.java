package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * IDOR / BOLA on EVERY group-scoped route (B8): the route list comes from the generated OpenAPI document, so a new
 * route cannot be forgotten. Another user calling it with real ids must get exactly the answer a nonexistent group
 * gets (404 NOT_FOUND, never 403 and never a hint), an anonymous caller 401, and the owner's data must not change.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "springdoc.api-docs.enabled=true")
class IdorMatrixIT extends AbstractApiIT {

    private record Op(HttpMethod method, String path, JsonNode operation) {
        String label() {
            return method + " " + path;
        }
    }

    private List<Op> groupScopedOperations() throws Exception {
        JsonNode doc = json.readTree(mvc.perform(get("/v3/api-docs")).andReturn().getResponse().getContentAsString());
        List<Op> ops = new ArrayList<>();
        doc.get("paths").fields().forEachRemaining(path -> {
            if (path.getKey().contains("{gid}")) {
                path.getValue().fields().forEachRemaining(m ->
                        ops.add(new Op(HttpMethod.valueOf(m.getKey().toUpperCase()), path.getKey(), m.getValue())));
            }
        });
        return ops;
    }

    private static boolean declares(Op op, String header) {
        JsonNode params = op.operation().get("parameters");
        if (params == null) {
            return false;
        }
        for (JsonNode p : params) {
            if ("header".equals(p.path("in").asText()) && header.equalsIgnoreCase(p.path("name").asText())) {
                return true;
            }
        }
        return false;
    }

    private static String fill(String path, Map<String, String> ids) {
        String url = path;
        for (Map.Entry<String, String> e : ids.entrySet()) {
            url = url.replace("{" + e.getKey() + "}", e.getValue());
        }
        assertThat(url).as("route " + path + " has a placeholder this matrix does not know: add its id").doesNotContain("{");
        return url;
    }

    /** A well-formed body per operation, so a rejection can only come from the ownership check. */
    private static Object validBody(Op op, Map<String, String> ids) {
        String key = op.label();
        Map<String, Object> payer = Map.of("memberId", ids.get("mid"), "amountMinor", 1000L);
        Map<String, Object> expense = new LinkedHashMap<>();
        expense.put("title", "Attack");
        expense.put("expenseDate", "2026-10-18");
        expense.put("splitType", "EQUAL");
        expense.put("totalMinor", 1000L);
        expense.put("payers", List.of(payer));
        return switch (key) {
            case "POST /api/v1/groups/{gid}/members" -> Map.of("displayName", "Intruder");
            case "PATCH /api/v1/groups/{gid}/members/{mid}" -> Map.of("displayName", "Renamed");
            case "PATCH /api/v1/groups/{gid}" -> Map.of("name", "Hijacked");
            case "POST /api/v1/groups/{gid}/transfer-ownership" -> Map.of("toMemberId", ids.get("mid"));
            case "POST /api/v1/groups/{gid}/expenses", "POST /api/v1/groups/{gid}/expenses/preview",
                 "PUT /api/v1/groups/{gid}/expenses/{eid}" -> expense;
            case "POST /api/v1/groups/{gid}/settlements" -> Map.of("fromMemberId", ids.get("mid"),
                    "toMemberId", ids.get("mid2"), "amountMinor", 100L, "settledOn", "2026-10-20");
            default -> null;
        };
    }

    private MvcResult attack(Op op, Session as, Map<String, String> ids) throws Exception {
        List<String> headers = new ArrayList<>();
        if (declares(op, "Idempotency-Key")) {
            headers.add("Idempotency-Key");
            headers.add(UUID.randomUUID().toString());
        }
        if (declares(op, "If-Match")) {
            headers.add("If-Match");
            headers.add("\"1\"");
        }
        return call(op.method(), fill(op.path(), ids), as, validBody(op, ids), headers.toArray(new String[0]));
    }

    private Map<String, Object> snapshot(String gid) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("group", jdbc.queryForMap("select name, type, version, updated_at from expense_groups where id = ?::uuid", gid));
        s.put("members", jdbc.queryForList("select id, display_name, sort_order, role, status, left_at from members where group_id = ?::uuid "
                + "order by sort_order", gid));
        s.put("expenses", jdbc.queryForList("select id, title, total_minor, version, deleted_at from expenses "
                + "where group_id = ?::uuid order by id", gid));
        s.put("settlements", jdbc.queryForList("select id, amount_minor, status, confirmed_at, cancelled_at, deleted_at from settlements "
                + "where group_id = ?::uuid order by id", gid));
        s.put("invites", jdbc.queryForList("select id, use_count, revoked_at from group_invites where group_id = ?::uuid order by id", gid));
        s.put("requests", jdbc.queryForList("select id, status from join_requests where group_id = ?::uuid order by id", gid));
        s.put("revisions", jdbc.queryForObject("select count(*) from expense_revisions r join expenses e on e.id = r.expense_id "
                + "where e.group_id = ?::uuid", Long.class, gid));
        s.put("keys", jdbc.queryForObject("select count(*) from idempotency_keys", Long.class));
        return s;
    }

    @Test
    void anotherUserGetsTheSame404OnEveryGroupScopedRouteAndChangesNothing() throws Exception {
        Session owner = newUser();
        Session attacker = newUser();
        String gid = createGroup(owner, "Private").get("id").asText();
        String m1 = member(owner, gid, "A").get("id").asText();
        String m2 = member(owner, gid, "B").get("id").asText();
        String eid = createExpense(owner, gid, equalBody("Mine", 3000, null, m1, 3000L)).get("id").asText();
        String sid = body(call(HttpMethod.POST, "/api/v1/groups/" + gid + "/settlements", owner,
                Map.of("fromMemberId", m1, "toMemberId", m2, "amountMinor", 100L, "settledOn", "2026-10-20"),
                "Idempotency-Key", UUID.randomUUID().toString())).get("id").asText();
        JsonNode invite = body(call(HttpMethod.POST, "/api/v1/groups/" + gid + "/invites", owner,
                Map.of("requiresApproval", true), "Idempotency-Key", UUID.randomUUID().toString()));
        String iid = invite.get("id").asText();
        Session joiner = newUser();
        String rid = body(call(HttpMethod.POST, "/api/v1/invites/" + invite.get("code").asText() + "/join", joiner,
                Map.of("newMemberName", "Joiner"), "Idempotency-Key", UUID.randomUUID().toString())).get("requestId").asText();
        Map<String, String> real = Map.of("gid", gid, "mid", m1, "mid2", m2, "eid", eid, "sid", sid, "iid", iid, "rid", rid);
        Map<String, String> ghost = Map.of("gid", UUID.randomUUID().toString(), "mid", UUID.randomUUID().toString(),
                "mid2", UUID.randomUUID().toString(), "eid", UUID.randomUUID().toString(),
                "sid", UUID.randomUUID().toString(), "iid", UUID.randomUUID().toString(),
                "rid", UUID.randomUUID().toString());

        List<Op> ops = groupScopedOperations();
        Set<String> labels = new TreeSet<>();
        ops.forEach(o -> labels.add(o.label()));
        assertThat(ops).as("group-scoped operations found in the OpenAPI document").hasSize(28);

        Map<String, Object> before = snapshot(gid);
        for (Op op : ops) {
            MvcResult foreign = attack(op, attacker, real);
            MvcResult missing = attack(op, attacker, ghost);
            assertThat(status(foreign)).as(op.label() + " as another user").isEqualTo(404);
            assertThat(code(foreign)).as(op.label()).isEqualTo("NOT_FOUND");
            assertThat(problemWithoutRequestId(foreign)).as(op.label() + " must equal the nonexistent-group answer")
                    .isEqualTo(problemWithoutRequestId(missing));
            // `instance` merely echoes the URL the caller sent; nothing else may mention the owner's ids
            assertThat(problemWithoutRequestId(foreign).toString()).as(op.label()).doesNotContain(gid).doesNotContain(m1)
                    .doesNotContain(eid);

            MvcResult anonymous = attack(op, null, real);
            assertThat(status(anonymous)).as(op.label() + " without a token").isEqualTo(401);
        }
        assertThat(snapshot(gid)).as("nothing of the owner's changed").isEqualTo(before);
        // and the owner still sees everything
        assertThat(status(call(HttpMethod.GET, "/api/v1/groups/" + gid, owner, null))).isEqualTo(200);
        System.out.println("IDOR matrix covered: " + labels);
    }
}
