package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B15: every event type is written in the same transaction as its business change, with the right actor, payload and
 * recipients (A98); replays, no-ops and lost races write nothing (A95).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class GroupEventsIT extends AbstractActivityIT {

    private final class World {
        final Session owner = newUser();
        final Session admin = newUser();
        final Session alice = newUser();
        final Session bob = newUser();
        final Session carol = newUser();
        final String gid;
        final String ownerMid;
        final String adminMid;
        final String aliceMid;
        final String bobMid;
        final String carolMid;
        final String ghostMid;

        World() throws Exception {
            gid = createGroup(owner, "Events " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            adminMid = linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
            aliceMid = linkUser(gid, alice, "MEMBER", "ACTIVE", "Alice");
            bobMid = linkUser(gid, bob, "MEMBER", "ACTIVE", "Bob");
            carolMid = linkUser(gid, carol, "MEMBER", "ACTIVE", "Carol");
            ghostMid = addMember(owner, gid, "Ghost").get("id").asText();
        }

        String base() {
            return "/api/v1/groups/" + gid;
        }

        JsonNode expense(Session as, List<String> participants, String payer, long total) throws Exception {
            return createExpense(as, gid, equalBody("Dinner", total, participants, payer, total));
        }

        MvcResult settle(Session as, String from, String to, long amount) throws Exception {
            return call(POST, base() + "/settlements", as, Map.of("fromMemberId", from, "toMemberId", to,
                    "amountMinor", amount, "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString());
        }

        JsonNode invite(boolean approval) throws Exception {
            MvcResult r = call(POST, base() + "/invites", owner, Map.of("requiresApproval", approval),
                    "Idempotency-Key", UUID.randomUUID().toString());
            assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
            return body(r);
        }

        MvcResult join(Session as, String code, Object body, String key) throws Exception {
            return call(POST, "/api/v1/invites/" + code + "/join", as, body, "Idempotency-Key", key);
        }
    }

    // ---- expenses ---------------------------------------------------------------------------------------------------

    @Test
    void anExpenseAddedNotifiesPayersAndParticipantsWithAnAccountButNeverTheActorOrAGhost() throws Exception {
        World w = new World();
        JsonNode e = w.expense(w.alice, List.of(w.aliceMid, w.bobMid, w.ghostMid), w.aliceMid, 3000);

        Map<String, Object> event = onlyEvent(w.gid, "EXPENSE_ADDED");
        assertThat(event.get("actor").toString()).isEqualTo(w.aliceMid);
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("expenseId").asText()).isEqualTo(e.get("id").asText());
        assertThat(payload.get("version").asInt()).isEqualTo(1);
        assertThat(payload.get("totalMinor").asLong()).isEqualTo(3000);
        assertThat(recipients(event.get("id"))).as("Bob only: Alice is the actor, the ghost has no account, "
                + "the admin is not part of it").isEqualTo(ids(w.bob));
    }

    @Test
    void anItemizedExpenseNotifiesItsItemAssignees() throws Exception {
        World w = new World();
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("title", "Restaurant");
        body.put("expenseDate", "2026-10-18");
        body.put("splitType", "ITEMIZED");
        body.put("payers", List.of(Map.of("memberId", w.ownerMid, "amountMinor", 1000L)));
        body.put("items", List.of(Map.of("name", "Fish", "amountMinor", 600L, "assigneeMemberIds", List.of(w.aliceMid)),
                Map.of("name", "Rice", "amountMinor", 400L, "assigneeMemberIds", List.of(w.bobMid))));
        createExpense(w.owner, w.gid, body);

        assertThat(recipients(onlyEvent(w.gid, "EXPENSE_ADDED").get("id"))).isEqualTo(ids(w.alice, w.bob));
    }

    @Test
    void anEditNotifiesTheUnionOfThePreviousAndTheNewParticipants() throws Exception {
        World w = new World();
        JsonNode e = w.expense(w.owner, List.of(w.ownerMid, w.aliceMid, w.bobMid), w.ownerMid, 3000);
        String eid = e.get("id").asText();

        MvcResult edited = call(PUT, w.base() + "/expenses/" + eid, w.owner,
                equalBody("Dinner", 2000, List.of(w.ownerMid, w.aliceMid, w.carolMid), w.ownerMid, 2000L),
                "If-Match", "\"1\"");
        assertThat(status(edited)).as(edited.getResponse().getContentAsString()).isEqualTo(200);

        Map<String, Object> event = onlyEvent(w.gid, "EXPENSE_EDITED");
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("version").asInt()).isEqualTo(2);
        assertThat(payload.get("totalMinor").asLong()).isEqualTo(2000);
        assertThat(recipients(event.get("id"))).as("Alice stays, Bob was removed, Carol was added; each once")
                .isEqualTo(ids(w.alice, w.bob, w.carol));
    }

    @Test
    void aDeleteNotifiesThePreviousParticipantsAndASoftDeletedExpenseKeepsItsFeedRow() throws Exception {
        World w = new World();
        String eid = w.expense(w.owner, List.of(w.ownerMid, w.aliceMid, w.bobMid), w.ownerMid, 3000).get("id").asText();
        assertThat(status(call(DELETE, w.base() + "/expenses/" + eid, w.owner, null, "If-Match", "\"1\""))).isEqualTo(204);

        Map<String, Object> event = onlyEvent(w.gid, "EXPENSE_DELETED");
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("version").asInt()).isEqualTo(2);
        assertThat(payload.has("totalMinor")).isFalse();
        assertThat(recipients(event.get("id"))).isEqualTo(ids(w.alice, w.bob));
    }

    @Test
    void aMemberWhoLeftIsNotNotifiedAboutALaterDelete() throws Exception {
        World w = new World();
        String eid = w.expense(w.owner, List.of(w.ownerMid, w.aliceMid, w.bobMid), w.ownerMid, 3000).get("id").asText();
        assertThat(status(call(POST, w.base() + "/leave", w.bob, null))).isEqualTo(204);
        assertThat(status(call(DELETE, w.base() + "/expenses/" + eid, w.owner, null, "If-Match", "\"1\""))).isEqualTo(204);

        assertThat(recipients(onlyEvent(w.gid, "EXPENSE_DELETED").get("id"))).isEqualTo(ids(w.alice));
    }

    // ---- settlements ------------------------------------------------------------------------------------------------

    @Test
    void aDeclaredPaymentNotifiesOnlyTheReceiverAndARecordedOneNotifiesTheOtherParty() throws Exception {
        World w = new World();
        assertThat(status(w.settle(w.alice, w.aliceMid, w.bobMid, 500))).isEqualTo(201);
        Map<String, Object> pending = onlyEvent(w.gid, "SETTLEMENT_PENDING");
        assertThat(pending.get("actor").toString()).isEqualTo(w.aliceMid);
        JsonNode payload = json.readTree((String) pending.get("payload"));
        assertThat(payload.get("amountMinor").asLong()).isEqualTo(500);
        assertThat(payload.get("fromMemberId").asText()).isEqualTo(w.aliceMid);
        assertThat(payload.get("toMemberId").asText()).isEqualTo(w.bobMid);
        assertThat(recipients(pending.get("id"))).isEqualTo(ids(w.bob));

        assertThat(status(w.settle(w.bob, w.aliceMid, w.bobMid, 700))).as("the receiver records it: CONFIRMED").isEqualTo(201);
        Map<String, Object> confirmed = onlyEvent(w.gid, "SETTLEMENT_CONFIRMED");
        assertThat(confirmed.get("actor").toString()).isEqualTo(w.bobMid);
        assertThat(recipients(confirmed.get("id"))).isEqualTo(ids(w.alice));
    }

    @Test
    void confirmDisputeAndCancelEachWriteOneEventForTheRightPeople() throws Exception {
        World w = new World();
        String s1 = body(w.settle(w.alice, w.aliceMid, w.bobMid, 500)).get("id").asText();
        String s2 = body(w.settle(w.alice, w.aliceMid, w.bobMid, 600)).get("id").asText();
        String s3 = body(w.settle(w.alice, w.aliceMid, w.bobMid, 700)).get("id").asText();

        assertThat(status(call(POST, w.base() + "/settlements/" + s1 + "/confirm", w.bob, null))).isEqualTo(200);
        assertThat(status(call(POST, w.base() + "/settlements/" + s2 + "/dispute", w.bob, null))).isEqualTo(200);
        assertThat(status(call(POST, w.base() + "/settlements/" + s3 + "/cancel", w.alice, null))).isEqualTo(200);

        assertThat(recipients(onlyEvent(w.gid, "SETTLEMENT_CONFIRMED").get("id"))).isEqualTo(ids(w.alice));
        assertThat(recipients(onlyEvent(w.gid, "SETTLEMENT_DISPUTED").get("id")))
                .as("the payer and the managers, not the receiver who disputed").isEqualTo(ids(w.alice, w.owner, w.admin));
        assertThat(recipients(onlyEvent(w.gid, "SETTLEMENT_CANCELLED").get("id"))).isEqualTo(ids(w.bob));
    }

    @Test
    void aRepeatedTransitionIsANoOpWithoutASecondEvent() throws Exception {
        World w = new World();
        String sid = body(w.settle(w.alice, w.aliceMid, w.bobMid, 500)).get("id").asText();
        assertThat(status(call(POST, w.base() + "/settlements/" + sid + "/confirm", w.bob, null))).isEqualTo(200);
        long events = eventCount(w.gid);
        long notifications = notificationCount(w.gid);

        assertThat(status(call(POST, w.base() + "/settlements/" + sid + "/confirm", w.bob, null))).isEqualTo(200);

        assertThat(eventCount(w.gid)).isEqualTo(events);
        assertThat(notificationCount(w.gid)).isEqualTo(notifications);
        assertThat(eventsOf(w.gid, "SETTLEMENT_CONFIRMED")).hasSize(1);
    }

    @Test
    void ofTwoParallelConfirmsOnlyTheWinnerWritesAnEvent() throws Exception {
        World w = new World();
        String sid = body(w.settle(w.alice, w.aliceMid, w.bobMid, 500)).get("id").asText();
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Callable<Integer> confirm = () -> status(call(POST, w.base() + "/settlements/" + sid + "/confirm", w.bob, null));
            Future<Integer> a = pool.submit(confirm);
            Future<Integer> b = pool.submit(confirm);
            assertThat(a.get()).isEqualTo(200);
            assertThat(b.get()).isEqualTo(200);
        } finally {
            pool.shutdownNow();
        }
        assertThat(eventsOf(w.gid, "SETTLEMENT_CONFIRMED")).hasSize(1);
    }

    // ---- joining ----------------------------------------------------------------------------------------------------

    @Test
    void joiningWithAnInviteNotifiesTheInviterAndTheManagersAndAReplayWritesNothingMore() throws Exception {
        World w = new World();
        String code = w.invite(false).get("code").asText();
        Session joiner = newUser();
        String key = UUID.randomUUID().toString();

        MvcResult first = w.join(joiner, code, Map.of("newMemberName", "Newcomer"), key);
        assertThat(status(first)).as(first.getResponse().getContentAsString()).isEqualTo(201);
        String newMid = body(first).get("member").get("id").asText();

        Map<String, Object> event = onlyEvent(w.gid, "INVITE_ACCEPTED");
        assertThat(event.get("actor").toString()).isEqualTo(newMid);
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("memberId").asText()).isEqualTo(newMid);
        assertThat(payload.has("inviteId")).isTrue();
        assertThat(recipients(event.get("id"))).as("the inviter (Owner) and the Admin; not the joiner")
                .isEqualTo(ids(w.owner, w.admin));

        MvcResult replay = w.join(joiner, code, Map.of("newMemberName", "Newcomer"), key);
        assertThat(replay.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(eventsOf(w.gid, "INVITE_ACCEPTED")).as("a replay writes no second event").hasSize(1);
    }

    @Test
    void claimingAGhostAndRejoiningAfterLeavingAreAcceptedInvitesToo() throws Exception {
        World w = new World();
        String code = w.invite(false).get("code").asText();
        Session claimer = newUser();
        assertThat(status(w.join(claimer, code, Map.of("claimMemberId", w.ghostMid), UUID.randomUUID().toString())))
                .isEqualTo(201);
        assertThat(status(call(POST, w.base() + "/leave", claimer, null))).isEqualTo(204);
        assertThat(status(w.join(claimer, code, Map.of("claimMemberId", w.ghostMid), UUID.randomUUID().toString())))
                .as("A79: the person's own LEFT member is reactivated").isEqualTo(201);

        assertThat(eventsOf(w.gid, "INVITE_ACCEPTED")).hasSize(2);
        assertThat(eventsOf(w.gid, "MEMBER_LEFT")).hasSize(1);
    }

    @Test
    void askingTwiceForApprovalWritesOneJoinRequestedEventForManagersWithoutAnActor() throws Exception {
        World w = new World();
        String code = w.invite(true).get("code").asText();
        Session asker = newUser();
        for (int i = 0; i < 2; i++) {
            MvcResult r = w.join(asker, code, Map.of("newMemberName", "Asker"), UUID.randomUUID().toString());
            assertThat(status(r)).isEqualTo(202);
        }

        Map<String, Object> event = onlyEvent(w.gid, "JOIN_REQUESTED");
        assertThat(event.get("actor")).isNull();
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.has("requestId")).isTrue();
        assertThat(payload.has("memberId")).as("a new member has no id yet").isFalse();
        assertThat(recipients(event.get("id"))).isEqualTo(ids(w.owner, w.admin));
    }

    @Test
    void approvingAJoinRequestNotifiesThePersonAndTheOtherManagersNotTheApprover() throws Exception {
        World w = new World();
        String code = w.invite(true).get("code").asText();
        Session asker = newUser();
        String rid = body(w.join(asker, code, Map.of("newMemberName", "Asker"), UUID.randomUUID().toString()))
                .get("requestId").asText();

        assertThat(status(call(POST, w.base() + "/join-requests/" + rid + "/approve", w.owner, null))).isEqualTo(200);

        Map<String, Object> event = onlyEvent(w.gid, "MEMBER_JOINED");
        assertThat(event.get("actor").toString()).isEqualTo(w.ownerMid);
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("requestId").asText()).isEqualTo(rid);
        assertThat(recipients(event.get("id"))).isEqualTo(ids(asker, w.admin));
        assertThat(eventsOf(w.gid, "INVITE_ACCEPTED")).as("approval is MEMBER_JOINED, not INVITE_ACCEPTED").isEmpty();

        call(POST, w.base() + "/join-requests/" + rid + "/approve", w.owner, null);   // repeating a decision
        assertThat(eventsOf(w.gid, "MEMBER_JOINED")).hasSize(1);
    }

    // ---- member lifecycle -------------------------------------------------------------------------------------------

    @Test
    void leavingNotifiesTheManagersAndRemovingAMemberNotifiesTheOtherManagersButNotTheRemoved() throws Exception {
        World w = new World();
        assertThat(status(call(POST, w.base() + "/leave", w.alice, null))).isEqualTo(204);
        Map<String, Object> left = onlyEvent(w.gid, "MEMBER_LEFT");
        assertThat(left.get("actor").toString()).isEqualTo(w.aliceMid);
        JsonNode payload = json.readTree((String) left.get("payload"));
        assertThat(payload.get("memberId").asText()).isEqualTo(w.aliceMid);
        assertThat(payload.get("previousRole").asText()).isEqualTo("MEMBER");
        assertThat(recipients(left.get("id"))).isEqualTo(ids(w.owner, w.admin));

        MvcResult removed = call(PATCH, w.base() + "/members/" + w.bobMid, w.admin, Map.of("status", "LEFT"));
        assertThat(status(removed)).isEqualTo(200);
        List<Map<String, Object>> all = eventsOf(w.gid, "MEMBER_LEFT");
        assertThat(all).hasSize(2);
        Map<String, Object> byAdmin = all.get(1);
        assertThat(byAdmin.get("actor").toString()).isEqualTo(w.adminMid);
        assertThat(recipients(byAdmin.get("id"))).as("the Owner only: the admin is the actor, Bob has no access")
                .isEqualTo(ids(w.owner));
    }

    @Test
    void reactivatingAMemberNotifiesThatMember() throws Exception {
        World w = new World();
        call(PATCH, w.base() + "/members/" + w.bobMid, w.admin, Map.of("status", "LEFT"));
        assertThat(status(call(PATCH, w.base() + "/members/" + w.bobMid, w.admin, Map.of("status", "ACTIVE")))).isEqualTo(200);

        Map<String, Object> event = onlyEvent(w.gid, "MEMBER_REACTIVATED");
        assertThat(event.get("actor").toString()).isEqualTo(w.adminMid);
        assertThat(recipients(event.get("id"))).isEqualTo(ids(w.bob));
    }

    @Test
    void aRoleChangeNotifiesTheAffectedMemberWithTheOldAndTheNewRoleAndASecondSameChangeWritesNothing() throws Exception {
        World w = new World();
        assertThat(status(call(PATCH, w.base() + "/members/" + w.aliceMid, w.owner, Map.of("role", "ADMIN")))).isEqualTo(200);
        assertThat(status(call(PATCH, w.base() + "/members/" + w.aliceMid, w.owner, Map.of("role", "ADMIN")))).isEqualTo(200);

        Map<String, Object> event = onlyEvent(w.gid, "ROLE_CHANGED");
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("role").asText()).isEqualTo("ADMIN");
        assertThat(payload.get("previousRole").asText()).isEqualTo("MEMBER");
        assertThat(recipients(event.get("id"))).isEqualTo(ids(w.alice));
    }

    @Test
    void aRenameAloneWritesNoEvent() throws Exception {
        World w = new World();
        assertThat(status(call(PATCH, w.base() + "/members/" + w.aliceMid, w.owner, Map.of("displayName", "Alice B"))))
                .isEqualTo(200);
        assertThat(eventCount(w.gid)).isZero();
    }

    @Test
    void transferringOwnershipNotifiesTheNewOwner() throws Exception {
        World w = new World();
        assertThat(status(call(POST, w.base() + "/transfer-ownership", w.owner, Map.of("toMemberId", w.adminMid))))
                .isEqualTo(204);

        Map<String, Object> event = onlyEvent(w.gid, "OWNERSHIP_TRANSFERRED");
        assertThat(event.get("actor").toString()).isEqualTo(w.ownerMid);
        JsonNode payload = json.readTree((String) event.get("payload"));
        assertThat(payload.get("memberId").asText()).isEqualTo(w.adminMid);
        assertThat(payload.get("previousRole").asText()).isEqualTo("ADMIN");
        assertThat(recipients(event.get("id"))).isEqualTo(ids(w.admin));
    }

    @Test
    void unlinkingAnAccountIsInTheFeedOnlyAndUnlinkingAGhostIsNotAnEvent() throws Exception {
        World w = new World();
        assertThat(status(call(POST, w.base() + "/members/" + w.ghostMid + "/unlink", w.owner, null))).isEqualTo(204);
        assertThat(eventsOf(w.gid, "MEMBER_UNLINKED")).as("a member without an account: nothing changed").isEmpty();

        assertThat(status(call(POST, w.base() + "/members/" + w.bobMid + "/unlink", w.owner, null))).isEqualTo(204);
        Map<String, Object> event = onlyEvent(w.gid, "MEMBER_UNLINKED");
        assertThat(event.get("actor").toString()).isEqualTo(w.ownerMid);
        assertThat(recipients(event.get("id"))).isEmpty();
        assertThat(notificationCount(w.gid)).isZero();
    }

    @Test
    void groupEditsInvitesAndGhostChangesAreNotEvents() throws Exception {
        World w = new World();
        w.invite(false);
        addMember(w.owner, w.gid, "Another ghost");
        assertThat(status(call(PATCH, w.base(), w.owner, Map.of("name", "Renamed"), "If-Match", "\"1\"")))
                .isEqualTo(200);
        assertThat(eventCount(w.gid)).isZero();
    }

    @Test
    void everyEventTypeOfTheEnumIsAcceptedByTheDatabaseConstraint() {
        World w;
        try {
            w = new World();
        } catch (Exception e) {
            throw new AssertionError(e);
        }
        for (app.qesma.service.EventType t : app.qesma.service.EventType.values()) {
            jdbc.update("insert into group_events (id, group_id, type, payload, created_at) values (?, ?::uuid, ?, '{}'::jsonb, now())",
                    UUID.randomUUID(), w.gid, t.name());
        }
        assertThat(eventCount(w.gid)).isEqualTo(app.qesma.service.EventType.values().length);
    }
}
