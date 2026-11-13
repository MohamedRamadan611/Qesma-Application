package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.MemberRef;
import app.qesma.persistence.BalanceTotalsQuery;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

/**
 * V15 against a database that already holds Phase 1 data (B13, A86): the data is inserted at schema version 14 and the
 * migration then runs on it. Balances must be identical before and after, live payments become CONFIRMED +
 * recorded_by_admin, Phase 1 soft-deleted ones become CANCELLED (kept, not dropped), and the CHECKs tie the status to
 * its timestamps.
 */
class SettlementStatusMigrationIT extends AbstractIntegrationTest {

    /** The balance statement exactly as Phase 1 ran it (settlements counted while deleted_at is null). */
    private static final String PHASE1_SQL = """
            select member_id, sum(paid)::bigint, sum(owed)::bigint, sum(sent)::bigint, sum(received)::bigint
            from (
              select p.member_id, p.amount_minor as paid, 0::bigint as owed, 0::bigint as sent, 0::bigint as received
              from expense_payers p join expenses e on e.id = p.expense_id where e.group_id = ? and e.deleted_at is null
              union all
              select s.member_id, 0, s.owed_minor, 0, 0
              from expense_splits s join expenses e on e.id = s.expense_id where e.group_id = ? and e.deleted_at is null
              union all
              select t.from_member_id, 0, 0, t.amount_minor, 0 from settlements t where t.group_id = ? and t.deleted_at is null
              union all
              select t.to_member_id, 0, 0, 0, t.amount_minor from settlements t where t.group_id = ? and t.deleted_at is null
            ) ledger group by member_id""";

    private record Db(String url, JdbcTemplate jdbc) {
        Flyway flyway(String target) {
            return Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword())
                    .target(target == null ? MigrationVersion.LATEST : MigrationVersion.fromVersion(target)).load();
        }
    }

    private Db newDatabase() throws SQLException {
        String name = "mig_" + UUID.randomUUID().toString().replace("-", "");
        try (Connection c = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             Statement s = c.createStatement()) {
            s.execute("create database " + name);
        }
        String url = "jdbc:postgresql://" + POSTGRES.getHost() + ":" + POSTGRES.getMappedPort(5432) + "/" + name;
        return new Db(url, new JdbcTemplate(new DriverManagerDataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword())));
    }

    private static UUID user(JdbcTemplate jdbc, String name) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into users (id, auth_provider, auth_subject, email, display_name) values (?, 'GOOGLE', ?, ?, ?)",
                id, "sub-" + id, id + "@example.com", name);
        return id;
    }

    private static UUID member(JdbcTemplate jdbc, UUID group, String name, UUID userId, String role, int sort) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order, role) values (?, ?, ?, ?, ?, ?)",
                id, group, name, userId, sort, role);
        return id;
    }

    private static UUID settlement(JdbcTemplate jdbc, UUID group, UUID from, UUID to, long amount, UUID creator,
                                   boolean deleted) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, "
                + "created_by_user_id, deleted_at) values (?, ?, ?, ?, ?, date '2026-10-20', ?, case when ? then now() end)",
                id, group, from, to, amount, creator, deleted);
        return id;
    }

    private static Map<String, Long> nets(JdbcTemplate jdbc, UUID group, List<MemberRef> roster, boolean phase1Sql) {
        List<BalanceCalculator.MemberTotals> totals = phase1Sql
                ? jdbc.query(PHASE1_SQL, (rs, i) -> new BalanceCalculator.MemberTotals(rs.getObject(1, UUID.class).toString(),
                        rs.getLong(2), rs.getLong(3), rs.getLong(4), rs.getLong(5)), group, group, group, group)
                : new BalanceTotalsQuery(jdbc).totals(group);
        return BalanceCalculator.netsFromTotals(roster, totals);
    }

    @Test
    void phase1BalancesAreIdenticalAfterTheBackfillAndDeletedPaymentsBecomeCancelled() throws Exception {
        Db db = newDatabase();
        db.flyway("14").migrate();
        JdbcTemplate jdbc = db.jdbc();
        UUID owner = user(jdbc, "Owner");
        UUID asem = user(jdbc, "Asem");
        UUID group = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'Dahab', 'TRIP', 3)",
                group, owner);
        UUID m = member(jdbc, group, "M", owner, "OWNER", 1);
        UUID a = member(jdbc, group, "A", asem, "MEMBER", 2);
        UUID s = member(jdbc, group, "S", null, "MEMBER", 3);
        List<MemberRef> roster = List.of(new MemberRef(m.toString(), 1), new MemberRef(a.toString(), 2), new MemberRef(s.toString(), 3));

        // V1: E1 paid by M 100.00 (A 50.00, S 50.00); E2 paid by S 30.00 (A 30.00)
        UUID e1 = UUID.randomUUID();
        UUID e2 = UUID.randomUUID();
        for (Object[] e : new Object[][] {{e1, 10000L}, {e2, 3000L}}) {
            jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                    + "values (?, ?, 'e', 'EXACT', ?, date '2026-10-18', ?)", e[0], group, e[1], owner);
        }
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 10000), (?, ?, 3000)", e1, m, e2, s);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, 5000), (?, ?, 5000), (?, ?, 3000)",
                e1, a, e1, s, e2, a);

        Map<String, Long> v1 = nets(jdbc, group, roster, true);
        assertThat(v1).containsExactly(Map.entry(m.toString(), 10000L), Map.entry(a.toString(), -8000L), Map.entry(s.toString(), -2000L));

        UUID live = settlement(jdbc, group, a, m, 8000, asem, false);            // V2: A paid M 80.00
        UUID deleted = settlement(jdbc, group, s, m, 999, owner, true);           // a Phase 1 soft-deleted payment
        UUID noCreator = settlement(jdbc, group, s, m, 500, owner, false);        // created by the owner (linked)
        Map<String, Long> v2Before = nets(jdbc, group, roster, true);
        assertThat(v2Before).containsExactly(Map.entry(m.toString(), 1500L), Map.entry(a.toString(), 0L), Map.entry(s.toString(), -1500L));

        db.flyway(null).migrate();

        assertThat(nets(jdbc, group, roster, false)).as("balances before and after V15 are identical").isEqualTo(v2Before);
        assertThat(nets(jdbc, group, roster, true)).as("the Phase 1 statement still agrees").isEqualTo(v2Before);

        Map<String, Object> liveRow = jdbc.queryForMap("select status, recorded_by_admin, confirmed_at = created_at as same, "
                + "declared_at = created_at as declared, cancelled_at, created_by_member_id from settlements where id = ?", live);
        assertThat(liveRow.get("status")).isEqualTo("CONFIRMED");
        assertThat(liveRow.get("recorded_by_admin")).isEqualTo(true);
        assertThat(liveRow.get("same")).isEqualTo(true);
        assertThat(liveRow.get("declared")).isEqualTo(true);
        assertThat(liveRow.get("cancelled_at")).isNull();
        assertThat(liveRow.get("created_by_member_id")).isEqualTo(a);             // taken from the linked creator
        assertThat(jdbc.queryForObject("select status from settlements where id = ?", String.class, deleted))
                .as("a soft-deleted Phase 1 row is kept as CANCELLED").isEqualTo("CANCELLED");
        assertThat(jdbc.queryForObject("select cancelled_at = deleted_at from settlements where id = ?", Boolean.class, deleted)).isTrue();
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?", Long.class, group)).isEqualTo(3L);
        assertThat(jdbc.queryForObject("select created_by_member_id from settlements where id = ?", UUID.class, noCreator))
                .isEqualTo(m);
    }

    @Test
    void theChecksTieTheStatusToItsTimestampsAndNoRowCanSkipTheStatus() throws Exception {
        Db db = newDatabase();
        db.flyway(null).migrate();
        JdbcTemplate jdbc = db.jdbc();
        UUID owner = user(jdbc, "Owner");
        UUID group = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'G', 'TRIP', 2)", group, owner);
        UUID m = member(jdbc, group, "M", owner, "OWNER", 1);
        UUID a = member(jdbc, group, "A", null, "MEMBER", 2);
        String insert = "insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, "
                + "created_by_user_id, status, declared_at, confirmed_at, disputed_at, cancelled_at, deleted_at) "
                + "values (?, ?, ?, ?, 100, date '2026-10-20', ?, ?, now(), %s, %s, %s, %s)";
        UUID ok = UUID.randomUUID();

        assertThat(jdbc.update(insert.formatted("null", "null", "null", "null"), ok, group, a, m, owner, "PENDING")).isEqualTo(1);
        assertThat(jdbc.update(insert.formatted("now()", "null", "null", "null"), UUID.randomUUID(), group, a, m, owner, "CONFIRMED")).isEqualTo(1);
        assertThat(jdbc.update(insert.formatted("null", "now()", "null", "null"), UUID.randomUUID(), group, a, m, owner, "DISPUTED")).isEqualTo(1);
        assertThat(jdbc.update(insert.formatted("null", "null", "now()", "now()"), UUID.randomUUID(), group, a, m, owner, "CANCELLED")).isEqualTo(1);

        String[][] bad = {
                {"PENDING", "now()", "null", "null", "null"},       // pending but already confirmed
                {"PENDING", "null", "now()", "null", "null"},       // pending but disputed
                {"CONFIRMED", "null", "null", "null", "null"},      // confirmed without a timestamp
                {"DISPUTED", "null", "null", "null", "null"},       // disputed without a timestamp
                {"CANCELLED", "null", "null", "null", "null"},      // cancelled without a timestamp
                {"CONFIRMED", "now()", "null", "now()", "null"},    // confirmed and cancelled
                {"CONFIRMED", "now()", "null", "null", "now()"},    // legacy deleted_at only on CANCELLED rows
                {"DONE", "null", "null", "null", "null"}};          // unknown status
        for (String[] b : bad) {
            assertThatThrownBy(() -> jdbc.update(insert.formatted(b[1], b[2], b[3], b[4]), UUID.randomUUID(), group, a, m,
                    owner, b[0])).as(String.join(",", b)).isInstanceOf(DataIntegrityViolationException.class);
        }
        assertThatThrownBy(() -> jdbc.update("update settlements set status = 'CONFIRMED' where id = ?", ok))
                .as("a status change must set its timestamp in the same statement").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, "
                + "settled_on, created_by_user_id) values (?, ?, ?, ?, 100, date '2026-10-20', ?)", UUID.randomUUID(), group, a, m,
                owner)).as("status is NOT NULL").isInstanceOf(DataIntegrityViolationException.class);
    }
}
