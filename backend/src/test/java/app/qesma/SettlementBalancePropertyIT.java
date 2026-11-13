package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Payer;
import app.qesma.persistence.BalanceTotalsQuery;
import app.qesma.persistence.PendingPairsQuery;
import app.qesma.persistence.YourNetQuery;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.constraints.LongRange;
import org.flywaydb.core.Flyway;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

/**
 * B13 / A83 as a property over real PostgreSQL: for random expenses and random settlements in random statuses,
 * (1) the nets always sum to zero, (2) the nets equal what the row-by-row engine computes from the CONFIRMED rows
 * alone, (3) adding PENDING / DISPUTED / CANCELLED rows never changes a net or the caller's {@code yourNet}, and
 * (4) {@code pendingMinor} / {@code hasDispute} per exact pair are the sum of PENDING rows and the presence of a
 * DISPUTED row. The scenario derives from one seed, so a failure is reproducible.
 */
class SettlementBalancePropertyIT extends AbstractIntegrationTest {

    private static final String[] STATUSES = {"PENDING", "CONFIRMED", "DISPUTED", "CANCELLED"};

    private static JdbcTemplate jdbc;

    private static synchronized JdbcTemplate jdbc() throws SQLException {
        if (jdbc == null) {
            String name = "prop_" + UUID.randomUUID().toString().replace("-", "");
            try (Connection c = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(),
                    POSTGRES.getPassword()); Statement s = c.createStatement()) {
                s.execute("create database " + name);
            }
            String url = "jdbc:postgresql://" + POSTGRES.getHost() + ":" + POSTGRES.getMappedPort(5432) + "/" + name;
            Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()).load().migrate();
            jdbc = new JdbcTemplate(new DriverManagerDataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()));
        }
        return jdbc;
    }

    private record Settle(UUID from, UUID to, long amount, String status) {
    }

    @Property(tries = 40)
    void netsCountConfirmedOnlyAndTheOpenOnesAreInformationOnly(@ForAll @LongRange(min = 0, max = Long.MAX_VALUE) long seed)
            throws Exception {
        JdbcTemplate db = jdbc();
        Random rnd = new Random(seed);
        UUID user = UUID.randomUUID();
        db.update("insert into users (id, auth_provider, auth_subject, email, display_name) values (?, 'GOOGLE', ?, ?, 'P')",
                user, "sub-" + user, user + "@example.com");
        UUID gid = UUID.randomUUID();
        int n = 2 + rnd.nextInt(5);
        db.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, ?, 'TRIP', ?)",
                gid, user, "G" + gid, n);
        List<UUID> ids = new ArrayList<>();
        List<MemberRef> roster = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            UUID m = UUID.randomUUID();
            ids.add(m);
            roster.add(new MemberRef(m.toString(), i + 1));
            db.update("insert into members (id, group_id, display_name, user_id, sort_order) values (?, ?, ?, ?, ?)",
                    m, gid, "m" + i, i == 0 ? user : null, i + 1);
        }

        List<ExpenseLedgerEntry> expenses = new ArrayList<>();
        for (int e = rnd.nextInt(6); e > 0; e--) {
            expenses.add(insertExpense(db, rnd, gid, user, ids));
        }
        List<SettlementEntry> confirmed = new ArrayList<>();
        List<Settle> all = new ArrayList<>();
        for (int s = rnd.nextInt(6); s > 0; s--) {
            Settle st = randomSettlement(rnd, ids, "CONFIRMED");
            insertSettlement(db, gid, user, st);
            confirmed.add(new SettlementEntry(st.from().toString(), st.to().toString(), st.amount()));
        }

        Map<String, Long> before = netsFromDb(db, gid, roster);
        assertThat(before).as("seed " + seed + ": confirmed-only oracle")
                .isEqualTo(BalanceCalculator.nets(roster, expenses, confirmed));

        for (int s = rnd.nextInt(10); s > 0; s--) {                         // informational rows, any non-confirmed status
            Settle st = randomSettlement(rnd, ids, STATUSES[rnd.nextInt(4)]);
            if (st.status().equals("CONFIRMED")) {
                st = new Settle(st.from(), st.to(), st.amount(), "PENDING");
            }
            insertSettlement(db, gid, user, st);
            all.add(st);
        }

        Map<String, Long> after = netsFromDb(db, gid, roster);
        assertThat(after).as("seed " + seed + ": open and cancelled rows never move a net").isEqualTo(before);
        assertThat(after.values().stream().mapToLong(Long::longValue).sum()).as("seed " + seed + ": zero sum").isZero();

        YourNetQuery.YourTotals mine = new YourNetQuery(db).forGroups(user, List.of(gid)).get(gid);
        assertThat(BalanceCalculator.memberNet(mine.totals())).as("seed " + seed + ": yourNet")
                .isEqualTo(after.get(ids.get(0).toString()));

        Map<String, long[]> expected = new HashMap<>();                     // pair -> [pendingSum, disputed 0/1, rows]
        for (Settle st : all) {
            if (st.status().equals("PENDING") || st.status().equals("DISPUTED")) {
                long[] cell = expected.computeIfAbsent(st.from() + ">" + st.to(), k -> new long[3]);
                cell[0] += st.status().equals("PENDING") ? st.amount() : 0;
                cell[1] |= st.status().equals("DISPUTED") ? 1 : 0;
                cell[2]++;
            }
        }
        Map<String, long[]> actual = new HashMap<>();
        for (PendingPairsQuery.Pair p : new PendingPairsQuery(db).pairs(gid)) {
            actual.put(p.fromMemberId() + ">" + p.toMemberId(),
                    new long[] {p.pendingMinor(), p.hasDispute() ? 1 : 0, p.ids().size()});
        }
        assertThat(actual.keySet()).as("seed " + seed + ": pairs").isEqualTo(expected.keySet());
        expected.forEach((pair, cell) -> assertThat(actual.get(pair)).as("seed " + seed + " " + pair).containsExactly(cell));
    }

    private static Map<String, Long> netsFromDb(JdbcTemplate db, UUID gid, List<MemberRef> roster) {
        return BalanceCalculator.netsFromTotals(roster, new BalanceTotalsQuery(db).totals(gid));
    }

    private static Settle randomSettlement(Random rnd, List<UUID> ids, String status) {
        int from = rnd.nextInt(ids.size());
        int to = (from + 1 + rnd.nextInt(ids.size() - 1)) % ids.size();
        return new Settle(ids.get(from), ids.get(to), 1 + rnd.nextInt(10_000_000), status);
    }

    private static void insertSettlement(JdbcTemplate db, UUID gid, UUID user, Settle s) {
        db.update("""
                insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on,
                    created_by_user_id, status, declared_at, confirmed_at, disputed_at, cancelled_at)
                values (?, ?, ?, ?, ?, date '2026-10-20', ?, ?, now(),
                    case when ? = 'CONFIRMED' then now() end,
                    case when ? = 'DISPUTED' then now() end,
                    case when ? = 'CANCELLED' then now() end)""",
                UUID.randomUUID(), gid, s.from(), s.to(), s.amount(), user, s.status(), s.status(), s.status(), s.status());
    }

    /** An EXACT expense: one or two payers, one to three owers, both adding up to the same total. */
    private static ExpenseLedgerEntry insertExpense(JdbcTemplate db, Random rnd, UUID gid, UUID user, List<UUID> ids) {
        long total = 1 + rnd.nextInt(10_000_000);
        UUID eid = UUID.randomUUID();
        db.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                + "values (?, ?, 'e', 'EXACT', ?, date '2026-10-18', ?)", eid, gid, total, user);
        List<Payer> payers = new ArrayList<>();
        Map<String, Long> owed = new LinkedHashMap<>();
        for (Map.Entry<UUID, Long> p : split(rnd, ids, total, 1 + rnd.nextInt(2), true).entrySet()) {
            db.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, ?)", eid, p.getKey(),
                    p.getValue());
            payers.add(new Payer(p.getKey().toString(), p.getValue()));
        }
        for (Map.Entry<UUID, Long> o : split(rnd, ids, total, 1 + rnd.nextInt(3), false).entrySet()) {
            db.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, ?)", eid, o.getKey(),
                    o.getValue());
            owed.put(o.getKey().toString(), o.getValue());
        }
        return new ExpenseLedgerEntry(payers, owed);
    }

    /** {@code parts} distinct members share {@code total}; every part is at least 1 when {@code positive}. */
    private static Map<UUID, Long> split(Random rnd, List<UUID> ids, long total, int parts, boolean positive) {
        int k = Math.min(parts, ids.size());
        if (positive) {
            k = (int) Math.min(k, total);
        }
        List<UUID> pool = new ArrayList<>(ids);
        java.util.Collections.shuffle(pool, rnd);
        Map<UUID, Long> out = new LinkedHashMap<>();
        long left = total;
        for (int i = 0; i < k; i++) {
            long part = i == k - 1 ? left : (positive ? 1 + rnd.nextLong(left - (k - i - 1)) : rnd.nextLong(left + 1));
            out.put(pool.get(i), part);
            left -= part;
        }
        return out;
    }
}
