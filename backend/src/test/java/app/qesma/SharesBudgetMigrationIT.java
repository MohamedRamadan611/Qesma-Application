package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.MemberRef;
import app.qesma.persistence.BalanceTotalsQuery;
import java.sql.Connection;
import java.sql.DriverManager;
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
 * V23 (BSA3) against pre-BSA3 data: every existing row stays valid and unchanged (all new columns NULL), balances are
 * identical before and after, and the new CHECKs hold (A185-A190, A196).
 */
class SharesBudgetMigrationIT extends AbstractIntegrationTest {

    @Test
    void existingRowsStayUnchangedBalancesAreIdenticalAndTheNewChecksHold() throws Exception {
        String name = "mig_" + UUID.randomUUID().toString().replace("-", "");
        try (Connection c = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             Statement s = c.createStatement()) {
            s.execute("create database " + name);
        }
        String url = "jdbc:postgresql://" + POSTGRES.getHost() + ":" + POSTGRES.getMappedPort(5432) + "/" + name;
        JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()));
        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword())
                .target(MigrationVersion.fromVersion("22")).load().migrate();

        UUID owner = UUID.randomUUID();
        jdbc.update("insert into users (id, auth_provider, auth_subject, email, display_name) values (?, 'GOOGLE', ?, ?, 'O')",
                owner, "sub-" + owner, owner + "@example.com");
        UUID group = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'G', 'TRIP', 2)", group, owner);
        UUID m = UUID.randomUUID();
        UUID a = UUID.randomUUID();
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order, role) values (?, ?, 'M', ?, 1, 'OWNER')", m, group, owner);
        jdbc.update("insert into members (id, group_id, display_name, sort_order, role) values (?, ?, 'A', 2, 'MEMBER')", a, group);

        // EQUAL 100.01 split 50.01 / 50.00 paid by M
        UUID equal = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                + "values (?, ?, 'eq', 'EQUAL', 10001, date '2026-10-18', ?)", equal, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 10001)", equal, m);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, 5001), (?, ?, 5000)",
                equal, m, equal, a);
        // EXACT 100.00 split 40.00 / 60.00 paid by A
        UUID exact = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                + "values (?, ?, 'ex', 'EXACT', 10000, date '2026-10-18', ?)", exact, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 10000)", exact, a);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, 4000), (?, ?, 6000)",
                exact, m, exact, a);
        // ITEMIZED 110.00 (one 100.00 item shared, 10% service) paid by M, as V22 stores it
        UUID itemized = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor, "
                + "service_bps, service_minor, tax_minor, adjustment_minor, discount_minor, delivery_minor, created_by_user_id) "
                + "values (?, ?, 'dinner', 'ITEMIZED', 11000, date '2026-10-18', 10000, 1000, 1000, 0, 0, 0, 0, ?)",
                itemized, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 11000)", itemized, m);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor, items_minor, discount_minor, service_minor, "
                + "tax_minor, adjustment_minor, delivery_minor) values (?, ?, 5500, 5000, 0, 500, 0, 0, 0), "
                + "(?, ?, 5500, 5000, 0, 500, 0, 0, 0)", itemized, m, itemized, a);
        // A confirmed settlement A -> M 20.00
        jdbc.update("insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, "
                + "created_by_user_id, status, declared_at, confirmed_at) values (?, ?, ?, ?, 2000, date '2026-10-19', ?, "
                + "'CONFIRMED', now(), now())",
                UUID.randomUUID(), group, a, m, owner);

        List<MemberRef> roster = List.of(new MemberRef(m.toString(), 1), new MemberRef(a.toString(), 2));
        Map<String, Long> before = nets(jdbc, group, roster);
        List<Map<String, Object>> expensesBefore = jdbc.queryForList("select * from expenses order by id");
        List<Map<String, Object>> splitsBefore = jdbc.queryForList("select * from expense_splits order by expense_id, member_id");

        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()).load().migrate();

        assertThat(nets(jdbc, group, roster)).as("balances before and after V23").isEqualTo(before);
        // Every old column keeps its value; every new column is NULL on every existing row.
        List<Map<String, Object>> expensesAfter = jdbc.queryForList("select * from expenses order by id");
        for (int i = 0; i < expensesBefore.size(); i++) {
            assertThat(expensesAfter.get(i)).containsAllEntriesOf(expensesBefore.get(i))
                    .containsEntry("period_from", null).containsEntry("period_to", null);
        }
        List<Map<String, Object>> splitsAfter = jdbc.queryForList("select * from expense_splits order by expense_id, member_id");
        for (int i = 0; i < splitsBefore.size(); i++) {
            assertThat(splitsAfter.get(i)).containsAllEntriesOf(splitsBefore.get(i)).containsEntry("share_units", null)
                    .containsEntry("present_from", null).containsEntry("present_to", null);
        }
        assertThat(jdbc.queryForList("select default_share_units from members where group_id = ?", Integer.class, group))
                .containsOnlyNulls();
        assertThat(jdbc.queryForMap("select budget_minor, trip_start_date, trip_end_date from expense_groups where id = ?", group))
                .containsEntry("budget_minor", null).containsEntry("trip_start_date", null).containsEntry("trip_end_date", null);

        // A SHARES expense with a period and its units/presence rows is accepted.
        UUID shares = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, period_from, period_to, "
                + "created_by_user_id) values (?, ?, 'rent', 'SHARES', 900000, date '2026-12-01', date '2026-11-01', "
                + "date '2026-11-30', ?)", shares, group, owner);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor, share_units, present_from, present_to) "
                + "values (?, ?, 600000, 2, date '2026-11-01', date '2026-11-30'), (?, ?, 300000, 1, date '2026-11-01', date '2026-11-30')",
                shares, m, shares, a);

        // The new CHECKs (data-modeling: the invariants live in the schema too).
        assertThatThrownBy(() -> jdbc.update("update expenses set split_type = 'PERCENT' where id = ?", equal))
                .as("unknown split type").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set period_from = date '2026-11-01', period_to = date '2026-11-30' "
                + "where id = ?", equal)).as("a period only on SHARES").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set period_to = null where id = ?", shares))
                .as("one period bound").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set period_to = date '2026-10-31' where id = ?", shares))
                .as("reversed period").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set period_from = date '2026-01-01', period_to = date '2027-01-02' "
                + "where id = ?", shares)).as("367 days").isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update expenses set period_from = date '2026-01-01', period_to = date '2027-01-01' "
                + "where id = ?", shares)).as("366 days").isEqualTo(1);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set share_units = 0 where expense_id = ?", shares))
                .as("units 0").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set share_units = 101 where expense_id = ?", shares))
                .as("units 101").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set present_to = null where expense_id = ?", shares))
                .as("one presence bound").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set present_to = date '2026-10-31' where expense_id = ?", shares))
                .as("reversed presence").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set present_from = date '2026-11-01', "
                + "present_to = date '2026-11-30' where expense_id = ?", exact)).as("presence without units")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set share_units = 1 where expense_id = ?", itemized))
                .as("units on an itemized breakdown row").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update members set default_share_units = 0 where id = ?", a))
                .as("default units 0").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update members set default_share_units = 101 where id = ?", a))
                .as("default units 101").isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update members set default_share_units = 100 where id = ?", a)).isEqualTo(1);
        assertThatThrownBy(() -> jdbc.update("update expense_groups set budget_minor = 0 where id = ?", group))
                .as("budget 0").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_groups set budget_minor = 1000000000001 where id = ?", group))
                .as("budget above the A43 cap").isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update expense_groups set budget_minor = 1000000000000 where id = ?", group)).isEqualTo(1);
        assertThatThrownBy(() -> jdbc.update("update expense_groups set trip_start_date = date '2026-11-05', "
                + "trip_end_date = date '2026-11-04' where id = ?", group)).as("trip end before start")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update expense_groups set trip_start_date = date '2026-11-05', trip_end_date = null "
                + "where id = ?", group)).as("each trip date is optional").isEqualTo(1);
    }

    private static Map<String, Long> nets(JdbcTemplate jdbc, UUID group, List<MemberRef> roster) {
        return BalanceCalculator.netsFromTotals(roster, new BalanceTotalsQuery(jdbc).totals(group));
    }
}
