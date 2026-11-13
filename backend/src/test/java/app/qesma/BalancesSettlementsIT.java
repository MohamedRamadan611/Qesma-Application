package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.Limits;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Payer;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Balances and settlements end to end on real PostgreSQL: spec vectors V1/V2, soft deletes, partial and excess
 * settlements, idempotency, ownership isolation, delete rules, the amount cap, and a randomized ledger where
 * applying the returned transfers must zero every balance.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class BalancesSettlementsIT extends AbstractApiIT {

    private static final String GROUPS = "/api/v1/groups/";

    /** [groupId, M, A, S] in sort order (the founder's example members). */
    private List<String> mas(Session owner) throws Exception {
        String gid = createGroup(owner, "G " + UUID.randomUUID()).get("id").asText();
        return List.of(gid, member(owner, gid, "M").get("id").asText(), member(owner, gid, "A").get("id").asText(),
                member(owner, gid, "S").get("id").asText());
    }

    /** V1: E1 paid by M 100.00 (A 50.00, S 50.00); E2 paid by S 30.00 (A 30.00). Returns [E1, E2] ids. */
    private List<String> v1(Session owner, List<String> g) throws Exception {
        String e1 = createExpense(owner, g.get(0),
                exactBody("E1", 10000, List.of(g.get(2), 5000L, g.get(3), 5000L), g.get(1), 10000L)).get("id").asText();
        String e2 = createExpense(owner, g.get(0),
                exactBody("E2", 3000, List.of(g.get(2), 3000L), g.get(3), 3000L)).get("id").asText();
        return List.of(e1, e2);
    }

    private MvcResult settle(Session as, String gid, String key, String from, String to, long amount) throws Exception {
        return call(POST, GROUPS + gid + "/settlements", as, settlementBody(from, to, amount), "Idempotency-Key", key);
    }

    private static Map<String, Object> settlementBody(String from, String to, long amount) {
        Map<String, Object> b = new LinkedHashMap<>();
        b.put("fromMemberId", from);
        b.put("toMemberId", to);
        b.put("amountMinor", amount);
        b.put("settledOn", "2026-10-20");
        return b;
    }

    private JsonNode settleOk(Session as, String gid, String from, String to, long amount) throws Exception {
        MvcResult r = settle(as, gid, UUID.randomUUID().toString(), from, to, amount);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        return body(r);
    }

    private JsonNode balances(Session as, String gid) throws Exception {
        MvcResult r = call(GET, GROUPS + gid + "/balances", as, null);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        return body(r);
    }

    private static Map<String, Long> netsOf(JsonNode balances) {
        Map<String, Long> nets = new LinkedHashMap<>();
        balances.get("nets").forEach(n -> nets.put(n.get("memberId").asText(), n.get("netMinor").asLong()));
        return nets;
    }

    private static List<String> transfersOf(JsonNode balances) {
        List<String> out = new ArrayList<>();
        balances.get("transfers").forEach(t -> out.add(t.get("fromMemberId").asText() + ">" + t.get("toMemberId").asText()
                + ":" + t.get("amountMinor").asLong()));
        return out;
    }

    // ---- spec vectors -----------------------------------------------------------------------------------------

    @Test
    void v1NetsAndTransfersThroughTheApi() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        v1(ali, g);

        JsonNode b = balances(ali, g.get(0));

        assertThat(netsOf(b)).containsExactly(Map.entry(g.get(1), 10000L), Map.entry(g.get(2), -8000L),
                Map.entry(g.get(3), -2000L));                                      // M +100.00, A -80.00, S -20.00
        assertThat(transfersOf(b)).containsExactly(g.get(2) + ">" + g.get(1) + ":8000",   // A -> M 80.00
                g.get(3) + ">" + g.get(1) + ":2000");                                        // S -> M 20.00
    }

    @Test
    void v2AfterASettlementTheBalancesShift() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        v1(ali, g);
        settleOk(ali, g.get(0), g.get(2), g.get(1), 8000);                          // A paid M 80.00

        JsonNode b = balances(ali, g.get(0));

        assertThat(netsOf(b)).containsExactly(Map.entry(g.get(1), 2000L), Map.entry(g.get(2), 0L),
                Map.entry(g.get(3), -2000L));
        assertThat(transfersOf(b)).containsExactly(g.get(3) + ">" + g.get(1) + ":2000");   // S -> M 20.00
    }

    @Test
    void anEmptyGroupHasZeroNetsForEveryoneAndNoTransfers() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        JsonNode b = balances(ali, g.get(0));
        assertThat(netsOf(b).values()).hasSize(3).containsOnly(0L);
        assertThat(b.get("transfers")).isEmpty();
        // a brand-new group has exactly one member since B9 (the owner), with a zero balance and nothing to settle
        String lonely = createGroup(ali, "Just me").get("id").asText();
        JsonNode alone = balances(ali, lonely);
        assertThat(netsOf(alone).values()).hasSize(1).containsOnly(0L);
        assertThat(alone.get("transfers")).isEmpty();
    }

    // ---- soft deletes, edits, partial and excess ----------------------------------------------------------------

    @Test
    void aConfirmedSettlementCannotBeUndoneButDeletingOrEditingAnExpenseMovesTheBalances() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        List<String> e = v1(ali, g);
        String sid = settleOk(ali, g.get(0), g.get(2), g.get(1), 8000).get("id").asText();
        assertThat(netsOf(balances(ali, g.get(0))).get(g.get(2))).isZero();

        MvcResult undo = call(POST, GROUPS + g.get(0) + "/settlements/" + sid + "/cancel", ali, null);   // B13: no delete
        assertThat(status(undo)).isEqualTo(409);
        assertThat(code(undo)).isEqualTo("INVALID_STATE_TRANSITION");
        assertThat(netsOf(balances(ali, g.get(0))).get(g.get(2))).as("a confirmed settlement stays").isZero();

        assertThat(status(call(DELETE, GROUPS + g.get(0) + "/expenses/" + e.get(0), ali, null,
                "If-Match", "\"1\""))).isEqualTo(204);
        JsonNode afterDelete = balances(ali, g.get(0));                              // only E2 left, plus the confirmed 80.00 payment
        assertThat(netsOf(afterDelete)).containsExactly(Map.entry(g.get(1), -8000L), Map.entry(g.get(2), 5000L),
                Map.entry(g.get(3), 3000L));

        MvcResult edit = call(PUT, GROUPS + g.get(0) + "/expenses/" + e.get(1), ali,
                exactBody("E2", 3000, List.of(g.get(1), 1000L, g.get(2), 2000L), g.get(3), 3000L), "If-Match", "\"1\"");
        assertThat(status(edit)).isEqualTo(200);
        assertThat(netsOf(balances(ali, g.get(0)))).containsExactly(Map.entry(g.get(1), -9000L),
                Map.entry(g.get(2), 6000L), Map.entry(g.get(3), 3000L));
    }

    @Test
    void aPartialSettlementShrinksTheDebtAndAnExcessOneFlipsIt() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        v1(ali, g);

        settleOk(ali, g.get(0), g.get(2), g.get(1), 3000);                           // partial: A still owes M 50.00
        assertThat(netsOf(balances(ali, g.get(0))).get(g.get(2))).isEqualTo(-5000L);

        settleOk(ali, g.get(0), g.get(2), g.get(1), 6000);                           // total 90.00 > the 80.00 owed
        JsonNode b = balances(ali, g.get(0));
        assertThat(netsOf(b)).containsExactly(Map.entry(g.get(1), 1000L), Map.entry(g.get(2), 1000L),
                Map.entry(g.get(3), -2000L));                                         // A is now owed 10.00 as well
        assertThat(transfersOf(b)).containsExactly(g.get(3) + ">" + g.get(1) + ":1000",   // tie: lower sort order first
                g.get(3) + ">" + g.get(2) + ":1000");
    }

    @Test
    void listIsPagedNewestFirstShowsCancelledOnesAndFiltersByStatus() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        String first = settleOk(ali, g.get(0), g.get(2), g.get(1), 100).get("id").asText();
        MvcResult later = call(POST, GROUPS + g.get(0) + "/settlements", ali,
                Map.of("fromMemberId", g.get(3), "toMemberId", g.get(1), "amountMinor", 200L, "settledOn", "2026-11-01"),
                "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(later)).isEqualTo(201);
        String gone = settleOk(ali, g.get(0), g.get(2), g.get(3), 300).get("id").asText();
        jdbc.update("update settlements set status = 'CANCELLED', confirmed_at = null, cancelled_at = now() where id = ?::uuid", gone);

        JsonNode page = body(call(GET, GROUPS + g.get(0) + "/settlements?size=10", ali, null));

        assertThat(page.get("items")).hasSize(3);                                  // the cancelled one stays in the history
        assertThat(page.get("totalElements").asLong()).isEqualTo(3);
        JsonNode live = body(call(GET, GROUPS + g.get(0) + "/settlements?status=CONFIRMED&size=10", ali, null));
        assertThat(live.get("items")).hasSize(2);
        assertThat(body(call(GET, GROUPS + g.get(0) + "/settlements?status=CANCELLED", ali, null)).get("items")).hasSize(1);
        assertThat(status(call(GET, GROUPS + g.get(0) + "/settlements?status=BOGUS", ali, null))).isEqualTo(422);
        assertThat(page.get("items").get(0).get("settledOn").asText()).isEqualTo("2026-11-01");   // newest date first
        assertThat(live.get("items").get(1).get("id").asText()).isEqualTo(first);
        assertThat(body(call(GET, GROUPS + g.get(0) + "/settlements?size=1&page=1", ali, null)).get("items")).hasSize(1);
        assertThat(status(call(GET, GROUPS + g.get(0) + "/settlements?size=101", ali, null))).isEqualTo(422);
    }

    // ---- validation -------------------------------------------------------------------------------------------

    @Test
    void invalidSettlementsAreRejectedWithStableCodesAndStoreNothing() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        Session bob = newUser();
        List<String> other = mas(bob);
        String url = GROUPS + g.get(0) + "/settlements";
        long cap = Limits.MAX_AMOUNT_MINOR;

        Map<String, Map<String, Object>> cases = new LinkedHashMap<>();
        cases.put("same member", settlementBody(g.get(1), g.get(1), 100));
        cases.put("zero", settlementBody(g.get(1), g.get(2), 0));
        cases.put("negative", settlementBody(g.get(1), g.get(2), -1));
        cases.put("over cap", settlementBody(g.get(1), g.get(2), cap + 1));
        Map<String, Object> noDate = settlementBody(g.get(1), g.get(2), 100);
        noDate.remove("settledOn");
        cases.put("no date", noDate);
        Map<String, Object> longNote = settlementBody(g.get(1), g.get(2), 100);
        longNote.put("note", "x".repeat(201));
        cases.put("long note", longNote);
        cases.put("other group's member", settlementBody(g.get(1), other.get(1), 100));
        cases.put("unknown member", settlementBody(g.get(1), UUID.randomUUID().toString(), 100));

        for (Map.Entry<String, Map<String, Object>> c : cases.entrySet()) {
            MvcResult r = call(POST, url, ali, c.getValue(), "Idempotency-Key", UUID.randomUUID().toString());
            assertThat(status(r)).as(c.getKey()).isEqualTo(422);
            assertThat(code(r)).as(c.getKey()).isEqualTo(c.getKey().contains("member") && !c.getKey().equals("same member")
                    ? "MEMBER_NOT_IN_GROUP" : "VALIDATION_ERROR");
        }
        assertThat(status(call(POST, url, ali, settlementBody(g.get(1), g.get(2), 100)))).isEqualTo(422);  // no key
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, g.get(0)))
                .isZero();
        // a corrected request with the same key as a failed one succeeds (failures store no key)
        String key = UUID.randomUUID().toString();
        assertThat(status(settle(ali, g.get(0), key, g.get(1), g.get(1), 100))).isEqualTo(422);
        assertThat(status(settle(ali, g.get(0), key, g.get(1), g.get(2), Limits.MAX_AMOUNT_MINOR))).isEqualTo(201);
    }

    // ---- idempotency -----------------------------------------------------------------------------------------

    @Test
    void replayingASettlementReturnsTheSameAnswerAndAChangedBodyIsKeyReuse() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        String key = UUID.randomUUID().toString();

        MvcResult first = settle(ali, g.get(0), key, g.get(2), g.get(1), 8000);
        MvcResult second = settle(ali, g.get(0), key, g.get(2), g.get(1), 8000);

        assertThat(status(first)).isEqualTo(201);
        assertThat(status(second)).isEqualTo(201);
        assertThat(second.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(second)).isEqualTo(body(first));
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, g.get(0)))
                .isEqualTo(1L);
        assertThat(code(settle(ali, g.get(0), key, g.get(2), g.get(1), 8001))).isEqualTo("IDEMPOTENCY_KEY_REUSED");
        String otherGroup = mas(ali).get(0);
        MvcResult elsewhere = settle(ali, otherGroup, key, g.get(2), g.get(1), 8000);
        assertThat(status(elsewhere)).isEqualTo(422);                               // same key, different group
        assertThat(code(elsewhere)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
    }

    @Test
    void twentyParallelRequestsWithOneKeyRecordExactlyOneSettlementEvenWithAStrangerRacing() throws Exception {
        Session ali = newUser();
        Session eve = newUser();
        List<String> g = mas(ali);
        String key = UUID.randomUUID().toString();
        ExecutorService pool = Executors.newFixedThreadPool(24);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<int[]>> results = new ArrayList<>();
        try {
            for (int i = 0; i < 20; i++) {
                results.add(pool.submit(() -> {
                    go.await();
                    return new int[] {1, status(settle(ali, g.get(0), key, g.get(2), g.get(1), 8000))};
                }));
            }
            for (int i = 0; i < 4; i++) {
                results.add(pool.submit(() -> {
                    go.await();
                    return new int[] {2, status(settle(eve, g.get(0), key, g.get(2), g.get(1), 8000))};
                }));
            }
            go.countDown();
            for (Future<int[]> f : results) {
                int[] r = f.get();
                assertThat(r[1]).as("who=" + r[0]).isEqualTo(r[0] == 1 ? 201 : 404);
            }
        } finally {
            pool.shutdownNow();
        }
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, g.get(0)))
                .isEqualTo(1L);
        assertThat(jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?", Long.class,
                eve.userId(), key)).isZero();
    }

    // ---- authorization -----------------------------------------------------------------------------------------

    @Test
    void anotherUsersGroupAndSettlementsAreTheSame404AsNothingOnEveryVerb() throws Exception {
        Session ali = newUser();
        Session bob = newUser();
        List<String> g = mas(ali);
        String sid = settleOk(ali, g.get(0), g.get(2), g.get(1), 100).get("id").asText();
        String ghostGroup = UUID.randomUUID().toString();
        String ghost = UUID.randomUUID().toString();
        String key = UUID.randomUUID().toString();

        List<MvcResult[]> pairs = List.of(
                new MvcResult[] {call(GET, GROUPS + g.get(0) + "/balances", bob, null),
                        call(GET, GROUPS + ghostGroup + "/balances", bob, null)},
                new MvcResult[] {call(GET, GROUPS + g.get(0) + "/settlements", bob, null),
                        call(GET, GROUPS + ghostGroup + "/settlements", bob, null)},
                new MvcResult[] {settle(bob, g.get(0), key, g.get(2), g.get(1), 100),
                        settle(bob, ghostGroup, key, g.get(2), g.get(1), 100)},
                new MvcResult[] {call(POST, GROUPS + g.get(0) + "/settlements/" + sid + "/cancel", bob, null),
                        call(POST, GROUPS + ghostGroup + "/settlements/" + ghost + "/cancel", bob, null)});
        for (MvcResult[] pair : pairs) {
            assertThat(status(pair[0])).isEqualTo(404);
            assertThat(problemWithoutRequestId(pair[0])).isEqualTo(problemWithoutRequestId(pair[1]));
        }
        assertThat(status(call(GET, GROUPS + g.get(0) + "/balances", null, null))).isEqualTo(401);
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid and status = 'CONFIRMED'",
                Long.class, g.get(0))).isEqualTo(1L);
        assertThat(jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?", Long.class,
                bob.userId(), key)).isZero();
    }

    @Test
    void aSettlementOfAnotherGroupOfTheSameOwnerIsNotReachableAndThereIsNoDelete() throws Exception {
        Session ali = newUser();
        List<String> g1 = mas(ali);
        List<String> g2 = mas(ali);
        String sid = settleOk(ali, g1.get(0), g1.get(2), g1.get(1), 100).get("id").asText();

        assertThat(status(call(POST, GROUPS + g2.get(0) + "/settlements/" + sid + "/cancel", ali, null))).isEqualTo(404);
        MvcResult undo = call(POST, GROUPS + g1.get(0) + "/settlements/" + sid + "/cancel", ali, null);
        assertThat(status(undo)).as("a confirmed settlement is final").isEqualTo(409);
        assertThat(code(undo)).isEqualTo("INVALID_STATE_TRANSITION");
        assertThat(status(call(DELETE, GROUPS + g1.get(0) + "/settlements/" + sid, ali, null))).as("no delete route").isIn(404, 405);
        assertThat(jdbc.queryForObject("select status from settlements where id = ?::uuid", String.class, sid))
                .as("the row is untouched").isEqualTo("CONFIRMED");
    }

    // ---- delete rules -----------------------------------------------------------------------------------------

    @Test
    void aMemberInASettlementEvenACancelledOneAndAGroupWithSettlementsCannotBeDeleted() throws Exception {
        Session ali = newUser();
        List<String> g = new java.util.ArrayList<>(mas(ali));
        g.add(member(ali, g.get(0), "X").get("id").asText());
        String sid = settleOk(ali, g.get(0), g.get(2), g.get(3), 100).get("id").asText();
        jdbc.update("update settlements set status = 'CANCELLED', confirmed_at = null, cancelled_at = now() where id = ?::uuid", sid);

        MvcResult member = call(DELETE, GROUPS + g.get(0) + "/members/" + g.get(2), ali, null);
        assertThat(status(member)).isEqualTo(409);
        assertThat(code(member)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
        MvcResult receiver = call(DELETE, GROUPS + g.get(0) + "/members/" + g.get(3), ali, null);
        assertThat(code(receiver)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
        assertThat(status(call(DELETE, GROUPS + g.get(0) + "/members/" + g.get(4), ali, null))).isEqualTo(204); // unused
        MvcResult group = call(DELETE, GROUPS + g.get(0), ali, null);
        assertThat(status(group)).isEqualTo(409);
        assertThat(code(group)).isEqualTo("GROUP_NOT_EMPTY");
    }

    // ---- amount cap (review CP2-001) ------------------------------------------------------------------------------

    @Test
    void amountsAtTheCapAreAcceptedAboveItTheyAreRefusedEverywhere() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        long cap = Limits.MAX_AMOUNT_MINOR;
        String url = GROUPS + g.get(0) + "/expenses";

        assertThat(status(postExpense(ali, g.get(0), UUID.randomUUID().toString(),
                equalBody("At cap", cap, List.of(g.get(1), g.get(2)), g.get(1), cap)))).isEqualTo(201);
        Map<String, Object> over = equalBody("Over", cap + 1, null, g.get(1), cap + 1);
        MvcResult create = postExpense(ali, g.get(0), UUID.randomUUID().toString(), over);
        assertThat(status(create)).isEqualTo(422);
        assertThat(code(create)).isEqualTo("VALIDATION_ERROR");
        assertThat(status(call(POST, url + "/preview", ali, over))).isEqualTo(422);
        String eid = createExpense(ali, g.get(0), equalBody("Small", 100, null, g.get(1), 100L)).get("id").asText();
        assertThat(status(call(PUT, url + "/" + eid, ali, over, "If-Match", "\"1\""))).isEqualTo(422);

        // an itemized bill whose parts are each within the cap but whose computed total is above it
        Map<String, Object> bill = new LinkedHashMap<>();
        bill.put("title", "Huge");
        bill.put("expenseDate", "2026-10-18");
        bill.put("splitType", "ITEMIZED");
        bill.put("payers", List.of(Map.of("memberId", g.get(1), "amountMinor", 1L)));
        bill.put("items", List.of(Map.of("name", "a", "amountMinor", 600_000_000_000L, "assigneeMemberIds", List.of(g.get(1))),
                Map.of("name", "b", "amountMinor", 600_000_000_000L, "assigneeMemberIds", List.of(g.get(2)))));
        assertThat(status(call(POST, url + "/preview", ali, bill))).isEqualTo(422);
        assertThat(status(settle(ali, g.get(0), UUID.randomUUID().toString(), g.get(1), g.get(2), cap))).isEqualTo(201);
        assertThat(status(settle(ali, g.get(0), UUID.randomUUID().toString(), g.get(1), g.get(2), cap + 1))).isEqualTo(422);
    }

    @Test
    void manyCapSizedExpensesNoLongerBreakTheGroupViewsOrBalances() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        long cap = Limits.MAX_AMOUNT_MINOR;
        for (int i = 0; i < 12; i++) {                                    // 12 x 10^12 is far beyond any real ledger
            createExpense(ali, g.get(0), exactBody("Big " + i, cap, List.of(g.get(2), cap), g.get(1), cap));
        }
        assertThat(status(call(GET, GROUPS + g.get(0), ali, null))).isEqualTo(200);
        assertThat(status(call(GET, "/api/v1/groups", ali, null))).isEqualTo(200);
        JsonNode b = balances(ali, g.get(0));
        assertThat(netsOf(b)).containsExactly(Map.entry(g.get(1), 12 * cap), Map.entry(g.get(2), -12 * cap),
                Map.entry(g.get(3), 0L));
        assertThat(body(call(GET, GROUPS + g.get(0), ali, null)).get("totalSpentMinor").asLong()).isEqualTo(12 * cap);
    }

    @Test
    void theDatabaseEnforcesTheCapAndTheSettlementRules() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        String user = ali.userId().toString();
        String insert = "insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, "
                + "note, created_by_user_id, status, declared_at, confirmed_at) values (?::uuid, ?::uuid, ?::uuid, ?::uuid, ?, "
                + "date '2026-10-20', ?, ?::uuid, 'CONFIRMED', now(), now())";

        assertThat(jdbc.update(insert, UUID.randomUUID().toString(), g.get(0), g.get(1), g.get(2),
                Limits.MAX_AMOUNT_MINOR, "ok", user)).isEqualTo(1);                          // control
        for (Object[] bad : new Object[][] {
                {g.get(1), g.get(1), 100L, null}, {g.get(1), g.get(2), 0L, null}, {g.get(1), g.get(2), -1L, null},
                {g.get(1), g.get(2), Limits.MAX_AMOUNT_MINOR + 1, null}, {g.get(1), g.get(2), 100L, "   "},
                {g.get(1), g.get(2), 100L, "x".repeat(201)}}) {
            assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID().toString(), g.get(0), bad[0], bad[1], bad[2],
                    bad[3], user)).isInstanceOf(DataIntegrityViolationException.class);
        }
        assertThatThrownBy(() -> jdbc.update("""
                insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id)
                values (?::uuid, ?::uuid, 't', 'EQUAL', ?, date '2026-10-20', ?::uuid)""", UUID.randomUUID().toString(),
                g.get(0), Limits.MAX_AMOUNT_MINOR + 1, user)).isInstanceOf(DataIntegrityViolationException.class);
    }

    // ---- randomized ledger -----------------------------------------------------------------------------------------

    private static List<String> subset(List<String> ids, Random rnd) {
        List<String> copy = new ArrayList<>(ids);
        Collections.shuffle(copy, rnd);
        return copy.subList(0, 1 + rnd.nextInt(ids.size()));
    }

    @Test
    void afterARandomLedgerTheNetsSumToZeroBothQueryPathsAgreeAndApplyingTheTransfersZeroesEverything() throws Exception {
        long seed = 424242L;
        Random rnd = new Random(seed);
        Session ali = newUser();
        String gid = createGroup(ali, "Random " + UUID.randomUUID()).get("id").asText();
        List<String> ids = new ArrayList<>();
        for (String n : List.of("A", "B", "C", "D", "E", "F")) {
            ids.add(member(ali, gid, n).get("id").asText());
        }
        List<String> liveExpenses = new ArrayList<>();
        Map<String, Integer> expenseVersion = new LinkedHashMap<>();
        List<String> liveSettlements = new ArrayList<>();

        for (int step = 0; step < 150; step++) {
            String ctx = "seed=" + seed + " step=" + step;
            int dice = rnd.nextInt(100);
            if (dice < 30 || liveExpenses.isEmpty()) {
                long total = 1 + rnd.nextInt(300000);
                List<String> payers = subset(ids, rnd);
                payers = payers.subList(0, (int) Math.min(payers.size(), total));
                Object[] pay = new Object[payers.size() * 2];
                long left = total;
                for (int i = 0; i < payers.size(); i++) {
                    long part = i == payers.size() - 1 ? left : Math.min(left - (payers.size() - 1 - i), 1 + rnd.nextInt((int) Math.max(1, left / 2)));
                    pay[2 * i] = payers.get(i);
                    pay[2 * i + 1] = part;
                    left -= part;
                }
                Map<String, Object> body = rnd.nextBoolean()
                        ? equalBody("e" + step, total, rnd.nextBoolean() ? null : subset(ids, rnd), pay)
                        : exactBody("e" + step, total, List.of(ids.get(0), total / 2, ids.get(1), total - total / 2), pay);
                JsonNode created = createExpense(ali, gid, body);
                liveExpenses.add(created.get("id").asText());
                expenseVersion.put(created.get("id").asText(), 1);
            } else if (dice < 45) {
                String eid = liveExpenses.get(rnd.nextInt(liveExpenses.size()));
                long total = 1 + rnd.nextInt(300000);
                MvcResult r = call(PUT, GROUPS + gid + "/expenses/" + eid, ali,
                        equalBody("edit" + step, total, subset(ids, rnd), ids.get(rnd.nextInt(ids.size())), total),
                        "If-Match", "\"" + expenseVersion.get(eid) + "\"");
                assertThat(status(r)).as(ctx).isEqualTo(200);
                expenseVersion.merge(eid, 1, Integer::sum);
            } else if (dice < 60) {
                String eid = liveExpenses.remove(rnd.nextInt(liveExpenses.size()));
                assertThat(status(call(DELETE, GROUPS + gid + "/expenses/" + eid, ali, null, "If-Match",
                        "\"" + expenseVersion.remove(eid) + "\""))).as(ctx).isEqualTo(204);
            } else if (dice < 90) {
                int from = rnd.nextInt(ids.size());
                int to = (from + 1 + rnd.nextInt(ids.size() - 1)) % ids.size();
                liveSettlements.add(settleOk(ali, gid, ids.get(from), ids.get(to), 1 + rnd.nextInt(100000)).get("id").asText());
            } else if (!liveSettlements.isEmpty()) {
                String sid = liveSettlements.get(rnd.nextInt(liveSettlements.size()));
                assertThat(status(call(POST, GROUPS + gid + "/settlements/" + sid + "/cancel", ali, null))).as(ctx).isEqualTo(409);
            }
            JsonNode b = balances(ali, gid);
            Map<String, Long> nets = netsOf(b);
            assertThat(nets.values().stream().mapToLong(Long::longValue).sum()).as(ctx).isZero();
            if (step % 25 == 0) {
                assertThat(nets).as(ctx + " rows vs totals").isEqualTo(netsFromRows(ali, gid, ids));
            }
        }
        assertThat(netsOf(balances(ali, gid))).isEqualTo(netsFromRows(ali, gid, ids));

        // apply the suggested transfers as real settlements: everybody ends at zero, nothing left to suggest
        for (String t : transfersOf(balances(ali, gid))) {
            String[] parts = t.split("[>:]");
            settleOk(ali, gid, parts[0], parts[1], Long.parseLong(parts[2]));
        }
        JsonNode settled = balances(ali, gid);
        assertThat(netsOf(settled).values()).containsOnly(0L);
        assertThat(settled.get("transfers")).isEmpty();
    }

    /** The row-by-row engine rule, fed from the API's own lists. */
    private Map<String, Long> netsFromRows(Session as, String gid, List<String> ids) throws Exception {
        List<MemberRef> roster = new ArrayList<>();
        for (int i = 0; i < ids.size(); i++) {
            roster.add(new MemberRef(ids.get(i), i + 1));
        }
        List<BalanceCalculator.ExpenseLedgerEntry> expenses = new ArrayList<>();
        for (JsonNode e : body(call(GET, GROUPS + gid + "/expenses?size=100", as, null)).get("items")) {
            List<Payer> payers = new ArrayList<>();
            e.get("payers").forEach(p -> payers.add(new Payer(p.get("memberId").asText(), p.get("amountMinor").asLong())));
            Map<String, Long> owed = new LinkedHashMap<>();
            e.get("shares").forEach(s -> owed.put(s.get("memberId").asText(), s.get("owedMinor").asLong()));
            expenses.add(new BalanceCalculator.ExpenseLedgerEntry(payers, owed));
        }
        List<BalanceCalculator.SettlementEntry> settlements = new ArrayList<>();
        for (JsonNode s : body(call(GET, GROUPS + gid + "/settlements?status=CONFIRMED&size=100", as, null)).get("items")) {
            settlements.add(new BalanceCalculator.SettlementEntry(s.get("fromMemberId").asText(),
                    s.get("toMemberId").asText(), s.get("amountMinor").asLong()));
        }
        return BalanceCalculator.nets(roster, expenses, settlements);
    }

    // ---- concurrency -------------------------------------------------------------------------------------------

    @Test
    void balancesReadWhileOthersWriteAlwaysSumToZero() throws Exception {
        Session ali = newUser();
        List<String> g = mas(ali);
        v1(ali, g);
        ExecutorService pool = Executors.newFixedThreadPool(6);
        AtomicBoolean writing = new AtomicBoolean(true);
        try {
            List<Future<?>> writers = new ArrayList<>();
            for (int w = 0; w < 4; w++) {
                int n = w;
                writers.add(pool.submit(() -> {
                    for (int i = 0; i < 12; i++) {
                        if (n % 2 == 0) {
                            settleOk(ali, g.get(0), g.get(2), g.get(1), 100 + i);
                        } else {
                            createExpense(ali, g.get(0), equalBody("w" + n + "-" + i, 900 + i, null, g.get(1), 900L + i));
                        }
                    }
                    return null;
                }));
            }
            Future<Integer> reader = pool.submit(() -> {
                int reads = 0;
                while (writing.get() || reads < 20) {
                    JsonNode b = balances(ali, g.get(0));
                    assertThat(netsOf(b).values().stream().mapToLong(Long::longValue).sum()).isZero();
                    reads++;
                }
                return reads;
            });
            for (Future<?> f : writers) {
                f.get();
            }
            writing.set(false);
            assertThat(reader.get()).isGreaterThanOrEqualTo(20);
        } finally {
            pool.shutdownNow();
        }
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, g.get(0)))
                .isEqualTo(24L);
    }
}
