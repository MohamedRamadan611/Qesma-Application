package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;

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
 * Edit, delete and history of expenses on real PostgreSQL: recalculation, revisions, optimistic concurrency under
 * parallel writers, soft-delete visibility, ownership isolation and validation parity with create.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ExpenseEditDeleteIT extends AbstractApiIT {

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

    /** V5 items: Pizza 200.00 (A,B), Pasta 150.00 (C), Drinks 90.00 (A,B,C). */
    private static List<Map<String, Object>> restaurant(List<String> g) {
        return List.of(item("Pizza", 20000, g.get(1), g.get(2)), item("Pasta", 15000, g.get(3)),
                item("Drinks", 9000, g.get(1), g.get(2), g.get(3)));
    }

    private Map<String, Object> bill(List<String> g, int serviceBps, long paid) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("title", "Seafood dinner");
        body.put("expenseDate", "2026-10-18");
        body.put("splitType", "ITEMIZED");
        body.put("payers", List.of(Map.of("memberId", g.get(1), "amountMinor", paid)));
        body.put("items", restaurant(g));
        body.put("service", Map.of("bps", serviceBps));
        body.put("tax", Map.of("bps", 1400, "base", "SUBTOTAL_PLUS_SERVICE"));
        return body;
    }

    private static List<Long> owed(JsonNode shares) {
        List<Long> out = new ArrayList<>();
        shares.forEach(s -> out.add(s.get("owedMinor").asLong()));
        return out;
    }

    private static String url(String gid, String eid) {
        return "/api/v1/groups/" + gid + "/expenses/" + eid;
    }

    private MvcResult put(Session as, String gid, String eid, int version, Object body) throws Exception {
        return call(PUT, url(gid, eid), as, body, "If-Match", "\"" + version + "\"");
    }

    private MvcResult del(Session as, String gid, String eid, int version) throws Exception {
        return call(DELETE, url(gid, eid), as, null, "If-Match", "\"" + version + "\"");
    }

    private long revisionCount(String eid) {
        return jdbc.queryForObject("select count(*) from expense_revisions where expense_id = ?::uuid", Long.class, eid);
    }

    private int versionOf(String eid) {
        return jdbc.queryForObject("select version from expenses where id = ?::uuid", Integer.class, eid);
    }

    private long childRows(String eid) {
        return jdbc.queryForObject("""
                select (select count(*) from expense_payers where expense_id = ?::uuid)
                     + (select count(*) from expense_splits where expense_id = ?::uuid)
                     + (select count(*) from expense_items where expense_id = ?::uuid)
                     + (select count(*) from expense_item_assignees a join expense_items i on i.id = a.item_id
                        where i.expense_id = ?::uuid)""", Long.class, eid, eid, eid, eid);
    }

    // ---- edit -----------------------------------------------------------------------------------------------

    @Test
    void editingTheServiceChargeFrom12To10PercentRecalculatesEverythingAndReplacesTheChildren() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode created = createExpense(ali, g.get(0), bill(g, 1200, 56179));
        String eid = created.get("id").asText();
        assertThat(owed(created.get("shares"))).containsExactly(16599L, 16598L, 22982L);
        long before = childRows(eid);

        MvcResult r = put(ali, g.get(0), eid, 1, bill(g, 1000, 55176));

        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        JsonNode e = body(r);
        assertThat(etagOf(r)).isEqualTo("\"2\"");
        assertThat(e.get("version").asInt()).isEqualTo(2);
        assertThat(e.get("id").asText()).isEqualTo(eid);
        assertThat(e.get("createdAt")).isEqualTo(created.get("createdAt"));
        assertThat(owed(e.get("shares"))).containsExactly(16302L, 16302L, 22572L);
        assertThat(e.get("totalMinor").asLong()).isEqualTo(55176);
        assertThat(e.get("charges").get("service").get("bps").asInt()).isEqualTo(1000);
        assertThat(e.get("charges").get("service").get("amountMinor").asLong()).isEqualTo(4400);
        assertThat(e.get("charges").get("tax").get("amountMinor").asLong()).isEqualTo(6776);
        assertThat(childRows(eid)).as("old payers/splits/items are replaced, not duplicated").isEqualTo(before);
        assertThat(versionOf(eid)).isEqualTo(2);

        JsonNode detail = body(call(GET, url(g.get(0), eid), ali, null));
        assertThat(detail.get("shares")).isEqualTo(e.get("shares"));
        assertThat(detail.get("items")).isEqualTo(e.get("items"));
        assertThat(jdbc.queryForObject("select total_minor from expenses where id = ?::uuid", Long.class, eid))
                .isEqualTo(55176L);
    }

    @Test
    void createReturnsAnETagAndWritesExactlyOneCreateRevisionAndAReplayWritesNone() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Taxi", 3000, null, g.get(1), 3000L);

        MvcResult first = postExpense(ali, g.get(0), key, body);
        MvcResult replay = postExpense(ali, g.get(0), key, body);

        assertThat(status(first)).isEqualTo(201);
        assertThat(etagOf(first)).isEqualTo("\"1\"");
        assertThat(etagOf(replay)).isEqualTo("\"1\"");
        String eid = body(first).get("id").asText();
        assertThat(revisionCount(eid)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select change_type from expense_revisions where expense_id = ?::uuid",
                String.class, eid)).isEqualTo("CREATE");
        assertThat(etagOf(call(GET, url(g.get(0), eid), ali, null))).isEqualTo("\"1\"");
    }

    @Test
    void revisionsAfterCreateUpdateDeleteAreChronologicalAndKeepEachSnapshot() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), bill(g, 1200, 56179)).get("id").asText();
        assertThat(status(put(ali, g.get(0), eid, 1, bill(g, 1000, 55176)))).isEqualTo(200);
        MvcResult deleted = del(ali, g.get(0), eid, 2);
        assertThat(status(deleted)).isEqualTo(204);
        assertThat(etagOf(deleted)).isEqualTo("\"3\"");

        MvcResult r = call(GET, url(g.get(0), eid) + "/revisions", ali, null);

        assertThat(status(r)).isEqualTo(200);
        JsonNode revs = body(r);
        assertThat(revs).hasSize(3);
        assertThat(revs.get(0).get("version").asInt()).isEqualTo(1);
        assertThat(revs.get(0).get("changeType").asText()).isEqualTo("CREATE");
        assertThat(revs.get(1).get("changeType").asText()).isEqualTo("UPDATE");
        assertThat(revs.get(2).get("changeType").asText()).isEqualTo("DELETE");
        for (JsonNode rev : revs) {
            assertThat(rev.get("changedByUserId").asText()).isEqualTo(ali.userId().toString());
            assertThat(rev.get("snapshot").get("id").asText()).isEqualTo(eid);
            assertThat(rev.get("snapshot").get("version").asInt()).isEqualTo(rev.get("version").asInt());
        }
        assertThat(revs.get(0).get("snapshot").get("charges").get("service").get("amountMinor").asLong())
                .isEqualTo(5280);                                                        // 12%: the old state survives
        assertThat(owed(revs.get(0).get("snapshot").get("shares"))).containsExactly(16599L, 16598L, 22982L);
        assertThat(revs.get(1).get("snapshot").get("charges").get("service").get("amountMinor").asLong())
                .isEqualTo(4400);                                                        // 10%
        assertThat(revs.get(2).get("snapshot").get("totalMinor").asLong()).isEqualTo(55176);
        for (int i = 1; i < 3; i++) {
            assertThat(java.time.Instant.parse(revs.get(i).get("changedAt").asText()))
                    .isAfterOrEqualTo(java.time.Instant.parse(revs.get(i - 1).get("changedAt").asText()));
        }
    }

    @Test
    void staleMissingAndMalformedIfMatchChangeNothing() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), bill(g, 1200, 56179)).get("id").asText();
        assertThat(status(put(ali, g.get(0), eid, 1, bill(g, 1000, 55176)))).isEqualTo(200);   // now at v2
        long rows = childRows(eid);

        MvcResult stale = put(ali, g.get(0), eid, 1, bill(g, 500, 1));
        assertThat(status(stale)).isEqualTo(409);
        assertThat(code(stale)).isEqualTo("VERSION_CONFLICT");
        MvcResult staleDelete = del(ali, g.get(0), eid, 1);
        assertThat(status(staleDelete)).isEqualTo(409);
        assertThat(code(staleDelete)).isEqualTo("VERSION_CONFLICT");
        MvcResult future = put(ali, g.get(0), eid, 9, bill(g, 500, 1));
        assertThat(status(future)).isEqualTo(409);

        MvcResult missing = call(PUT, url(g.get(0), eid), ali, bill(g, 500, 1));
        assertThat(status(missing)).isEqualTo(428);
        assertThat(status(call(DELETE, url(g.get(0), eid), ali, null))).isEqualTo(428);
        for (String bad : new String[] {"abc", "*", "\"1\", \"2\"", "\"-1\""}) {
            assertThat(status(call(PUT, url(g.get(0), eid), ali, bill(g, 500, 1), "If-Match", bad))).as(bad)
                    .isEqualTo(422);
        }

        assertThat(versionOf(eid)).isEqualTo(2);
        assertThat(revisionCount(eid)).isEqualTo(2);
        assertThat(childRows(eid)).isEqualTo(rows);
        assertThat(body(call(GET, url(g.get(0), eid), ali, null)).get("totalMinor").asLong()).isEqualTo(55176);
    }

    @Test
    void sixteenParallelEditsWithTheSameVersionHaveExactlyOneWinner() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), bill(g, 1200, 56179)).get("id").asText();
        ExecutorService pool = Executors.newFixedThreadPool(16);
        CountDownLatch go = new CountDownLatch(1);
        List<Integer> statuses = new ArrayList<>();
        try {
            List<Future<Integer>> results = new ArrayList<>();
            for (int i = 0; i < 16; i++) {
                int n = i;
                results.add(pool.submit(() -> {
                    Map<String, Object> body = equalBody("Edit " + n, 1000 + n, null, g.get(1), 1000L + n);
                    go.await();
                    return status(put(ali, g.get(0), eid, 1, body));
                }));
            }
            go.countDown();
            for (Future<Integer> f : results) {
                statuses.add(f.get());
            }
        } finally {
            pool.shutdownNow();
        }

        assertThat(statuses.stream().filter(s -> s == 200).count()).isEqualTo(1);
        assertThat(statuses.stream().filter(s -> s == 409).count()).isEqualTo(15);
        assertThat(versionOf(eid)).isEqualTo(2);
        assertThat(revisionCount(eid)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from expense_payers where expense_id = ?::uuid", Long.class, eid))
                .isEqualTo(1L);
        // the stored title, total and the UPDATE snapshot all come from the same single winner
        String title = jdbc.queryForObject("select title from expenses where id = ?::uuid", String.class, eid);
        Long total = jdbc.queryForObject("select total_minor from expenses where id = ?::uuid", Long.class, eid);
        assertThat(total).isEqualTo(1000L + Integer.parseInt(title.substring("Edit ".length())));
        assertThat(jdbc.queryForObject("select snapshot->>'title' from expense_revisions where expense_id = ?::uuid "
                + "and version = 2", String.class, eid)).isEqualTo(title);
    }

    @Test
    void parallelDeletesAndAnEditRacingADeleteLeaveOneConsistentHistory() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Race", 900, null, g.get(1), 900L)).get("id").asText();
        ExecutorService pool = Executors.newFixedThreadPool(9);
        CountDownLatch go = new CountDownLatch(1);
        List<Integer> deletes = new ArrayList<>();
        int editStatus;
        try {
            List<Future<Integer>> results = new ArrayList<>();
            for (int i = 0; i < 8; i++) {
                results.add(pool.submit(() -> {
                    go.await();
                    return status(del(ali, g.get(0), eid, 1));
                }));
            }
            Future<Integer> edit = pool.submit(() -> {
                go.await();
                return status(put(ali, g.get(0), eid, 1, equalBody("Raced", 901, null, g.get(1), 901L)));
            });
            go.countDown();
            for (Future<Integer> f : results) {
                deletes.add(f.get());
            }
            editStatus = edit.get();
        } finally {
            pool.shutdownNow();
        }

        long deleteWins = deletes.stream().filter(s -> s == 204).count();
        boolean editWon = editStatus == 200;
        assertThat(deleteWins + (editWon ? 1 : 0)).as("exactly one writer wins the version").isEqualTo(1);
        assertThat(deletes).allMatch(s -> s == 204 || s == 404 || s == 409);
        assertThat(editStatus).isIn(200, 404, 409);
        List<Integer> versions = jdbc.queryForList(
                "select version from expense_revisions where expense_id = ?::uuid order by version", Integer.class, eid);
        assertThat(versions).containsExactly(1, 2);                      // contiguous, no duplicates, one new revision
        assertThat(versionOf(eid)).isEqualTo(2);
    }

    // ---- delete ----------------------------------------------------------------------------------------------

    @Test
    void aDeletedExpenseDisappearsFromListsDetailAndTotalsButNotFromHistoryOrTheDeleteRules() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String keep = createExpense(ali, g.get(0), equalBody("Keep", 1000, null, g.get(1), 1000L)).get("id").asText();
        String gone = createExpense(ali, g.get(0), equalBody("Gone", 4000, null, g.get(2), 4000L)).get("id").asText();
        assertThat(body(call(GET, "/api/v1/groups/" + g.get(0), ali, null)).get("totalSpentMinor").asLong())
                .isEqualTo(5000);

        assertThat(status(del(ali, g.get(0), gone, 1))).isEqualTo(204);

        JsonNode page = body(call(GET, "/api/v1/groups/" + g.get(0) + "/expenses", ali, null));
        assertThat(page.get("items")).hasSize(1);
        assertThat(page.get("items").get(0).get("id").asText()).isEqualTo(keep);
        assertThat(status(call(GET, url(g.get(0), gone), ali, null))).isEqualTo(404);
        assertThat(body(call(GET, "/api/v1/groups/" + g.get(0), ali, null)).get("totalSpentMinor").asLong())
                .isEqualTo(1000);
        assertThat(status(call(GET, url(g.get(0), gone) + "/revisions", ali, null))).isEqualTo(200);
        assertThat(jdbc.queryForObject("select deleted_at is not null from expenses where id = ?::uuid", Boolean.class,
                gone)).isTrue();                                                       // soft delete: the row is still there
        // ledger rules still count the deleted expense (A30)
        assertThat(code(call(DELETE, "/api/v1/groups/" + g.get(0) + "/members/" + g.get(2), ali, null)))
                .isEqualTo("MEMBER_HAS_TRANSACTIONS");
        assertThat(code(call(DELETE, "/api/v1/groups/" + g.get(0), ali, null))).isEqualTo("GROUP_NOT_EMPTY");
    }

    @Test
    void deletingOrEditingADeletedExpenseIsA404() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Once", 1000, null, g.get(1), 1000L)).get("id").asText();
        assertThat(status(del(ali, g.get(0), eid, 1))).isEqualTo(204);

        for (MvcResult r : List.of(del(ali, g.get(0), eid, 1), del(ali, g.get(0), eid, 2),
                put(ali, g.get(0), eid, 2, equalBody("Again", 1000, null, g.get(1), 1000L)))) {
            assertThat(status(r)).isEqualTo(404);
            assertThat(code(r)).isEqualTo("NOT_FOUND");
        }
        assertThat(revisionCount(eid)).isEqualTo(2);
        assertThat(versionOf(eid)).isEqualTo(2);
    }

    // ---- authorization ---------------------------------------------------------------------------------------

    @Test
    void anotherUsersEditDeleteAndRevisionsAreTheSame404AsNothingAndChangeNothing() throws Exception {
        Session ali = newUser();
        Session bob = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Mine", 1000, null, g.get(1), 1000L)).get("id").asText();
        String ghost = UUID.randomUUID().toString();
        Map<String, Object> hijack = equalBody("Hijacked", 2000, null, g.get(1), 2000L);

        MvcResult p1 = put(bob, g.get(0), eid, 1, hijack);
        MvcResult p2 = put(bob, g.get(0), ghost, 1, hijack);
        assertThat(status(p1)).isEqualTo(404);
        assertThat(problemWithoutRequestId(p1)).isEqualTo(problemWithoutRequestId(p2));
        MvcResult d1 = del(bob, g.get(0), eid, 1);
        MvcResult d2 = del(bob, UUID.randomUUID().toString(), ghost, 1);
        assertThat(status(d1)).isEqualTo(404);
        assertThat(problemWithoutRequestId(d1)).isEqualTo(problemWithoutRequestId(d2));
        MvcResult v1 = call(GET, url(g.get(0), eid) + "/revisions", bob, null);
        MvcResult v2 = call(GET, url(UUID.randomUUID().toString(), ghost) + "/revisions", bob, null);
        assertThat(status(v1)).isEqualTo(404);
        assertThat(problemWithoutRequestId(v1)).isEqualTo(problemWithoutRequestId(v2));

        assertThat(status(call(PUT, url(g.get(0), eid), null, hijack, "If-Match", "\"1\""))).isEqualTo(401);
        assertThat(versionOf(eid)).isEqualTo(1);
        assertThat(revisionCount(eid)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select title from expenses where id = ?::uuid", String.class, eid))
                .isEqualTo("Mine");
    }

    @Test
    void anExpenseCannotBeEditedOrDeletedThroughAnotherGroupOfTheSameOwner() throws Exception {
        Session ali = newUser();
        List<String> g1 = abc(ali);
        List<String> g2 = abc(ali);
        String eid = createExpense(ali, g1.get(0), equalBody("G1", 1000, null, g1.get(1), 1000L)).get("id").asText();

        assertThat(status(put(ali, g2.get(0), eid, 1, equalBody("Moved", 1000, null, g2.get(1), 1000L))))
                .isEqualTo(404);
        assertThat(status(del(ali, g2.get(0), eid, 1))).isEqualTo(404);
        assertThat(status(call(GET, url(g2.get(0), eid) + "/revisions", ali, null))).isEqualTo(404);
        assertThat(jdbc.queryForObject("select group_id::text from expenses where id = ?::uuid", String.class, eid))
                .isEqualTo(g1.get(0));
    }

    // ---- validation parity ----------------------------------------------------------------------------------------

    @Test
    void editRejectsExactlyWhatCreateRejectsAndAFailedEditChangesNothing() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), bill(g, 1200, 56179)).get("id").asText();
        long rows = childRows(eid);

        Map<String, Object> badPayers = bill(g, 1200, 56178);
        Map<String, Object> noItems = bill(g, 1200, 56179);
        noItems.put("items", List.of());
        Map<String, Object> badBps = bill(g, 10001, 56179);
        Map<String, Object> stranger = equalBody("S", 100, null, UUID.randomUUID().toString(), 100L);
        Map<String, Object> blankTitle = equalBody(" ", 100, null, g.get(1), 100L);
        Map<String, Object> exactMismatch = exactBody("X", 100, List.of(g.get(1), 40L, g.get(2), 40L), g.get(1), 100L);

        for (Map<String, Object> bad : List.of(badPayers, noItems, badBps, stranger, blankTitle, exactMismatch)) {
            MvcResult asCreate = postExpense(ali, g.get(0), UUID.randomUUID().toString(), bad);
            MvcResult asEdit = put(ali, g.get(0), eid, 1, bad);
            assertThat(status(asEdit)).as(bad.toString()).isEqualTo(status(asCreate));
            assertThat(code(asEdit)).as(bad.toString()).isEqualTo(code(asCreate));
        }
        assertThat(versionOf(eid)).isEqualTo(1);
        assertThat(revisionCount(eid)).isEqualTo(1);
        assertThat(childRows(eid)).isEqualTo(rows);
        assertThat(jdbc.queryForObject("select total_minor from expenses where id = ?::uuid", Long.class, eid))
                .isEqualTo(56179L);
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void theSplitTypeCanChangeBetweenEditsAndTheSchemaConstraintsStillHold() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Flex", 1000, null, g.get(1), 1000L)).get("id").asText();

        JsonNode toItemized = body(put(ali, g.get(0), eid, 1, bill(g, 1200, 56179)));
        assertThat(toItemized.get("splitType").asText()).isEqualTo("ITEMIZED");
        assertThat(toItemized.get("items")).hasSize(3);
        assertThat(jdbc.queryForObject("select subtotal_minor from expenses where id = ?::uuid", Long.class, eid))
                .isEqualTo(44000L);

        JsonNode back = body(put(ali, g.get(0), eid, 2, equalBody("Flex", 900, null, g.get(1), 900L)));
        assertThat(back.get("splitType").asText()).isEqualTo("EQUAL");
        assertThat(back.get("items").isNull()).isTrue();
        assertThat(back.get("charges").isNull()).isTrue();
        assertThat(owed(back.get("shares"))).containsExactly(300L, 300L, 300L);
        assertThat(jdbc.queryForObject("select subtotal_minor is null and service_bps is null and tax_base is null "
                + "from expenses where id = ?::uuid", Boolean.class, eid)).isTrue();
        assertThat(jdbc.queryForObject("select count(*) from expense_items where expense_id = ?::uuid", Long.class, eid))
                .isZero();
        assertThat(revisionCount(eid)).isEqualTo(3);
    }

    // ---- schema ------------------------------------------------------------------------------------------------

    @Test
    void theDatabaseRejectsDuplicateVersionsAndUnknownChangeTypes() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Schema", 1000, null, g.get(1), 1000L)).get("id").asText();
        String insert = "insert into expense_revisions (id, expense_id, version, change_type, snapshot, "
                + "changed_by_user_id) values (?::uuid, ?::uuid, ?, ?, '{}'::jsonb, ?::uuid)";

        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID().toString(), eid, 1, "UPDATE",
                ali.userId().toString())).isInstanceOf(DataIntegrityViolationException.class);   // v1 exists
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID().toString(), eid, 2, "RENAME",
                ali.userId().toString())).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID().toString(), eid, 0, "UPDATE",
                ali.userId().toString())).isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update(insert, UUID.randomUUID().toString(), eid, 2, "UPDATE", ali.userId().toString()))
                .isEqualTo(1);                                                                    // control: valid row
    }
}
