package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B16 / A107-A111: the rate-limited Remind. The clock is a test double so the 24 hour window can be crossed; the
 * per-account cap is lowered to 2 so it can be reached cheaply (no test here sends more than 2 reminders per account
 * except the cap test itself).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "qesma.remind.daily-cap-per-user=2")
@Import(RemindIT.Doubles.class)
class RemindIT extends AbstractActivityIT {

    static final class MutableClock extends Clock {
        private final AtomicReference<Duration> offset = new AtomicReference<>(Duration.ZERO);

        void advance(Duration d) {
            offset.updateAndGet(o -> o.plus(d));
        }

        void reset() {
            offset.set(Duration.ZERO);
        }

        @Override
        public ZoneId getZone() {
            return ZoneId.of("UTC");
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return Instant.now().plus(offset.get());
        }
    }

    @TestConfiguration
    static class Doubles {
        @Bean
        @Primary
        MutableClock remindTestClock() {
            return new MutableClock();
        }
    }

    private static final Duration WINDOW = Duration.ofHours(24);

    @Autowired MutableClock clock;

    @AfterEach
    void putTheClockBack() {
        clock.reset();
    }

    /** O (owner) paid 3000, split equally with D (a linked MEMBER): D owes O 1500. */
    private final class Fx {
        final Session owner = newUser();
        final Session debtor = newUser();
        final String gid;
        final String ownerMid;
        final String debtorMid;

        Fx() throws Exception {
            gid = createGroup(owner, "Remind " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            debtorMid = linkUser(gid, debtor, "MEMBER", "ACTIVE", "Debtor");
            createExpense(owner, gid, equalBody("Dinner", 3000, null, ownerMid, 3000L));
        }

        MvcResult remind(Session as, String from, String to, String key) throws Exception {
            return call(POST, "/api/v1/groups/" + gid + "/transfers/remind", as,
                    Map.of("fromMemberId", from, "toMemberId", to), "Idempotency-Key", key);
        }

        MvcResult remind(Session as) throws Exception {
            return remind(as, debtorMid, ownerMid, UUID.randomUUID().toString());
        }

        long remindLogRows() {
            return jdbc.queryForObject("select count(*) from remind_log where group_id = ?::uuid", Long.class, gid);
        }

        JsonNode balances(Session as) throws Exception {
            return body(call(GET, "/api/v1/groups/" + gid + "/balances", as, null));
        }
    }

    private static Instant at(JsonNode n) {
        return Instant.parse(n.asText());
    }

    @Test
    void aReminderNotifiesOnlyTheDebtorWithTheServerAmount() throws Exception {
        Fx f = new Fx();
        MvcResult r = f.remind(f.owner);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        JsonNode view = body(r);
        long suggested = f.balances(f.owner).get("transfers").get(0).get("amountMinor").asLong();
        assertThat(view.get("amountMinor").asLong()).isEqualTo(1500L).isEqualTo(suggested);
        assertThat(view.get("fromMemberId").asText()).isEqualTo(f.debtorMid);
        assertThat(view.get("toMemberId").asText()).isEqualTo(f.ownerMid);
        assertThat(at(view.get("canRemindAt"))).isEqualTo(at(view.get("remindedAt")).plus(WINDOW));

        Map<String, Object> event = onlyEvent(f.gid, "REMINDER");
        assertThat(event.get("actor").toString()).isEqualTo(f.ownerMid);
        JsonNode payload = json.readTree(event.get("payload").toString());
        assertThat(payload.get("amountMinor").asLong()).isEqualTo(1500L);
        assertThat(payload.get("fromMemberId").asText()).isEqualTo(f.debtorMid);
        assertThat(recipients(event.get("id"))).isEqualTo(ids(f.debtor));
        assertThat(f.remindLogRows()).isEqualTo(1);

        JsonNode inbox = body(call(GET, "/api/v1/notifications?limit=5", f.debtor, null)).get("items");
        assertThat(inbox.get(0).get("type").asText()).isEqualTo("REMINDER");
        assertThat(inbox.get(0).get("payload").get("amountMinor").asLong()).isEqualTo(1500L);
        assertThat(inbox.get(0).get("subject").isNull()).isTrue();
        assertThat(body(call(GET, "/api/v1/notifications?limit=5", f.owner, null)).get("items").toString())
                .as("the creditor is not notified of their own reminder").doesNotContain("REMINDER");
    }

    @Test
    void aSecondReminderInTheWindowIs429WithTheExactNextTimeAndWorksAfterIt() throws Exception {
        Fx f = new Fx();
        Instant sent = at(body(f.remind(f.owner)).get("remindedAt"));

        String retryKey = UUID.randomUUID().toString();
        MvcResult limited = f.remind(f.owner, f.debtorMid, f.ownerMid, retryKey);
        assertThat(status(limited)).isEqualTo(429);
        assertThat(code(limited)).isEqualTo("REMIND_RATE_LIMITED");
        assertThat(limited.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(at(body(limited).get("nextAllowedAt"))).isEqualTo(sent.plus(WINDOW));
        assertThat(f.remindLogRows()).isEqualTo(1);
        assertThat(eventsOf(f.gid, "REMINDER")).hasSize(1);

        clock.advance(WINDOW.plusSeconds(1));
        MvcResult again = f.remind(f.owner, f.debtorMid, f.ownerMid, retryKey);     // the 429 stored nothing: same key works
        assertThat(status(again)).as(again.getResponse().getContentAsString()).isEqualTo(201);
        assertThat(f.remindLogRows()).isEqualTo(2);
    }

    @Test
    void anotherCreditorOrManagerForTheSameDebtorIsLimitedToo() throws Exception {
        Fx f = new Fx();
        Session admin = newUser();
        linkUser(f.gid, admin, "ADMIN", "ACTIVE", "Admin");
        assertThat(status(f.remind(f.owner))).isEqualTo(201);
        MvcResult other = f.remind(admin, f.debtorMid, f.ownerMid, UUID.randomUUID().toString());
        assertThat(status(other)).isEqualTo(429);
        assertThat(code(other)).isEqualTo("REMIND_RATE_LIMITED");
    }

    @Test
    void canRemindAtIsNullThenSetThenNullAgainInBalances() throws Exception {
        Fx f = new Fx();
        assertThat(f.balances(f.debtor).get("transfers").get(0).get("canRemindAt").isNull()).isTrue();
        Instant sent = at(body(f.remind(f.owner)).get("remindedAt"));
        for (Session viewer : List.of(f.owner, f.debtor)) {
            assertThat(at(f.balances(viewer).get("transfers").get(0).get("canRemindAt"))).isEqualTo(sent.plus(WINDOW));
        }
        clock.advance(WINDOW.plusSeconds(1));
        assertThat(f.balances(f.owner).get("transfers").get(0).get("canRemindAt").isNull()).isTrue();
    }

    @Test
    void theRulesOfWhoAndWhatCanBeReminded() throws Exception {
        Fx f = new Fx();
        String key = UUID.randomUUID().toString();
        String unknown = UUID.randomUUID().toString();

        // caller is the debtor, same member twice, missing ids, unknown member, wrong direction (as a manager)
        MvcResult asDebtor = f.remind(f.debtor, f.debtorMid, f.ownerMid, key);
        assertThat(status(call(POST, "/api/v1/groups/" + f.gid + "/transfers/remind", f.owner, Map.of(), "Idempotency-Key", key)))
                .isEqualTo(422);
        assertThat(status(f.remind(f.owner, f.debtorMid, f.debtorMid, key))).isEqualTo(422);
        assertThat(status(f.remind(f.owner, f.ownerMid, f.debtorMid, key))).as("the caller is the debtor").isEqualTo(422);
        MvcResult notInGroup = f.remind(f.owner, unknown, f.ownerMid, key);
        assertThat(status(notInGroup)).isEqualTo(422);
        assertThat(code(notInGroup)).isEqualTo("MEMBER_NOT_IN_GROUP");
        assertThat(status(asDebtor)).as("a member who is not the creditor needs REMIND_ANY").isEqualTo(403);
        Session admin = newUser();
        linkUser(f.gid, admin, "ADMIN", "ACTIVE", "Admin");
        MvcResult wrongWay = f.remind(admin, f.ownerMid, f.debtorMid, key);
        assertThat(status(wrongWay)).isEqualTo(422);
        assertThat(code(wrongWay)).isEqualTo("VALIDATION_ERROR");
        assertThat(wrongWay.getResponse().getContentAsString()).contains("no suggested transfer");
        assertThat(f.remindLogRows()).isZero();
        assertThat(eventsOf(f.gid, "REMINDER")).isEmpty();
    }

    @Test
    void aGhostAnInactiveMemberAndASettledGroupCannotBeReminded() throws Exception {
        Fx f = new Fx();
        String ghost = addMember(f.owner, f.gid, "Ghost").get("id").asText();
        createExpense(f.owner, f.gid, equalBody("Lunch", 3000, List.of(f.ownerMid, ghost), f.ownerMid, 3000L));
        MvcResult ghostResult = f.remind(f.owner, ghost, f.ownerMid, UUID.randomUUID().toString());
        assertThat(status(ghostResult)).isEqualTo(422);
        assertThat(code(ghostResult)).isEqualTo("VALIDATION_ERROR");
        assertThat(ghostResult.getResponse().getContentAsString()).contains("no account");

        jdbc.update("update members set status = 'LEFT', left_at = now() where id = ?::uuid", f.debtorMid);
        MvcResult left = f.remind(f.owner);
        assertThat(status(left)).isEqualTo(422);
        assertThat(code(left)).isEqualTo("MEMBER_INACTIVE");

        Session o2 = newUser();
        String g2 = createGroup(o2, "Settled " + UUID.randomUUID()).get("id").asText();
        String o2m = member(o2, g2, "O").get("id").asText();
        Session d2 = newUser();
        String d2m = linkUser(g2, d2, "MEMBER", "ACTIVE", "D");
        MvcResult none = call(POST, "/api/v1/groups/" + g2 + "/transfers/remind", o2,
                Map.of("fromMemberId", d2m, "toMemberId", o2m), "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(none)).as("nothing is owed").isEqualTo(422);
        assertThat(code(none)).isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void creditorOwnerAndAdminMayRemindButAnotherPlainMemberMayNot() throws Exception {
        // C (a plain member) paid 3000 split three ways with O and D: D and O both owe C 1000
        Session owner = newUser();
        Session creditor = newUser();
        Session debtor = newUser();
        Session bystander = newUser();
        Session admin = newUser();
        Session stranger = newUser();
        Session leftUser = newUser();
        String gid = createGroup(owner, "Roles " + UUID.randomUUID()).get("id").asText();
        String ownerMid = member(owner, gid, "O").get("id").asText();
        String cMid = linkUser(gid, creditor, "MEMBER", "ACTIVE", "C");
        String dMid = linkUser(gid, debtor, "MEMBER", "ACTIVE", "D");
        linkUser(gid, bystander, "MEMBER", "ACTIVE", "B");
        linkUser(gid, admin, "ADMIN", "ACTIVE", "A");
        linkUser(gid, leftUser, "MEMBER", "LEFT", "Gone");
        createExpense(creditor, gid, equalBody("Dinner", 3000, List.of(ownerMid, cMid, dMid), cMid, 3000L));
        String url = "/api/v1/groups/" + gid + "/transfers/remind";
        Map<String, Object> body = Map.of("fromMemberId", dMid, "toMemberId", cMid);
        String k = UUID.randomUUID().toString();

        assertThat(status(call(POST, url, bystander, body, "Idempotency-Key", k))).isEqualTo(403);
        assertThat(code(call(POST, url, bystander, body, "Idempotency-Key", k))).isEqualTo("FORBIDDEN");
        assertThat(status(call(POST, url, stranger, body, "Idempotency-Key", k))).isEqualTo(404);
        assertThat(status(call(POST, url, leftUser, body, "Idempotency-Key", k))).isEqualTo(404);
        assertThat(status(call(POST, url, null, body, "Idempotency-Key", k))).isEqualTo(401);
        assertThat(status(call(POST, url, creditor, body, "Idempotency-Key", k))).as("the creditor").isEqualTo(201);

        // the owner and the admin each remind for another debtor-creditor pair: O -> C
        Map<String, Object> ownerPair = Map.of("fromMemberId", ownerMid, "toMemberId", cMid);
        assertThat(status(call(POST, url, admin, ownerPair, "Idempotency-Key", UUID.randomUUID().toString())))
                .as("an admin for somebody else's transfer").isEqualTo(201);
        // a second group so the owner's own remind is not limited by the pair
        Session owner2 = newUser();
        Session c2 = newUser();
        Session d2 = newUser();
        String g2 = createGroup(owner2, "Roles2 " + UUID.randomUUID()).get("id").asText();
        member(owner2, g2, "O");
        String c2m = linkUser(g2, c2, "MEMBER", "ACTIVE", "C");
        String d2m = linkUser(g2, d2, "MEMBER", "ACTIVE", "D");
        createExpense(c2, g2, equalBody("Dinner", 2000, List.of(c2m, d2m), c2m, 2000L));
        assertThat(status(call(POST, "/api/v1/groups/" + g2 + "/transfers/remind", owner2,
                Map.of("fromMemberId", d2m, "toMemberId", c2m), "Idempotency-Key", UUID.randomUUID().toString())))
                .as("the owner for somebody else's transfer").isEqualTo(201);
    }

    @Test
    void replayReturnsTheStoredAnswerAndASecondEventIsNeverWritten() throws Exception {
        Fx f = new Fx();
        String key = UUID.randomUUID().toString();
        MvcResult first = f.remind(f.owner, f.debtorMid, f.ownerMid, key);
        MvcResult replay = f.remind(f.owner, f.debtorMid, f.ownerMid, key);
        assertThat(status(first)).isEqualTo(201);
        assertThat(status(replay)).isEqualTo(201);
        assertThat(replay.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(first.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(body(replay)).isEqualTo(body(first));
        assertThat(eventsOf(f.gid, "REMINDER")).hasSize(1);
        assertThat(f.remindLogRows()).isEqualTo(1);
        assertThat(jdbc.queryForObject("select count(*) from notifications n join group_events e on e.id = n.event_id "
                + "where e.group_id = ?::uuid and e.type = 'REMINDER'", Long.class, f.gid)).isEqualTo(1L);

        // the same key with another request is refused (a replay never consumes or changes anything)
        MvcResult reused = f.remind(f.owner, UUID.randomUUID().toString(), f.ownerMid, key);
        assertThat(status(reused)).isEqualTo(422);
        assertThat(code(reused)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
    }

    @Test
    void theCapPerAccountAcrossGroupsAnswers429WithTheOldestPlusTheWindow() throws Exception {
        Session sender = newUser();
        List<Fx2> groups = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            groups.add(new Fx2(sender));
        }
        Instant first = at(body(groups.get(0).remind(sender)).get("remindedAt"));
        clock.advance(Duration.ofMinutes(5));
        assertThat(status(groups.get(1).remind(sender))).isEqualTo(201);
        clock.advance(Duration.ofMinutes(5));
        MvcResult third = groups.get(2).remind(sender);
        assertThat(status(third)).isEqualTo(429);
        assertThat(code(third)).isEqualTo("REMIND_RATE_LIMITED");
        assertThat(at(body(third).get("nextAllowedAt"))).isEqualTo(first.plus(WINDOW));

        clock.advance(WINDOW);                                      // the first reminder left the window
        assertThat(status(groups.get(2).remind(sender))).isEqualTo(201);
    }

    /** A group where {@code owner} is owed by a linked debtor. */
    private final class Fx2 {
        final String gid;
        final String ownerMid;
        final String debtorMid;

        Fx2(Session owner) throws Exception {
            gid = createGroup(owner, "Cap " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "O").get("id").asText();
            debtorMid = linkUser(gid, newUser(), "MEMBER", "ACTIVE", "D");
            createExpense(owner, gid, equalBody("Dinner", 2000, null, ownerMid, 2000L));
        }

        MvcResult remind(Session as) throws Exception {
            return call(POST, "/api/v1/groups/" + gid + "/transfers/remind", as,
                    Map.of("fromMemberId", debtorMid, "toMemberId", ownerMid), "Idempotency-Key", UUID.randomUUID().toString());
        }
    }

    @Test
    void aMutedDebtorStillGets201ButNoNotificationAndTheSlotIsConsumed() throws Exception {
        Fx f = new Fx();
        assertThat(status(call(PUT, "/api/v1/groups/" + f.gid + "/notification-prefs", f.debtor, Map.of("muted", true))))
                .isEqualTo(200);
        MvcResult r = f.remind(f.owner);
        assertThat(status(r)).isEqualTo(201);
        Map<String, Object> event = onlyEvent(f.gid, "REMINDER");
        assertThat(recipients(event.get("id"))).isEmpty();
        assertThat(f.remindLogRows()).isEqualTo(1);
        assertThat(status(f.remind(f.owner))).as("the slot was consumed").isEqualTo(429);
    }

    @Test
    void twoParallelRemindersForOnePairGiveExactlyOneSentAndOneLimited() throws Exception {
        for (int round = 0; round < 5; round++) {
            Fx f = new Fx();
            List<Callable<Integer>> tasks = List.of(
                    () -> status(f.remind(f.owner)),
                    () -> status(f.remind(f.owner)));
            ExecutorService pool = Executors.newFixedThreadPool(2);
            try {
                CountDownLatch ready = new CountDownLatch(2);
                CountDownLatch go = new CountDownLatch(1);
                List<Future<Integer>> futures = new ArrayList<>();
                for (Callable<Integer> t : tasks) {
                    futures.add(pool.submit(() -> {
                        ready.countDown();
                        go.await();
                        return t.call();
                    }));
                }
                ready.await();
                go.countDown();
                List<Integer> statuses = new ArrayList<>();
                for (Future<Integer> fu : futures) {
                    statuses.add(fu.get());
                }
                assertThat(statuses).containsExactlyInAnyOrder(201, 429);
            } finally {
                pool.shutdownNow();
            }
            assertThat(f.remindLogRows()).isEqualTo(1);
            assertThat(eventsOf(f.gid, "REMINDER")).hasSize(1);
        }
    }
}
