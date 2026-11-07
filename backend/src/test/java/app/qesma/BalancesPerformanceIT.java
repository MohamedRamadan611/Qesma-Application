package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import app.qesma.persistence.BalanceTotalsQuery;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.EntityManagerFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Performance sanity for balances on the planned maximum (15 members, 500 expenses, 200 settlements): a stated time
 * bound, a statement-count bound, and the EXPLAIN output that docs/perf-notes.md is built from.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class BalancesPerformanceIT extends AbstractApiIT {

    /** Generous on purpose (a laptop running Docker); the measured time is about a millisecond or two. */
    private static final long BOUND_MILLIS = 2000;

    @Autowired EntityManagerFactory emf;

    private long p95Millis(Session as, org.springframework.http.HttpMethod method, String url, Object body) throws Exception {
        long[] samples = new long[25];
        for (int i = 0; i < samples.length; i++) {
            long started = System.nanoTime();
            MvcResult r = call(method, url, as, body);
            samples[i] = (System.nanoTime() - started) / 1_000_000;
            assertThat(status(r)).as(url).isEqualTo(200);
        }
        java.util.Arrays.sort(samples);
        return samples[(int) Math.ceil(samples.length * 0.95) - 1];
    }

    @Test
    void balancesForFifteenMembersFiveHundredExpensesAndTwoHundredSettlementsIsFastAndCheap() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Max " + UUID.randomUUID()).get("id").asText();
        List<String> members = new ArrayList<>();
        for (int i = 0; i < 15; i++) {
            members.add(addMember(ali, gid, "M" + i).get("id").asText());
        }
        String user = ali.userId().toString();
        // member (n mod 15) pays expense n; three consecutive members share it equally; plain SQL, no temp tables
        jdbc.update("""
                insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id)
                select gen_random_uuid(), ?::uuid, 'e' || g, 'EQUAL', 3000, date '2026-01-01' + (g % 300), ?::uuid
                from generate_series(1, 500) g""", gid, user);
        String numbered = "(select id, row_number() over (order by id) as n from expenses where group_id = '" + gid + "'::uuid)";
        jdbc.update("insert into expense_payers select e.id, m.id, 3000 from " + numbered + " e "
                + "join members m on m.group_id = '" + gid + "'::uuid and m.sort_order = 1 + (e.n % 15)");
        for (int k = 0; k < 3; k++) {
            jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) select e.id, m.id, 1000 from "
                    + numbered + " e join members m on m.group_id = '" + gid + "'::uuid "
                    + "and m.sort_order = 1 + ((e.n + " + k + ") % 15)");
        }
        jdbc.update("""
                insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on,
                                         created_by_user_id)
                select gen_random_uuid(), ?::uuid, f.id, t.id, 100 + g, date '2026-02-01' + (g % 200), ?::uuid
                from generate_series(1, 200) g
                join members f on f.group_id = ?::uuid and f.sort_order = 1 + (g % 15)
                join members t on t.group_id = ?::uuid and t.sort_order = 1 + ((g + 1 + g % 13) % 15)""",
                gid, user, gid, gid);
        assertThat(jdbc.queryForObject("select count(*) from expenses where group_id = ?::uuid", Long.class, gid))
                .isEqualTo(500L);
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Long.class, gid))
                .isEqualTo(200L);
        jdbc.execute("analyze expenses");
        jdbc.execute("analyze expense_payers");
        jdbc.execute("analyze expense_splits");
        jdbc.execute("analyze settlements");

        // warm up, then measure
        for (int i = 0; i < 3; i++) {
            assertThat(status(call(GET, "/api/v1/groups/" + gid + "/balances", ali, null))).isEqualTo(200);
        }
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        long started = System.nanoTime();
        MvcResult r = call(GET, "/api/v1/groups/" + gid + "/balances", ali, null);
        long millis = (System.nanoTime() - started) / 1_000_000;
        long jpaStatements = stats.getPrepareStatementCount();

        assertThat(status(r)).isEqualTo(200);
        JsonNode b = body(r);
        assertThat(b.get("nets")).hasSize(15);
        assertThat(b.get("nets").findValues("netMinor").stream().mapToLong(JsonNode::asLong).sum()).isZero();
        assertThat(millis).as("balances on the maximum dataset, ms (bound %d)", BOUND_MILLIS).isLessThan(BOUND_MILLIS);
        assertThat(jpaStatements).as("JPA statements: group + members (the totals are one JDBC statement)")
                .isLessThanOrEqualTo(3);
        System.out.println("PERF balances(15 members, 500 expenses, 200 settlements) = " + millis + " ms, JPA statements = "
                + jpaStatements);

        // p95 proxy (spec 11: p95 under ~500 ms): 25 calls of each typical request on the maximum dataset
        String eid = body(call(GET, "/api/v1/groups/" + gid + "/expenses?size=1", ali, null)).get("items").get(0).get("id").asText();
        Map<String, String> typical = new LinkedHashMap<>();
        typical.put("group detail", "/api/v1/groups/" + gid);
        typical.put("group list", "/api/v1/groups");
        typical.put("expense list", "/api/v1/groups/" + gid + "/expenses?size=20");
        typical.put("expense detail", "/api/v1/groups/" + gid + "/expenses/" + eid);
        typical.put("revisions", "/api/v1/groups/" + gid + "/expenses/" + eid + "/revisions");
        typical.put("settlements", "/api/v1/groups/" + gid + "/settlements?size=20");
        typical.put("balances", "/api/v1/groups/" + gid + "/balances");
        StringBuilder timings = new StringBuilder();
        for (Map.Entry<String, String> t : typical.entrySet()) {
            long p95 = p95Millis(ali, GET, t.getValue(), null);
            timings.append(t.getKey()).append(" p95=").append(p95).append(" ms; ");
            assertThat(p95).as("p95 of " + t.getKey() + " (spec 11 target 500 ms)").isLessThan(500);
        }
        long previewP95 = p95Millis(ali, org.springframework.http.HttpMethod.POST, "/api/v1/groups/" + gid + "/expenses/preview",
                equalBody("T", 900, null, members.get(0), 900L));
        timings.append("preview p95=").append(previewP95).append(" ms");
        assertThat(previewP95).as("p95 of preview").isLessThan(500);
        System.out.println("PERF p95 on the maximum dataset: " + timings);

        Map<String, String> queries = new LinkedHashMap<>();
        queries.put("balances (the single grouped statement)", BalanceTotalsQuery.SQL.replace("?", "'" + gid + "'::uuid"));
        queries.put("settlements page", "select * from settlements where group_id = '" + gid + "'::uuid "
                + "and deleted_at is null order by settled_on desc, created_at desc, id desc limit 20");
        queries.put("settlements count", "select count(*) from settlements where group_id = '" + gid
                + "'::uuid and deleted_at is null");
        queries.put("members of a group", "select * from members where group_id = '" + gid + "'::uuid order by sort_order");
        queries.put("group summaries (list of groups)", "select g.id, g.name, (select count(*) from members m where m.group_id = g.id), "
                + "(select coalesce(sum(x.total_minor), 0) from expenses x where x.group_id = g.id and x.deleted_at is null), "
                + "(select max(x.created_at) from expenses x where x.group_id = g.id and x.deleted_at is null) "
                + "from expense_groups g where g.owner_user_id = '" + user + "'::uuid order by g.created_at desc, g.id desc limit 20");
        queries.put("revisions of an expense", "select version, change_type, snapshot::text from expense_revisions "
                + "where expense_id = '" + eid + "'::uuid order by version");
        queries.put("member-in-settlement check", "select 1 from settlements where from_member_id = '" + members.get(3)
                + "'::uuid or to_member_id = '" + members.get(3) + "'::uuid limit 1");
        StringBuilder out = new StringBuilder("# EXPLAIN (ANALYZE, BUFFERS): 15 members, 500 expenses, 200 settlements\n");
        out.append("\nbalances request: ").append(millis).append(" ms, JPA statements: ").append(jpaStatements).append("\n");
        for (Map.Entry<String, String> q : queries.entrySet()) {
            out.append("\n## ").append(q.getKey()).append("\n");
            for (String line : jdbc.queryForList("explain (analyze, buffers) " + q.getValue(), String.class)) {
                out.append(line).append("\n");
            }
        }
        Files.writeString(Path.of("target", "perf-balances-explain.txt"), out.toString());
        System.out.println(out);
    }
}
