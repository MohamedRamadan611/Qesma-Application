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
 * V21 (BSA2) against pre-BSA2 data: items read back as quantity 1 with unit = amount, itemized expenses and their
 * breakdown rows get discount 0, EQUAL/EXACT rows stay untouched, balances are identical, and the new CHECKs hold.
 */
class ItemizedV2MigrationIT extends AbstractIntegrationTest {

    @Test
    void existingRowsReadBackAsQuantityOneWithoutDiscountAndBalancesAreIdentical() throws Exception {
        String name = "mig_" + UUID.randomUUID().toString().replace("-", "");
        try (Connection c = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             Statement s = c.createStatement()) {
            s.execute("create database " + name);
        }
        String url = "jdbc:postgresql://" + POSTGRES.getHost() + ":" + POSTGRES.getMappedPort(5432) + "/" + name;
        JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()));
        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword())
                .target(MigrationVersion.fromVersion("20")).load().migrate();

        UUID owner = UUID.randomUUID();
        jdbc.update("insert into users (id, auth_provider, auth_subject, email, display_name) values (?, 'GOOGLE', ?, ?, 'O')",
                owner, "sub-" + owner, owner + "@example.com");
        UUID group = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'G', 'TRIP', 2)", group, owner);
        UUID m = UUID.randomUUID();
        UUID a = UUID.randomUUID();
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order, role) values (?, ?, 'M', ?, 1, 'OWNER')", m, group, owner);
        jdbc.update("insert into members (id, group_id, display_name, sort_order, role) values (?, ?, 'A', 2, 'MEMBER')", a, group);

        // An ITEMIZED bill as B5 stored it: one 100.00 item shared by M and A, service 10%.
        UUID itemized = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, subtotal_minor, "
                + "service_bps, service_minor, tax_minor, adjustment_minor, created_by_user_id) "
                + "values (?, ?, 'dinner', 'ITEMIZED', 11000, date '2026-10-18', 10000, 1000, 1000, 0, 0, ?)",
                itemized, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 11000)", itemized, m);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor, items_minor, service_minor, tax_minor, "
                + "adjustment_minor) values (?, ?, 5500, 5000, 500, 0, 0), (?, ?, 5500, 5000, 500, 0, 0)",
                itemized, m, itemized, a);
        UUID item = UUID.randomUUID();
        jdbc.update("insert into expense_items (id, expense_id, name, amount_minor, sort_order) values (?, ?, 'Meal', 10000, 0)",
                item, itemized);
        // And an EXACT expense, which must keep NULL itemized columns.
        UUID exact = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                + "values (?, ?, 'e', 'EXACT', 10000, date '2026-10-18', ?)", exact, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 10000)", exact, a);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, 4000), (?, ?, 6000)",
                exact, m, exact, a);

        List<MemberRef> roster = List.of(new MemberRef(m.toString(), 1), new MemberRef(a.toString(), 2));
        Map<String, Long> before = nets(jdbc, group, roster);

        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()).load().migrate();

        assertThat(nets(jdbc, group, roster)).as("balances before and after V21").isEqualTo(before);
        assertThat(jdbc.queryForMap("select quantity, unit_amount_minor, amount_minor from expense_items where id = ?", item))
                .containsEntry("quantity", 1).containsEntry("unit_amount_minor", 10000L).containsEntry("amount_minor", 10000L);
        assertThat(jdbc.queryForMap("select discount_minor, discount_bps, discount_amount_minor, service_amount_minor, "
                + "tax_amount_minor from expenses where id = ?", itemized))
                .containsEntry("discount_minor", 0L).containsEntry("discount_bps", null)
                .containsEntry("discount_amount_minor", null).containsEntry("service_amount_minor", null)
                .containsEntry("tax_amount_minor", null);
        assertThat(jdbc.queryForList("select discount_minor from expense_splits where expense_id = ?", Long.class, itemized))
                .containsExactly(0L, 0L);
        // V22 (A180): ITEMIZED rows get delivery 0, EQUAL/EXACT rows stay NULL, balances do not move
        assertThat(jdbc.queryForObject("select delivery_minor from expenses where id = ?", Long.class, itemized)).isZero();
        assertThat(jdbc.queryForList("select delivery_minor from expense_splits where expense_id = ?", Long.class, itemized))
                .containsExactly(0L, 0L);
        assertThat(jdbc.queryForObject("select delivery_minor from expenses where id = ?", Long.class, exact)).isNull();
        assertThat(jdbc.queryForList("select delivery_minor from expense_splits where expense_id = ?", Long.class, exact))
                .containsOnlyNulls();
        assertThat(jdbc.queryForObject("select discount_minor from expenses where id = ?", Long.class, exact)).isNull();
        assertThat(jdbc.queryForList("select discount_minor from expense_splits where expense_id = ?", Long.class, exact))
                .containsOnlyNulls();

        // The new CHECKs (data-modeling: the invariants live in the schema too).
        assertThatThrownBy(() -> jdbc.update("update expense_items set quantity = 1000 where id = ?", item))
                .as("quantity above 999").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_items set quantity = 2 where id = ?", item))
                .as("amount must equal quantity x unit").isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update expense_items set quantity = 2, unit_amount_minor = 5000 where id = ?", item))
                .isEqualTo(1);
        assertThatThrownBy(() -> jdbc.update("update expenses set service_amount_minor = 1000 where id = ?", itemized))
                .as("service in both forms").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set discount_minor = null where id = ?", itemized))
                .as("an ITEMIZED expense carries its discount total").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expenses set discount_minor = 0 where id = ?", exact))
                .as("itemized columns on an EXACT expense").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update expense_splits set discount_minor = 1 where expense_id = ?", itemized))
                .as("the breakdown must still explain owed").isInstanceOf(DataIntegrityViolationException.class);
    }

    private static Map<String, Long> nets(JdbcTemplate jdbc, UUID group, List<MemberRef> roster) {
        return BalanceCalculator.netsFromTotals(roster, new BalanceTotalsQuery(jdbc).totals(group));
    }
}
