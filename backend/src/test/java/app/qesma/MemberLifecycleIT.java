package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B12 member lifecycle (Decisions A77-A82): the full (actor, target, action) transition table, LEFT semantics in new
 * records and in history, ownership transfer atomicity and races, rejoin through an invite. One test per table cell
 * group; every test builds its own group, so tests are independent.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class MemberLifecycleIT extends AbstractApiIT {

    private static String key() {
        return UUID.randomUUID().toString();
    }

    /** A group with an owner, an admin, a member, a LEFT member, a ghost and a stranger. */
    private final class W {
        final Session owner = newUser();
        final Session admin = newUser();
        final Session member = newUser();
        final Session left = newUser();
        final Session stranger = newUser();
        final String gid;
        final String base;
        final String ownerMid;
        final String adminMid;
        final String memberMid;
        final String leftMid;
        final String ghost;

        W() throws Exception {
            gid = createGroup(owner, "Life " + UUID.randomUUID()).get("id").asText();
            base = "/api/v1/groups/" + gid;
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            adminMid = linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
            memberMid = linkUser(gid, member, "MEMBER", "ACTIVE", "Member");
            leftMid = linkUser(gid, left, "MEMBER", "LEFT", "Gone");
            ghost = addMember(owner, gid, "Ghost").get("id").asText();
        }

        MvcResult patch(Session as, String mid, Map<String, Object> body) throws Exception {
            return call(PATCH, base + "/members/" + mid, as, body);
        }

        MvcResult leave(Session as) throws Exception {
            return call(POST, base + "/leave", as, null);
        }

        MvcResult transfer(Session as, String toMid) throws Exception {
            return call(POST, base + "/transfer-ownership", as, Map.of("toMemberId", toMid));
        }

        String role(String mid) {
            return jdbc.queryForObject("select role from members where id = ?::uuid", String.class, mid);
        }

        String status(String mid) {
            return jdbc.queryForObject("select status from members where id = ?::uuid", String.class, mid);
        }

        int owners() {
            return jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and role = 'OWNER'",
                    Integer.class, gid);
        }
    }

    private void assertProblem(MvcResult r, int status, String code) throws Exception {
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(status);
        assertThat(code(r)).isEqualTo(code);
    }

    // ---- Owner ---------------------------------------------------------------------------------------------------

    @Test
    void ownerCannotLeaveEvenWhenAlone() throws Exception {
        W w = new W();
        assertProblem(w.leave(w.owner), 409, "OWNER_MUST_TRANSFER");
        Session solo = newUser();
        String g = createGroup(solo, "Solo " + UUID.randomUUID()).get("id").asText();
        assertProblem(call(POST, "/api/v1/groups/" + g + "/leave", solo, null), 409, "OWNER_MUST_TRANSFER");
        assertThat(w.status(w.ownerMid)).isEqualTo("ACTIVE");
    }

    @Test
    void ownersOwnRoleAndStatusAreProtected() throws Exception {
        W w = new W();
        assertProblem(w.patch(w.owner, w.ownerMid, Map.of("role", "MEMBER")), 409, "OWNER_MEMBER_PROTECTED");
        assertProblem(w.patch(w.owner, w.ownerMid, Map.of("status", "LEFT")), 409, "OWNER_MEMBER_PROTECTED");
        assertThat(w.role(w.ownerMid)).isEqualTo("OWNER");
    }

    @Test
    void ownerDemotesAnAdminAndPromotesAMember() throws Exception {
        W w = new W();
        MvcResult demoted = w.patch(w.owner, w.adminMid, Map.of("role", "MEMBER"));
        assertThat(status(demoted)).isEqualTo(200);
        assertThat(body(demoted).get("role").asText()).isEqualTo("MEMBER");
        MvcResult promoted = w.patch(w.owner, w.memberMid, Map.of("role", "ADMIN"));
        assertThat(status(promoted)).isEqualTo(200);
        assertThat(w.role(w.memberMid)).isEqualTo("ADMIN");
        assertThat(w.role(w.adminMid)).isEqualTo("MEMBER");
    }

    @Test
    void roleOwnerThroughPatchIsRefusedAndOnlyKnownValuesPass() throws Exception {
        W w = new W();
        assertProblem(w.patch(w.owner, w.memberMid, Map.of("role", "OWNER")), 422, "VALIDATION_ERROR");
        assertProblem(w.patch(w.owner, w.memberMid, Map.of("role", "SUPERUSER")), 422, "VALIDATION_ERROR");
        assertProblem(w.patch(w.owner, w.memberMid, Map.of("status", "BANNED")), 422, "VALIDATION_ERROR");
        assertThat(w.role(w.memberMid)).isEqualTo("MEMBER");
        assertThat(w.owners()).isEqualTo(1);
    }

    @Test
    void ownerRemovesAnAdminAndAMemberAndTheyLoseAccessWithRoleReset() throws Exception {
        W w = new W();
        assertThat(status(w.patch(w.owner, w.adminMid, Map.of("status", "LEFT")))).isEqualTo(200);
        assertThat(status(w.patch(w.owner, w.memberMid, Map.of("status", "LEFT")))).isEqualTo(200);
        assertThat(w.status(w.adminMid)).isEqualTo("LEFT");
        assertThat(w.role(w.adminMid)).as("least privilege on return").isEqualTo("MEMBER");
        assertThat(jdbc.queryForObject("select left_at is not null from members where id = ?::uuid", Boolean.class,
                w.adminMid)).isTrue();
        assertProblem(call(GET, w.base, w.admin, null), 404, "NOT_FOUND");
        assertProblem(call(GET, w.base, w.member, null), 404, "NOT_FOUND");
    }

    @Test
    void ownerReactivatesALeftMemberWhoGetsAccessBack() throws Exception {
        W w = new W();
        assertProblem(call(GET, w.base, w.left, null), 404, "NOT_FOUND");
        MvcResult r = w.patch(w.owner, w.leftMid, Map.of("status", "ACTIVE"));
        assertThat(status(r)).isEqualTo(200);
        assertThat(body(r).get("status").asText()).isEqualTo("ACTIVE");
        assertThat(status(call(GET, w.base, w.left, null))).isEqualTo(200);
        assertThat(jdbc.queryForObject("select left_at is null from members where id = ?::uuid", Boolean.class,
                w.leftMid)).isTrue();
    }

    @Test
    void ownerCanRenameAnyMember() throws Exception {
        W w = new W();
        assertThat(status(w.patch(w.owner, w.leftMid, Map.of("displayName", "Renamed Left")))).isEqualTo(200);
    }

    // ---- Admin ---------------------------------------------------------------------------------------------------

    @Test
    void adminRemovesAndReactivatesAMember() throws Exception {
        W w = new W();
        assertThat(status(w.patch(w.admin, w.memberMid, Map.of("status", "LEFT")))).isEqualTo(200);
        assertThat(w.status(w.memberMid)).isEqualTo("LEFT");
        assertThat(status(w.patch(w.admin, w.leftMid, Map.of("status", "ACTIVE")))).isEqualTo(200);
        assertThat(w.status(w.leftMid)).isEqualTo("ACTIVE");
    }

    @Test
    void adminCannotTouchAnotherAdminNorTheOwnerNorChangeRoles() throws Exception {
        W w = new W();
        Session admin2 = newUser();
        String admin2Mid = linkUser(w.gid, admin2, "ADMIN", "ACTIVE", "Admin Two");
        assertProblem(w.patch(w.admin, admin2Mid, Map.of("status", "LEFT")), 403, "FORBIDDEN");
        assertProblem(w.patch(w.admin, admin2Mid, Map.of("role", "MEMBER")), 403, "FORBIDDEN");
        assertProblem(w.patch(w.admin, w.memberMid, Map.of("role", "ADMIN")), 403, "FORBIDDEN");
        assertProblem(w.patch(w.admin, w.ownerMid, Map.of("status", "LEFT")), 409, "OWNER_MEMBER_PROTECTED");
        assertThat(w.status(admin2Mid)).isEqualTo("ACTIVE");
        assertThat(w.role(w.memberMid)).isEqualTo("MEMBER");
        assertThat(w.role(w.ownerMid)).isEqualTo("OWNER");
    }

    @Test
    void adminLeavesAndTheirRoleIsReset() throws Exception {
        W w = new W();
        assertThat(status(w.leave(w.admin))).isEqualTo(204);
        assertThat(w.status(w.adminMid)).isEqualTo("LEFT");
        assertThat(w.role(w.adminMid)).isEqualTo("MEMBER");
        assertProblem(call(GET, w.base, w.admin, null), 404, "NOT_FOUND");
    }

    @Test
    void adminCannotLeaveThroughPatchAndCannotTransfer() throws Exception {
        W w = new W();
        assertProblem(w.patch(w.admin, w.adminMid, Map.of("status", "LEFT")), 422, "VALIDATION_ERROR");
        assertProblem(w.transfer(w.admin, w.memberMid), 403, "FORBIDDEN");
        assertThat(w.status(w.adminMid)).isEqualTo("ACTIVE");
    }

    // ---- Member --------------------------------------------------------------------------------------------------

    @Test
    void memberCannotChangeRolesOrStatusOrTransfer() throws Exception {
        W w = new W();
        assertProblem(w.patch(w.member, w.memberMid, Map.of("role", "ADMIN")), 403, "FORBIDDEN");
        assertProblem(w.patch(w.member, w.adminMid, Map.of("status", "LEFT")), 403, "FORBIDDEN");
        assertProblem(w.patch(w.member, w.memberMid, Map.of("displayName", "X")), 403, "FORBIDDEN");
        assertProblem(w.transfer(w.member, w.adminMid), 403, "FORBIDDEN");
        assertThat(w.role(w.memberMid)).isEqualTo("MEMBER");
    }

    @Test
    void memberLeavesAndTheirBalanceStays() throws Exception {
        W w = new W();
        assertThat(status(w.leave(w.member))).isEqualTo(204);
        assertThat(w.status(w.memberMid)).isEqualTo("LEFT");
        assertProblem(w.leave(w.member), 404, "NOT_FOUND");                       // a second leave is a stranger's call
        JsonNode list = body(call(GET, "/api/v1/groups", w.member, null));
        assertThat(list.toString()).doesNotContain(w.gid);
    }

    // ---- LEFT and strangers --------------------------------------------------------------------------------------

    @Test
    void leftMemberAndStrangerAreStrangersToEveryEndpointAndGetTheSameBody() throws Exception {
        W w = new W();
        for (Session s : List.of(w.left, w.stranger)) {
            assertProblem(call(GET, w.base, s, null), 404, "NOT_FOUND");
            assertProblem(call(GET, w.base + "/balances", s, null), 404, "NOT_FOUND");
            assertProblem(w.patch(s, w.memberMid, Map.of("status", "LEFT")), 404, "NOT_FOUND");
            assertProblem(w.leave(s), 404, "NOT_FOUND");
            assertProblem(w.transfer(s, w.adminMid), 404, "NOT_FOUND");
        }
        assertThat(problemWithoutRequestId(call(GET, w.base, w.left, null)))
                .isEqualTo(problemWithoutRequestId(call(GET, w.base, w.stranger, null)));
    }

    @Test
    void aMemberWithoutAnAccountHasNoRoleOrStatusAndALeftMemberGetsNoRole() throws Exception {
        W w = new W();
        assertProblem(w.patch(w.owner, w.ghost, Map.of("status", "LEFT")), 422, "VALIDATION_ERROR");
        assertProblem(w.patch(w.owner, w.ghost, Map.of("role", "ADMIN")), 422, "VALIDATION_ERROR");
        assertProblem(w.patch(w.owner, w.leftMid, Map.of("role", "ADMIN")), 422, "VALIDATION_ERROR");
        assertThat(status(w.patch(w.owner, w.ghost, Map.of("displayName", "Ghost Renamed")))).isEqualTo(200);
    }

    // ---- mass assignment -----------------------------------------------------------------------------------------

    @Test
    void patchBindsOnlyTheThreeFieldsAndAppliesNothingWhenOneFieldIsRefused() throws Exception {
        W w = new W();
        Session other = newUser();
        // unknown fields are ignored, never bound
        MvcResult r = w.patch(w.owner, w.memberMid, Map.of("displayName", "Member 2", "userId", other.userId().toString(),
                "sortOrder", 99, "leftAt", "2020-01-01T00:00:00Z", "joinedAt", "2020-01-01T00:00:00Z"));
        assertThat(status(r)).isEqualTo(200);
        assertThat(jdbc.queryForObject("select user_id from members where id = ?::uuid", UUID.class, w.memberMid))
                .isEqualTo(w.member.userId());
        assertThat(jdbc.queryForObject("select sort_order from members where id = ?::uuid", Integer.class, w.memberMid))
                .isNotEqualTo(99);
        assertThat(jdbc.queryForObject("select left_at from members where id = ?::uuid", Object.class, w.memberMid)).isNull();
        // empty body
        assertProblem(w.patch(w.owner, w.memberMid, Map.of()), 422, "VALIDATION_ERROR");
        // a name change next to a refused role: nothing is applied
        assertProblem(w.patch(w.owner, w.memberMid, Map.of("displayName", "Changed", "role", "OWNER")), 422,
                "VALIDATION_ERROR");
        assertThat(jdbc.queryForObject("select display_name from members where id = ?::uuid", String.class, w.memberMid))
                .isEqualTo("Member 2");
        // an admin may rename but not set a role: the whole request is refused
        assertProblem(w.patch(w.admin, w.memberMid, Map.of("displayName", "Admin Name", "role", "ADMIN")), 403, "FORBIDDEN");
        assertThat(jdbc.queryForObject("select display_name from members where id = ?::uuid", String.class, w.memberMid))
                .isEqualTo("Member 2");
    }

    // ---- LEFT members in new records, kept in history ------------------------------------------------------------

    private Map<String, Object> settlement(String from, String to) {
        return Map.of("fromMemberId", from, "toMemberId", to, "amountMinor", 100L, "settledOn", "2026-10-20");
    }

    @Test
    void aLeftMemberIsRejectedInExpenseCreatePreviewAndSettlement() throws Exception {
        W w = new W();
        // payer
        assertProblem(postExpense(w.owner, w.gid, key(), equalBody("P", 1000, null, w.leftMid, 1000L)), 422, "MEMBER_INACTIVE");
        // EQUAL participant
        assertProblem(postExpense(w.owner, w.gid, key(),
                equalBody("E", 1000, List.of(w.ownerMid, w.leftMid), w.ownerMid, 1000L)), 422, "MEMBER_INACTIVE");
        // EXACT share
        assertProblem(postExpense(w.owner, w.gid, key(),
                exactBody("X", 1000, List.of(w.ownerMid, 500L, w.leftMid, 500L), w.ownerMid, 1000L)), 422, "MEMBER_INACTIVE");
        // preview
        assertProblem(call(POST, w.base + "/expenses/preview", w.owner,
                equalBody("V", 1000, List.of(w.ownerMid, w.leftMid), w.ownerMid, 1000L)), 422, "MEMBER_INACTIVE");
        // settlement, both sides
        assertProblem(call(POST, w.base + "/settlements", w.owner, settlement(w.leftMid, w.ownerMid),
                "Idempotency-Key", key()), 422, "MEMBER_INACTIVE");
        assertProblem(call(POST, w.base + "/settlements", w.owner, settlement(w.ownerMid, w.leftMid),
                "Idempotency-Key", key()), 422, "MEMBER_INACTIVE");
        assertThat(countExpenses(w.gid)).isZero();
        // an id from another group is still not-in-group, not inactive
        Session other = newUser();
        String foreign = member(other, createGroup(other, "Elsewhere " + UUID.randomUUID()).get("id").asText(), "Z").get("id").asText();
        assertProblem(postExpense(w.owner, w.gid, key(), equalBody("F", 1000, null, foreign, 1000L)), 422, "MEMBER_NOT_IN_GROUP");
    }

    @Test
    void aLeftMemberIsRejectedInItemizedAssignees() throws Exception {
        W w = new W();
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("title", "Dinner");
        body.put("expenseDate", "2026-10-18");
        body.put("splitType", "ITEMIZED");
        body.put("items", List.of(Map.of("name", "Fish", "amountMinor", 1000L,
                "assigneeMemberIds", List.of(w.ownerMid, w.leftMid))));
        body.put("payers", List.of(Map.of("memberId", w.ownerMid, "amountMinor", 1000L)));
        assertProblem(postExpense(w.owner, w.gid, key(), body), 422, "MEMBER_INACTIVE");
    }

    @Test
    void equalWithoutParticipantsMeansTheActiveMembersOnly() throws Exception {
        W w = new W();
        JsonNode e = createExpense(w.owner, w.gid, equalBody("All", 3000, null, w.ownerMid, 3000L));
        Set<String> sharers = new HashSet<>();
        e.get("shares").forEach(s -> sharers.add(s.get("memberId").asText()));
        assertThat(sharers).containsExactlyInAnyOrder(w.ownerMid, w.adminMid, w.memberMid, w.ghost)
                .doesNotContain(w.leftMid);
    }

    @Test
    void anExpenseThatAlreadyHasALeftMemberCanBeEditedButNotGiveANewOne() throws Exception {
        W w = new W();
        JsonNode e = createExpense(w.owner, w.gid,
                equalBody("Dinner", 3000, List.of(w.ownerMid, w.memberMid, w.adminMid), w.ownerMid, 3000L));
        String eid = e.get("id").asText();
        assertThat(status(w.patch(w.owner, w.memberMid, Map.of("status", "LEFT")))).isEqualTo(200);

        // keeping the LEFT member (still a participant) is fine
        MvcResult kept = call(PUT, w.base + "/expenses/" + eid, w.owner,
                equalBody("Dinner v2", 3000, List.of(w.ownerMid, w.memberMid, w.adminMid), w.ownerMid, 3000L), "If-Match", "\"1\"");
        assertThat(status(kept)).as(kept.getResponse().getContentAsString()).isEqualTo(200);
        // omitting participants = all usable members, which still contains the kept one
        MvcResult all = call(PUT, w.base + "/expenses/" + eid, w.owner,
                equalBody("Dinner v3", 3000, null, w.ownerMid, 3000L), "If-Match", "\"2\"");
        assertThat(status(all)).isEqualTo(200);
        // adding a different LEFT member who was never in the expense is refused
        assertProblem(call(PUT, w.base + "/expenses/" + eid, w.owner,
                equalBody("Dinner v4", 3000, List.of(w.ownerMid, w.leftMid), w.ownerMid, 3000L), "If-Match", "\"3\""),
                422, "MEMBER_INACTIVE");
        // dropping the LEFT member is allowed, and after that they cannot come back
        assertThat(status(call(PUT, w.base + "/expenses/" + eid, w.owner,
                equalBody("Dinner v5", 3000, List.of(w.ownerMid, w.adminMid), w.ownerMid, 3000L), "If-Match", "\"3\""))).isEqualTo(200);
        assertProblem(call(PUT, w.base + "/expenses/" + eid, w.owner,
                equalBody("Dinner v6", 3000, List.of(w.ownerMid, w.memberMid), w.ownerMid, 3000L), "If-Match", "\"4\""),
                422, "MEMBER_INACTIVE");
    }

    @Test
    void aLeftMemberStaysInHistoryBalancesAndSuggestedTransfersAndBalancesSumToZero() throws Exception {
        W w = new W();
        createExpense(w.owner, w.gid, equalBody("Hotel", 3000, List.of(w.ownerMid, w.memberMid, w.adminMid, w.ghost),
                w.ownerMid, 3000L));
        createExpense(w.owner, w.gid, equalBody("Taxi", 1000, List.of(w.memberMid, w.adminMid), w.memberMid, 1000L));
        assertThat(status(w.leave(w.member))).isEqualTo(204);

        JsonNode balances = body(call(GET, w.base + "/balances", w.owner, null));
        long sum = 0;
        long memberNet = Long.MIN_VALUE;
        for (JsonNode n : balances.get("nets")) {
            sum += n.get("netMinor").asLong();
            if (n.get("memberId").asText().equals(w.memberMid)) {
                memberNet = n.get("netMinor").asLong();
            }
        }
        assertThat(sum).as("nets sum to zero with a LEFT member present").isZero();
        assertThat(memberNet).as("the member who left keeps their balance").isNotEqualTo(Long.MIN_VALUE);
        assertThat(memberNet).isEqualTo(-750L + 1000L - 500L);                     // owes 750, paid 1000, owes 500 of the taxi
        boolean inTransfers = false;
        for (JsonNode t : balances.get("transfers")) {
            inTransfers |= t.get("fromMemberId").asText().equals(w.memberMid) || t.get("toMemberId").asText().equals(w.memberMid);
        }
        assertThat(inTransfers || memberNet == 0).as("suggested transfers still involve the member who left").isTrue();
        JsonNode expenses = body(call(GET, w.base + "/expenses", w.owner, null));
        assertThat(expenses.get("items")).hasSize(2);
        assertThat(expenses.toString()).contains(w.memberMid);
    }

    // ---- ownership transfer ----------------------------------------------------------------------------------------

    @Test
    void transferMakesTheTargetOwnerAndTheOldOwnerAdminInOneStep() throws Exception {
        W w = new W();
        MvcResult r = w.transfer(w.owner, w.memberMid);
        assertThat(status(r)).isEqualTo(204);
        assertThat(w.role(w.memberMid)).isEqualTo("OWNER");
        assertThat(w.role(w.ownerMid)).isEqualTo("ADMIN");
        assertThat(w.owners()).isEqualTo(1);
        // the new owner may now do owner things; the old owner may not
        assertThat(status(call(GET, "/api/v1/groups", w.member, null))).isEqualTo(200);
        assertProblem(w.transfer(w.owner, w.adminMid), 403, "FORBIDDEN");
        assertProblem(call(DELETE, w.base, w.owner, null), 403, "FORBIDDEN");
        assertThat(status(w.transfer(w.member, w.ownerMid))).isEqualTo(204);       // and back
        assertThat(w.role(w.ownerMid)).isEqualTo("OWNER");
        assertThat(w.owners()).isEqualTo(1);
    }

    @Test
    void aRefusedTransferChangesNothing() throws Exception {
        W w = new W();
        assertProblem(w.transfer(w.owner, w.leftMid), 422, "MEMBER_INACTIVE");
        assertProblem(w.transfer(w.owner, w.ghost), 422, "VALIDATION_ERROR");
        assertProblem(w.transfer(w.owner, w.ownerMid), 422, "VALIDATION_ERROR");
        assertProblem(w.transfer(w.owner, UUID.randomUUID().toString()), 404, "NOT_FOUND");
        assertProblem(call(POST, w.base + "/transfer-ownership", w.owner, Map.of()), 422, "VALIDATION_ERROR");
        assertThat(w.role(w.ownerMid)).isEqualTo("OWNER");
        assertThat(w.owners()).isEqualTo(1);
    }

    @Test
    void aMemberOfAnotherGroupCannotBeTheTarget() throws Exception {
        W w = new W();
        Session other = newUser();
        String otherGid = createGroup(other, "Other " + UUID.randomUUID()).get("id").asText();
        String foreign = member(other, otherGid, "Foreign").get("id").asText();
        assertProblem(w.transfer(w.owner, foreign), 404, "NOT_FOUND");
        assertThat(w.owners()).isEqualTo(1);
    }

    @Test
    void twoParallelTransfersLeaveExactlyOneOwner() throws Exception {
        for (int round = 0; round < 3; round++) {
            W w = new W();
            ExecutorService pool = Executors.newFixedThreadPool(2);
            CountDownLatch go = new CountDownLatch(1);
            List<Callable<Integer>> calls = List.of(
                    () -> { go.await(); return status(w.transfer(w.owner, w.memberMid)); },
                    () -> { go.await(); return status(w.transfer(w.owner, w.adminMid)); });
            List<Future<Integer>> results = new ArrayList<>();
            for (Callable<Integer> c : calls) {
                results.add(pool.submit(c));
            }
            go.countDown();
            List<Integer> codes = new ArrayList<>();
            for (Future<Integer> f : results) {
                codes.add(f.get());
            }
            pool.shutdown();
            assertThat(codes).as("one transfer wins, the other caller is no longer owner").containsExactlyInAnyOrder(204, 403);
            assertThat(w.owners()).isEqualTo(1);
            assertThat(w.role(w.ownerMid)).isEqualTo("ADMIN");
        }
    }

    @Test
    void aTransferRacingWithTheTargetLeavingEndsConsistent() throws Exception {
        W w = new W();
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch go = new CountDownLatch(1);
        Future<Integer> transfer = pool.submit(() -> { go.await(); return status(w.transfer(w.owner, w.memberMid)); });
        Future<Integer> leave = pool.submit(() -> { go.await(); return status(w.leave(w.member)); });
        go.countDown();
        int t = transfer.get();
        int l = leave.get();
        pool.shutdown();
        assertThat(w.owners()).isEqualTo(1);
        // either the member left first (transfer 422) or became owner first (leave 409): never a LEFT owner
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and role = 'OWNER' "
                + "and status = 'LEFT'", Integer.class, w.gid)).isZero();
        assertThat(t == 204 ? l == 409 : (t == 422 && l == 204)).as("transfer %d, leave %d", t, l).isTrue();
    }

    // ---- rejoin ----------------------------------------------------------------------------------------------------

    private JsonNode invite(Session as, String gid, boolean approval) throws Exception {
        return body(call(POST, "/api/v1/groups/" + gid + "/invites", as, Map.of("requiresApproval", approval),
                "Idempotency-Key", key()));
    }

    @Test
    void aLeftPersonRejoinsThroughAnInviteAndGetsTheirOldMemberBack() throws Exception {
        W w = new W();
        String code = invite(w.owner, w.gid, false).get("code").asText();
        MvcResult r = call(POST, "/api/v1/invites/" + code + "/join", w.left, Map.of("newMemberName", "Gone"),
                "Idempotency-Key", key());
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        assertThat(body(r).get("member").get("id").asText()).isEqualTo(w.leftMid);
        assertThat(w.status(w.leftMid)).isEqualTo("ACTIVE");
        assertThat(w.role(w.leftMid)).isEqualTo("MEMBER");
        assertThat(jdbc.queryForObject("select left_at is null from members where id = ?::uuid", Boolean.class, w.leftMid)).isTrue();
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id = ?", Integer.class,
                w.gid, w.left.userId())).isEqualTo(1);
        assertThat(status(call(GET, w.base, w.left, null))).isEqualTo(200);
    }

    @Test
    void aLeftPersonRejoinsAfterApprovalToo() throws Exception {
        W w = new W();
        String code = invite(w.owner, w.gid, true).get("code").asText();
        MvcResult asked = call(POST, "/api/v1/invites/" + code + "/join", w.left, Map.of("newMemberName", "Gone"),
                "Idempotency-Key", key());
        assertThat(status(asked)).isEqualTo(202);
        assertThat(w.status(w.leftMid)).as("still LEFT until approved").isEqualTo("LEFT");
        String rid = body(asked).get("requestId").asText();
        assertThat(status(call(POST, w.base + "/join-requests/" + rid + "/approve", w.owner, null))).isEqualTo(200);
        assertThat(w.status(w.leftMid)).isEqualTo("ACTIVE");
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id = ?", Integer.class,
                w.gid, w.left.userId())).isEqualTo(1);
    }

    @Test
    void unlinkingALeftMemberTurnsItIntoAClaimableGhost() throws Exception {
        W w = new W();
        assertThat(status(call(POST, w.base + "/members/" + w.leftMid + "/unlink", w.owner, null))).isEqualTo(204);
        assertThat(w.status(w.leftMid)).isEqualTo("ACTIVE");
        assertThat(jdbc.queryForObject("select user_id is null from members where id = ?::uuid", Boolean.class, w.leftMid)).isTrue();
        String code = invite(w.owner, w.gid, false).get("code").asText();
        Session newcomer = newUser();
        MvcResult r = call(POST, "/api/v1/invites/" + code + "/join", newcomer, Map.of("claimMemberId", w.leftMid),
                "Idempotency-Key", key());
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        assertThat(body(r).get("member").get("id").asText()).isEqualTo(w.leftMid);
    }

    // ---- group delete (A23) and the database -----------------------------------------------------------------------

    @Test
    void leavingMembersDoNotMakeAGroupDeletable() throws Exception {
        W w = new W();
        assertThat(status(w.leave(w.member))).isEqualTo(204);
        assertThat(status(w.leave(w.admin))).isEqualTo(204);
        assertProblem(call(DELETE, w.base, w.owner, null), 409, "GROUP_NOT_EMPTY");

        Session owner = newUser();
        String twoOfUs = createGroup(owner, "Two " + UUID.randomUUID()).get("id").asText();
        Session guest = newUser();
        linkUser(twoOfUs, guest, "MEMBER", "LEFT", "Guest");
        assertProblem(call(DELETE, "/api/v1/groups/" + twoOfUs, owner, null), 409, "GROUP_NOT_EMPTY");

        String history = createGroup(owner, "History " + UUID.randomUUID()).get("id").asText();
        String m = member(owner, history, "Me").get("id").asText();
        createExpense(owner, history, equalBody("Dinner", 1000, null, m, 1000L));
        assertProblem(call(DELETE, "/api/v1/groups/" + history, owner, null), 409, "GROUP_NOT_EMPTY");

        String empty = createGroup(owner, "Empty " + UUID.randomUUID()).get("id").asText();
        assertThat(status(call(DELETE, "/api/v1/groups/" + empty, owner, null))).isEqualTo(204);
    }

    @Test
    void theDatabaseRefusesALeftMemberWithoutAnAccount() throws Exception {
        W w = new W();
        assertThatThrownBy(() -> jdbc.update("insert into members (id, group_id, display_name, sort_order, role, status, "
                        + "joined_at, left_at) values (?, ?::uuid, 'Nobody', 77, 'MEMBER', 'LEFT', now(), now())",
                UUID.randomUUID(), w.gid)).isInstanceOf(DataIntegrityViolationException.class);
    }
}
