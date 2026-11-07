package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Payer;
import com.fasterxml.jackson.databind.JsonNode;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * CP2 (B4-B6) ledger checks on real PostgreSQL: the money invariant across a random sequence of creates, edits and
 * deletes (nets computed with the engine's BalanceCalculator must sum to zero), idempotency, concurrency and
 * ownership exercised together, and EXPLAIN plans of the hot queries on seeded data.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class Cp2LedgerInvariantIT extends AbstractApiIT {

    private static final long SEED = 20261107L;

    // ---- random ledger ------------------------------------------------------------------------------------

    /** What the test believes is live: expense id -> current version. */
    private final Map<String, Integer> live = new LinkedHashMap<>();
    private final Map<String, Integer> versions = new HashMap<>();      // every expense ever created
    private final Map<String, Boolean> deleted = new HashMap<>();

    private static List<Long> split(long total, int parts, Random rnd, boolean allowZero) {
        List<Long> cuts = new ArrayList<>();
        for (int i = 0; i < parts - 1; i++) {
            cuts.add(allowZero ? (long) (rnd.nextDouble() * (total + 1)) : 1 + (long) (rnd.nextDouble() * (total - 1)));
        }
        Collections.sort(cuts);
        List<Long> out = new ArrayList<>();
        long prev = 0;
        for (long c : cuts) {
            out.add(c - prev);
            prev = c;
        }
        out.add(total - prev);
        return out;
    }

    private static List<String> subset(List<String> ids, Random rnd, int min) {
        List<String> copy = new ArrayList<>(ids);
        Collections.shuffle(copy, rnd);
        return copy.subList(0, min + rnd.nextInt(ids.size() - min + 1));
    }

    private static Object[] payers(List<String> ids, long total, Random rnd) {
        int k = (int) Math.min(total, 1 + rnd.nextInt(3));
        List<String> who = subset(ids, rnd, 1);
        who = who.subList(0, Math.min(k, who.size()));
        List<Long> amounts = split(total, who.size(), rnd, false);
        Object[] out = new Object[who.size() * 2];
        for (int i = 0; i < who.size(); i++) {
            out[2 * i] = who.get(i);
            out[2 * i + 1] = amounts.get(i);
        }
        return out;
    }

    private Map<String, Object> randomBody(Session as, String gid, List<String> ids, Random rnd) throws Exception {
        int kind = rnd.nextInt(3);
        String title = "t" + rnd.nextInt(100000);
        if (kind == 0) {
            long total = 1 + rnd.nextInt(200000);
            Map<String, Object> b = equalBody(title, total, rnd.nextBoolean() ? null : subset(ids, rnd, 1),
                    payers(ids, total, rnd));
            return b;
        }
        if (kind == 1) {
            long total = 1 + rnd.nextInt(200000);
            List<String> who = subset(ids, rnd, 1);
            List<Long> amounts = split(total, who.size(), rnd, true);
            if (amounts.stream().allMatch(a -> a == 0)) {
                amounts.set(0, total);
            }
            List<Object> shares = new ArrayList<>();
            for (int i = 0; i < who.size(); i++) {
                shares.add(who.get(i));
                shares.add(amounts.get(i));
            }
            return exactBody(title, total, shares, payers(ids, total, rnd));
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("title", title);
        body.put("expenseDate", "2026-10-" + String.format("%02d", 1 + rnd.nextInt(28)));
        body.put("splitType", "ITEMIZED");
        List<Map<String, Object>> items = new ArrayList<>();
        for (int i = 0, n = 1 + rnd.nextInt(4); i < n; i++) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("name", "i" + i);
            item.put("amountMinor", 1L + rnd.nextInt(50000));
            item.put("assigneeMemberIds", subset(ids, rnd, 1));
            items.add(item);
        }
        body.put("items", items);
        if (rnd.nextBoolean()) {
            body.put("service", Map.of("bps", rnd.nextInt(3001)));
        }
        if (rnd.nextBoolean()) {
            body.put("tax", Map.of("bps", rnd.nextInt(2001),
                    "base", rnd.nextBoolean() ? "SUBTOTAL" : "SUBTOTAL_PLUS_SERVICE"));
        }
        if (rnd.nextInt(4) == 0) {
            body.put("adjustmentMinor", (long) (rnd.nextInt(101) - 50));
        }
        // payers are only known once the engine has computed the total: ask preview (no payers yet)
        MvcResult p = call(POST, "/api/v1/groups/" + gid + "/expenses/preview", as, body);
        if (status(p) != 200) {
            return null;                                           // the engine legitimately rejected this bill
        }
        long total = body(p).get("totalMinor").asLong();
        Object[] pay = payers(ids, total, rnd);
        List<Map<String, Object>> list = new ArrayList<>();
        for (int i = 0; i < pay.length; i += 2) {
            list.add(Map.of("memberId", pay[i], "amountMinor", pay[i + 1]));
        }
        body.put("payers", list);
        return body;
    }

    private void assertLedgerIsConsistent(Session as, String gid, List<String> ids) throws Exception {
        JsonNode page = body(call(GET, "/api/v1/groups/" + gid + "/expenses?size=100", as, null));
        assertThat(page.get("items")).as("live expenses").hasSize(live.size());
        List<MemberRef> roster = new ArrayList<>();
        for (int i = 0; i < ids.size(); i++) {
            roster.add(new MemberRef(ids.get(i), i + 1));
        }
        List<BalanceCalculator.ExpenseLedgerEntry> ledger = new ArrayList<>();
        long spent = 0;
        for (JsonNode e : page.get("items")) {
            long total = e.get("totalMinor").asLong();
            long paid = 0;
            List<Payer> payers = new ArrayList<>();
            for (JsonNode p : e.get("payers")) {
                paid += p.get("amountMinor").asLong();
                payers.add(new Payer(p.get("memberId").asText(), p.get("amountMinor").asLong()));
            }
            long owed = 0;
            Map<String, Long> owedBy = new LinkedHashMap<>();
            for (JsonNode s : e.get("shares")) {
                owed += s.get("owedMinor").asLong();
                owedBy.put(s.get("memberId").asText(), s.get("owedMinor").asLong());
                if (!s.get("itemsMinor").isNull()) {
                    assertThat(s.get("itemsMinor").asLong() + s.get("serviceMinor").asLong()
                            + s.get("taxMinor").asLong() + s.get("adjustmentMinor").asLong())
                            .as("breakdown explains owed").isEqualTo(s.get("owedMinor").asLong());
                }
            }
            assertThat(paid).as("sum(payers) == total").isEqualTo(total);
            assertThat(owed).as("sum(owed) == total").isEqualTo(total);
            assertThat(live).containsKey(e.get("id").asText());
            assertThat(e.get("version").asInt()).isEqualTo(live.get(e.get("id").asText()));
            ledger.add(new BalanceCalculator.ExpenseLedgerEntry(payers, owedBy));
            spent += total;
        }
        Map<String, Long> nets = BalanceCalculator.nets(roster, ledger, List.of());
        assertThat(nets.values().stream().mapToLong(Long::longValue).sum()).as("sum(net) == 0").isZero();
        assertThat(body(call(GET, "/api/v1/groups/" + gid, as, null)).get("totalSpentMinor").asLong())
                .as("group total = sum of live expenses").isEqualTo(spent);
    }

    @Test
    void netsSumToZeroAfterARandomSequenceOfCreatesEditsAndDeletes() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Random " + UUID.randomUUID()).get("id").asText();
        List<String> ids = new ArrayList<>();
        for (String n : List.of("A", "B", "C", "D", "E")) {
            ids.add(member(ali, gid, n).get("id").asText());
        }
        Random rnd = new Random(SEED);
        String base = "/api/v1/groups/" + gid + "/expenses";
        int created = 0;
        int edited = 0;
        int removed = 0;
        int rejected = 0;

        for (int step = 0; step < 200; step++) {
            String context = "seed=" + SEED + " step=" + step;
            int dice = rnd.nextInt(100);
            if (dice < 40 || live.isEmpty()) {
                Map<String, Object> body = randomBody(ali, gid, ids, rnd);
                if (body == null) {
                    rejected++;
                    continue;
                }
                MvcResult r = postExpense(ali, gid, UUID.randomUUID().toString(), body);
                assertThat(status(r)).as(context + " " + r.getResponse().getContentAsString()).isEqualTo(201);
                String eid = body(r).get("id").asText();
                live.put(eid, 1);
                versions.put(eid, 1);
                deleted.put(eid, false);
                created++;
            } else if (dice < 70) {
                String eid = new ArrayList<>(live.keySet()).get(rnd.nextInt(live.size()));
                Map<String, Object> body = randomBody(ali, gid, ids, rnd);
                if (body == null) {
                    rejected++;
                    continue;
                }
                MvcResult r = call(PUT, base + "/" + eid, ali, body, "If-Match", "\"" + live.get(eid) + "\"");
                assertThat(status(r)).as(context + " " + r.getResponse().getContentAsString()).isEqualTo(200);
                live.put(eid, live.get(eid) + 1);
                versions.put(eid, live.get(eid));
                edited++;
            } else if (dice < 85) {
                String eid = new ArrayList<>(live.keySet()).get(rnd.nextInt(live.size()));
                MvcResult r = call(DELETE, base + "/" + eid, ali, null, "If-Match", "\"" + live.get(eid) + "\"");
                assertThat(status(r)).as(context).isEqualTo(204);
                versions.put(eid, live.get(eid) + 1);
                deleted.put(eid, true);
                live.remove(eid);
                removed++;
            } else {
                // a corrupt request must be refused and must not change anything
                int before = countExpenses(gid);
                Map<String, Object> bad = equalBody("bad", 1000, null, ids.get(0), 999L);
                MvcResult r = postExpense(ali, gid, UUID.randomUUID().toString(), bad);
                assertThat(status(r)).as(context).isEqualTo(422);
                assertThat(countExpenses(gid)).as(context).isEqualTo(before);
            }
            assertLedgerIsConsistent(ali, gid, ids);
        }
        System.out.println("CP2 random ledger: created=" + created + " edited=" + edited + " deleted=" + removed
                + " engine-rejected=" + rejected + " live=" + live.size());
        assertThat(created).isGreaterThan(40);
        assertThat(edited).isGreaterThan(20);
        assertThat(removed).isGreaterThan(10);

        // history: one revision per version, contiguous, CREATE first, DELETE last only for deleted expenses
        for (Map.Entry<String, Integer> e : versions.entrySet()) {
            List<Map<String, Object>> rows = jdbc.queryForList(
                    "select version, change_type from expense_revisions where expense_id = ?::uuid order by version",
                    e.getKey());
            assertThat(rows).as("revisions of " + e.getKey()).hasSize(e.getValue());
            for (int i = 0; i < rows.size(); i++) {
                assertThat(rows.get(i).get("version")).isEqualTo(i + 1);
            }
            assertThat(rows.get(0).get("change_type")).isEqualTo("CREATE");
            if (deleted.get(e.getKey())) {
                assertThat(rows.get(rows.size() - 1).get("change_type")).isEqualTo("DELETE");
            }
            assertThat(jdbc.queryForObject("select version from expenses where id = ?::uuid", Integer.class, e.getKey()))
                    .isEqualTo(e.getValue());
        }
        // the same invariants straight from the tables
        assertThat(jdbc.queryForObject("""
                select count(*) from expenses e where e.group_id = ?::uuid and e.deleted_at is null and (
                  e.total_minor <> (select coalesce(sum(p.amount_minor), 0) from expense_payers p where p.expense_id = e.id)
                  or e.total_minor <> (select coalesce(sum(s.owed_minor), 0) from expense_splits s where s.expense_id = e.id))""",
                Long.class, gid)).isZero();
        Long paidTotal = jdbc.queryForObject("""
                select coalesce(sum(p.amount_minor), 0) from expense_payers p join expenses e on e.id = p.expense_id
                where e.group_id = ?::uuid and e.deleted_at is null""", Long.class, gid);
        Long owedTotal = jdbc.queryForObject("""
                select coalesce(sum(s.owed_minor), 0) from expense_splits s join expenses e on e.id = s.expense_id
                where e.group_id = ?::uuid and e.deleted_at is null""", Long.class, gid);
        assertThat(paidTotal).as("sum(net) == sum(paid) - sum(owed) == 0 in SQL").isEqualTo(owedTotal);
    }

    // ---- idempotency + concurrency + ownership together ---------------------------------------------------

    private <T> List<T> runTogether(List<java.util.concurrent.Callable<T>> jobs) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(Math.max(1, jobs.size()));
        CountDownLatch go = new CountDownLatch(1);
        try {
            List<Future<T>> futures = new ArrayList<>();
            for (java.util.concurrent.Callable<T> job : jobs) {
                futures.add(pool.submit(() -> {
                    go.await();
                    return job.call();
                }));
            }
            go.countDown();
            List<T> out = new ArrayList<>();
            for (Future<T> f : futures) {
                out.add(f.get());
            }
            return out;
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void aStrangerRacingTheOwnerWithTheSameKeyNeverInterfersAndLeavesNoKeyBehind() throws Exception {
        Session owner = newUser();
        Session stranger = newUser();
        String gid = createGroup(owner, "Owned").get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String strangerGroup = createGroup(stranger, "Theirs").get("id").asText();
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Shared key", 1000, null, a, 1000L);

        List<java.util.concurrent.Callable<int[]>> jobs = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            jobs.add(() -> new int[] {1, status(postExpense(owner, gid, key, body))});
            jobs.add(() -> new int[] {2, status(postExpense(stranger, gid, key, body))});          // owner's group
            jobs.add(() -> new int[] {3, status(postExpense(stranger, strangerGroup, key, body))}); // wrong member -> 422
        }
        List<int[]> results = runTogether(jobs);

        assertThat(results).filteredOn(r -> r[0] == 1).allMatch(r -> r[1] == 201);
        assertThat(results).filteredOn(r -> r[0] == 2).allMatch(r -> r[1] == 404);
        assertThat(results).filteredOn(r -> r[0] == 3).allMatch(r -> r[1] == 422);                  // A is not their member
        assertThat(countExpenses(gid)).isEqualTo(1);
        assertThat(countExpenses(strangerGroup)).isZero();
        assertThat(jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?", Long.class,
                stranger.userId(), key)).as("a refused request stores no key").isZero();
        MvcResult replay = postExpense(owner, gid, key, body);
        assertThat(status(replay)).isEqualTo(201);
        assertThat(replay.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
    }

    @Test
    void parallelSameKeyCreatesWhileAStrangerProbesTheNewExpenseOnEveryVerb() throws Exception {
        Session owner = newUser();
        Session stranger = newUser();
        String gid = createGroup(owner, "Probed").get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Probe me", 1000, null, a, 1000L);
        String first = body(postExpenseOk(owner, gid, UUID.randomUUID().toString(), body)).get("id").asText();
        String base = "/api/v1/groups/" + gid + "/expenses/" + first;

        List<java.util.concurrent.Callable<int[]>> jobs = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            jobs.add(() -> new int[] {1, status(postExpense(owner, gid, key, body))});
            jobs.add(() -> new int[] {2, status(call(PUT, base, stranger, body, "If-Match", "\"1\""))});
            jobs.add(() -> new int[] {3, status(call(DELETE, base, stranger, null, "If-Match", "\"1\""))});
            jobs.add(() -> new int[] {4, status(call(GET, base, stranger, null))});
            jobs.add(() -> new int[] {5, status(call(GET, base + "/revisions", stranger, null))});
        }
        List<int[]> results = runTogether(jobs);

        assertThat(results).filteredOn(r -> r[0] == 1).allMatch(r -> r[1] == 201);
        assertThat(results).filteredOn(r -> r[0] >= 2).allMatch(r -> r[1] == 404);
        assertThat(countExpenses(gid)).as("the first expense plus exactly one for the shared key").isEqualTo(2);
        assertThat(jdbc.queryForObject("select version from expenses where id = ?::uuid", Integer.class, first)).isEqualTo(1);
        assertThat(jdbc.queryForObject("select deleted_at is null from expenses where id = ?::uuid", Boolean.class, first))
                .isTrue();
    }

    private MvcResult postExpenseOk(Session as, String gid, String key, Object body) throws Exception {
        MvcResult r = postExpense(as, gid, key, body);
        assertThat(status(r)).isEqualTo(201);
        return r;
    }

    @Test
    void editsRacingADeleteAndAStrangerLeaveExactlyOneWriterAndAContiguousHistory() throws Exception {
        Session owner = newUser();
        Session stranger = newUser();
        String gid = createGroup(owner, "Race").get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String eid = body(postExpenseOk(owner, gid, UUID.randomUUID().toString(),
                equalBody("Base", 1000, null, a, 1000L))).get("id").asText();
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;

        List<java.util.concurrent.Callable<int[]>> jobs = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            Object edit = equalBody("Edit " + i, 2000 + i, null, a, 2000L + i);
            jobs.add(() -> new int[] {1, status(call(PUT, url, owner, edit, "If-Match", "\"1\""))});
        }
        for (int i = 0; i < 2; i++) {
            jobs.add(() -> new int[] {2, status(call(DELETE, url, owner, null, "If-Match", "\"1\""))});
        }
        for (int i = 0; i < 4; i++) {
            jobs.add(() -> new int[] {3, status(call(PUT, url, stranger, equalBody("Evil", 1, null, a, 1L),
                    "If-Match", "\"1\""))});
            jobs.add(() -> new int[] {3, status(call(DELETE, url, stranger, null, "If-Match", "\"1\""))});
        }
        List<int[]> results = runTogether(jobs);

        long owners = results.stream().filter(r -> r[0] <= 2 && (r[1] == 200 || r[1] == 204)).count();
        assertThat(owners).as("exactly one owner write wins").isEqualTo(1);
        assertThat(results).filteredOn(r -> r[0] == 3).allMatch(r -> r[1] == 404);
        assertThat(results).filteredOn(r -> r[0] <= 2).allMatch(r -> r[1] == 200 || r[1] == 204 || r[1] == 409 || r[1] == 404);
        assertThat(jdbc.queryForList("select version from expense_revisions where expense_id = ?::uuid order by version",
                Integer.class, eid)).containsExactly(1, 2);
        assertThat(jdbc.queryForObject("select title from expenses where id = ?::uuid", String.class, eid))
                .isNotEqualTo("Evil");
    }

    @Test
    void replayingTheOriginalCreateAfterAnEditAndADeleteServesTheStoredAnswerAndCreatesNothing() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Replay").get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Original", 1000, null, a, 1000L);
        JsonNode created = body(postExpenseOk(owner, gid, key, body));
        String eid = created.get("id").asText();
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;
        assertThat(status(call(PUT, url, owner, equalBody("Edited", 2000, null, a, 2000L), "If-Match", "\"1\""))).isEqualTo(200);
        assertThat(status(call(DELETE, url, owner, null, "If-Match", "\"2\""))).isEqualTo(204);

        MvcResult replay = postExpense(owner, gid, key, body);

        assertThat(status(replay)).isEqualTo(201);
        assertThat(replay.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(replay).get("title").asText()).isEqualTo("Original");      // A26: the stored answer, as at creation
        assertThat(body(replay).get("version").asInt()).isEqualTo(1);
        assertThat(countExpenses(gid)).as("no second expense, the deleted one stays deleted").isEqualTo(1);
        assertThat(status(call(GET, url, owner, null))).isEqualTo(404);
    }

    // ---- EXPLAIN of the hot queries ----------------------------------------------------------------------------

    @Test
    void explainTheHotQueriesOnAThreeThousandExpenseGroup() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Big " + UUID.randomUUID()).get("id").asText();
        String m1 = member(ali, gid, "A").get("id").asText();
        String m2 = member(ali, gid, "B").get("id").asText();
        String user = ali.userId().toString();
        jdbc.update("""
                insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id,
                                      created_at, updated_at)
                select gen_random_uuid(), ?::uuid, 't' || g, 'EQUAL', 1000, date '2026-01-01' + (g % 300), ?::uuid,
                       now() - (g || ' minutes')::interval, now()
                from generate_series(1, 3000) g""", gid, user);
        jdbc.update("insert into expense_payers select id, ?::uuid, 1000 from expenses where group_id = ?::uuid", m1, gid);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) select id, ?::uuid, 500 "
                + "from expenses where group_id = ?::uuid", m1, gid);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) select id, ?::uuid, 500 "
                + "from expenses where group_id = ?::uuid", m2, gid);
        jdbc.execute("analyze expenses");
        jdbc.execute("analyze expense_payers");
        jdbc.execute("analyze expense_splits");
        String ids = String.join(",", jdbc.queryForList("select id::text from expenses where group_id = ?::uuid "
                + "order by expense_date desc, created_at desc, id desc limit 20", String.class, gid).stream()
                .map(s -> "'" + s + "'::uuid").toList());

        Map<String, String> queries = new LinkedHashMap<>();
        queries.put("list page (no filters)", "select * from expenses where group_id = '" + gid + "'::uuid "
                + "and deleted_at is null and expense_date >= date '1900-01-01' and expense_date <= date '2200-01-01' "
                + "order by expense_date desc, created_at desc, id desc limit 20");
        queries.put("list page (date range)", "select * from expenses where group_id = '" + gid + "'::uuid "
                + "and deleted_at is null and expense_date >= date '2026-03-01' and expense_date <= date '2026-04-01' "
                + "order by expense_date desc, created_at desc, id desc limit 20");
        queries.put("list count", "select count(*) from expenses where group_id = '" + gid + "'::uuid "
                + "and deleted_at is null and expense_date >= date '1900-01-01' and expense_date <= date '2200-01-01'");
        queries.put("list page filtered by member", "select * from expenses e where e.group_id = '" + gid + "'::uuid "
                + "and e.deleted_at is null and (exists (select 1 from expense_payers p where p.expense_id = e.id "
                + "and p.member_id = '" + m2 + "'::uuid) or exists (select 1 from expense_splits s "
                + "where s.expense_id = e.id and s.member_id = '" + m2 + "'::uuid)) "
                + "order by e.expense_date desc, e.created_at desc, e.id desc limit 20");
        queries.put("group totals", "select coalesce(sum(total_minor), 0), max(created_at) from expenses "
                + "where group_id = '" + gid + "'::uuid and deleted_at is null");
        queries.put("splits of a page", "select * from expense_splits where expense_id in (" + ids + ")");
        queries.put("payers of a page", "select * from expense_payers where expense_id in (" + ids + ")");
        queries.put("member-in-use check", "select 1 from expense_payers where member_id = '" + m2 + "'::uuid limit 1");

        StringBuilder out = new StringBuilder("# EXPLAIN (ANALYZE, BUFFERS) on 3000 expenses in one group\n");
        for (Map.Entry<String, String> q : queries.entrySet()) {
            out.append("\n## ").append(q.getKey()).append("\n");
            for (String line : jdbc.queryForList("explain (analyze, buffers) " + q.getValue(), String.class)) {
                out.append(line).append("\n");
            }
        }
        Path file = Path.of("target", "cp2-explain.txt");
        Files.writeString(file, out.toString());
        System.out.println(out);
        assertThat(out.toString()).contains("list page (no filters)");
    }
}
