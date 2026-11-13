package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B13: who may create which settlement (A85), the lifecycle PENDING -> CONFIRMED / DISPUTED / CANCELLED, who may act
 * (the payer never confirms their own payment), idempotent repeats, authorization precedence, mass assignment and
 * that nothing is ever deleted. The state table itself is covered cell by cell in SettlementTransitionsTest.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class SettlementLifecycleIT extends AbstractApiIT {

    private final class Cast {
        final Session owner = newUser();
        final Session admin = newUser();
        final Session member = newUser();
        final Session member2 = newUser();
        final Session stranger = newUser();
        final String gid;
        final String ownerMid;
        final String adminMid;
        final String memberMid;
        final String member2Mid;
        final String ghostMid;

        Cast() throws Exception {
            gid = createGroup(owner, "Settle " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            adminMid = linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
            memberMid = linkUser(gid, member, "MEMBER", "ACTIVE", "Member");
            member2Mid = linkUser(gid, member2, "MEMBER", "ACTIVE", "Member2");
            ghostMid = addMember(owner, gid, "Ghost").get("id").asText();
        }

        String base() {
            return "/api/v1/groups/" + gid;
        }

        MvcResult create(Session as, String from, String to, long amount) throws Exception {
            return call(POST, base() + "/settlements", as, bodyOf(from, to, amount),
                    "Idempotency-Key", UUID.randomUUID().toString());
        }

        /** Creates and returns the new settlement's view; fails the test on anything but 201. */
        JsonNode created(Session as, String from, String to, long amount) throws Exception {
            MvcResult r = create(as, from, to, amount);
            assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
            return body(r);
        }

        MvcResult act(Session as, String sid, String action) throws Exception {
            return call(POST, base() + "/settlements/" + sid + "/" + action, as, null);
        }

        String dbStatus(String sid) {
            return jdbc.queryForObject("select status from settlements where id = ?::uuid", String.class, sid);
        }
    }

    private static Map<String, Object> bodyOf(String from, String to, long amount) {
        Map<String, Object> b = new LinkedHashMap<>();
        b.put("fromMemberId", from);
        b.put("toMemberId", to);
        b.put("amountMinor", amount);
        b.put("settledOn", "2026-10-20");
        return b;
    }

    // ---- creation: the initial status is the server's decision (A85) ---------------------------------------------

    @Test
    void theInitialStatusFollowsWhoRecordsWhat() throws Exception {
        Cast c = new Cast();

        JsonNode declared = c.created(c.member, c.memberMid, c.member2Mid, 1000);      // the payer declares
        assertThat(declared.get("status").asText()).isEqualTo("PENDING");
        assertThat(declared.get("recordedByAdmin").asBoolean()).isFalse();
        assertThat(declared.get("createdByMemberId").asText()).isEqualTo(c.memberMid);
        assertThat(declared.get("declaredAt").isNull()).isFalse();
        assertThat(declared.get("confirmedAt").isNull()).isTrue();

        JsonNode receipt = c.created(c.member, c.member2Mid, c.memberMid, 1000);       // the receiver records: confirmed
        assertThat(receipt.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(receipt.get("recordedByAdmin").asBoolean()).isFalse();
        assertThat(receipt.get("confirmedAt").isNull()).isFalse();

        JsonNode fromGhost = c.created(c.member, c.ghostMid, c.memberMid, 500);        // cash received from a ghost
        assertThat(fromGhost.get("status").asText()).isEqualTo("CONFIRMED");

        JsonNode adminPays = c.created(c.admin, c.adminMid, c.ownerMid, 700);          // an admin declaring for themselves
        assertThat(adminPays.get("status").asText()).isEqualTo("PENDING");
        assertThat(adminPays.get("recordedByAdmin").asBoolean()).isFalse();

        JsonNode onBehalf = c.created(c.admin, c.member2Mid, c.ownerMid, 300);         // an admin on behalf of two others
        assertThat(onBehalf.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(onBehalf.get("recordedByAdmin").asBoolean()).isTrue();

        JsonNode ownerOnBehalf = c.created(c.owner, c.ghostMid, c.member2Mid, 200);
        assertThat(ownerOnBehalf.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(ownerOnBehalf.get("recordedByAdmin").asBoolean()).isTrue();

        JsonNode toGhost = c.created(c.owner, c.ownerMid, c.ghostMid, 100);            // nobody could ever confirm a ghost
        assertThat(toGhost.get("status").asText()).isEqualTo("CONFIRMED");
        assertThat(toGhost.get("recordedByAdmin").asBoolean()).isTrue();
    }

    @Test
    void aMemberCannotRecordForOthersOrDeclareToAGhostAndNothingIsStored() throws Exception {
        Cast c = new Cast();
        long before = jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, c.gid);

        for (MvcResult r : new MvcResult[] {
                c.create(c.member, c.member2Mid, c.ownerMid, 100),     // between two other members
                c.create(c.member, c.ownerMid, c.ghostMid, 100),       // between an owner and a ghost
                c.create(c.member, c.memberMid, c.ghostMid, 100)}) {   // declaring to a ghost: nobody could confirm it
            assertThat(status(r)).isEqualTo(403);
            assertThat(code(r)).isEqualTo("FORBIDDEN");
        }
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, c.gid))
                .isEqualTo(before);
    }

    @Test
    void aStrangerGets404OnEveryRoute() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.member, c.memberMid, c.member2Mid, 100).get("id").asText();
        MvcResult foreignCreate = c.create(c.stranger, c.memberMid, c.member2Mid, 100);
        assertThat(status(foreignCreate)).isEqualTo(404);
        for (String action : new String[] {"confirm", "dispute", "cancel"}) {
            MvcResult foreign = c.act(c.stranger, sid, action);
            MvcResult nothing = call(POST, "/api/v1/groups/" + UUID.randomUUID() + "/settlements/" + UUID.randomUUID()
                    + "/" + action, c.stranger, null);
            assertThat(status(foreign)).as(action).isEqualTo(404);
            assertThat(problemWithoutRequestId(foreign)).as(action).isEqualTo(problemWithoutRequestId(nothing));
        }
        assertThat(c.dbStatus(sid)).isEqualTo("PENDING");
    }

    @Test
    void anUnknownSettlementAndASettlementOfAnotherGroupAre404ForAMember() throws Exception {
        Cast c = new Cast();
        Cast other = new Cast();
        String foreign = other.created(other.member, other.memberMid, other.member2Mid, 100).get("id").asText();
        assertThat(status(c.act(c.owner, UUID.randomUUID().toString(), "cancel"))).isEqualTo(404);
        assertThat(status(c.act(c.owner, foreign, "cancel"))).isEqualTo(404);
        assertThat(other.dbStatus(foreign)).isEqualTo("PENDING");
    }

    // ---- the lifecycle ---------------------------------------------------------------------------------------------

    @Test
    void pendingConfirmedIsFinalAndEveryRepeatIsAnIdempotentNoOp() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.member, c.memberMid, c.member2Mid, 1000).get("id").asText();

        MvcResult first = c.act(c.member2, sid, "confirm");
        assertThat(status(first)).isEqualTo(200);
        JsonNode view = body(first);
        assertThat(view.get("status").asText()).isEqualTo("CONFIRMED");
        String stamp = view.get("confirmedAt").asText();
        assertThat(stamp).isNotBlank();

        JsonNode again = body(c.act(c.member2, sid, "confirm"));                        // repeat: same view, same timestamp
        assertThat(again.get("confirmedAt").asText()).isEqualTo(stamp);
        assertThat(body(c.act(c.owner, sid, "confirm")).get("confirmedAt").asText()).isEqualTo(stamp);   // even by a manager

        for (String action : new String[] {"dispute", "cancel"}) {
            MvcResult r = c.act(action.equals("dispute") ? c.member2 : c.member, sid, action);
            assertThat(status(r)).as(action).isEqualTo(409);
            assertThat(code(r)).as(action).isEqualTo("INVALID_STATE_TRANSITION");
        }
        assertThat(c.dbStatus(sid)).isEqualTo("CONFIRMED");
    }

    @Test
    void pendingDisputedThenConfirmedOrCancelled() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.member, c.memberMid, c.member2Mid, 1000).get("id").asText();

        JsonNode disputed = body(c.act(c.member2, sid, "dispute"));
        assertThat(disputed.get("status").asText()).isEqualTo("DISPUTED");
        String stamp = disputed.get("disputedAt").asText();
        assertThat(body(c.act(c.member2, sid, "dispute")).get("disputedAt").asText()).isEqualTo(stamp);   // no-op

        assertThat(status(c.act(c.member, sid, "confirm"))).as("the payer cannot resolve their own payment").isEqualTo(403);
        assertThat(status(c.act(c.member, sid, "dispute"))).isEqualTo(403);
        assertThat(status(c.act(c.member2, sid, "cancel"))).as("the receiver does not cancel").isEqualTo(403);

        JsonNode cancelled = body(c.act(c.member, sid, "cancel"));                       // the payer withdraws it
        assertThat(cancelled.get("status").asText()).isEqualTo("CANCELLED");
        assertThat(cancelled.get("disputedAt").asText()).as("history of the dispute is kept").isEqualTo(stamp);
        assertThat(body(c.act(c.owner, sid, "cancel")).get("cancelledAt").asText())
                .isEqualTo(cancelled.get("cancelledAt").asText());                      // repeat by a manager: no-op

        assertThat(code(c.act(c.member2, sid, "confirm"))).isEqualTo("INVALID_STATE_TRANSITION");
        assertThat(code(c.act(c.owner, sid, "confirm"))).isEqualTo("INVALID_STATE_TRANSITION");

        String other = c.created(c.member, c.memberMid, c.member2Mid, 400).get("id").asText();
        c.act(c.member2, other, "dispute");
        assertThat(body(c.act(c.member2, other, "confirm")).get("status").asText()).isEqualTo("CONFIRMED");   // receiver resolves
    }

    @Test
    void thePayerNeverConfirmsEvenAsAdminButAnotherAdminOrTheOwnerMay() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.admin, c.adminMid, c.ownerMid, 900).get("id").asText();   // the admin pays the owner
        MvcResult self = c.act(c.admin, sid, "confirm");
        assertThat(status(self)).isEqualTo(403);
        assertThat(code(self)).isEqualTo("FORBIDDEN");
        assertThat(status(c.act(c.member, sid, "confirm"))).as("an uninvolved member").isEqualTo(403);
        assertThat(c.dbStatus(sid)).isEqualTo("PENDING");
        assertThat(status(c.act(c.owner, sid, "confirm"))).isEqualTo(200);                  // the receiver

        String memberPaid = c.created(c.member, c.memberMid, c.member2Mid, 900).get("id").asText();
        assertThat(status(c.act(c.admin, memberPaid, "confirm"))).as("an admin on behalf of the receiver").isEqualTo(200);
        assertThat(status(c.act(c.admin, c.created(c.member, c.memberMid, c.member2Mid, 50).get("id").asText(), "dispute")))
                .as("only the receiver disputes").isEqualTo(403);
    }

    @Test
    void aCancelledSettlementStaysInTheHistoryAndFiltersFindIt() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.member, c.memberMid, c.member2Mid, 1000).get("id").asText();
        c.created(c.member, c.member2Mid, c.memberMid, 100);                                // a confirmed one
        assertThat(status(c.act(c.admin, sid, "cancel"))).as("an admin may cancel").isEqualTo(200);

        JsonNode all = body(call(GET, c.base() + "/settlements", c.member, null));
        assertThat(all.get("totalElements").asLong()).isEqualTo(2);
        JsonNode cancelled = body(call(GET, c.base() + "/settlements?status=CANCELLED", c.member, null));
        assertThat(cancelled.get("items")).hasSize(1);
        assertThat(cancelled.get("items").get(0).get("id").asText()).isEqualTo(sid);
        assertThat(body(call(GET, c.base() + "/settlements?status=PENDING&status=DISPUTED", c.member, null))
                .get("items")).isEmpty();
    }

    // ---- replay, mass assignment, immutability ---------------------------------------------------------------------

    @Test
    void aReplayedCreateReturnsTheStoredAnswerAndStoresOneRow() throws Exception {
        Cast c = new Cast();
        String key = UUID.randomUUID().toString();
        Map<String, Object> request = bodyOf(c.memberMid, c.member2Mid, 1500);
        MvcResult one = call(POST, c.base() + "/settlements", c.member, request, "Idempotency-Key", key);
        MvcResult two = call(POST, c.base() + "/settlements", c.member, request, "Idempotency-Key", key);

        assertThat(status(one)).isEqualTo(201);
        assertThat(status(two)).isEqualTo(201);
        assertThat(two.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(two)).isEqualTo(body(one));
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, c.gid))
                .isEqualTo(1L);
        c.act(c.member2, body(one).get("id").asText(), "confirm");                          // the stored body is a snapshot
        MvcResult three = call(POST, c.base() + "/settlements", c.member, request, "Idempotency-Key", key);
        assertThat(body(three)).as("a replay answers the original response").isEqualTo(body(one));
    }

    @Test
    void theClientCannotChooseTheStatusOrAnyServerField() throws Exception {
        Cast c = new Cast();
        Map<String, Object> request = bodyOf(c.memberMid, c.member2Mid, 1000);
        request.put("status", "CONFIRMED");
        request.put("confirmedAt", "2001-01-01T00:00:00Z");
        request.put("declaredAt", "2001-01-01T00:00:00Z");
        request.put("recordedByAdmin", true);
        request.put("createdByMemberId", c.ownerMid);
        request.put("createdAt", "2001-01-01T00:00:00Z");
        request.put("groupId", UUID.randomUUID().toString());
        MvcResult r = call(POST, c.base() + "/settlements", c.member, request, "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(r)).isEqualTo(201);

        Map<String, Object> row = jdbc.queryForMap("select status, confirmed_at, recorded_by_admin, group_id::text as grp, "
                + "created_by_member_id::text as creator, declared_at, created_at from settlements where id = ?::uuid",
                body(r).get("id").asText());
        assertThat(row.get("status")).isEqualTo("PENDING");
        assertThat(row.get("confirmed_at")).isNull();
        assertThat(row.get("recorded_by_admin")).isEqualTo(false);
        assertThat(row.get("grp")).isEqualTo(c.gid);
        assertThat(row.get("creator")).isEqualTo(c.memberMid);
        assertThat(row.get("declared_at").toString()).doesNotContain("2001");
        assertThat(row.get("created_at").toString()).doesNotContain("2001");
    }

    @Test
    void thereIsNoWayToDeleteASettlement() throws Exception {
        Cast c = new Cast();
        String sid = c.created(c.member, c.memberMid, c.member2Mid, 100).get("id").asText();
        for (Session s : new Session[] {c.member, c.admin, c.owner}) {
            assertThat(status(call(DELETE, c.base() + "/settlements/" + sid, s, null))).isIn(404, 405);
        }
        c.act(c.member, sid, "cancel");
        assertThat(jdbc.queryForObject("select count(*) from settlements where id = ?::uuid", Long.class, sid)).isEqualTo(1L);
        assertThat(c.dbStatus(sid)).isEqualTo("CANCELLED");
        assertThat(jdbc.queryForObject("select deleted_at is null from settlements where id = ?::uuid", Boolean.class, sid))
                .as("deleted_at is a legacy column that is no longer written").isTrue();
    }
}
