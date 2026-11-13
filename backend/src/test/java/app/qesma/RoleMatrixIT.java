package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B10 role x operation matrix (Decisions A65-A67). Every group-scoped operation of the generated OpenAPI document is
 * called as OWNER, ADMIN, MEMBER, a LEFT member, a stranger and anonymously, each time on a FRESH group so that one
 * cell cannot influence another. The test fails when an operation has no row, so a new route cannot be forgotten.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "springdoc.api-docs.enabled=true")
class RoleMatrixIT extends AbstractApiIT {

    private enum Actor { OWNER, ADMIN, MEMBER, LEFT, STRANGER, ANONYMOUS }

    /** Expected status per operation for OWNER, ADMIN, MEMBER (LEFT/STRANGER are always 404, ANONYMOUS always 401). */
    private record Row(int owner, int admin, int member) {
        int expected(Actor a) {
            return switch (a) {
                case OWNER -> owner;
                case ADMIN -> admin;
                case MEMBER -> member;
                case LEFT, STRANGER -> 404;
                case ANONYMOUS -> 401;
            };
        }
    }

    /**
     * The resources targeted here were created by the OWNER: "own" for the owner, "others'" for ADMIN and MEMBER, so the
     * MEMBER is refused on expense/settlement edits. A 409 for an allowed role proves authorization passed and the
     * business rule (group not empty, member in use) answered.
     */
    private static final Map<String, Row> MATRIX = new LinkedHashMap<>();

    static {
        MATRIX.put("GET /api/v1/groups/{gid}", new Row(200, 200, 200));
        MATRIX.put("PATCH /api/v1/groups/{gid}", new Row(200, 200, 403));
        MATRIX.put("DELETE /api/v1/groups/{gid}", new Row(409, 403, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/members", new Row(201, 201, 403));
        MATRIX.put("PATCH /api/v1/groups/{gid}/members/{mid}", new Row(200, 200, 403));
        MATRIX.put("DELETE /api/v1/groups/{gid}/members/{mid}", new Row(409, 409, 403));
        MATRIX.put("GET /api/v1/groups/{gid}/expenses", new Row(200, 200, 200));
        MATRIX.put("POST /api/v1/groups/{gid}/expenses", new Row(201, 201, 201));
        MATRIX.put("POST /api/v1/groups/{gid}/expenses/preview", new Row(200, 200, 200));
        MATRIX.put("GET /api/v1/groups/{gid}/expenses/{eid}", new Row(200, 200, 200));
        MATRIX.put("PUT /api/v1/groups/{gid}/expenses/{eid}", new Row(200, 200, 403));
        MATRIX.put("DELETE /api/v1/groups/{gid}/expenses/{eid}", new Row(204, 204, 403));
        MATRIX.put("GET /api/v1/groups/{gid}/expenses/{eid}/revisions", new Row(200, 200, 200));
        MATRIX.put("GET /api/v1/groups/{gid}/balances", new Row(200, 200, 200));
        MATRIX.put("GET /api/v1/groups/{gid}/settlements", new Row(200, 200, 200));
        // B13: recording a payment between two OTHER members is for Owner/Admin only (403 for a member)
        MATRIX.put("POST /api/v1/groups/{gid}/settlements", new Row(201, 201, 403));
        // the target is a PENDING settlement declared by the member to the owner's member: the owner is the receiver, the member
        // the payer, the admin a manager. The payer never confirms their own payment; only the receiver disputes.
        MATRIX.put("POST /api/v1/groups/{gid}/settlements/{sid}/confirm", new Row(200, 200, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/settlements/{sid}/dispute", new Row(200, 403, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/settlements/{sid}/cancel", new Row(200, 200, 200));
        // B11: invitations, join requests and unlink (Owner and Admin only)
        MATRIX.put("POST /api/v1/groups/{gid}/invites", new Row(201, 201, 403));
        MATRIX.put("GET /api/v1/groups/{gid}/invites", new Row(200, 200, 403));
        MATRIX.put("DELETE /api/v1/groups/{gid}/invites/{iid}", new Row(204, 204, 403));
        MATRIX.put("GET /api/v1/groups/{gid}/join-requests", new Row(200, 200, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/join-requests/{rid}/approve", new Row(200, 200, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/join-requests/{rid}/reject", new Row(200, 200, 403));
        MATRIX.put("POST /api/v1/groups/{gid}/members/{mid}/unlink", new Row(204, 204, 403));
        // B12: leaving (everyone but the owner, who must transfer first: 409) and ownership transfer (Owner only)
        MATRIX.put("POST /api/v1/groups/{gid}/leave", new Row(409, 204, 204));
        MATRIX.put("POST /api/v1/groups/{gid}/transfer-ownership", new Row(204, 403, 403));
    }

    /** One group with one caller per role, an expense and a settlement created by the owner. */
    private record Cast(Session owner, Session admin, Session member, Session left, Session stranger, Session joiner) {
    }

    private Cast cast() throws Exception {
        return new Cast(newUser(), newUser(), newUser(), newUser(), newUser(), newUser());
    }

    private final class Fixture {
        final Session owner;
        final Session admin;
        final Session member;
        final Session left;
        final Session stranger;
        final String gid;
        final String m1;
        final String m2;
        final String adminMember;
        final String eid;
        final String sid;       // confirmed, recorded by the owner on behalf (m1 -> m2)
        final String pid;       // PENDING, declared by the member to m1
        final String iid;
        final String rid;

        Fixture(Cast cast) throws Exception {
            owner = cast.owner();
            admin = cast.admin();
            member = cast.member();
            left = cast.left();
            stranger = cast.stranger();
            gid = createGroup(owner, "Matrix " + UUID.randomUUID()).get("id").asText();
            m1 = member(owner, gid, "A").get("id").asText();
            m2 = member(owner, gid, "B").get("id").asText();
            adminMember = linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
            String memberMid = linkUser(gid, member, "MEMBER", "ACTIVE", "Member");
            linkUser(gid, left, "MEMBER", "LEFT", "Gone");
            eid = createExpense(owner, gid, equalBody("Dinner", 3000, null, m1, 3000L)).get("id").asText();
            sid = body(call(POST, "/api/v1/groups/" + gid + "/settlements", owner,
                    Map.of("fromMemberId", m1, "toMemberId", m2, "amountMinor", 100L, "settledOn", "2026-10-20"),
                    "Idempotency-Key", UUID.randomUUID().toString())).get("id").asText();
            pid = body(call(POST, "/api/v1/groups/" + gid + "/settlements", member,
                    Map.of("fromMemberId", memberMid, "toMemberId", m1, "amountMinor", 70L, "settledOn", "2026-10-20"),
                    "Idempotency-Key", UUID.randomUUID().toString())).get("id").asText();
            JsonNode invite = body(call(POST, "/api/v1/groups/" + gid + "/invites", owner, Map.of("requiresApproval", true),
                    "Idempotency-Key", UUID.randomUUID().toString()));
            iid = invite.get("id").asText();
            rid = body(call(POST, "/api/v1/invites/" + invite.get("code").asText() + "/join", cast.joiner(),
                    Map.of("newMemberName", "Joiner"), "Idempotency-Key", UUID.randomUUID().toString()))
                    .get("requestId").asText();
        }

        Session session(Actor a) {
            return switch (a) {
                case OWNER -> owner;
                case ADMIN -> admin;
                case MEMBER -> member;
                case LEFT -> left;
                case STRANGER -> stranger;
                case ANONYMOUS -> null;
            };
        }

        String url(String path) {
            String target = path.endsWith("/confirm") || path.endsWith("/dispute") || path.endsWith("/cancel") ? pid : sid;
            return path.replace("{gid}", gid).replace("{mid}", m2).replace("{eid}", eid).replace("{sid}", target).replace("{iid}", iid).replace("{rid}", rid);
        }

        Object requestBody(String label) {
            Map<String, Object> expense = new LinkedHashMap<>();
            expense.put("title", "Edited");
            expense.put("expenseDate", "2026-10-18");
            expense.put("splitType", "EQUAL");
            expense.put("totalMinor", 1000L);
            expense.put("payers", List.of(Map.of("memberId", m1, "amountMinor", 1000L)));
            return switch (label) {
                case "PATCH /api/v1/groups/{gid}" -> Map.of("name", "Renamed " + UUID.randomUUID());
                case "POST /api/v1/groups/{gid}/members" -> Map.of("displayName", "Newcomer");
                case "POST /api/v1/groups/{gid}/invites" -> Map.of("requiresApproval", false);
                case "POST /api/v1/groups/{gid}/transfer-ownership" -> Map.of("toMemberId", adminMember);
                case "PATCH /api/v1/groups/{gid}/members/{mid}" -> Map.of("displayName", "Renamed B");
                case "POST /api/v1/groups/{gid}/expenses", "POST /api/v1/groups/{gid}/expenses/preview",
                     "PUT /api/v1/groups/{gid}/expenses/{eid}" -> expense;
                case "POST /api/v1/groups/{gid}/settlements" -> Map.of("fromMemberId", m1, "toMemberId", m2,
                        "amountMinor", 100L, "settledOn", "2026-10-20");
                default -> null;
            };
        }
    }

    private List<String> openApiGroupOperations() throws Exception {
        JsonNode doc = json.readTree(mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .get("/v3/api-docs")).andReturn().getResponse().getContentAsString());
        List<String> labels = new ArrayList<>();
        doc.get("paths").fields().forEachRemaining(p -> {
            if (p.getKey().contains("{gid}")) {
                p.getValue().fields().forEachRemaining(m -> labels.add(m.getKey().toUpperCase() + " " + p.getKey()));
            }
        });
        return labels;
    }

    private MvcResult call(Fixture f, String label, Actor actor) throws Exception {
        String[] parts = label.split(" ", 2);
        List<String> headers = new ArrayList<>();
        if (label.equals("POST /api/v1/groups/{gid}/expenses") || label.equals("POST /api/v1/groups/{gid}/settlements")
                || label.equals("POST /api/v1/groups/{gid}/invites")) {
            headers.add("Idempotency-Key");
            headers.add(UUID.randomUUID().toString());
        }
        if (label.equals("PATCH /api/v1/groups/{gid}") || label.equals("PUT /api/v1/groups/{gid}/expenses/{eid}")
                || label.equals("DELETE /api/v1/groups/{gid}/expenses/{eid}")) {
            headers.add("If-Match");
            headers.add("\"1\"");
        }
        return call(HttpMethod.valueOf(parts[0]), f.url(parts[1]), f.session(actor), f.requestBody(label), headers.toArray(new String[0]));
    }

    @Test
    void everyGroupScopedOperationHasARowAndEveryCellIsAsExpected() throws Exception {
        assertThat(openApiGroupOperations()).as("operations in the OpenAPI document vs matrix rows")
                .containsExactlyInAnyOrderElementsOf(MATRIX.keySet());

        List<String> mismatches = new ArrayList<>();
        Cast cast = cast();
        for (Map.Entry<String, Row> row : MATRIX.entrySet()) {
            for (Actor actor : Actor.values()) {
                Fixture f = new Fixture(cast);
                MvcResult r = call(f, row.getKey(), actor);
                int expected = row.getValue().expected(actor);
                if (status(r) != expected) {
                    mismatches.add(row.getKey() + " as " + actor + ": expected " + expected + " got " + status(r) + " "
                            + r.getResponse().getContentAsString());
                } else if (expected == 403 && !"FORBIDDEN".equals(code(r))) {
                    mismatches.add(row.getKey() + " as " + actor + ": 403 without code FORBIDDEN");
                } else if (expected == 404 && !"NOT_FOUND".equals(code(r))) {
                    mismatches.add(row.getKey() + " as " + actor + ": 404 without code NOT_FOUND");
                }
            }
        }
        assertThat(mismatches).as("cells that differ from the matrix").isEmpty();
    }

    @Test
    void aMemberCanEditAndDeleteWhatTheyCreatedButNotWhatOthersCreated() throws Exception {
        Fixture f = new Fixture(cast());
        String base = "/api/v1/groups/" + f.gid;
        String mine = createExpense(f.member, f.gid, equalBody("Mine", 2000, null, f.m1, 2000L)).get("id").asText();

        Map<String, Object> edit = equalBody("Mine edited", 2500, null, f.m1, 2500L);
        assertThat(status(call(PUT, base + "/expenses/" + mine, f.member, edit, "If-Match", "\"1\""))).isEqualTo(200);
        assertThat(status(call(PUT, base + "/expenses/" + f.eid, f.member, edit, "If-Match", "\"1\""))).isEqualTo(403);
        assertThat(status(call(DELETE, base + "/expenses/" + f.eid, f.member, null, "If-Match", "\"1\""))).isEqualTo(403);
        assertThat(status(call(POST, base + "/settlements/" + f.sid + "/cancel", f.member, null))).isEqualTo(403);   // not theirs
        assertThat(status(call(POST, base + "/settlements/" + f.pid + "/cancel", f.member, null))).isEqualTo(200);   // their own declaration
        // an admin may touch the member's expense, the owner too
        assertThat(status(call(DELETE, base + "/expenses/" + mine, f.admin, null, "If-Match", "\"2\""))).isEqualTo(204);
        // nothing of the owner's changed by the refused calls
        assertThat(jdbc.queryForObject("select title from expenses where id = ?::uuid", String.class, f.eid)).isEqualTo("Dinner");
        assertThat(jdbc.queryForObject("select status from settlements where id = ?::uuid", String.class, f.sid)).isEqualTo("CONFIRMED");
    }

    @Test
    void groupListShowsGroupsOfAnyRoleWithTheCallersRoleAndOwnNet() throws Exception {
        Fixture f = new Fixture(cast());
        JsonNode memberList = body(call(GET, "/api/v1/groups", f.member, null));
        JsonNode adminList = body(call(GET, "/api/v1/groups", f.admin, null));
        JsonNode ownerList = body(call(GET, "/api/v1/groups", f.owner, null));
        assertThat(findGroup(memberList, f.gid).get("yourRole").asText()).isEqualTo("MEMBER");
        assertThat(findGroup(adminList, f.gid).get("yourRole").asText()).isEqualTo("ADMIN");
        assertThat(findGroup(ownerList, f.gid).get("yourRole").asText()).isEqualTo("OWNER");
        assertThat(body(call(GET, "/api/v1/groups", f.left, null)).toString()).doesNotContain(f.gid);
        assertThat(body(call(GET, "/api/v1/groups", f.stranger, null)).toString()).doesNotContain(f.gid);

        // the member is a real participant: 3000 paid by A, equal among A, B, Admin, Member (Gone is LEFT but still a row)
        JsonNode detail = body(call(GET, "/api/v1/groups/" + f.gid, f.member, null));
        assertThat(detail.get("yourRole").asText()).isEqualTo("MEMBER");
        assertThat(detail.get("yourMemberId").asText()).isNotEqualTo(detail.get("members").get(0).get("id").asText());
        boolean sawYou = false;
        for (JsonNode m : detail.get("members")) {
            assertThat(m.has("role") && m.has("status") && m.has("hasAccount")).isTrue();
            assertThat(m.has("userId")).as("account ids are never exposed").isFalse();
            if (m.get("isYou").asBoolean()) {
                sawYou = true;
                assertThat(m.get("role").asText()).isEqualTo("MEMBER");
                assertThat(m.get("hasAccount").asBoolean()).isTrue();
            }
        }
        assertThat(sawYou).isTrue();
        assertThat(detail.get("yourNetMinor").isNull()).isFalse();
    }

    @Test
    void yourNetMinorIsTheCallersOwnBalanceForANonOwnerMember() throws Exception {
        Session owner = newUser();
        Session guest = newUser();
        String gid = createGroup(owner, "Net " + UUID.randomUUID()).get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String g = linkUser(gid, guest, "MEMBER", "ACTIVE", "Guest");
        createExpense(owner, gid, equalBody("Dinner", 3000, null, a, 3000L));           // 1500 each between A and Guest
        JsonNode list = body(call(GET, "/api/v1/groups", guest, null));
        assertThat(findGroup(list, gid).get("yourNetMinor").asLong()).isEqualTo(-1500L);
        assertThat(body(call(GET, "/api/v1/groups/" + gid, guest, null)).get("yourMemberId").asText()).isEqualTo(g);
        JsonNode ownerList = body(call(GET, "/api/v1/groups", owner, null));
        assertThat(findGroup(ownerList, gid).get("yourNetMinor").asLong()).isEqualTo(1500L);
    }

    private static JsonNode findGroup(JsonNode page, String gid) {
        for (JsonNode g : page.get("items")) {
            if (gid.equals(g.get("id").asText())) {
                return g;
            }
        }
        throw new AssertionError("group " + gid + " not in " + page);
    }
}
