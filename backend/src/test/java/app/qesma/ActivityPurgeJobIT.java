package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.service.ActivityPurgeJob;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/** B15 / A103: events older than the retention (180 days) go, with their notifications; newer ones stay. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ActivityPurgeJobIT extends AbstractActivityIT {

    @Autowired ActivityPurgeJob job;

    private UUID event(String gid, int daysAgo) {
        UUID id = UUID.randomUUID();
        jdbc.update("insert into group_events (id, group_id, type, payload, created_at) "
                + "values (?, ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, now() - make_interval(days => ?))", id, gid, daysAgo);
        return id;
    }

    private void notify(UUID eventId, UUID userId) {
        jdbc.update("insert into notifications (id, user_id, event_id, created_at) "
                + "select gen_random_uuid(), ?, id, created_at from group_events where id = ?", userId, eventId);
    }

    @Test
    void oldEventsAndTheirNotificationsAreRemovedAndRecentOnesAreKept() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Purge " + UUID.randomUUID()).get("id").asText();
        UUID old1 = event(gid, 200);
        UUID old2 = event(gid, 181);
        UUID recent = event(gid, 179);
        UUID fresh = event(gid, 0);
        notify(old1, owner.userId());
        notify(recent, owner.userId());

        int deleted = job.runOnce();

        assertThat(deleted).isGreaterThanOrEqualTo(2);       // other tests in the shared database may add rows
        assertThat(jdbc.queryForList("select id from group_events where group_id = ?::uuid", UUID.class, gid))
                .containsExactlyInAnyOrder(recent, fresh).doesNotContain(old1, old2);
        assertThat(jdbc.queryForObject("select count(*) from notifications where event_id = ?", Long.class, old1))
                .as("the old notification went with its event").isZero();
        assertThat(jdbc.queryForObject("select count(*) from notifications where event_id = ?", Long.class, recent))
                .isEqualTo(1L);
    }

    @Test
    void moreThanOneChunkIsPurgedInOneRun() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Purge big " + UUID.randomUUID()).get("id").asText();
        jdbc.update("insert into group_events (id, group_id, type, payload, created_at) "
                + "select gen_random_uuid(), ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, now() - interval '400 days' "
                + "from generate_series(1, 5001)", gid);
        UUID keep = event(gid, 1);

        int deleted = job.runOnce();

        assertThat(deleted).as("5001 rows need two chunks of 5000").isGreaterThanOrEqualTo(5001);
        assertThat(jdbc.queryForList("select id from group_events where group_id = ?::uuid", UUID.class, gid))
                .containsExactly(keep);
        assertThat(job.runOnce()).as("nothing left to purge").isZero();
    }
}
