package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B17 part B (A114-A120): DELETE /me. The invariant that matters most: nobody else's balance and no ledger row changes.
 * Then the purge of every personal-data table, the end of every session, re-registration of the freed identifiers,
 * the ownership rules, replays and parallel sign-ins, and that no identifier reaches a log.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "logging.level.app.qesma=DEBUG")
class AccountDeletionIT extends AbstractApiIT {

    private static final String GROUPS = "/api/v1/groups/";
    private static final String ME = "/api/v1/me";
    private static final String PASSWORD = "correct horse battery";

    /** A Google account with a known email and the refresh token of its sign-in. */
    private record Google(Session session, String subject, String email, String refreshToken) {
    }

    private Google googleUser(String subject, String name) throws Exception {
        String email = subject + "@example.com";
        MvcResult r = call(POST, "/api/v1/auth/google", null,
                "{\"idToken\":\"fake:" + subject + ":" + email + ":" + name + "\"}");
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        JsonNode b = body(r);
        return new Google(new Session(b.get("accessToken").asText(), UUID.fromString(b.get("user").get("id").asText())),
                subject, email, b.get("refreshToken").asText());
    }

    private Google freshGoogle(String name) throws Exception {
        return googleUser("sub-" + UUID.randomUUID(), name);
    }

    private JsonNode registerPassword(String username) throws Exception {
        MvcResult r = call(POST, "/api/v1/auth/register", null, Map.of("username", username, "password", PASSWORD));
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        return body(r);
    }

    private static Session sessionOf(JsonNode auth) {
        return new Session(auth.get("accessToken").asText(), UUID.fromString(auth.get("user").get("id").asText()));
    }

    private MvcResult deleteMe(Session as, Object body) throws Exception {
        return call(DELETE, ME, as, body);
    }

    private static Map<String, Object> confirm() {
        return Map.of("confirm", "DELETE");
    }

    private long count(String sql, Object... args) {
        return jdbc.queryForObject(sql, Long.class, args);
    }

    // ---- the invariant ------------------------------------------------------------------------------------

    @Test
    void everyOtherMembersBalanceAndEveryLedgerRowIsIdenticalBeforeAndAfter() throws Exception {
        Session ali = newUser();
        Google dina = freshGoogle("Dina Account");
        String gid = createGroup(ali, "Dahab").get("id").asText();
        String aliMember = body(call(GET, GROUPS + gid, ali, null)).get("members").get(0).get("id").asText();
        String dinaMember = linkUser(gid, dina.session(), "MEMBER", "ACTIVE", "Dina");
        String omarMember = addMember(ali, gid, "Omar").get("id").asText();   // a name-only member

        List<String> all = List.of(aliMember, dinaMember, omarMember);
        createExpense(ali, gid, equalBody("Dinner", 9000, null, aliMember, 9000L));
        createExpense(dina.session(), gid, equalBody("Taxi", 3000, null, dinaMember, 3000L));
        createExpense(ali, gid, exactBody("Fuel", 7000, List.of(aliMember, 2000L, dinaMember, 3000L, omarMember, 2000L),
                aliMember, 7000L));
        Map<String, Object> settlement = new LinkedHashMap<>();
        settlement.put("fromMemberId", dinaMember);
        settlement.put("toMemberId", aliMember);
        settlement.put("amountMinor", 1500L);
        settlement.put("settledOn", "2026-10-20");
        MvcResult settled = call(POST, GROUPS + gid + "/settlements", dina.session(), settlement,
                "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(settled)).as(settled.getResponse().getContentAsString()).isEqualTo(201);

        // Ali is the owner and stays; Dina (a plain member) deletes her account.
        JsonNode balancesBefore = body(call(GET, GROUPS + gid + "/balances", ali, null));
        JsonNode expensesBefore = body(call(GET, GROUPS + gid + "/expenses?size=100", ali, null));
        JsonNode groupBefore = body(call(GET, GROUPS + gid, ali, null));
        assertThat(balancesBefore.get("nets")).as("the scenario has money in it").isNotEmpty();
        long ledgerBefore = count("select (select count(*) from expenses) + (select count(*) from expense_payers) "
                + "+ (select count(*) from expense_splits) + (select count(*) from settlements) "
                + "+ (select count(*) from expense_revisions)");
        long membersBefore = count("select count(*) from members where group_id = ?::uuid", gid);

        assertThat(status(deleteMe(dina.session(), confirm()))).isEqualTo(204);

        assertThat(body(call(GET, GROUPS + gid + "/balances", ali, null))).isEqualTo(balancesBefore);
        assertThat(body(call(GET, GROUPS + gid + "/expenses?size=100", ali, null))).isEqualTo(expensesBefore);
        assertThat(count("select (select count(*) from expenses) + (select count(*) from expense_payers) "
                + "+ (select count(*) from expense_splits) + (select count(*) from settlements) "
                + "+ (select count(*) from expense_revisions)")).isEqualTo(ledgerBefore);
        assertThat(count("select count(*) from members where group_id = ?::uuid", gid)).isEqualTo(membersBefore);

        // the group read differs only in Dina's member: it keeps its id and name and is no longer connected
        JsonNode groupAfter = body(call(GET, GROUPS + gid, ali, null));
        for (JsonNode before : groupBefore.get("members")) {
            JsonNode after = null;
            for (JsonNode m : groupAfter.get("members")) {
                if (m.get("id").asText().equals(before.get("id").asText())) {
                    after = m;
                }
            }
            assertThat(after).isNotNull();
            if (before.get("id").asText().equals(dinaMember)) {
                assertThat(before.get("hasAccount").asBoolean()).isTrue();
                assertThat(after.get("hasAccount").asBoolean()).isFalse();
                assertThat(after.get("displayName").asText()).isEqualTo("Dina");
                assertThat(after.get("role").asText()).isEqualTo("MEMBER");
            } else {
                assertThat(after).isEqualTo(before);
            }
        }
        assertThat(all).hasSize(3);
    }

    // ---- purge, anonymisation, re-registration ------------------------------------------------------------

    @Test
    void everyPersonalDataTableHasNoRowOfTheUserAndTheAccountRowIsAnonymised() throws Exception {
        Session ali = newUser();
        Google dina = freshGoogle("Dina Account");
        UUID id = dina.session().userId();
        String gid = createGroup(ali, "Purge").get("id").asText();
        String aliMember = body(call(GET, GROUPS + gid, ali, null)).get("members").get(0).get("id").asText();
        String dinaMember = linkUser(gid, dina.session(), "MEMBER", "ACTIVE", "Dina");
        // an expense by Ali that includes Dina: Dina gets a notification
        createExpense(ali, gid, equalBody("Lunch", 3000, null, aliMember, 3000L));
        // her own idempotent create, payment handles and a muted preference
        createExpense(dina.session(), gid, equalBody("Snack", 600, null, dinaMember, 600L));
        assertThat(status(call(PUT, ME + "/payment-handles", dina.session(),
                Map.of("instapay", "dina@bank", "wallet", "01012345678")))).isEqualTo(200);
        assertThat(status(call(PUT, ME + "/notification-prefs", dina.session(), Map.of("enabled", false)))).isEqualTo(200);
        // a request to join another group and a reminder she sent (rows in the two remaining personal tables)
        String other = createGroup(ali, "Other").get("id").asText();
        UUID inviteId = UUID.randomUUID();
        jdbc.update("insert into group_invites (id, group_id, code, created_by_member_id, expires_at, requires_approval) "
                + "select ?, ?::uuid, 'ABCDEFGH', m.id, now() + interval '1 day', true from members m "
                + "where m.group_id = ?::uuid limit 1", inviteId, other, other);
        jdbc.update("insert into join_requests (id, invite_id, group_id, user_id, new_member_name) "
                + "values (?, ?, ?::uuid, ?, 'Dina Wants In')", UUID.randomUUID(), inviteId, other, id);
        jdbc.update("insert into remind_log (id, group_id, from_member_id, to_member_id, sent_by_user_id, created_at) "
                + "values (?, ?::uuid, ?::uuid, ?::uuid, ?, now())", UUID.randomUUID(), gid, dinaMember, aliMember, id);

        String where = " where user_id = ?";
        assertThat(count("select count(*) from refresh_tokens" + where, id)).isPositive();
        assertThat(count("select count(*) from payment_handles" + where, id)).isPositive();
        assertThat(count("select count(*) from notification_prefs" + where, id)).isPositive();
        assertThat(count("select count(*) from notifications" + where, id)).as("Dina was notified of Lunch").isPositive();
        assertThat(count("select count(*) from idempotency_keys" + where, id)).isPositive();
        assertThat(count("select count(*) from join_requests" + where, id)).isPositive();
        assertThat(count("select count(*) from remind_log where sent_by_user_id = ?", id)).isPositive();

        assertThat(status(deleteMe(dina.session(), confirm()))).isEqualTo(204);

        for (String table : List.of("user_passwords", "email_tokens", "refresh_tokens", "payment_handles",
                "notification_prefs", "notifications", "idempotency_keys", "join_requests", "members")) {
            assertThat(count("select count(*) from " + table + where, id)).as(table).isZero();
        }
        assertThat(count("select count(*) from remind_log where sent_by_user_id = ?", id)).as("remind_log").isZero();

        Map<String, Object> row = jdbc.queryForMap("select display_name, auth_subject, email, email_verified_at, deleted_at "
                + "from users where id = ?", id);
        assertThat(row.get("display_name")).isEqualTo("Deleted user");
        assertThat((String) row.get("auth_subject")).startsWith("deleted:").doesNotContain(dina.subject());
        assertThat(row.get("email")).isNull();
        assertThat(row.get("email_verified_at")).isNull();
        assertThat(row.get("deleted_at")).isNotNull();
        // what she wrote stays: the ledger rows still point at her (now anonymous) account
        assertThat(count("select count(*) from expenses where created_by_user_id = ?", id)).isEqualTo(1);
        // her member is still there with its name, unclaimed, so an invite can offer it again
        Map<String, Object> member = jdbc.queryForMap("select display_name, user_id, role, status from members where id = ?::uuid",
                dinaMember);
        assertThat(member.get("display_name")).isEqualTo("Dina");
        assertThat(member.get("user_id")).isNull();
        assertThat(member.get("role")).isEqualTo("MEMBER");
        assertThat(member.get("status")).isEqualTo("ACTIVE");
    }

    @Test
    void theOldGoogleSubjectAndThePasswordUsernameCanRegisterAgainAsNewAccounts() throws Exception {
        Google dina = freshGoogle("Dina");
        assertThat(status(deleteMe(dina.session(), confirm()))).isEqualTo(204);
        Google again = googleUser(dina.subject(), "Dina Again");
        assertThat(again.session().userId()).isNotEqualTo(dina.session().userId());
        assertThat(status(call(GET, ME, again.session(), null))).isEqualTo(200);
        assertThat(body(call(GET, ME, again.session(), null)).get("displayName").asText()).isEqualTo("Dina Again");

        String username = "user" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        JsonNode first = registerPassword(username);
        Session s = sessionOf(first);
        // password accounts must send the password; a wrong one is a 422 that changes nothing
        assertThat(status(deleteMe(s, confirm()))).isEqualTo(422);
        assertThat(status(deleteMe(s, Map.of("confirm", "DELETE", "password", "wrong password here")))).isEqualTo(422);
        assertThat(status(call(GET, ME, s, null))).isEqualTo(200);
        assertThat(status(deleteMe(s, Map.of("confirm", "DELETE", "password", PASSWORD)))).isEqualTo(204);
        assertThat(count("select count(*) from user_passwords where user_id = ?", s.userId())).isZero();

        // the username is free again and the old password does not open the new account
        MvcResult old = call(POST, "/api/v1/auth/login", null, Map.of("username", username, "password", PASSWORD));
        assertThat(status(old)).isEqualTo(401);
        JsonNode second = registerPassword(username);
        assertThat(sessionOf(second).userId()).isNotEqualTo(s.userId());
    }

    // ---- sessions and replays -----------------------------------------------------------------------------

    @Test
    void allSessionsEndAndARepeatedCallIs401() throws Exception {
        Google dina = freshGoogle("Dina");
        Google second = googleUser(dina.subject(), "Dina");                    // a second device, same account
        assertThat(second.session().userId()).isEqualTo(dina.session().userId());

        assertThat(status(deleteMe(dina.session(), confirm()))).isEqualTo(204);

        for (Session s : List.of(dina.session(), second.session())) {
            assertThat(status(call(GET, ME, s, null))).as("access token refused at once").isEqualTo(401);
            assertThat(status(call(POST, "/api/v1/groups", s, Map.of("name", "Zombie", "type", "TRIP"))))
                    .as("a deleted account cannot start anything new").isEqualTo(401);
        }
        for (Google g : List.of(dina, second)) {
            assertThat(status(call(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", g.refreshToken()))))
                    .as("refresh token ended").isEqualTo(401);
        }
        MvcResult again = deleteMe(dina.session(), confirm());
        assertThat(status(again)).isEqualTo(401);
        assertThat(code(again)).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void aWrongOrMissingConfirmationChangesNothing() throws Exception {
        Google dina = freshGoogle("Dina");
        for (Object bad : new Object[] {Map.of("confirm", "delete"), Map.of("confirm", ""), Map.of("password", "x"), "{}"}) {
            assertThat(status(deleteMe(dina.session(), bad))).as(bad.toString()).isEqualTo(422);
        }
        assertThat(status(call(DELETE, ME, dina.session(), null))).isGreaterThanOrEqualTo(400);
        assertThat(status(call(GET, ME, dina.session(), null))).isEqualTo(200);
        assertThat(status(call(DELETE, ME, null, confirm()))).isEqualTo(401);
    }

    // ---- ownership ----------------------------------------------------------------------------------------

    @Test
    void anOwnerWithOtherActiveMembersOrWithHistoryMustTransferFirst() throws Exception {
        Google ali = freshGoogle("Ali Account");
        Google dina = freshGoogle("Dina Account");
        String shared = createGroup(ali.session(), "Shared").get("id").asText();
        String dinaMember = linkUser(shared, dina.session(), "MEMBER", "ACTIVE", "Dina");
        String history = createGroup(ali.session(), "History").get("id").asText();
        String aliInHistory = body(call(GET, GROUPS + history, ali.session(), null)).get("members").get(0).get("id").asText();
        createExpense(ali.session(), history, equalBody("Solo", 1000, null, aliInHistory, 1000L));

        MvcResult blocked = deleteMe(ali.session(), confirm());
        assertThat(status(blocked)).isEqualTo(409);
        assertThat(code(blocked)).isEqualTo("OWNER_MUST_TRANSFER");
        List<String> listed = new ArrayList<>();
        body(blocked).get("groups").forEach(g -> listed.add(g.get("id").asText()));
        assertThat(listed).containsExactlyInAnyOrder(shared, history);
        // nothing happened: the account and its sessions are intact
        assertThat(status(call(GET, ME, ali.session(), null))).isEqualTo(200);
        assertThat(count("select count(*) from members where user_id = ?", ali.session().userId())).isEqualTo(2);
        assertThat(count("select count(*) from refresh_tokens where user_id = ?", ali.session().userId())).isPositive();

        // transferring the shared group is not enough while the group with history is still owned
        assertThat(status(call(POST, GROUPS + shared + "/transfer-ownership", ali.session(), Map.of("toMemberId", dinaMember))))
                .isEqualTo(204);
        MvcResult stillBlocked = deleteMe(ali.session(), confirm());
        assertThat(status(stillBlocked)).isEqualTo(409);
        assertThat(body(stillBlocked).get("groups")).hasSize(1);
        assertThat(body(stillBlocked).get("groups").get(0).get("id").asText()).isEqualTo(history);

        // a sole owner with history and nobody else is blocked too (never an ownerless group); once the only
        // other active member exists and takes over, the deletion goes through
        Google omar = freshGoogle("Omar Account");
        String omarMember = linkUser(history, omar.session(), "MEMBER", "ACTIVE", "Omar");
        assertThat(status(call(POST, GROUPS + history + "/transfer-ownership", ali.session(), Map.of("toMemberId", omarMember))))
                .isEqualTo(204);
        assertThat(status(deleteMe(ali.session(), confirm()))).isEqualTo(204);
        // history is intact, now owned by Omar; Ali's member is an unclaimed ghost
        assertThat(body(call(GET, GROUPS + history + "/expenses", omar.session(), null)).get("items")).hasSize(1);
        assertThat(count("select count(*) from members where id = ?::uuid and user_id is null and role = 'MEMBER'", aliInHistory))
                .isEqualTo(1);
    }

    @Test
    void aSoleMemberOfAnEmptyGroupDeletesTheGroupEvenWithInvitesAndRequests() throws Exception {
        Google ali = freshGoogle("Ali Account");
        Google dina = freshGoogle("Dina Account");
        String gid = createGroup(ali.session(), "Empty").get("id").asText();
        UUID inviteId = UUID.randomUUID();
        jdbc.update("insert into group_invites (id, group_id, code, created_by_member_id, expires_at, requires_approval) "
                + "select ?, ?::uuid, 'JKLMNPQR', m.id, now() + interval '1 day', true from members m "
                + "where m.group_id = ?::uuid limit 1", inviteId, gid, gid);
        jdbc.update("insert into join_requests (id, invite_id, group_id, user_id, new_member_name) values (?, ?, ?::uuid, ?, 'Pending')",
                UUID.randomUUID(), inviteId, gid, dina.session().userId());
        String ghost = addMember(ali.session(), gid, "Ghost").get("id").asText();

        assertThat(status(deleteMe(ali.session(), confirm()))).isEqualTo(204);

        assertThat(count("select count(*) from expense_groups where id = ?::uuid", gid)).isZero();
        assertThat(count("select count(*) from members where group_id = ?::uuid", gid)).isZero();
        assertThat(count("select count(*) from group_invites where group_id = ?::uuid", gid)).isZero();
        assertThat(count("select count(*) from join_requests where group_id = ?::uuid", gid)).isZero();
        assertThat(ghost).isNotBlank();
        // and Dina, who only asked to join, is unaffected
        assertThat(status(call(GET, ME, dina.session(), null))).isEqualTo(200);
    }

    // ---- what others can still read -----------------------------------------------------------------------

    @Test
    void theDeletedAccountsNameAndIdNeverAppearInOthersActivityOrNotificationReads() throws Exception {
        Google ali = freshGoogle("Ali Account");
        Google dina = freshGoogle("Zebulon Account");
        String gid = createGroup(ali.session(), "Feed").get("id").asText();
        String aliMember = body(call(GET, GROUPS + gid, ali.session(), null)).get("members").get(0).get("id").asText();
        String dinaMember = linkUser(gid, dina.session(), "MEMBER", "ACTIVE", "Dina");
        createExpense(dina.session(), gid, equalBody("Taxi", 3000, null, dinaMember, 3000L));
        createExpense(ali.session(), gid, equalBody("Lunch", 3000, null, aliMember, 3000L));

        assertThat(status(deleteMe(dina.session(), confirm()))).isEqualTo(204);

        String feed = call(GET, GROUPS + gid + "/activity", ali.session(), null).getResponse().getContentAsString();
        String notifications = call(GET, "/api/v1/notifications", ali.session(), null).getResponse().getContentAsString();
        for (String text : List.of(feed, notifications)) {
            assertThat(text).doesNotContain("Zebulon").doesNotContain(dina.session().userId().toString())
                    .doesNotContain(dina.email());
        }
        assertThat(feed).as("the member stays in the history by its id").contains(dinaMember);
        assertThat(status(call(GET, GROUPS + gid + "/activity", ali.session(), null))).isEqualTo(200);
    }

    // ---- concurrency --------------------------------------------------------------------------------------

    private <T> List<T> runConcurrently(List<Callable<T>> calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(calls.size());
        CountDownLatch go = new CountDownLatch(1);
        try {
            List<Future<T>> futures = new ArrayList<>();
            for (Callable<T> c : calls) {
                futures.add(pool.submit(() -> {
                    go.await();
                    return c.call();
                }));
            }
            go.countDown();
            List<T> out = new ArrayList<>();
            for (Future<T> f : futures) {
                out.add(f.get());
            }
            return out;
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void parallelDeletionsHaveExactlyOneWinner() throws Exception {
        Google dina = freshGoogle("Dina");
        List<Callable<Integer>> calls = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            calls.add(() -> status(deleteMe(dina.session(), confirm())));
        }
        List<Integer> statuses = runConcurrently(calls);
        assertThat(statuses.stream().filter(s -> s == 204)).hasSize(1);
        assertThat(statuses.stream().filter(s -> s == 401)).hasSize(5);
        assertThat(count("select count(*) from users where id = ? and deleted_at is not null", dina.session().userId())).isEqualTo(1);
    }

    @Test
    void signInsRacingTheDeletionLeaveNoUsableSessionAndNeverFail() throws Exception {
        Google dina = freshGoogle("Dina");
        UUID oldId = dina.session().userId();
        List<Callable<Object>> calls = new ArrayList<>();
        calls.add(() -> status(deleteMe(dina.session(), confirm())));
        for (int i = 0; i < 6; i++) {
            calls.add(() -> {
                MvcResult r = call(POST, "/api/v1/auth/google", null,
                        "{\"idToken\":\"fake:" + dina.subject() + ":" + dina.email() + ":Dina\"}");
                return r;
            });
        }
        List<Object> results = runConcurrently(calls);
        assertThat(results.get(0)).isEqualTo(204);
        for (Object o : results.subList(1, results.size())) {
            MvcResult login = (MvcResult) o;
            if (status(login) == 401) {        // the sign-in found the account deleted: refused, no session
                continue;
            }
            assertThat(status(login)).as(login.getResponse().getContentAsString()).isEqualTo(200);
            JsonNode b = body(login);
            Session s = new Session(b.get("accessToken").asText(), UUID.fromString(b.get("user").get("id").asText()));
            if (s.userId().equals(oldId)) {   // the sign-in won the race against the deletion: its token is dead
                assertThat(status(call(GET, ME, s, null))).isEqualTo(401);
                assertThat(status(call(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", b.get("refreshToken").asText()))))
                        .isEqualTo(401);
            } else {                           // it came after: a brand new account
                assertThat(status(call(GET, ME, s, null))).isEqualTo(200);
            }
        }
        assertThat(count("select count(*) from refresh_tokens where user_id = ?", oldId)).as("no session row survives").isZero();
    }

    @Test
    void passwordSignInsRacingTheDeletionNeverFailWithAServerError() throws Exception {
        String username = "race" + UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        Session s = sessionOf(registerPassword(username));
        List<Callable<Integer>> calls = new ArrayList<>();
        calls.add(() -> status(deleteMe(s, Map.of("confirm", "DELETE", "password", PASSWORD))));
        for (int i = 0; i < 5; i++) {
            calls.add(() -> status(call(POST, "/api/v1/auth/login", null, Map.of("username", username, "password", PASSWORD))));
        }
        List<Integer> statuses = runConcurrently(calls);
        assertThat(statuses.get(0)).isEqualTo(204);
        assertThat(statuses.subList(1, statuses.size())).allMatch(st -> st == 200 || st == 401);
        assertThat(count("select count(*) from refresh_tokens where user_id = ?", s.userId())).isZero();
    }

    // ---- logs ---------------------------------------------------------------------------------------------

    private static String everything(ILoggingEvent e) {
        StringBuilder sb = new StringBuilder(e.getFormattedMessage()).append('\n').append(e.getMDCPropertyMap());
        if (e.getKeyValuePairs() != null) {
            e.getKeyValuePairs().forEach(kv -> sb.append('\n').append(kv.key).append('=').append(kv.value));
        }
        if (e.getArgumentArray() != null) {
            for (Object a : e.getArgumentArray()) {
                sb.append('\n').append(a);
            }
        }
        for (IThrowableProxy t = e.getThrowableProxy(); t != null; t = t.getCause()) {
            sb.append('\n').append(t.getClassName()).append(':').append(t.getMessage());
        }
        return sb.toString();
    }

    @Test
    void noEmailUsernameNameOrPasswordReachesAnyLog() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Level before = root.getLevel();
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        String subject = "logsub-" + UUID.randomUUID();
        String username = "logname" + UUID.randomUUID().toString().replace("-", "").substring(0, 10);
        String secretName = "Quasimodo" + UUID.randomUUID().toString().substring(0, 6);
        UUID googleId;
        try {
            Google g = googleUser(subject, secretName);
            googleId = g.session().userId();
            deleteMe(g.session(), Map.of("confirm", "nope"));                                  // 422
            assertThat(status(deleteMe(g.session(), confirm()))).isEqualTo(204);
            deleteMe(g.session(), confirm());                                                  // 401 replay
            Session p = sessionOf(registerPassword(username));
            deleteMe(p, Map.of("confirm", "DELETE", "password", "a wrong secret phrase"));     // 422
            assertThat(status(deleteMe(p, Map.of("confirm", "DELETE", "password", PASSWORD)))).isEqualTo(204);
        } finally {
            root.detachAppender(appender);
            root.setLevel(before);
        }
        List<ILoggingEvent> events = new ArrayList<>(appender.list);
        assertThat(events.stream().map(ILoggingEvent::getFormattedMessage)).as("our own event was logged")
                .anyMatch(m -> m.startsWith("account.deleted userId=" + googleId));
        for (ILoggingEvent event : events) {
            String text = everything(event);
            for (String secret : List.of(subject, subject + "@example.com", username, secretName, PASSWORD,
                    "a wrong secret phrase")) {
                assertThat(text).as("log event of " + event.getLoggerName()).doesNotContain(secret);
            }
        }
    }
}
