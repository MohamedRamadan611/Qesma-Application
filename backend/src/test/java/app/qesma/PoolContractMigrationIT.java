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

/** V20 against Phase 2 data (BSA1): old rows get OTHER / false / PAYMENT, balances are identical, the CHECKs hold. */
class PoolContractMigrationIT extends AbstractIntegrationTest {

    @Test
    void oldRowsGetDefaultsAndBalancesAreIdentical() throws Exception {
        String name = "mig_" + UUID.randomUUID().toString().replace("-", "");
        try (Connection c = DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             Statement s = c.createStatement()) {
            s.execute("create database " + name);
        }
        String url = "jdbc:postgresql://" + POSTGRES.getHost() + ":" + POSTGRES.getMappedPort(5432) + "/" + name;
        JdbcTemplate jdbc = new JdbcTemplate(new DriverManagerDataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()));
        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword())
                .target(MigrationVersion.fromVersion("19")).load().migrate();

        UUID owner = UUID.randomUUID();
        jdbc.update("insert into users (id, auth_provider, auth_subject, email, display_name) values (?, 'GOOGLE', ?, ?, 'O')",
                owner, "sub-" + owner, owner + "@example.com");
        UUID group = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'G', 'TRIP', 2)", group, owner);
        UUID m = UUID.randomUUID();
        UUID a = UUID.randomUUID();
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order, role) values (?, ?, 'M', ?, 1, 'OWNER')", m, group, owner);
        jdbc.update("insert into members (id, group_id, display_name, sort_order, role) values (?, ?, 'A', 2, 'MEMBER')", a, group);
        UUID e = UUID.randomUUID();
        jdbc.update("insert into expenses (id, group_id, title, split_type, total_minor, expense_date, created_by_user_id) "
                + "values (?, ?, 'e', 'EXACT', 10000, date '2026-10-18', ?)", e, group, owner);
        jdbc.update("insert into expense_payers (expense_id, member_id, amount_minor) values (?, ?, 10000)", e, m);
        jdbc.update("insert into expense_splits (expense_id, member_id, owed_minor) values (?, ?, 4000), (?, ?, 6000)", e, m, e, a);
        UUID st = UUID.randomUUID();
        jdbc.update("insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on, "
                + "created_by_user_id, status, declared_at, confirmed_at, recorded_by_admin) "
                + "values (?, ?, ?, ?, 2000, date '2026-10-20', ?, 'CONFIRMED', now(), now(), true)", st, group, a, m, owner);

        List<MemberRef> roster = List.of(new MemberRef(m.toString(), 1), new MemberRef(a.toString(), 2));
        Map<String, Long> before = nets(jdbc, group, roster);

        Flyway.configure().dataSource(url, POSTGRES.getUsername(), POSTGRES.getPassword()).load().migrate();

        assertThat(nets(jdbc, group, roster)).as("balances before and after V20").isEqualTo(before);
        assertThat(jdbc.queryForObject("select category from expenses where id = ?", String.class, e)).isEqualTo("OTHER");
        assertThat(jdbc.queryForObject("select paid_from_pool from expenses where id = ?", Boolean.class, e)).isFalse();
        assertThat(jdbc.queryForObject("select kind from settlements where id = ?", String.class, st)).isEqualTo("PAYMENT");
        assertThat(jdbc.queryForObject("select treasurer_member_id from expense_groups where id = ?", UUID.class, group)).isNull();

        assertThatThrownBy(() -> jdbc.update("update expenses set category = 'PIZZA' where id = ?", e))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update settlements set kind = 'GIFT' where id = ?", st))
                .isInstanceOf(DataIntegrityViolationException.class);
        UUID foreign = UUID.randomUUID();
        UUID otherGroup = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, 'H', 'TRIP', 1)", otherGroup, owner);
        jdbc.update("insert into members (id, group_id, display_name, sort_order, role) values (?, ?, 'X', 1, 'MEMBER')", foreign, otherGroup);
        assertThatThrownBy(() -> jdbc.update("update expense_groups set treasurer_member_id = ? where id = ?", foreign, group))
                .as("the treasurer must belong to the same group").isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update("update expense_groups set treasurer_member_id = ? where id = ?", a, group)).isEqualTo(1);
    }

    private static Map<String, Long> nets(JdbcTemplate jdbc, UUID group, List<MemberRef> roster) {
        return BalanceCalculator.netsFromTotals(roster, new BalanceTotalsQuery(jdbc).totals(group));
    }
}
