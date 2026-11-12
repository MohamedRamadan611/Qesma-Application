package app.qesma;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Helpers for API integration tests against real PostgreSQL. Concrete classes add @SpringBootTest,
 * @AutoConfigureMockMvc and @ActiveProfiles({"test", "fake-auth"}). Each test signs up its own users with
 * random Google subjects, so tests are independent and can share one database.
 */
public abstract class AbstractApiIT extends AbstractIntegrationTest {

    @Autowired protected MockMvc mvc;
    @Autowired protected ObjectMapper json;
    @Autowired protected JdbcTemplate jdbc;

    protected record Session(String accessToken, UUID userId) {
    }

    protected Session newUser() throws Exception {
        String sub = "sub-" + UUID.randomUUID();
        MvcResult r = mvc.perform(request(HttpMethod.POST, "/api/v1/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"fake:" + sub + ":" + sub + "@example.com:Tester\"}")).andReturn();
        JsonNode body = body(r);
        return new Session(body.get("accessToken").asText(), UUID.fromString(body.get("user").get("id").asText()));
    }

    /** Performs a request as {@code as} (null = anonymous). Extra headers are name/value pairs. */
    protected MvcResult call(HttpMethod method, String path, Session as, Object body, String... headers)
            throws Exception {
        MockHttpServletRequestBuilder b = request(method, path).contentType(MediaType.APPLICATION_JSON);
        if (as != null) {
            b.header("Authorization", "Bearer " + as.accessToken());
        }
        for (int i = 0; i + 1 < headers.length; i += 2) {
            b.header(headers[i], headers[i + 1]);
        }
        if (body != null) {
            b.content(body instanceof String s ? s : json.writeValueAsString(body));
        }
        return mvc.perform(b).andReturn();
    }

    protected JsonNode body(MvcResult r) throws Exception {
        String text = r.getResponse().getContentAsString();
        return text.isEmpty() ? json.nullNode() : json.readTree(text);
    }

    protected int status(MvcResult r) {
        return r.getResponse().getStatus();
    }

    protected String code(MvcResult r) throws Exception {
        return body(r).path("code").asText();
    }

    protected JsonNode createGroup(Session as, String name) throws Exception {
        MvcResult r = call(HttpMethod.POST, "/api/v1/groups", as,
                java.util.Map.of("name", name, "type", "TRIP"));
        if (status(r) != 201) {
            throw new AssertionError("create group failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    /**
     * Links {@code user} to a NEW member of the group with the given role and status, straight in the database: there is
     * no invitation API before B11, so this is how tests get ADMIN / MEMBER / LEFT callers. Returns the member id.
     */
    protected String linkUser(String groupId, Session user, String role, String status, String displayName) {
        int seq = jdbc.queryForObject("select member_seq from expense_groups where id = ?::uuid", Integer.class, groupId) + 1;
        jdbc.update("update expense_groups set member_seq = ? where id = ?::uuid", seq, groupId);
        UUID id = UUID.randomUUID();
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order, role, status, joined_at, left_at) "
                + "values (?, ?::uuid, ?, ?, ?, ?, ?, now(), case when ? = 'LEFT' then now() end)",
                id, groupId, displayName, user.userId(), seq, role, status, status);
        return id.toString();
    }

    private final java.util.Set<String> claimedOwnerMembers = java.util.concurrent.ConcurrentHashMap.newKeySet();

    /**
     * The first member a test "adds" to a group is the owner's own member (member #1 since B9), renamed; later ones
     * are real additions. This keeps the ids, sort orders and "all members" splits of tests that were written when
     * groups started empty, without weakening any assertion. Tests about member management use {@link #addMember}.
     */
    protected JsonNode member(Session as, String groupId, String name) throws Exception {
        if (claimedOwnerMembers.add(groupId)) {
            JsonNode group = body(call(org.springframework.http.HttpMethod.GET, "/api/v1/groups/" + groupId, as, null));
            String ownerMember = group.get("members").get(0).get("id").asText();
            MvcResult r = call(org.springframework.http.HttpMethod.PATCH,
                    "/api/v1/groups/" + groupId + "/members/" + ownerMember, as, java.util.Map.of("displayName", name));
            if (status(r) != 200) {
                throw new AssertionError("rename owner member failed: " + status(r) + " " + r.getResponse().getContentAsString());
            }
            return body(r);
        }
        return addMember(as, groupId, name);
    }

    protected JsonNode addMember(Session as, String groupId, String name) throws Exception {
        MvcResult r = call(HttpMethod.POST, "/api/v1/groups/" + groupId + "/members", as,
                java.util.Map.of("displayName", name));
        if (status(r) != 201) {
            throw new AssertionError("add member failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    /** EQUAL expense body. {@code participants} null means "all members" (field omitted). */
    protected Map<String, Object> equalBody(String title, long total, List<String> participants, Object... payers) {
        Map<String, Object> body = baseBody(title, total, "EQUAL", payers);
        if (participants != null) {
            body.put("participantMemberIds", participants);
        }
        return body;
    }

    /** EXACT expense body; {@code shares} are alternating memberId, amount pairs. */
    protected Map<String, Object> exactBody(String title, long total, List<Object> shares, Object... payers) {
        Map<String, Object> body = baseBody(title, total, "EXACT", payers);
        List<Map<String, Object>> list = new java.util.ArrayList<>();
        for (int i = 0; i + 1 < shares.size(); i += 2) {
            list.add(Map.of("memberId", shares.get(i), "amountMinor", shares.get(i + 1)));
        }
        body.put("shares", list);
        return body;
    }

    /** {@code payers} are alternating memberId, amount pairs. */
    private Map<String, Object> baseBody(String title, long total, String type, Object... payers) {
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("title", title);
        body.put("expenseDate", "2026-10-18");
        body.put("splitType", type);
        body.put("totalMinor", total);
        List<Map<String, Object>> list = new java.util.ArrayList<>();
        for (int i = 0; i + 1 < payers.length; i += 2) {
            list.add(Map.of("memberId", payers[i], "amountMinor", payers[i + 1]));
        }
        body.put("payers", list);
        return body;
    }

    protected MvcResult postExpense(Session as, String groupId, String key, Object body) throws Exception {
        return call(HttpMethod.POST, "/api/v1/groups/" + groupId + "/expenses", as, body, "Idempotency-Key", key);
    }

    /** Creates an expense with a fresh key and returns the response body; fails the test on any non-201. */
    protected JsonNode createExpense(Session as, String groupId, Object body) throws Exception {
        MvcResult r = postExpense(as, groupId, UUID.randomUUID().toString(), body);
        if (status(r) != 201) {
            throw new AssertionError("create expense failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    protected int countExpenses(String groupId) {
        return jdbc.queryForObject("select count(*) from expenses where group_id = ?::uuid", Integer.class, groupId);
    }

    protected String etagOf(MvcResult r) {
        return r.getResponse().getHeader("ETag");
    }

    /**
     * A problem+json body without the fields that legitimately differ between two otherwise identical errors:
     * the per-request id, and {@code instance} (an echo of the URL the caller itself sent, ids included).
     * Everything else (type, title, status, code) must match exactly.
     */
    protected JsonNode problemWithoutRequestId(MvcResult r) throws Exception {
        com.fasterxml.jackson.databind.node.ObjectNode node = (com.fasterxml.jackson.databind.node.ObjectNode) body(r);
        node.remove("requestId");
        node.remove("instance");
        return node;
    }
}
