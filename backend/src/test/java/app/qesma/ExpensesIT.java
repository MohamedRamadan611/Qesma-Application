package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Expenses end to end on real PostgreSQL: spec vectors V1/V3/V4 through the API, validation codes, the explicit
 * "All" snapshot, listing, ownership isolation, delete rules and schema constraints.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ExpensesIT extends AbstractApiIT {

    private static final String GROUPS = "/api/v1/groups";

    /** A group with the given member names; returns [groupId, memberId...] in creation (sort_order) order. */
    private List<String> groupWith(Session owner, String... names) throws Exception {
        List<String> ids = new ArrayList<>();
        ids.add(createGroup(owner, "G " + UUID.randomUUID()).get("id").asText());
        for (String n : names) {
            ids.add(member(owner, ids.get(0), n).get("id").asText());
        }
        return ids;
    }

    private static List<Long> owedOf(JsonNode expense) {
        List<Long> out = new ArrayList<>();
        expense.get("shares").forEach(s -> out.add(s.get("owedMinor").asLong()));
        return out;
    }

    // ---- spec vectors through the API --------------------------------------------------------------------

    @Test
    void v3EqualSplitRoundingGivesTheExtraPiasterToTheLowestSortOrder() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "M1", "M2", "M3");

        JsonNode e = createExpense(ali, g.get(0), equalBody("Dinner", 10000, null, g.get(1), 10000L));

        assertThat(owedOf(e)).containsExactly(3334L, 3333L, 3333L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(10000);
        assertThat(e.get("splitType").asText()).isEqualTo("EQUAL");
        assertThat(e.get("payers")).hasSize(1);
        assertThat(e.get("version").asInt()).isEqualTo(1);
        Long sum = jdbc.queryForObject("select sum(owed_minor) from expense_splits where expense_id = ?::uuid",
                Long.class, e.get("id").asText());
        assertThat(sum).isEqualTo(10000L);
    }

    @Test
    void v4MultiplePayersAreStoredAndSplitEqually() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "X", "Y", "Z", "W");

        JsonNode e = createExpense(ali, g.get(0),
                equalBody("Trip", 50000, null, g.get(1), 30000L, g.get(2), 20000L));

        assertThat(owedOf(e)).containsExactly(12500L, 12500L, 12500L, 12500L);
        assertThat(e.get("payers")).hasSize(2);
        assertThat(e.get("payers").get(0).get("memberId").asText()).isEqualTo(g.get(1));
        assertThat(e.get("payers").get(0).get("amountMinor").asLong()).isEqualTo(30000);
        assertThat(e.get("payers").get(1).get("amountMinor").asLong()).isEqualTo(20000);
        assertThat(jdbc.queryForObject("select count(*) from expense_payers where expense_id = ?::uuid",
                Integer.class, e.get("id").asText())).isEqualTo(2);
    }

    @Test
    void v1ExactSplitsWhereThePayerDoesNotParticipate() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "Mohamed", "Asem", "Mohsen");
        String m = g.get(1);
        String a = g.get(2);
        String s = g.get(3);

        JsonNode e1 = createExpense(ali, g.get(0), exactBody("E1", 10000, List.of(a, 5000L, s, 5000L), m, 10000L));
        JsonNode e2 = createExpense(ali, g.get(0), exactBody("E2", 3000, List.of(a, 3000L), s, 3000L));

        assertThat(e1.get("shares")).hasSize(2); // the payer M is not a participant
        assertThat(e1.get("shares").get(0).get("memberId").asText()).isEqualTo(a);
        assertThat(owedOf(e1)).containsExactly(5000L, 5000L);
        assertThat(owedOf(e2)).containsExactly(3000L);
        assertThat(e2.get("payers").get(0).get("memberId").asText()).isEqualTo(s);
    }

    // ---- the "All" snapshot ---------------------------------------------------------------------------------

    @Test
    void omittedParticipantsMeansAllCurrentMembersStoredExplicitlyAndLaterMembersAreNotAdded() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B", "C");
        JsonNode e = createExpense(ali, g.get(0), equalBody("All", 9000, null, g.get(1), 9000L));
        String id = e.get("id").asText();
        assertThat(jdbc.queryForObject("select count(*) from expense_splits where expense_id = ?::uuid",
                Integer.class, id)).isEqualTo(3);

        member(ali, g.get(0), "Late joiner");

        assertThat(jdbc.queryForObject("select count(*) from expense_splits where expense_id = ?::uuid",
                Integer.class, id)).isEqualTo(3);
        JsonNode read = body(call(GET, GROUPS + "/" + g.get(0) + "/expenses/" + id, ali, null));
        assertThat(read.get("shares")).hasSize(3);
        assertThat(owedOf(read)).containsExactly(3000L, 3000L, 3000L);
    }

    @Test
    void zeroOwedParticipantsAreKeptInTheSnapshot() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B", "C");

        JsonNode e = createExpense(ali, g.get(0), equalBody("Tiny", 2, null, g.get(1), 2L));

        assertThat(owedOf(e)).containsExactly(1L, 1L, 0L);
        assertThat(jdbc.queryForObject("select count(*) from expense_splits where expense_id = ?::uuid",
                Integer.class, e.get("id").asText())).isEqualTo(3);
    }

    @Test
    void anExplicitSubsetOfParticipantsIsHonoured() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B", "C");
        JsonNode e = createExpense(ali, g.get(0), equalBody("Two of three", 1001, List.of(g.get(3), g.get(1)),
                g.get(2), 1001L));
        assertThat(owedOf(e)).containsExactly(501L, 500L); // sorted by sort_order: A then C; extra unit to A
        assertThat(e.get("shares").get(0).get("memberId").asText()).isEqualTo(g.get(1));
        assertThat(e.get("shares").get(1).get("memberId").asText()).isEqualTo(g.get(3));
    }

    // ---- validation codes ------------------------------------------------------------------------------------

    private void assertRejected(Session as, String gid, Object body, int status, String code) throws Exception {
        MvcResult r = postExpense(as, gid, UUID.randomUUID().toString(), body);
        assertThat(status(r)).as(body.toString()).isEqualTo(status);
        assertThat(code(r)).as(body.toString()).isEqualTo(code);
        assertThat(countExpenses(gid)).as("nothing was stored").isZero();
    }

    @Test
    void everyValidationFailureHasItsStableCodeAndStoresNothing() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B");
        String gid = g.get(0);
        String a = g.get(1);
        String b = g.get(2);

        // engine: sums
        assertRejected(ali, gid, exactBody("x", 10000, List.of(a, 5000L, b, 4999L), a, 10000L), 422, "SPLIT_TOTAL_MISMATCH");
        assertRejected(ali, gid, exactBody("x", 10000, List.of(a, 10001L), a, 10000L), 422, "SPLIT_TOTAL_MISMATCH");
        assertRejected(ali, gid, equalBody("x", 10000, null, a, 6000L, b, 3999L), 422, "PAYERS_TOTAL_MISMATCH");
        assertRejected(ali, gid, equalBody("x", 10000, null, a, 10001L), 422, "PAYERS_TOTAL_MISMATCH");

        // shape / engine validation
        assertRejected(ali, gid, equalBody("x", 10000, null, a, 0L, b, 10000L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("x", 10000, null, a, -5L, b, 10005L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("x", 10000, null, a, 5000L, a, 5000L), 422, "VALIDATION_ERROR"); // duplicate payer
        assertRejected(ali, gid, equalBody("x", 10000, List.of(a, a), a, 10000L), 422, "VALIDATION_ERROR");  // duplicate participant
        assertRejected(ali, gid, equalBody("x", 10000, List.of(), a, 10000L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("x", 0, null, a, 1L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("x", -100, null, a, 100L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("   ", 100, null, a, 100L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, equalBody("t".repeat(101), 100, null, a, 100L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, exactBody("x", 100, List.of(a, -10L, b, 110L), a, 100L), 422, "VALIDATION_ERROR");
        assertRejected(ali, gid, exactBody("x", 100, List.of(a, 100L, a, 0L), a, 100L), 422, "VALIDATION_ERROR");
        // two payers whose amounts overflow a long when added: a typed validation error, never a 500
        assertRejected(ali, gid, equalBody("x", 100, null, a, Long.MAX_VALUE, b, Long.MAX_VALUE), 422, "VALIDATION_ERROR");

        Map<String, Object> itemized = equalBody("x", 100, null, a, 100L);
        itemized.put("splitType", "ITEMIZED");
        assertRejected(ali, gid, itemized, 422, "VALIDATION_ERROR");
        Map<String, Object> unknownType = equalBody("x", 100, null, a, 100L);
        unknownType.put("splitType", "PERCENT");
        assertRejected(ali, gid, unknownType, 422, "VALIDATION_ERROR");
        Map<String, Object> badDate = equalBody("x", 100, null, a, 100L);
        badDate.put("expenseDate", "1999-01-01");
        assertRejected(ali, gid, badDate, 422, "VALIDATION_ERROR");
    }

    @Test
    void membersOfAnotherGroupAreRejectedEvenWhenTheyBelongToTheSameUser() throws Exception {
        Session ali = newUser();
        List<String> g1 = groupWith(ali, "A", "B");
        List<String> g2 = groupWith(ali, "Outsider");
        String outsider = g2.get(1);

        assertRejected(ali, g1.get(0), equalBody("x", 100, null, outsider, 100L), 422, "MEMBER_NOT_IN_GROUP");
        assertRejected(ali, g1.get(0), equalBody("x", 100, List.of(g1.get(1), outsider), g1.get(1), 100L), 422,
                "MEMBER_NOT_IN_GROUP");
        assertRejected(ali, g1.get(0), exactBody("x", 100, List.of(outsider, 100L), g1.get(1), 100L), 422,
                "MEMBER_NOT_IN_GROUP");
        assertRejected(ali, g1.get(0), equalBody("x", 100, null, UUID.randomUUID().toString(), 100L), 422,
                "MEMBER_NOT_IN_GROUP");
    }

    @Test
    void missingOrMalformedIdempotencyKeyIs422() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        Object body = equalBody("x", 100, null, g.get(1), 100L);
        MvcResult none = call(POST, GROUPS + "/" + g.get(0) + "/expenses", ali, body);
        assertThat(status(none)).isEqualTo(422);
        assertThat(code(none)).isEqualTo("VALIDATION_ERROR");
        assertThat(status(postExpense(ali, g.get(0), "not-a-uuid", body))).isEqualTo(422);
        assertThat(countExpenses(g.get(0))).isZero();
    }

    // ---- ownership isolation (IDOR) ------------------------------------------------------------------------

    @Test
    void anotherUsersGroupAndExpensesAreNotFoundOnEveryVerbWithTheSameBodyAsNonexistent() throws Exception {
        Session owner = newUser();
        Session intruder = newUser();
        List<String> g = groupWith(owner, "A");
        String eid = createExpense(owner, g.get(0), equalBody("Mine", 100, null, g.get(1), 100L)).get("id").asText();

        JsonNode baseline = problemWithoutRequestId(
                call(GET, GROUPS + "/" + UUID.randomUUID() + "/expenses", intruder, null));
        String base = GROUPS + "/" + g.get(0) + "/expenses";
        List<MvcResult> attempts = List.of(
                postExpense(intruder, g.get(0), UUID.randomUUID().toString(), equalBody("x", 100, null, g.get(1), 100L)),
                call(GET, base, intruder, null),
                call(GET, base + "/" + eid, intruder, null));
        for (MvcResult r : attempts) {
            assertThat(status(r)).isEqualTo(404);
            assertThat(problemWithoutRequestId(r)).isEqualTo(baseline);
        }
        assertThat(countExpenses(g.get(0))).isEqualTo(1);

        // an expense id of someone else's group is also a 404 through my own group
        List<String> mine = groupWith(intruder, "B");
        MvcResult cross = call(GET, GROUPS + "/" + mine.get(0) + "/expenses/" + eid, intruder, null);
        assertThat(status(cross)).isEqualTo(404);
        assertThat(problemWithoutRequestId(cross)).isEqualTo(baseline);
        // and an unknown expense id in my own group is the same 404
        assertThat(problemWithoutRequestId(call(GET, GROUPS + "/" + mine.get(0) + "/expenses/" + UUID.randomUUID(),
                intruder, null))).isEqualTo(baseline);
    }

    @Test
    void intrudersCannotUseTheirOwnKeyToLearnAnythingAndKeysAreScopedPerUser() throws Exception {
        Session ali = newUser();
        Session bob = newUser();
        List<String> ga = groupWith(ali, "A");
        List<String> gb = groupWith(bob, "B");
        String sharedKey = UUID.randomUUID().toString();

        MvcResult first = postExpense(ali, ga.get(0), sharedKey, equalBody("x", 100, null, ga.get(1), 100L));
        MvcResult second = postExpense(bob, gb.get(0), sharedKey, equalBody("x", 100, null, gb.get(1), 100L));

        assertThat(status(first)).isEqualTo(201);
        assertThat(status(second)).isEqualTo(201); // same key text, different user: independent
        assertThat(body(first).get("id").asText()).isNotEqualTo(body(second).get("id").asText());
    }

    // ---- listing ---------------------------------------------------------------------------------------------

    private JsonNode expenseOn(Session s, List<String> g, String title, String date, int payerIdx, long total)
            throws Exception {
        Map<String, Object> body = equalBody(title, total, null, g.get(payerIdx), total);
        body.put("expenseDate", date);
        return createExpense(s, g.get(0), body);
    }

    @Test
    void listIsPagedOrderedNewestDateFirstAndExcludesSoftDeleted() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B");
        JsonNode oldest = expenseOn(ali, g, "oldest", "2026-01-01", 1, 100);
        expenseOn(ali, g, "middle-1", "2026-02-01", 1, 200);
        JsonNode sameDayLater = expenseOn(ali, g, "middle-2", "2026-02-01", 1, 300); // same date, created later
        JsonNode newest = expenseOn(ali, g, "newest", "2026-03-01", 1, 400);
        JsonNode doomed = expenseOn(ali, g, "doomed", "2026-04-01", 1, 500);
        jdbc.update("update expenses set deleted_at = now() where id = ?::uuid", doomed.get("id").asText());

        JsonNode p0 = body(call(GET, GROUPS + "/" + g.get(0) + "/expenses?page=0&size=2", ali, null));
        JsonNode p1 = body(call(GET, GROUPS + "/" + g.get(0) + "/expenses?page=1&size=2", ali, null));
        JsonNode p2 = body(call(GET, GROUPS + "/" + g.get(0) + "/expenses?page=2&size=2", ali, null));

        assertThat(p0.get("totalElements").asLong()).isEqualTo(4); // the deleted one is not counted
        assertThat(p0.get("totalPages").asInt()).isEqualTo(2);
        assertThat(p0.get("items").get(0).get("id").asText()).isEqualTo(newest.get("id").asText());
        assertThat(p0.get("items").get(1).get("id").asText()).isEqualTo(sameDayLater.get("id").asText());
        assertThat(p1.get("items")).hasSize(2);
        assertThat(p1.get("items").get(1).get("id").asText()).isEqualTo(oldest.get("id").asText());
        assertThat(p2.get("items")).isEmpty();
        // each item carries payers and shares
        assertThat(p0.get("items").get(0).get("payers")).hasSize(1);
        assertThat(p0.get("items").get(0).get("shares")).hasSize(2);

        // soft-deleted expenses are also invisible by id
        assertThat(status(call(GET, GROUPS + "/" + g.get(0) + "/expenses/" + doomed.get("id").asText(), ali, null)))
                .isEqualTo(404);
    }

    @Test
    void listFiltersByDateRangeAndByMemberAsPayerOrParticipant() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B", "C");
        expenseOn(ali, g, "jan", "2026-01-15", 1, 300);
        // B pays, only A and B participate
        Map<String, Object> feb = equalBody("feb", 200, List.of(g.get(1), g.get(2)), g.get(2), 200L);
        feb.put("expenseDate", "2026-02-15");
        createExpense(ali, g.get(0), feb);
        expenseOn(ali, g, "mar", "2026-03-15", 1, 300);
        String base = GROUPS + "/" + g.get(0) + "/expenses";

        assertThat(body(call(GET, base + "?fromDate=2026-02-01&toDate=2026-02-28", ali, null)).get("totalElements")
                .asLong()).isEqualTo(1);
        assertThat(body(call(GET, base + "?fromDate=2026-02-15&toDate=2026-02-15", ali, null)).get("totalElements")
                .asLong()).isEqualTo(1); // bounds are inclusive
        assertThat(body(call(GET, base + "?fromDate=2026-02-16", ali, null)).get("totalElements").asLong()).isEqualTo(1);
        assertThat(body(call(GET, base + "?toDate=2026-01-31", ali, null)).get("totalElements").asLong()).isEqualTo(1);

        // member C: participant of "jan" and "mar" (all members) but not of "feb"
        assertThat(body(call(GET, base + "?memberId=" + g.get(3), ali, null)).get("totalElements").asLong()).isEqualTo(2);
        // member A: payer of "jan" and "mar", participant of "feb"
        assertThat(body(call(GET, base + "?memberId=" + g.get(1), ali, null)).get("totalElements").asLong()).isEqualTo(3);
        // member B: payer and participant of "feb", participant of "jan" and "mar"; here narrowed by a date filter
        assertThat(body(call(GET, base + "?memberId=" + g.get(2) + "&fromDate=2026-02-01&toDate=2026-02-28", ali, null))
                .get("totalElements").asLong()).isEqualTo(1);
        // unknown member: empty, not an error
        assertThat(body(call(GET, base + "?memberId=" + UUID.randomUUID(), ali, null)).get("totalElements").asLong())
                .isZero();
    }

    @Test
    void listRejectsBadPagingAndInvertedDates() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String base = GROUPS + "/" + g.get(0) + "/expenses";
        for (String q : new String[] {"?size=0", "?size=101", "?page=-1", "?fromDate=2026-05-02&toDate=2026-05-01"}) {
            MvcResult r = call(GET, base + q, ali, null);
            assertThat(status(r)).as(q).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(status(call(GET, base + "?fromDate=nope", ali, null))).isEqualTo(400);
    }

    // ---- group totals and delete rules ----------------------------------------------------------------------

    @Test
    void groupEndpointsShowTotalSpentAndLastExpenseAtIgnoringSoftDeletedExpenses() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        JsonNode empty = body(call(GET, GROUPS + "/" + g.get(0), ali, null));
        assertThat(empty.get("totalSpentMinor").asLong()).isZero();
        assertThat(empty.get("lastExpenseAt").isNull()).isTrue();

        createExpense(ali, g.get(0), equalBody("one", 12345, null, g.get(1), 12345L));
        JsonNode last = createExpense(ali, g.get(0), equalBody("two", 100, null, g.get(1), 100L));
        JsonNode doomed = createExpense(ali, g.get(0), equalBody("three", 99999, null, g.get(1), 99999L));
        jdbc.update("update expenses set deleted_at = now() where id = ?::uuid", doomed.get("id").asText());

        JsonNode detail = body(call(GET, GROUPS + "/" + g.get(0), ali, null));
        assertThat(detail.get("totalSpentMinor").asLong()).isEqualTo(12445);
        assertThat(detail.get("lastExpenseAt").isNull()).isFalse();
        // the newest NON-deleted expense, with the same instant the create response reported
        assertThat(detail.get("lastExpenseAt").asText()).isEqualTo(last.get("createdAt").asText());

        JsonNode row = null;
        for (JsonNode item : body(call(GET, GROUPS, ali, null)).get("items")) {
            if (item.get("id").asText().equals(g.get(0))) {
                row = item;
            }
        }
        assertThat(row).isNotNull();
        assertThat(row.get("totalSpentMinor").asLong()).isEqualTo(12445);
        assertThat(row.get("lastExpenseAt").asText()).isEqualTo(detail.get("lastExpenseAt").asText());
    }

    @Test
    void aMemberInAnyExpenseCannotBeDeletedAndNeitherCanAGroupWithExpenses() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "Owner", "Payer", "Participant", "Bystander");
        JsonNode e = createExpense(ali, g.get(0),
                equalBody("x", 100, List.of(g.get(2), g.get(3)), g.get(2), 100L));
        String base = GROUPS + "/" + g.get(0);

        for (String used : List.of(g.get(2), g.get(3))) { // payer+participant, and participant only
            MvcResult r = call(DELETE, base + "/members/" + used, ali, null);
            assertThat(status(r)).isEqualTo(409);
            assertThat(code(r)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
        }
        assertThat(status(call(DELETE, base + "/members/" + g.get(4), ali, null))).isEqualTo(204); // bystander

        MvcResult group = call(DELETE, base, ali, null);
        assertThat(status(group)).isEqualTo(409);
        assertThat(code(group)).isEqualTo("GROUP_NOT_EMPTY");

        // soft-deleting the expense does not free its members or its group (the ledger is never erased)
        jdbc.update("update expenses set deleted_at = now() where id = ?::uuid", e.get("id").asText());
        assertThat(status(call(DELETE, base + "/members/" + g.get(2), ali, null))).isEqualTo(409);
        assertThat(status(call(DELETE, base, ali, null))).isEqualTo(409);
    }

    @Test
    void aMemberOnlyAPayerIsAlsoProtected() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "Owner", "OnlyPays", "Owes");
        createExpense(ali, g.get(0), equalBody("x", 100, List.of(g.get(3)), g.get(2), 100L));
        MvcResult r = call(DELETE, GROUPS + "/" + g.get(0) + "/members/" + g.get(2), ali, null);
        assertThat(status(r)).isEqualTo(409);
        assertThat(code(r)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
    }

    // ---- schema constraints are the last line of defence -------------------------------------------------------

    @Test
    void databaseRejectsRowsThatBreakTheExpenseRules() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        JsonNode e = createExpense(ali, g.get(0), equalBody("ok", 100, null, g.get(1), 100L));
        String eid = e.get("id").asText();
        String insert = "insert into expenses (id, group_id, title, split_type, total_minor, expense_date, "
                + "created_by_user_id) values (?, ?::uuid, ?, ?, ?, '2026-01-01', ?)";
        UUID owner = ali.userId();

        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), g.get(0), "t", "EQUAL", 0L, owner))
                .isInstanceOf(DataIntegrityViolationException.class);                          // total > 0
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), g.get(0), "  ", "EQUAL", 5L, owner))
                .isInstanceOf(DataIntegrityViolationException.class);                          // title
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), g.get(0), "t", "PERCENT", 5L, owner))
                .isInstanceOf(DataIntegrityViolationException.class);                          // split_type
        assertThatThrownBy(() -> jdbc.update("update expenses set tax_minor = 5 where id = ?::uuid", eid))
                .isInstanceOf(DataIntegrityViolationException.class);                          // itemized column on EQUAL
        assertThatThrownBy(() -> jdbc.update(
                "insert into expense_payers (expense_id, member_id, amount_minor) values (?::uuid, ?::uuid, 0)",
                eid, g.get(1))).isInstanceOf(DataIntegrityViolationException.class);           // amount > 0 (and PK)
        assertThatThrownBy(() -> jdbc.update(
                "update expense_splits set owed_minor = -1 where expense_id = ?::uuid", eid))
                .isInstanceOf(DataIntegrityViolationException.class);                          // owed >= 0
        assertThatThrownBy(() -> jdbc.update(
                "insert into expense_splits (expense_id, member_id, owed_minor) values (?::uuid, ?::uuid, 1)",
                eid, g.get(1))).isInstanceOf(DataIntegrityViolationException.class);           // PK (expense, member)
        assertThatThrownBy(() -> jdbc.update("delete from members where id = ?::uuid", g.get(1)))
                .isInstanceOf(DataIntegrityViolationException.class);                          // FK from payers/splits
    }

    // ---- logging ---------------------------------------------------------------------------------------------

    @Test
    void logsNameTheExpenseEventsButNeverTheTitle() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        String title = "TopSecretDinner" + UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        try {
            Session ali = newUser();
            List<String> g = groupWith(ali, "A");
            Object body = equalBody(title, 100, null, g.get(1), 100L);
            postExpense(ali, g.get(0), key, body);
            postExpense(ali, g.get(0), key, body); // replay
            postExpense(ali, g.get(0), key, equalBody(title + "!", 100, null, g.get(1), 100L)); // reuse
        } finally {
            root.detachAppender(appender);
        }
        StringBuilder all = new StringBuilder();
        List<String> events = new ArrayList<>();
        for (ILoggingEvent e : new ArrayList<>(appender.list)) {
            all.append(e.getFormattedMessage()).append('\n');
            if (e.getKeyValuePairs() != null) {
                e.getKeyValuePairs().forEach(kv -> {
                    all.append(kv.key).append('=').append(kv.value).append('\n');
                    if ("event".equals(kv.key)) {
                        events.add(String.valueOf(kv.value));
                    }
                });
            }
        }
        assertThat(all.toString()).doesNotContain("TopSecretDinner");
        assertThat(events).contains("expense.created", "expense.replayed", "idempotency.key_reused");
    }

}
