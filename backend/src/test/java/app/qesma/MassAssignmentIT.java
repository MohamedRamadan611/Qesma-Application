package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Mass assignment (B8): clients can send any JSON property. Server-controlled ones (ids, owner, group, version,
 * timestamps, deletion, derived amounts, sort order) must be ignored on every create and update body.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class MassAssignmentIT extends AbstractApiIT {

    /** Properties no client may set, added to every body below. */
    private static Map<String, Object> withForbidden(Map<String, Object> body, Session other, String foreignGroup) {
        Map<String, Object> evil = new LinkedHashMap<>(body);
        evil.put("id", UUID.randomUUID().toString());
        evil.put("version", 99);
        evil.put("groupId", foreignGroup);
        evil.put("ownerUserId", other.userId().toString());
        evil.put("userId", other.userId().toString());
        evil.put("createdByUserId", other.userId().toString());
        evil.put("createdAt", "2001-01-01T00:00:00Z");
        evil.put("updatedAt", "2001-01-01T00:00:00Z");
        evil.put("deletedAt", "2001-01-01T00:00:00Z");
        evil.put("sortOrder", 999);
        evil.put("memberSeq", 999);
        evil.put("subtotalMinor", 1);
        evil.put("owedMinor", 1);
        evil.put("authSubject", "stolen");
        evil.put("email", "stolen@example.com");
        evil.put("isYou", true);
        evil.put("role", "OWNER");                       // B10: roles are never client-settable
        evil.put("yourRole", "OWNER");
        evil.put("status", "LEFT");
        evil.put("hasAccount", true);
        evil.put("joinedAt", "2001-01-01T00:00:00Z");
        evil.put("leftAt", "2001-01-01T00:00:00Z");
        evil.put("yourMemberId", UUID.randomUUID().toString());
        evil.put("yourNetMinor", 123456);
        return evil;
    }

    @Test
    void serverControlledPropertiesAreIgnoredOnEveryCreateAndUpdate() throws Exception {
        Session me = newUser();
        Session other = newUser();
        String foreignGroup = createGroup(other, "Theirs").get("id").asText();
        String key = UUID.randomUUID().toString();

        // group create
        Map<String, Object> groupBody = withForbidden(Map.of("name", "Mine", "type", "TRIP"), other, foreignGroup);
        MvcResult g = call(POST, "/api/v1/groups", me, groupBody);
        assertThat(status(g)).isEqualTo(201);
        String gid = body(g).get("id").asText();
        assertThat(gid).isNotEqualTo(groupBody.get("id"));
        Map<String, Object> row = jdbc.queryForMap("select owner_user_id::text as owner, version, member_seq, created_at "
                + "from expense_groups where id = ?::uuid", gid);
        assertThat(row.get("owner")).isEqualTo(me.userId().toString());
        assertThat(row.get("version")).isEqualTo(1);
        assertThat(row.get("member_seq")).isEqualTo(1);               // the owner is member #1 since B9
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id = ?::uuid", Long.class,
                gid, me.userId())).as("the owner is linked to exactly one member").isEqualTo(1L);
        assertThat(body(g).get("members").get(0).get("isYou").asBoolean()).isTrue();
        assertThat(body(g).get("yourMemberId").asText()).isEqualTo(body(g).get("members").get(0).get("id").asText());
        assertThat(row.get("created_at").toString()).doesNotContain("2001");

        // group update
        MvcResult patch = call(PATCH, "/api/v1/groups/" + gid, me,
                withForbidden(Map.of("name", "Renamed"), other, foreignGroup), "If-Match", "\"1\"");
        assertThat(status(patch)).isEqualTo(200);
        row = jdbc.queryForMap("select owner_user_id::text as owner, version, name from expense_groups where id = ?::uuid", gid);
        assertThat(row.get("owner")).isEqualTo(me.userId().toString());
        assertThat(row.get("version")).isEqualTo(2);
        assertThat(row.get("name")).isEqualTo("Renamed");

        // members
        MvcResult m1 = call(POST, "/api/v1/groups/" + gid + "/members", me,
                withForbidden(Map.of("displayName", "A"), other, foreignGroup));
        assertThat(status(m1)).isEqualTo(201);
        String a = body(m1).get("id").asText();
        String b = body(call(POST, "/api/v1/groups/" + gid + "/members", me, withForbidden(Map.of("displayName", "B"),
                other, foreignGroup))).get("id").asText();
        Map<String, Object> member = jdbc.queryForMap("select group_id::text as grp, sort_order, user_id from members "
                + "where id = ?::uuid", a);
        assertThat(member.get("grp")).isEqualTo(gid);
        assertThat(member.get("sort_order")).isEqualTo(2);              // after the owner's member #1
        assertThat(member.get("user_id")).as("a client cannot link a member to an account").isNull();
        assertThat(body(m1).get("isYou").asBoolean()).isFalse();
        Map<String, Object> roleRow = jdbc.queryForMap("select role, status, left_at, joined_at from members where id = ?::uuid", a);
        assertThat(roleRow.get("role")).as("a client cannot choose a member's role").isEqualTo("MEMBER");
        assertThat(roleRow.get("status")).isEqualTo("ACTIVE");
        assertThat(roleRow.get("left_at")).isNull();
        assertThat(roleRow.get("joined_at").toString()).doesNotContain("2001");
        assertThat(body(m1).get("role").asText()).isEqualTo("MEMBER");
        assertThat(body(m1).get("hasAccount").asBoolean()).isFalse();
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and role = 'OWNER'", Long.class, gid))
                .as("still exactly one owner").isEqualTo(1L);
        assertThat(body(g).get("yourRole").asText()).isEqualTo("OWNER");
        assertThat(jdbc.queryForObject("select sort_order from members where id = ?::uuid", Integer.class, b)).isEqualTo(3);
        // B12: role and status ARE fields of the member PATCH now, so they are not "ignored" any more: a forbidden value
        // is refused (422) and nothing of the request is applied; everything else in the evil body is still ignored.
        Map<String, Object> patchBody = withForbidden(Map.of("displayName", "A2"), other, foreignGroup);
        assertThat(status(call(PATCH, "/api/v1/groups/" + gid + "/members/" + a, me, patchBody))).isEqualTo(422);
        assertThat(jdbc.queryForObject("select display_name from members where id = ?::uuid", String.class, a)).isEqualTo("A");
        patchBody.remove("role");
        patchBody.remove("status");
        assertThat(status(call(PATCH, "/api/v1/groups/" + gid + "/members/" + a, me, patchBody))).isEqualTo(200);
        assertThat(jdbc.queryForObject("select sort_order from members where id = ?::uuid", Integer.class, a)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select role from members where id = ?::uuid", String.class, a)).isEqualTo("MEMBER");

        // profile
        String emailBefore = jdbc.queryForObject("select email from users where id = ?::uuid", String.class, me.userId());
        assertThat(status(call(PATCH, "/api/v1/me", me, withForbidden(Map.of("displayName", "Me2"), other,
                foreignGroup)))).isEqualTo(200);
        Map<String, Object> user = jdbc.queryForMap("select email, auth_subject, display_name from users where id = ?::uuid",
                me.userId());
        assertThat(user.get("email")).isEqualTo(emailBefore);
        assertThat(user.get("auth_subject")).isNotEqualTo("stolen");
        assertThat(user.get("display_name")).isEqualTo("Me2");

        // expense create and update (EQUAL: the itemized-only and derived numbers must not stick)
        Map<String, Object> expenseBody = withForbidden(equalBody("Dinner", 3000, null, a, 3000L), other, foreignGroup);
        MvcResult e = call(POST, "/api/v1/groups/" + gid + "/expenses", me, expenseBody, "Idempotency-Key", key);
        assertThat(status(e)).as(e.getResponse().getContentAsString()).isEqualTo(201);
        JsonNode created = body(e);
        String eid = created.get("id").asText();
        assertThat(eid).isNotEqualTo(expenseBody.get("id"));
        assertThat(created.get("version").asInt()).isEqualTo(1);
        assertThat(created.get("groupId").asText()).isEqualTo(gid);
        Map<String, Object> expense = jdbc.queryForMap("select group_id::text as grp, created_by_user_id::text as creator, "
                + "version, deleted_at, subtotal_minor, created_at from expenses where id = ?::uuid", eid);
        assertThat(expense.get("grp")).isEqualTo(gid);
        assertThat(expense.get("creator")).isEqualTo(me.userId().toString());
        assertThat(expense.get("version")).isEqualTo(1);
        assertThat(expense.get("deleted_at")).isNull();
        assertThat(expense.get("subtotal_minor")).isNull();
        assertThat(expense.get("created_at").toString()).doesNotContain("2001");
        assertThat(jdbc.queryForObject("select sum(owed_minor) from expense_splits where expense_id = ?::uuid", Long.class,
                eid)).isEqualTo(3000L);

        MvcResult put = call(PUT, "/api/v1/groups/" + gid + "/expenses/" + eid, me,
                withForbidden(equalBody("Dinner 2", 4000, null, a, 4000L), other, foreignGroup), "If-Match", "\"1\"");
        assertThat(status(put)).isEqualTo(200);
        expense = jdbc.queryForMap("select group_id::text as grp, version, deleted_at, created_by_user_id::text as creator "
                + "from expenses where id = ?::uuid", eid);
        assertThat(expense.get("grp")).isEqualTo(gid);
        assertThat(expense.get("version")).isEqualTo(2);                     // the server's bump, not the client's 99
        assertThat(expense.get("deleted_at")).isNull();
        assertThat(expense.get("creator")).isEqualTo(me.userId().toString());

        // settlement
        Map<String, Object> pay = withForbidden(Map.of("fromMemberId", b, "toMemberId", a, "amountMinor", 100L,
                "settledOn", "2026-10-20"), other, foreignGroup);
        MvcResult s = call(POST, "/api/v1/groups/" + gid + "/settlements", me, pay, "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(s)).isEqualTo(201);
        Map<String, Object> settlement = jdbc.queryForMap("select group_id::text as grp, created_by_user_id::text as creator, "
                + "deleted_at from settlements where id = ?::uuid", body(s).get("id").asText());
        assertThat(settlement.get("grp")).isEqualTo(gid);
        assertThat(settlement.get("creator")).isEqualTo(me.userId().toString());
        assertThat(settlement.get("deleted_at")).isNull();

        // nothing leaked into the other user's group
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Long.class, foreignGroup))
                .as("only the other owner's own member").isEqualTo(1L);
        assertThat(countExpenses(foreignGroup)).isZero();
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, foreignGroup))
                .isZero();
    }
}
