package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import app.qesma.security.RefreshTokens;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.CountDownLatch;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/**
 * End-to-end auth against real PostgreSQL with the fake Google verifier. Each test uses its own random
 * Google subject, so tests are independent and can share one database.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class AuthFlowIT extends AbstractIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;

    // ---- helpers ----------------------------------------------------------------------------------

    private MvcResult postJson(String path, String body) throws Exception {
        return mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(body)).andReturn();
    }

    private MvcResult loginRaw(String sub, String email, String name) throws Exception {
        return postJson("/api/v1/auth/google", "{\"idToken\":\"fake:" + sub + ":" + email + ":" + name + "\"}");
    }

    private JsonNode body(MvcResult r) throws Exception {
        return json.readTree(r.getResponse().getContentAsString());
    }

    private JsonNode login(String sub) throws Exception {
        MvcResult r = loginRaw(sub, sub + "@example.com", "Ali Hassan");
        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        return body(r);
    }

    private MvcResult refresh(String raw) throws Exception {
        return postJson("/api/v1/auth/refresh", "{\"refreshToken\":\"" + raw + "\"}");
    }

    private MvcResult logout(String raw) throws Exception {
        return postJson("/api/v1/auth/logout", "{\"refreshToken\":\"" + raw + "\"}");
    }

    private static String newSub() {
        return "sub-" + UUID.randomUUID();
    }

    private int countUsers(String sub) {
        return jdbc.queryForObject("select count(*) from users where auth_subject = ?", Integer.class, sub);
    }

    // ---- login ------------------------------------------------------------------------------------

    @Test
    void firstLoginCreatesOneUserAndRepeatLoginReturnsTheSame() throws Exception {
        String sub = newSub();
        JsonNode first = login(sub);
        JsonNode second = login(sub);

        assertThat(first.get("user").get("id").asText()).isEqualTo(second.get("user").get("id").asText());
        assertThat(first.get("user").get("displayName").asText()).isEqualTo("Ali Hassan");
        assertThat(first.get("user").get("email").asText()).isEqualTo(sub + "@example.com");
        assertThat(first.get("accessToken").asText()).isNotBlank();
        assertThat(first.get("refreshToken").asText()).isNotEqualTo(second.get("refreshToken").asText());
        assertThat(countUsers(sub)).isEqualTo(1);
    }

    @Test
    void sixteenConcurrentFirstLoginsStillCreateExactlyOneUser() throws Exception {
        String sub = newSub();
        ExecutorService pool = Executors.newFixedThreadPool(16);
        CountDownLatch go = new CountDownLatch(1);
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < 16; i++) {
            calls.add(() -> {
                go.await();
                return loginRaw(sub, sub + "@example.com", "Racer");
            });
        }
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (Callable<MvcResult> c : calls) {
            futures.add(pool.submit(c));
        }
        go.countDown();
        List<String> ids = new ArrayList<>();
        for (Future<MvcResult> f : futures) {
            MvcResult r = f.get();
            assertThat(r.getResponse().getStatus()).isEqualTo(200);
            ids.add(body(r).get("user").get("id").asText());
        }
        pool.shutdown();

        assertThat(ids).doesNotContainNull().containsOnly(ids.get(0));
        assertThat(countUsers(sub)).isEqualTo(1);
    }

    @Test
    void userWithoutGoogleNameGetsTheEmailLocalPart() throws Exception {
        MvcResult r = loginRaw(newSub(), "mohamed.ramadan61197@gmail.com", "");
        assertThat(body(r).get("user").get("displayName").asText()).isEqualTo("mohamed.ramadan61197");
    }

    @Test
    void invalidGoogleTokensAreRejectedWithTheGeneric401() throws Exception {
        for (String token : new String[] {"bogus", "fake:", "fake::a@b.com:x"}) {
            MvcResult r = postJson("/api/v1/auth/google", "{\"idToken\":\"" + token + "\"}");
            assertThat(r.getResponse().getStatus()).as(token).isEqualTo(401);
            assertThat(body(r).get("code").asText()).isEqualTo("UNAUTHORIZED");
        }
    }

    @Test
    void onlyTheHashOfTheRefreshTokenIsStored() throws Exception {
        String raw = login(newSub()).get("refreshToken").asText();
        Integer byHash = jdbc.queryForObject("select count(*) from refresh_tokens where token_hash = ?",
                Integer.class, (Object) RefreshTokens.hash(raw));
        assertThat(byHash).isEqualTo(1);
        Integer byRaw = jdbc.queryForObject("select count(*) from refresh_tokens where token_hash = ?",
                Integer.class, (Object) raw.getBytes());
        assertThat(byRaw).isZero();
    }

    // ---- refresh rotation, reuse, logout ----------------------------------------------------------

    @Test
    void refreshRotatesAndTheOldTokenStopsWorking() throws Exception {
        JsonNode session = login(newSub());
        String r1 = session.get("refreshToken").asText();

        MvcResult second = refresh(r1);
        assertThat(second.getResponse().getStatus()).isEqualTo(200);
        String r2 = body(second).get("refreshToken").asText();
        assertThat(r2).isNotEqualTo(r1);
        assertThat(body(second).get("accessToken").asText()).isNotBlank();

        assertThat(refresh(r2).getResponse().getStatus()).isEqualTo(200); // the new token works
        assertThat(refresh(r1).getResponse().getStatus()).isEqualTo(401); // the rotated one does not
    }

    @Test
    void reusingARotatedTokenRevokesTheWholeFamily() throws Exception {
        JsonNode session = login(newSub());
        String userId = session.get("user").get("id").asText();
        String r1 = session.get("refreshToken").asText();
        String r2 = body(refresh(r1)).get("refreshToken").asText();

        assertThat(refresh(r1).getResponse().getStatus()).isEqualTo(401); // replay of the old token
        assertThat(refresh(r2).getResponse().getStatus()).isEqualTo(401); // the legitimate newest token is dead too

        Integer stillActive = jdbc.queryForObject(
                "select count(*) from refresh_tokens where user_id = ?::uuid and revoked_at is null",
                Integer.class, userId);
        assertThat(stillActive).isZero();
    }

    @Test
    void twoSimultaneousRefreshesOfOneTokenYieldOneSuccessAndKillTheFamily() throws Exception {
        JsonNode session = login(newSub());
        String r1 = session.get("refreshToken").asText();
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch go = new CountDownLatch(1);
        Future<MvcResult> a = pool.submit(() -> { go.await(); return refresh(r1); });
        Future<MvcResult> b = pool.submit(() -> { go.await(); return refresh(r1); });
        go.countDown();
        MvcResult ra = a.get();
        MvcResult rb = b.get();
        pool.shutdown();

        assertThat(List.of(ra.getResponse().getStatus(), rb.getResponse().getStatus())).containsExactlyInAnyOrder(200, 401);
        MvcResult winner = ra.getResponse().getStatus() == 200 ? ra : rb;
        String newest = body(winner).get("refreshToken").asText();
        assertThat(refresh(newest).getResponse().getStatus()).as("family revoked by the loser").isEqualTo(401);
    }

    @Test
    void logoutEndsTheSessionAndIsIdempotent() throws Exception {
        String r1 = login(newSub()).get("refreshToken").asText();

        assertThat(logout(r1).getResponse().getStatus()).isEqualTo(204);
        assertThat(refresh(r1).getResponse().getStatus()).isEqualTo(401);
        assertThat(logout(r1).getResponse().getStatus()).isEqualTo(204);
        assertThat(logout("never-issued-token").getResponse().getStatus()).isEqualTo(204); // not an oracle
    }

    @Test
    void logoutKillsTheNewestTokenOfTheFamilyEvenAfterRotations() throws Exception {
        String r1 = login(newSub()).get("refreshToken").asText();
        String r2 = body(refresh(r1)).get("refreshToken").asText();
        String r3 = body(refresh(r2)).get("refreshToken").asText();

        assertThat(logout(r3).getResponse().getStatus()).isEqualTo(204);
        assertThat(refresh(r3).getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void expiredRefreshTokenIsRejectedWithTheSame401() throws Exception {
        JsonNode session = login(newSub());
        String userId = session.get("user").get("id").asText();
        jdbc.update("update refresh_tokens set created_at = now() - interval '2 days', "
                + "expires_at = now() - interval '1 day' where user_id = ?::uuid", userId);

        MvcResult r = refresh(session.get("refreshToken").asText());
        assertThat(r.getResponse().getStatus()).isEqualTo(401);
        assertThat(body(r).get("code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void unknownRefreshTokenIs401() throws Exception {
        assertThat(refresh("0123456789012345678901234567890123456789012").getResponse().getStatus()).isEqualTo(401);
    }

    // ---- /me --------------------------------------------------------------------------------------

    private MvcResult getMe(String access) throws Exception {
        return mvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + access)).andReturn();
    }

    private MvcResult patchMe(String access, String displayName) throws Exception {
        return mvc.perform(patch("/api/v1/me").header("Authorization", "Bearer " + access)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(java.util.Map.of("displayName", displayName)))).andReturn();
    }

    @Test
    void meReturnsTheProfileAndPatchTrimsAndPersistsTheName() throws Exception {
        JsonNode session = login(newSub());
        String access = session.get("accessToken").asText();

        MvcResult me = getMe(access);
        assertThat(me.getResponse().getStatus()).isEqualTo(200);
        assertThat(body(me).get("id").asText()).isEqualTo(session.get("user").get("id").asText());

        MvcResult patched = patchMe(access, "   Sara Ahmed  ");
        assertThat(patched.getResponse().getStatus()).isEqualTo(200);
        assertThat(body(patched).get("displayName").asText()).isEqualTo("Sara Ahmed");
        assertThat(body(getMe(access)).get("displayName").asText()).isEqualTo("Sara Ahmed");
    }

    @Test
    void patchMeValidatesTheName() throws Exception {
        String access = login(newSub()).get("accessToken").asText();

        for (String bad : new String[] {"", "    ", "x".repeat(61), "😀".repeat(61)}) {
            MvcResult r = patchMe(access, bad);
            assertThat(r.getResponse().getStatus()).as("[" + bad + "]").isEqualTo(422);
            assertThat(body(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(patchMe(access, "ع".repeat(60)).getResponse().getStatus()).isEqualTo(200); // 60 Arabic letters
        assertThat(patchMe(access, "x").getResponse().getStatus()).isEqualTo(200);
    }

    @Test
    void protectedEndpointsRequireAToken() throws Exception {
        assertThat(mvc.perform(get("/api/v1/me")).andReturn().getResponse().getStatus()).isEqualTo(401);
    }

    // ---- schema invariants (they live in the database, not only in code) ------------------------------

    @Test
    void databaseRejectsBlankDisplayNamesAndSecondUserForTheSameSubject() throws Exception {
        String sub = newSub();
        login(sub);
        assertThatThrownBy(() -> jdbc.update(
                "insert into users (id, auth_provider, auth_subject, display_name) values (?, 'GOOGLE', ?, ?)",
                UUID.randomUUID(), sub, "Other")).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(
                "insert into users (id, auth_provider, auth_subject, display_name) values (?, 'GOOGLE', ?, '   ')",
                UUID.randomUUID(), newSub())).isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(
                "insert into users (id, auth_provider, auth_subject, display_name) values (?, 'FACEBOOK', ?, 'x')",
                UUID.randomUUID(), newSub())).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsMalformedRefreshTokenRows() throws Exception {
        String userId = login(newSub()).get("user").get("id").asText();
        assertThatThrownBy(() -> jdbc.update(
                "insert into refresh_tokens (id, user_id, family_id, token_hash, expires_at) "
                        + "values (?, ?::uuid, ?, ?, now() + interval '1 day')",
                UUID.randomUUID(), userId, UUID.randomUUID(), new byte[] {1, 2, 3}))
                .isInstanceOf(DataIntegrityViolationException.class); // hash must be 32 bytes
        assertThatThrownBy(() -> jdbc.update(
                "update refresh_tokens set replaced_by_id = id where user_id = ?::uuid", userId))
                .isInstanceOf(DataIntegrityViolationException.class); // cannot replace itself
    }

    // ---- logging: no secrets, but the events are there --------------------------------------------------

    @Test
    void logsContainAuthEventsButNeverTokensOrAuthorizationHeaders() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        List<String> secrets = new ArrayList<>();
        String sub = newSub();
        try {
            JsonNode session = login(sub);
            String access = session.get("accessToken").asText();
            String r1 = session.get("refreshToken").asText();
            secrets.add(access);
            secrets.add(r1);
            getMe(access);
            String r2 = body(refresh(r1)).get("refreshToken").asText();
            secrets.add(r2);
            refresh(r1);            // reuse -> family revoked
            logout(r2);
            postJson("/api/v1/auth/google", "{\"idToken\":\"bogus-google-token-value\"}");
            secrets.add("bogus-google-token-value");
        } finally {
            root.detachAppender(appender);
        }

        StringBuilder everything = new StringBuilder();
        List<String> events = new ArrayList<>();
        for (ILoggingEvent e : new ArrayList<>(appender.list)) {
            everything.append(e.getFormattedMessage()).append('\n').append(e.getMDCPropertyMap()).append('\n');
            if (e.getKeyValuePairs() != null) {
                e.getKeyValuePairs().forEach(kv -> {
                    everything.append(kv.key).append('=').append(kv.value).append('\n');
                    if ("event".equals(kv.key)) {
                        events.add(String.valueOf(kv.value));
                    }
                });
            }
            if (e.getThrowableProxy() != null) {
                everything.append(e.getThrowableProxy().getMessage()).append('\n');
            }
        }
        String logs = everything.toString();

        for (String secret : secrets) {
            assertThat(logs).as("log output must not contain a token").doesNotContain(secret);
        }
        assertThat(logs).doesNotContain("Bearer ").doesNotContain("Authorization").doesNotContain(sub + "@example.com");
        assertThat(events).contains("auth.login", "auth.refresh", "auth.refresh.reuse_detected", "auth.logout",
                "auth.login.failed");
    }
}
