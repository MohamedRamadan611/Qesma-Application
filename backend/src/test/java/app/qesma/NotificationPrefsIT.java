package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B16 / A104-A106: the global switch and the per-group mute filter notifications at write time, never the feed, never
 * what already exists, and never other recipients.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class NotificationPrefsIT extends AbstractActivityIT {

    private final class World {
        final Session owner = newUser();
        final Session alice = newUser();
        final Session bob = newUser();
        final String gid;
        final String ownerMid;
        final String aliceMid;
        final String bobMid;

        World() throws Exception {
            gid = createGroup(owner, "Prefs " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            aliceMid = linkUser(gid, alice, "MEMBER", "ACTIVE", "Alice");
            bobMid = linkUser(gid, bob, "MEMBER", "ACTIVE", "Bob");
        }

        String base() {
            return "/api/v1/groups/" + gid;
        }

        /** The owner pays 3000, shared by all three: alice and bob are participants and get a notification. */
        Map<String, Object> dinner() {
            return equalBody("Dinner", 3000, null, ownerMid, 3000L);
        }

        long unread(Session as) throws Exception {
            return body(call(GET, "/api/v1/notifications/unread-count", as, null)).get("count").asLong();
        }
    }

    @Test
    void aGroupMuteSuppressesNotificationsButNotTheFeedNorOtherRecipients() throws Exception {
        World w = new World();
        MvcResult muted = call(PUT, w.base() + "/notification-prefs", w.alice, Map.of("muted", true));
        assertThat(status(muted)).isEqualTo(200);
        assertThat(body(muted).get("muted").asBoolean()).isTrue();

        createExpense(w.owner, w.gid, w.dinner());
        Map<String, Object> event = onlyEvent(w.gid, "EXPENSE_ADDED");
        assertThat(recipients(event.get("id"))).as("alice muted, bob did not").isEqualTo(ids(w.bob));
        assertThat(w.unread(w.alice)).isZero();
        assertThat(feed(w.alice, w.gid, "").get("items")).as("the feed is never filtered").hasSize(1);
    }

    @Test
    void unmutingRestoresNewNotificationsKeepsOldOnesAndDoesNotBackfill() throws Exception {
        World w = new World();
        createExpense(w.owner, w.gid, w.dinner());                                        // before: alice is notified
        assertThat(w.unread(w.alice)).isEqualTo(1);
        call(PUT, w.base() + "/notification-prefs", w.alice, Map.of("muted", true));
        assertThat(w.unread(w.alice)).as("muting keeps what exists").isEqualTo(1);
        createExpense(w.owner, w.gid, w.dinner());                                        // while muted
        assertThat(w.unread(w.alice)).isEqualTo(1);
        call(PUT, w.base() + "/notification-prefs", w.alice, Map.of("muted", false));
        assertThat(w.unread(w.alice)).as("unmuting does not backfill").isEqualTo(1);
        createExpense(w.owner, w.gid, w.dinner());                                        // after
        assertThat(w.unread(w.alice)).isEqualTo(2);
        assertThat(jdbc.queryForObject("select count(*) from notification_prefs where user_id = ?", Long.class,
                w.alice.userId())).as("the upsert reuses one row").isEqualTo(1L);
    }

    @Test
    void theGlobalSwitchSuppressesEveryGroupAndShowsInMe() throws Exception {
        World w = new World();
        assertThat(body(call(GET, "/api/v1/me", w.alice, null)).get("notificationsEnabled").asBoolean()).isTrue();
        MvcResult off = call(PUT, "/api/v1/me/notification-prefs", w.alice, Map.of("enabled", false));
        assertThat(status(off)).isEqualTo(200);
        assertThat(body(off).get("enabled").asBoolean()).isFalse();
        assertThat(body(call(GET, "/api/v1/me", w.alice, null)).get("notificationsEnabled").asBoolean()).isFalse();

        createExpense(w.owner, w.gid, w.dinner());
        assertThat(w.unread(w.alice)).isZero();
        assertThat(w.unread(w.bob)).isEqualTo(1);
        assertThat(eventsOf(w.gid, "EXPENSE_ADDED")).hasSize(1);

        call(PUT, "/api/v1/me/notification-prefs", w.alice, Map.of("enabled", true));
        assertThat(body(call(GET, "/api/v1/me", w.alice, null)).get("notificationsEnabled").asBoolean()).isTrue();
        createExpense(w.owner, w.gid, w.dinner());
        assertThat(w.unread(w.alice)).isEqualTo(1);
    }

    @Test
    void muteAppliesToDisputesAndRemindersToo() throws Exception {
        World w = new World();
        // alice pays bob (PENDING), bob disputes: the payer alice would be notified, unless she muted
        call(PUT, w.base() + "/notification-prefs", w.alice, Map.of("muted", true));
        String sid = body(call(POST, w.base() + "/settlements", w.alice, Map.of("fromMemberId", w.aliceMid,
                "toMemberId", w.bobMid, "amountMinor", 500L, "settledOn", "2026-10-20"),
                "Idempotency-Key", UUID.randomUUID().toString())).get("id").asText();
        assertThat(status(call(POST, w.base() + "/settlements/" + sid + "/dispute", w.bob, null))).isEqualTo(200);
        assertThat(recipients(onlyEvent(w.gid, "SETTLEMENT_DISPUTED").get("id")))
                .as("owner is a manager and is still notified, the muted payer is not").isEqualTo(ids(w.owner));

        // alice owes the owner; the owner reminds her; she is muted
        createExpense(w.owner, w.gid, equalBody("Dinner", 2000, List.of(w.ownerMid, w.aliceMid), w.ownerMid, 2000L));
        MvcResult r = call(POST, w.base() + "/transfers/remind", w.owner, Map.of("fromMemberId", w.aliceMid,
                "toMemberId", w.ownerMid), "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(r)).isEqualTo(201);
        assertThat(recipients(onlyEvent(w.gid, "REMINDER").get("id"))).isEmpty();
        assertThat(eventsOf(w.gid, "REMINDER")).as("still in the feed").hasSize(1);
    }

    @Test
    void groupDtoReflectsTheCallersOwnMuteOnly() throws Exception {
        World w = new World();
        assertThat(body(call(GET, w.base(), w.alice, null)).get("muted").asBoolean()).isFalse();
        call(PUT, w.base() + "/notification-prefs", w.alice, Map.of("muted", true));
        JsonNode mine = body(call(GET, w.base(), w.alice, null));
        assertThat(mine.get("muted").asBoolean()).isTrue();
        assertThat(body(call(GET, w.base(), w.bob, null)).get("muted").asBoolean()).isFalse();
    }

    @Test
    void whoMayCallWhatAndWhatIsValidated() throws Exception {
        World w = new World();
        Session stranger = newUser();
        assertThat(status(call(PUT, w.base() + "/notification-prefs", stranger, Map.of("muted", true)))).isEqualTo(404);
        assertThat(code(call(PUT, w.base() + "/notification-prefs", stranger, Map.of("muted", true)))).isEqualTo("NOT_FOUND");
        assertThat(status(call(PUT, w.base() + "/notification-prefs", null, Map.of("muted", true)))).isEqualTo(401);
        assertThat(status(call(PUT, "/api/v1/me/notification-prefs", null, Map.of("enabled", true)))).isEqualTo(401);
        MvcResult noField = call(PUT, w.base() + "/notification-prefs", w.alice, Map.of());
        assertThat(status(noField)).isEqualTo(422);
        assertThat(code(noField)).isEqualTo("VALIDATION_ERROR");
        assertThat(status(call(PUT, "/api/v1/me/notification-prefs", w.alice, Map.of()))).isEqualTo(422);
        assertThat(jdbc.queryForObject("select count(*) from notification_prefs where user_id = ?", Long.class,
                stranger.userId())).as("a refused call stores nothing").isZero();
    }
}
