package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
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
 * ITEMIZED bills and the preview endpoint end to end on real PostgreSQL: spec vectors V5-V8 with the exact numbers
 * from spec section 10, preview == create, preview persists nothing, validation codes, replay, ownership isolation
 * and the schema constraints that tie charges and breakdowns together.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ItemizedExpensesIT extends AbstractApiIT {

    private static final String[] TABLES = {"expenses", "expense_payers", "expense_splits", "expense_items",
            "expense_item_assignees", "idempotency_keys"};

    /** [groupId, A, B, C] with A, B, C in sort order. */
    private List<String> abc(Session owner) throws Exception {
        String gid = createGroup(owner, "G " + UUID.randomUUID()).get("id").asText();
        return List.of(gid, member(owner, gid, "A").get("id").asText(), member(owner, gid, "B").get("id").asText(),
                member(owner, gid, "C").get("id").asText());
    }

    private static Map<String, Object> item(String name, long amount, String... assignees) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("name", name);
        m.put("amountMinor", amount);
        m.put("assigneeMemberIds", List.of(assignees));
        return m;
    }

    /** Pizza 200.00 (A,B), Pasta 150.00 (C), Drinks 90.00 (A,B,C): the items shared by V5-V8. */
    private static List<Map<String, Object>> restaurant(List<String> g) {
        return List.of(item("Pizza", 20000, g.get(1), g.get(2)), item("Pasta", 15000, g.get(3)),
                item("Drinks", 9000, g.get(1), g.get(2), g.get(3)));
    }

    private Map<String, Object> bill(List<Map<String, Object>> items, Integer serviceBps, Integer taxBps,
                                     String taxBase, Long adjustment, Object... payers) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("title", "Seafood dinner");
        body.put("expenseDate", "2026-10-18");
        body.put("splitType", "ITEMIZED");
        List<Map<String, Object>> list = new ArrayList<>();
        for (int i = 0; i + 1 < payers.length; i += 2) {
            list.add(Map.of("memberId", payers[i], "amountMinor", payers[i + 1]));
        }
        body.put("payers", list);
        body.put("items", items);
        if (serviceBps != null) {
            body.put("service", Map.of("bps", serviceBps));
        }
        if (taxBps != null) {
            Map<String, Object> tax = new LinkedHashMap<>();
            tax.put("bps", taxBps);
            if (taxBase != null) {
                tax.put("base", taxBase);
            }
            body.put("tax", tax);
        }
        if (adjustment != null) {
            body.put("adjustmentMinor", adjustment);
        }
        return body;
    }

    private static List<Long> owed(JsonNode shares) {
        List<Long> out = new ArrayList<>();
        shares.forEach(s -> out.add(s.get("owedMinor").asLong()));
        return out;
    }

    private JsonNode preview(Session as, String gid, Object body) throws Exception {
        MvcResult r = call(POST, "/api/v1/groups/" + gid + "/expenses/preview", as, body);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        return body(r);
    }

    private long rows(String table) {
        return jdbc.queryForObject("select count(*) from " + table, Long.class);
    }

    // ---- spec vectors V5-V8 through the API ---------------------------------------------------------------

    @Test
    void v5ServiceAndTaxOnSubtotalPlusServiceWithTheTieBreakToTheLowerSortOrder() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);

        JsonNode e = createExpense(ali, g.get(0),
                bill(restaurant(g), 1200, 1400, "SUBTOTAL_PLUS_SERVICE", 0L, g.get(1), 56179L));

        assertThat(owed(e.get("shares"))).containsExactly(16599L, 16598L, 22982L);   // A 165.99, B 165.98, C 229.82
        assertThat(e.get("totalMinor").asLong()).isEqualTo(56179);
        assertThat(e.get("splitType").asText()).isEqualTo("ITEMIZED");
        JsonNode charges = e.get("charges");
        assertThat(charges.get("subtotalMinor").asLong()).isEqualTo(44000);
        assertThat(charges.get("service").get("bps").asInt()).isEqualTo(1200);
        assertThat(charges.get("service").get("amountMinor").asLong()).isEqualTo(5280);
        assertThat(charges.get("tax").get("bps").asInt()).isEqualTo(1400);
        assertThat(charges.get("tax").get("base").asText()).isEqualTo("SUBTOTAL_PLUS_SERVICE");
        assertThat(charges.get("tax").get("amountMinor").asLong()).isEqualTo(6899);
        assertThat(charges.get("adjustmentMinor").asLong()).isZero();
        JsonNode a = e.get("shares").get(0);
        assertThat(a.get("itemsMinor").asLong()).isEqualTo(13000);
        assertThat(a.get("serviceMinor").asLong()).isEqualTo(1560);
        assertThat(a.get("taxMinor").asLong()).isEqualTo(2039);
        assertThat(a.get("adjustmentMinor").asLong()).isZero();
        assertThat(e.get("items")).hasSize(3);
        assertThat(e.get("items").get(0).get("name").asText()).isEqualTo("Pizza");
        assertThat(e.get("items").get(0).get("assigneeMemberIds")).hasSize(2);
        assertThat(e.get("items").get(2).get("assigneeMemberIds")).hasSize(3);
    }

    @Test
    void v6ServiceOnly() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode e = createExpense(ali, g.get(0), bill(restaurant(g), 1200, null, null, null, g.get(1), 49280L));

        assertThat(owed(e.get("shares"))).containsExactly(14560L, 14560L, 20160L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(49280);
        assertThat(e.get("charges").get("tax").isNull()).isTrue();
        assertThat(e.get("charges").get("service").get("amountMinor").asLong()).isEqualTo(5280);
    }

    @Test
    void v7TaxOnlyOnSubtotal() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode e = createExpense(ali, g.get(0), bill(restaurant(g), null, 1400, "SUBTOTAL", null, g.get(1), 50160L));

        assertThat(owed(e.get("shares"))).containsExactly(14820L, 14820L, 20520L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(50160);
        assertThat(e.get("charges").get("service").isNull()).isTrue();
        assertThat(e.get("charges").get("tax").get("amountMinor").asLong()).isEqualTo(6160);
    }

    @Test
    void v8NeitherServiceNorTax() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode e = createExpense(ali, g.get(0), bill(restaurant(g), null, null, null, null, g.get(1), 44000L));

        assertThat(owed(e.get("shares"))).containsExactly(13000L, 13000L, 18000L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(44000);
        assertThat(e.get("charges").get("service").isNull()).isTrue();
        assertThat(e.get("charges").get("tax").isNull()).isTrue();
    }

    @Test
    void multiplePayersAndAPayerWhoIsNotAParticipantWork() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String d = member(ali, g.get(0), "D").get("id").asText();          // pays, eats nothing
        JsonNode e = createExpense(ali, g.get(0),
                bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 30000L, d, 26179L));

        assertThat(e.get("payers")).hasSize(2);
        assertThat(e.get("shares")).hasSize(3);                               // D owes nothing and is not a participant
        assertThat(owed(e.get("shares"))).containsExactly(16599L, 16598L, 22982L);
    }

    @Test
    void aMemberWithNoItemsIsDroppedFromSplitsAndANegativeAdjustmentLowersTheTotal() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        List<Map<String, Object>> items = List.of(item("Pizza", 20000, g.get(1), g.get(2)));

        JsonNode e = createExpense(ali, g.get(0), bill(items, null, null, null, -100L, g.get(1), 19900L));

        assertThat(e.get("shares")).hasSize(2);
        assertThat(owed(e.get("shares"))).containsExactly(9950L, 9950L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(19900);
        assertThat(e.get("charges").get("adjustmentMinor").asLong()).isEqualTo(-100);
        assertThat(jdbc.queryForObject("select count(*) from expense_splits where expense_id = ?::uuid", Long.class,
                e.get("id").asText())).isEqualTo(2L);
    }

    @Test
    void getDetailAndListShowItemsAssigneesAndCharges() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode created = createExpense(ali, g.get(0),
                bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L));
        createExpense(ali, g.get(0), equalBody("Taxi", 3000, null, g.get(1), 3000L));
        String base = "/api/v1/groups/" + g.get(0) + "/expenses";

        JsonNode detail = body(call(GET, base + "/" + created.get("id").asText(), ali, null));
        assertThat(detail.get("items")).isEqualTo(created.get("items"));
        assertThat(detail.get("charges")).isEqualTo(created.get("charges"));
        assertThat(detail.get("shares")).isEqualTo(created.get("shares"));

        JsonNode page = body(call(GET, base + "?size=10", ali, null));
        assertThat(page.get("items")).hasSize(2);
        JsonNode itemized = null;
        JsonNode plain = null;
        for (JsonNode x : page.get("items")) {
            if (x.get("splitType").asText().equals("ITEMIZED")) {
                itemized = x;
            } else {
                plain = x;
            }
        }
        assertThat(itemized.get("items")).hasSize(3);
        assertThat(itemized.get("charges").get("tax").get("amountMinor").asLong()).isEqualTo(6899);
        assertThat(plain.get("items").isNull()).isTrue();
        assertThat(plain.get("charges").isNull()).isTrue();
        assertThat(plain.get("shares").get(0).get("itemsMinor").isNull()).isTrue();
    }

    // ---- preview ---------------------------------------------------------------------------------------

    @Test
    void previewAndCreateReturnTheSameBreakdownForAllThreeSplitTypes() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        List<Object> exactShares = List.of(g.get(1), 4000L, g.get(2), 6000L);
        List<Map<String, Object>> bodies = List.of(
                equalBody("Dinner", 10000, null, g.get(1), 10000L),
                exactBody("Taxi", 10000, exactShares, g.get(1), 10000L),
                bill(restaurant(g), 1200, 1400, null, -7L, g.get(1), 56172L));

        for (Map<String, Object> request : bodies) {
            JsonNode previewed = preview(ali, g.get(0), request);
            JsonNode created = createExpense(ali, g.get(0), request);
            assertThat(previewed.get("members")).as(request.get("splitType").toString()).isEqualTo(created.get("shares"));
            assertThat(previewed.get("totalMinor").asLong()).isEqualTo(created.get("totalMinor").asLong());
            assertThat(previewed.get("payersTotalMatches").asBoolean()).isTrue();
        }
    }

    @Test
    void previewOfAnItemizedBillReportsEveryTotal() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);

        JsonNode p = preview(ali, g.get(0), bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L));

        assertThat(p.get("totalMinor").asLong()).isEqualTo(56179);
        assertThat(p.get("subtotalMinor").asLong()).isEqualTo(44000);
        assertThat(p.get("serviceMinor").asLong()).isEqualTo(5280);
        assertThat(p.get("taxMinor").asLong()).isEqualTo(6899);
        assertThat(p.get("adjustmentMinor").asLong()).isZero();
        assertThat(p.get("payersTotalMatches").asBoolean()).isTrue();
        assertThat(owed(p.get("members"))).containsExactly(16599L, 16598L, 22982L);
        assertThat(p.get("members").get(0).get("itemsMinor").asLong()).isEqualTo(13000);
    }

    @Test
    void previewFlagsAPayersMismatchAndAllowsNoPayersYetWhereCreateRejectsThem() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);

        JsonNode wrong = preview(ali, g.get(0), bill(restaurant(g), null, null, null, null, g.get(1), 43999L));
        assertThat(wrong.get("payersTotalMatches").asBoolean()).isFalse();
        assertThat(wrong.get("totalMinor").asLong()).isEqualTo(44000);

        Map<String, Object> noPayers = bill(restaurant(g), null, null, null, null);
        assertThat(preview(ali, g.get(0), noPayers).get("payersTotalMatches").asBoolean()).isFalse();

        MvcResult create = postExpense(ali, g.get(0), UUID.randomUUID().toString(),
                bill(restaurant(g), null, null, null, null, g.get(1), 43999L));
        assertThat(status(create)).isEqualTo(422);
        assertThat(code(create)).isEqualTo("PAYERS_TOTAL_MISMATCH");
        assertThat(status(postExpense(ali, g.get(0), UUID.randomUUID().toString(), noPayers))).isEqualTo(422);
        assertThat(countExpenses(g.get(0))).isZero();
    }

    @Test
    void previewPersistsNothingHoweverOftenItIsCalled() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        createExpense(ali, g.get(0), equalBody("Seed", 1000, null, g.get(1), 1000L)); // some data already present
        Map<String, Long> before = new LinkedHashMap<>();
        for (String t : TABLES) {
            before.put(t, rows(t));
        }
        List<Map<String, Object>> bodies = List.of(equalBody("E", 1000, null, g.get(1), 1000L),
                exactBody("X", 1000, List.of(g.get(1), 400L, g.get(2), 600L), g.get(1), 1000L),
                bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L));

        for (int i = 0; i < 3; i++) {
            for (Map<String, Object> b : bodies) {
                preview(ali, g.get(0), b);
            }
        }
        // a rejected preview must not leave anything behind either
        assertThat(status(call(POST, "/api/v1/groups/" + g.get(0) + "/expenses/preview", ali,
                bill(List.of(), null, null, null, null)))).isEqualTo(422);

        for (String t : TABLES) {
            assertThat(rows(t)).as(t).isEqualTo(before.get(t));
        }
    }

    @Test
    void previewOnAnotherUsersGroupIsTheSame404AsAGroupThatDoesNotExist() throws Exception {
        Session ali = newUser();
        Session bob = newUser();
        List<String> g = abc(ali);
        Map<String, Object> body = bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L);

        MvcResult foreign = call(POST, "/api/v1/groups/" + g.get(0) + "/expenses/preview", bob, body);
        MvcResult missing = call(POST, "/api/v1/groups/" + UUID.randomUUID() + "/expenses/preview", bob, body);

        assertThat(status(foreign)).isEqualTo(404);
        assertThat(problemWithoutRequestId(foreign)).isEqualTo(problemWithoutRequestId(missing));
        assertThat(status(call(POST, "/api/v1/groups/" + g.get(0) + "/expenses/preview", null, body))).isEqualTo(401);
    }

    @Test
    void createOnAnotherUsersGroupIsA404AndWritesNothing() throws Exception {
        Session ali = newUser();
        Session bob = newUser();
        List<String> g = abc(ali);

        MvcResult r = postExpense(bob, g.get(0), UUID.randomUUID().toString(),
                bill(restaurant(g), null, null, null, null, g.get(1), 44000L));

        assertThat(status(r)).isEqualTo(404);
        assertThat(countExpenses(g.get(0))).isZero();
    }

    // ---- validation ---------------------------------------------------------------------------------------

    private void assertCreateAndPreviewReject(Session as, String gid, Map<String, Object> body, int status, String code)
            throws Exception {
        MvcResult create = postExpense(as, gid, UUID.randomUUID().toString(), body);
        assertThat(status(create)).as("create " + body).isEqualTo(status);
        assertThat(code(create)).as("create " + body).isEqualTo(code);
        if (!code.equals("PAYERS_TOTAL_MISMATCH")) {          // preview reports payer mismatches as a flag instead
            MvcResult previewed = call(POST, "/api/v1/groups/" + gid + "/expenses/preview", as, body);
            assertThat(status(previewed)).as("preview " + body).isEqualTo(status);
            assertThat(code(previewed)).as("preview " + body).isEqualTo(code);
        }
        assertThat(countExpenses(gid)).as("nothing persisted for " + body).isZero();
    }

    @Test
    void invalidItemizedRequestsAreRejectedWithStableCodesByBothEndpoints() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String gid = g.get(0);
        Object a = g.get(1);
        List<Map<String, Object>> ok = restaurant(g);

        assertCreateAndPreviewReject(ali, gid, bill(List.of(), null, null, null, null, a, 1L), 422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(List.of(item("Pizza", 100)), null, null, null, null, a, 100L), 422,
                "VALIDATION_ERROR");                                                          // no assignee
        assertCreateAndPreviewReject(ali, gid, bill(List.of(item("Pizza", 0, g.get(1))), null, null, null, null, a, 1L),
                422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(ok, 10001, null, null, null, a, 1L), 422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(ok, -1, null, null, null, a, 1L), 422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(ok, null, 10001, null, null, a, 1L), 422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(ok, null, 1400, "TOTAL", null, a, 1L), 422, "VALIDATION_ERROR");
        assertCreateAndPreviewReject(ali, gid, bill(List.of(item("Pizza", 100, g.get(1), g.get(1))), null, null, null,
                null, a, 100L), 422, "VALIDATION_ERROR");                                      // duplicate assignee
        assertCreateAndPreviewReject(ali, gid, bill(List.of(item("Pizza", 100, g.get(1))), null, null, null, -100L, a,
                1L), 422, "VALIDATION_ERROR");                                                // total would be 0
        assertCreateAndPreviewReject(ali, gid, bill(List.of(item("Pizza", 100, UUID.randomUUID().toString())), null,
                null, null, null, a, 100L), 422, "MEMBER_NOT_IN_GROUP");
        assertCreateAndPreviewReject(ali, gid, bill(ok, null, null, null, null, UUID.randomUUID().toString(), 44000L),
                422, "MEMBER_NOT_IN_GROUP");
        assertCreateAndPreviewReject(ali, gid, bill(ok, null, null, null, null, a, 43999L), 422, "PAYERS_TOTAL_MISMATCH");
        Map<String, Object> wrongTotal = bill(ok, null, null, null, null, a, 44000L);
        wrongTotal.put("totalMinor", 44001L);
        assertCreateAndPreviewReject(ali, gid, wrongTotal, 422, "SPLIT_TOTAL_MISMATCH");
        Map<String, Object> itemsOnEqual = equalBody("E", 100, null, a, 100L);
        itemsOnEqual.put("items", ok);
        assertCreateAndPreviewReject(ali, gid, itemsOnEqual, 422, "VALIDATION_ERROR");
    }

    @Test
    void aStatedTotalThatMatchesTheComputedOneIsAccepted() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        Map<String, Object> body = bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L);
        body.put("totalMinor", 56179L);
        assertThat(createExpense(ali, g.get(0), body).get("totalMinor").asLong()).isEqualTo(56179);
    }

    @Test
    void aBillWithMoreThanOneHundredItemsIsRejected() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        List<Map<String, Object>> many = new ArrayList<>();
        for (int i = 0; i < 101; i++) {
            many.add(item("i" + i, 100, g.get(1)));
        }
        assertCreateAndPreviewReject(ali, g.get(0), bill(many, null, null, null, null, g.get(1), 10100L), 422,
                "VALIDATION_ERROR");
    }

    // ---- idempotency and concurrency ---------------------------------------------------------------------

    @Test
    void replayingAnItemizedCreateReturnsTheSameBodyAndStoresOneSetOfRows() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String key = UUID.randomUUID().toString();
        Map<String, Object> body = bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L);

        MvcResult first = postExpense(ali, g.get(0), key, body);
        MvcResult second = postExpense(ali, g.get(0), key, body);

        assertThat(status(first)).isEqualTo(201);
        assertThat(status(second)).isEqualTo(201);
        assertThat(second.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(second)).isEqualTo(body(first));          // jsonb: same content, not necessarily same bytes
        String eid = body(first).get("id").asText();
        assertThat(jdbc.queryForObject("select count(*) from expense_items where expense_id = ?::uuid", Long.class, eid))
                .isEqualTo(3L);
        assertThat(jdbc.queryForObject("""
                select count(*) from expense_item_assignees a join expense_items i on i.id = a.item_id
                where i.expense_id = ?::uuid""", Long.class, eid)).isEqualTo(6L);

        Map<String, Object> changed = bill(restaurant(g), 1200, 1500, null, 0L, g.get(1), 56179L);
        assertThat(code(postExpense(ali, g.get(0), key, changed))).isEqualTo("IDEMPOTENCY_KEY_REUSED");
    }

    @Test
    void parallelRetriesOfOneItemizedCreateProduceExactlyOneBill() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String key = UUID.randomUUID().toString();
        Map<String, Object> body = bill(restaurant(g), 1200, 1400, null, 0L, g.get(1), 56179L);
        ExecutorService pool = Executors.newFixedThreadPool(10);
        CountDownLatch go = new CountDownLatch(1);
        try {
            List<Future<Integer>> results = new ArrayList<>();
            for (int i = 0; i < 10; i++) {
                results.add(pool.submit(() -> {
                    go.await();
                    return status(postExpense(ali, g.get(0), key, body));
                }));
            }
            go.countDown();
            for (Future<Integer> f : results) {
                assertThat(f.get()).isEqualTo(201);
            }
        } finally {
            pool.shutdownNow();
        }
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
        assertThat(jdbc.queryForObject("""
                select count(*) from expense_items i join expenses e on e.id = i.expense_id
                where e.group_id = ?::uuid""", Long.class, g.get(0))).isEqualTo(3L);
    }

    // ---- delete rules ---------------------------------------------------------------------------------------

    @Test
    void anItemAssigneeWhoOwesNothingStillCannotBeDeleted() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        // 1 piaster between A and B: A owes 1, B owes 0 and is dropped from the splits, but stays an assignee.
        JsonNode e = createExpense(ali, g.get(0),
                bill(List.of(item("Mint", 1, g.get(1), g.get(2))), null, null, null, null, g.get(1), 1L));
        assertThat(e.get("shares")).hasSize(1);

        MvcResult blocked = call(DELETE, "/api/v1/groups/" + g.get(0) + "/members/" + g.get(2), ali, null);

        assertThat(status(blocked)).isEqualTo(409);
        assertThat(code(blocked)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
        assertThat(status(call(DELETE, "/api/v1/groups/" + g.get(0) + "/members/" + g.get(3), ali, null)))
                .isEqualTo(204);                                                             // C is unused
    }

    // ---- schema constraints ------------------------------------------------------------------------------------

    private void insertExpense(String id, String groupId, String userId, String type, long total, Long subtotal,
                               Long service, Long tax, Long adjustment, Integer serviceBps, Integer taxBps, String base) {
        jdbc.update("""
                insert into expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor,
                    service_bps, service_minor, tax_bps, tax_minor, tax_base, adjustment_minor, created_by_user_id)
                values (?::uuid, ?::uuid, 't', ?, ?, date '2026-10-18', ?, ?, ?, ?, ?, ?, ?, ?::uuid)""",
                id, groupId, type, total, subtotal, serviceBps, service, taxBps, tax, base, adjustment, userId);
    }

    @Test
    void theDatabaseRejectsItemizedExpensesWhoseChargesDoNotAddUp() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Schema").get("id").asText();
        String user = ali.userId().toString();

        // control: a consistent ITEMIZED row is accepted
        insertExpense(UUID.randomUUID().toString(), gid, user, "ITEMIZED", 561, 440L, 52L, 69L, 0L, 1200, 1400,
                "SUBTOTAL_PLUS_SERVICE");
        // total != subtotal + service + tax + adjustment
        assertThatThrownBy(() -> insertExpense(UUID.randomUUID().toString(), gid, user, "ITEMIZED", 999, 440L, 52L,
                69L, 0L, 1200, 1400, "SUBTOTAL_PLUS_SERVICE")).isInstanceOf(DataIntegrityViolationException.class);
        // an ITEMIZED row must carry its charges
        assertThatThrownBy(() -> insertExpense(UUID.randomUUID().toString(), gid, user, "ITEMIZED", 440, null, null,
                null, null, null, null, null)).isInstanceOf(DataIntegrityViolationException.class);
        // service amount without a service rate; tax rate without a base
        assertThatThrownBy(() -> insertExpense(UUID.randomUUID().toString(), gid, user, "ITEMIZED", 492, 440L, 52L,
                0L, 0L, null, null, null)).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertExpense(UUID.randomUUID().toString(), gid, user, "ITEMIZED", 501, 440L, 0L,
                61L, 0L, null, 1400, null)).isInstanceOf(DataIntegrityViolationException.class);
        // itemized columns on an EQUAL expense
        assertThatThrownBy(() -> insertExpense(UUID.randomUUID().toString(), gid, user, "EQUAL", 440, 440L, null,
                null, null, null, null, null)).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void theDatabaseRejectsSplitBreakdownsThatDoNotExplainTheOwedAmountAndBadItems() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode e = createExpense(ali, g.get(0), bill(restaurant(g), null, null, null, null, g.get(1), 44000L));
        String eid = e.get("id").asText();

        // all four breakdown columns or none; and they must add up to owed
        assertThatThrownBy(() -> jdbc.update("""
                update expense_splits set items_minor = 1 where expense_id = ?::uuid and member_id = ?::uuid""",
                eid, g.get(1))).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("""
                update expense_splits set items_minor = items_minor + 1 where expense_id = ?::uuid and member_id = ?::uuid""",
                eid, g.get(1))).isInstanceOf(DataIntegrityViolationException.class);

        assertThatThrownBy(() -> jdbc.update("""
                insert into expense_items (id, expense_id, name, amount_minor, sort_order)
                values (?::uuid, ?::uuid, 'zero', 0, 9)""", UUID.randomUUID().toString(), eid))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("""
                insert into expense_items (id, expense_id, name, amount_minor, sort_order)
                values (?::uuid, ?::uuid, '  ', 5, 9)""", UUID.randomUUID().toString(), eid))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("""
                insert into expense_items (id, expense_id, name, amount_minor, sort_order)
                values (?::uuid, ?::uuid, 'dup order', 5, 0)""", UUID.randomUUID().toString(), eid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
