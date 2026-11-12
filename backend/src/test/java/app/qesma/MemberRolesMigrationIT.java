package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.FlywayException;
import org.flywaydb.core.api.MigrationVersion;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

/**
 * V12 against a database that already holds Phase 1 data (B10): the data is inserted at schema version 11 and the
 * migration then runs on it. Each test uses its own empty database inside the shared container.
 */
class MemberRolesMigrationIT extends AbstractIntegrationTest {

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

    private static UUID group(JdbcTemplate jdbc, UUID owner, String name) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, member_seq) values (?, ?, ?, 'TRIP', 2)",
                id, owner, name);
        return id;
    }

    private static void member(JdbcTemplate jdbc, UUID group, String name, UUID userId, int sort) {
        jdbc.update("insert into members (id, group_id, display_name, user_id, sort_order) values (?, ?, ?, ?, ?)",
                UUID.randomUUID(), group, name, userId, sort);
    }

    @Test
    void phase1DataGetsOwnerAndMemberRolesAndNothingElseChanges() throws Exception {
        Db db = newDatabase();
        db.flyway("11").migrate();
        UUID owner = user(db.jdbc(), "Owner");
        UUID other = user(db.jdbc(), "Other");
        UUID g1 = group(db.jdbc(), owner, "G1");
        member(db.jdbc(), g1, "Owner", owner, 1);
        member(db.jdbc(), g1, "Ghost", null, 2);
        UUID g2 = group(db.jdbc(), other, "G2");
        member(db.jdbc(), g2, "Other", other, 1);

        db.flyway(null).migrate();

        assertThat(db.jdbc().queryForObject("select role from members where group_id = ? and user_id = ?", String.class, g1, owner))
                .isEqualTo("OWNER");
        assertThat(db.jdbc().queryForObject("select role from members where group_id = ? and user_id is null", String.class, g1))
                .isEqualTo("MEMBER");
        assertThat(db.jdbc().queryForObject("select role from members where group_id = ? and user_id = ?", String.class, g2, other))
                .isEqualTo("OWNER");
        assertThat(db.jdbc().queryForObject("select count(*) from members where status = 'ACTIVE' and left_at is null "
                + "and joined_at = created_at", Long.class)).isEqualTo(3L);
        assertThat(db.jdbc().queryForObject("select count(*) from members", Long.class)).isEqualTo(3L);
        assertThat(db.jdbc().queryForObject("select count(*) from pg_indexes where indexname in "
                + "('ux_members_group_owner', 'ix_members_user_active')", Long.class)).isEqualTo(2L);
    }

    @Test
    void aGroupWithoutAMemberLinkedToItsOwnerAbortsTheMigrationAndChangesNothing() throws Exception {
        Db db = newDatabase();
        db.flyway("11").migrate();
        UUID owner = user(db.jdbc(), "Legacy");
        UUID legacy = group(db.jdbc(), owner, "Created before B9");
        member(db.jdbc(), legacy, "Ghost only", null, 1);

        assertThatThrownBy(() -> db.flyway(null).migrate()).isInstanceOf(FlywayException.class)
                .hasMessageContaining("V12 aborted");

        assertThat(db.jdbc().queryForObject("select version from flyway_schema_history where success "
                + "order by installed_rank desc limit 1", String.class)).isEqualTo("11");
        assertThat(db.jdbc().queryForObject("select count(*) from information_schema.columns "
                + "where table_name = 'members' and column_name = 'role'", Long.class)).isZero();
    }
}
