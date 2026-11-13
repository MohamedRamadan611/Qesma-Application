package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.persistence.GroupEventStore;
import app.qesma.persistence.NotificationStore;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * B15: the three hot queries use their index. With a few thousand rows and sequential scans switched off for the
 * transaction (the usual way to prove an index is usable on a small test table), EXPLAIN must name the index.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ActivityQueryPlanIT extends AbstractActivityIT {

    @Autowired DataSource dataSource;

    private String explain(String sql, Object... params) throws Exception {
        try (Connection con = dataSource.getConnection()) {
            con.setAutoCommit(false);
            try {
                try (var st = con.createStatement()) {
                    st.execute("set local enable_seqscan = off");
                }
                List<String> lines = new ArrayList<>();
                try (PreparedStatement ps = con.prepareStatement("explain " + sql)) {
                    for (int i = 0; i < params.length; i++) {
                        ps.setObject(i + 1, params[i]);
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            lines.add(rs.getString(1));
                        }
                    }
                }
                return String.join("\n", lines);
            } finally {
                con.rollback();
            }
        }
    }

    /** 2000 events of one group for the reader, and as much again in other groups for other users (the usual shape). */
    private void seed(Session reader, String gid, Session other, String otherGid) {
        for (String[] target : new String[][] {{gid, reader.userId().toString()}, {otherGid, other.userId().toString()}}) {
            jdbc.update("insert into group_events (id, group_id, type, payload, created_at) "
                    + "select gen_random_uuid(), ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, now() - (g || ' seconds')::interval "
                    + "from generate_series(1, 2000) g", target[0]);
            jdbc.update("insert into notifications (id, user_id, event_id, created_at, read_at) "
                    + "select gen_random_uuid(), ?::uuid, id, created_at, case when random() < 0.9 then created_at end "
                    + "from group_events where group_id = ?::uuid", target[1], target[0]);
        }
        for (int i = 0; i < 20; i++) {                   // many more groups with a few events each
            String noise = jdbc.queryForObject("select id::text from expense_groups limit 1 offset ?", String.class, i);
            jdbc.update("insert into group_events (id, group_id, type, payload, created_at) "
                    + "select gen_random_uuid(), ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, now() - (g || ' minutes')::interval "
                    + "from generate_series(1, 300) g", noise);
        }
        jdbc.execute("analyze group_events");
        jdbc.execute("analyze notifications");
    }

    @Test
    void feedCenterAndUnreadCountUseTheirIndexes() throws Exception {
        Session owner = newUser();
        Session other = newUser();
        String gid = createGroup(owner, "Plans " + UUID.randomUUID()).get("id").asText();
        String otherGid = createGroup(other, "Plans other " + UUID.randomUUID()).get("id").asText();
        for (int i = 0; i < 20; i++) {
            createGroup(newUser(), "Noise " + i);
        }
        seed(owner, gid, other, otherGid);

        String feed = explain(GroupEventStore.FEED_SQL, UUID.fromString(gid), "infinity", GroupEventStore.NO_CURSOR_ID, 21);
        assertThat(feed).contains("ix_group_events_feed");

        String center = explain(NotificationStore.CENTER_SQL, owner.userId(), "infinity", GroupEventStore.NO_CURSOR_ID, 21);
        assertThat(center).contains("ix_notifications_user");

        String unread = explain(NotificationStore.UNREAD_COUNT_SQL, owner.userId());
        assertThat(unread).contains("ix_notifications_unread");

        String purge = explain("delete from group_events where id in (select id from group_events "
                + "where created_at < now() - interval '180 days' order by created_at limit 5000)");
        assertThat(purge).contains("ix_group_events_created");
    }
}
