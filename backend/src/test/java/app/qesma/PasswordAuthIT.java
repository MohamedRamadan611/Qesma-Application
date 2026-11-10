package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import app.qesma.service.MailSender;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.core.read.ListAppender;
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
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
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
 * Username + password sign-in (ADR-007, ADR-008) against real PostgreSQL: the round trip, the account rules, the failure answers,
 * lockout, change/reset/verify, concurrency, and the promise that no credential reaches the logs. The clock and the mail
 * sender are replaced by test doubles so expiry and "what would have been emailed" can be checked.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {"logging.level.app.qesma=DEBUG", "logging.level.org.springframework.security=DEBUG",
        "logging.level.org.hibernate.SQL=DEBUG"})
@Import(PasswordAuthIT.Doubles.class)
class PasswordAuthIT extends AbstractApiIT {

    /** A clock that tests can move forward. */
    static final class MutableClock extends Clock {
        private final AtomicReference<Instant> now = new AtomicReference<>(Instant.now());

        void advance(Duration d) {
            now.updateAndGet(i -> i.plus(d));
        }

        void reset() {
            now.set(Instant.now());
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
            return now.get();
        }
    }

    /** Records what would have been emailed. */
    static final class RecordingMailSender implements MailSender {
        record Mail(String kind, String to, String link) {
        }

        final List<Mail> sent = new CopyOnWriteArrayList<>();

        @Override
        public void sendVerification(String to, String link) {
            sent.add(new Mail("verification", to, link));
        }

        @Override
        public void sendPasswordReset(String to, String link) {
            sent.add(new Mail("reset", to, link));
        }

        List<Mail> to(String email, String kind) {
            return sent.stream().filter(m -> m.to().equals(email) && m.kind().equals(kind)).toList();
        }

        String lastToken(String email, String kind) {
            List<Mail> mails = to(email, kind);
            assertThat(mails).as("mails of kind " + kind + " to " + email).isNotEmpty();
            String link = mails.get(mails.size() - 1).link();
            return link.substring(link.indexOf("token=") + "token=".length());
        }
    }

    @TestConfiguration
    static class Doubles {
        @Bean
        @Primary
        MutableClock testClock() {
            return new MutableClock();
        }

        @Bean
        @Primary
        RecordingMailSender recordingMailSender() {
            return new RecordingMailSender();
        }
    }

    @Autowired MutableClock clock;
    @Autowired RecordingMailSender mails;

    @AfterEach
    void putTheClockBack() {
        clock.reset();
    }

    // ---- helpers ------------------------------------------------------------------------------------------

    private static final String PASSWORD = "correct horse battery";

    private static String newName() {
        return "user-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private MvcResult register(String username, String password) throws Exception {
        return call(POST, "/api/v1/auth/register", null, Map.of("username", username, "password", password));
    }

    private MvcResult login(String username, String password) throws Exception {
        return call(POST, "/api/v1/auth/login", null, Map.of("username", username, "password", password));
    }

    /** Recovery by email is on hold, so no account has an address; tests of the emailed links give one directly. */
    private void attachEmail(String username, String email) {
        jdbc.update("update users set email = ? where auth_provider = 'PASSWORD' and auth_subject = ?", email, username);
    }

    private JsonNode registered(String username) throws Exception {
        MvcResult r = register(username, PASSWORD);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(201);
        return body(r);
    }

    private Session sessionOf(JsonNode auth) {
        return new Session(auth.get("accessToken").asText(), UUID.fromString(auth.get("user").get("id").asText()));
    }

    private MvcResult refresh(String raw) throws Exception {
        return call(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", raw));
    }

    private int countUsers(String username) {
        return jdbc.queryForObject("select count(*) from users where auth_provider = 'PASSWORD' and auth_subject = ?", Integer.class, username.toLowerCase());
    }

    // ---- the round trip -----------------------------------------------------------------------------------

    @Test
    void registerLoginRefreshLogoutAndTheNewUserOwnsItsGroups() throws Exception {
        String name = newName();
        JsonNode created = registered("  " + name.toUpperCase() + " ");
        assertThat(created.get("user").get("username").asText()).isEqualTo(name);
        assertThat(created.get("user").get("email").isNull()).as("no email is collected").isTrue();
        assertThat(created.get("user").get("hasPassword").asBoolean()).isTrue();
        assertThat(created.get("user").get("emailVerified").asBoolean()).isFalse();
        assertThat(created.get("user").get("displayName").asText()).isEqualTo(name);
        assertThat(created.get("accessToken").asText()).isNotBlank();
        assertThat(created.get("refreshToken").asText()).isNotBlank();

        MvcResult in = login(" " + name + " ", PASSWORD);
        assertThat(status(in)).isEqualTo(200);
        assertThat(body(in).get("user").get("id").asText()).isEqualTo(created.get("user").get("id").asText());
        assertThat(status(login(name.toUpperCase(), PASSWORD))).as("case does not matter").isEqualTo(200);
        Session me = sessionOf(body(in));
        assertThat(status(call(GET, "/api/v1/me", me, null))).isEqualTo(200);

        MvcResult refreshed = refresh(body(in).get("refreshToken").asText());
        assertThat(status(refreshed)).isEqualTo(200);
        assertThat(status(call(POST, "/api/v1/auth/logout", null,
                Map.of("refreshToken", body(refreshed).get("refreshToken").asText())))).isEqualTo(204);

        // Authorization is unchanged: a password user owns its groups, and another user sees 404 (never 403).
        JsonNode group = createGroup(me, "Password trip");
        Session other = newUser();
        assertThat(status(call(GET, "/api/v1/groups/" + group.get("id").asText(), other, null))).isEqualTo(404);
        assertThat(status(call(GET, "/api/v1/groups/" + group.get("id").asText(), me, null))).isEqualTo(200);
    }

    @Test
    void googleUsersHaveNoPasswordAndAreVerified() throws Exception {
        Session google = newUser();
        JsonNode me = body(call(GET, "/api/v1/me", google, null));
        assertThat(me.get("hasPassword").asBoolean()).isFalse();
        assertThat(me.get("emailVerified").asBoolean()).isTrue();
    }

    @Test
    void thePasswordIsStoredOnlyAsASaltedHash() throws Exception {
        String a = newName();
        String b = newName();
        registered(a);
        registered(b);
        List<String> hashes = jdbc.queryForList("""
                select p.password_hash from user_passwords p join users u on u.id = p.user_id
                where u.auth_subject in (?, ?)""", String.class, a, b);
        assertThat(hashes).hasSize(2).allMatch(h -> h.startsWith("{bcrypt}") && !h.contains(PASSWORD));
        assertThat(hashes.get(0)).as("two users with one password get different hashes").isNotEqualTo(hashes.get(1));
    }

    @Test
    void aUsernameIsOneAccountWhateverItsCaseAndTheSamePasswordIsAnIdempotentRetry() throws Exception {
        String name = newName();
        JsonNode first = registered(name);

        MvcResult retry = register(" " + name.toUpperCase() + " ", PASSWORD);
        assertThat(status(retry)).as("a lost-reply retry with the same password signs in").isEqualTo(201);
        assertThat(body(retry).get("user").get("id").asText()).isEqualTo(first.get("user").get("id").asText());

        MvcResult other = register(name, "another correct password");
        assertThat(status(other)).isEqualTo(409);
        assertThat(code(other)).isEqualTo("USERNAME_TAKEN");
        assertThat(countUsers(name)).isEqualTo(1);
    }

    @Test
    void parallelRegistrationsOfOneEmailCreateExactlyOneAccount() throws Exception {
        String email = newName();
        ExecutorService pool = Executors.newFixedThreadPool(8);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            String password = i % 2 == 0 ? PASSWORD : "a different strong password " + i;
            Callable<MvcResult> call = () -> {
                go.await();
                return register(email, password);
            };
            futures.add(pool.submit(call));
        }
        go.countDown();
        int created = 0;
        int conflicts = 0;
        for (Future<MvcResult> f : futures) {
            int s = status(f.get());
            if (s == 201) {
                created++;
            } else {
                assertThat(s).isEqualTo(409);
                conflicts++;
            }
        }
        pool.shutdown();
        assertThat(countUsers(email)).isEqualTo(1);
        assertThat(created).as("at least the winner is accepted").isGreaterThanOrEqualTo(1);
        assertThat(created + conflicts).isEqualTo(8);
    }

    @Test
    void registeringOverAnExistingNameIsAPasswordCheckLikeAnyOther() throws Exception {
        String name = newName();
        registered(name);

        for (int i = 0; i < 5; i++) {
            assertThat(status(register(name, "wrong passphrase " + i))).as("a wrong password is refused").isEqualTo(409);
        }
        MvcResult locked = register(name, PASSWORD);
        assertThat(status(locked)).as("five failures through register lock the account: even the right password is refused").isEqualTo(409);
        assertThat(code(locked)).isEqualTo("USERNAME_TAKEN");
        assertThat(status(login(name, PASSWORD))).as("and sign-in is locked too").isEqualTo(401);

        clock.advance(Duration.ofMinutes(16));
        assertThat(status(register(name, PASSWORD))).as("the lock ended; the owner retrying is signed in").isEqualTo(201);
    }

    @Test
    void usernamesFollowTheirRules() throws Exception {
        Map<String, Integer> cases = new java.util.LinkedHashMap<>();
        cases.put("ab", 422);                       // too short
        cases.put("abc", 201);                      // 3: accepted
        cases.put("a".repeat(30), 201);             // 30: accepted
        cases.put("a".repeat(31), 422);
        cases.put("has space", 422);
        cases.put("a@b.com", 422);                  // never an email address
        cases.put("admin", 422);                    // reserved
        cases.put(".leading", 422);
        cases.put("trailing.", 422);
        cases.put("علي_حسن", 201);                  // Arabic letters are fine
        cases.put("Ali.H-9_x", 201);
        cases.put("emoji😀name", 422);
        cases.forEach((username, expected) -> {
            try {
                String unique = expected == 201 ? (username.length() >= 30 ? username.substring(0, 20) + UUID.randomUUID().toString().substring(0, 8) : username + UUID.randomUUID().toString().substring(0, 4)) : username;
                MvcResult r = register(expected == 201 && unique.length() > 30 ? unique.substring(0, 30) : unique, PASSWORD);
                assertThat(status(r)).as("username [" + username + "]").isEqualTo(expected);
                if (expected == 422) {
                    assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
                }
            } catch (Exception e) {
                throw new AssertionError(e);
            }
        });
    }

    @Test
    void aGoogleEmailDoesNotBlockAUsername() throws Exception {
        String name = newName();
        call(POST, "/api/v1/auth/google", null, Map.of("idToken", "fake:sub-" + UUID.randomUUID() + ":" + name + "@example.com:Googler"));
        assertThat(status(register(name, PASSWORD))).isEqualTo(201);
        assertThat(status(login(name + "@example.com", PASSWORD))).as("a Google account has no password to sign in with").isEqualTo(401);
    }

    @Test
    void thePasswordPolicyIsEnforced() throws Exception {
        String arabic36 = "ك".repeat(36);   // 36 letters = 72 bytes: the limit
        String arabic37 = "ك".repeat(37);   // 74 bytes
        Map<String, Integer> cases = new java.util.LinkedHashMap<>();
        cases.put("1234567", 422);                  // 7 characters
        cases.put("12345678", 422);                 // common
        cases.put("Password1", 422);                // common (case-insensitive)
        cases.put("        ", 422);                 // blank
        cases.put("abcdefgh", 201);                 // 8 characters: accepted
        cases.put("a".repeat(72), 201);             // 72 bytes: accepted
        cases.put("a".repeat(73), 422);             // 73 bytes
        cases.put(arabic36, 201);
        cases.put(arabic37, 422);
        cases.forEach((password, expected) -> {
            try {
                MvcResult r = register(newName(), password);
                assertThat(status(r)).as("password of %d chars".formatted(password.length())).isEqualTo(expected);
                if (expected == 422) {
                    assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
                    assertThat(r.getResponse().getContentAsString()).as("never echoes the password").doesNotContain(password.strip().isEmpty() ? "\u0000" : password);
                }
            } catch (Exception e) {
                throw new AssertionError(e);
            }
        });
        String own = newName();
        assertThat(status(register(own, own))).as("password equal to the username").isEqualTo(422);
        assertThat(status(register("a", PASSWORD))).isEqualTo(422);
        assertThat(status(register(newName(), PASSWORD + "x".repeat(300)))).as("request size bound").isEqualTo(422);
    }

    // ---- failure answers and lockout ----------------------------------------------------------------------

    @Test
    void everySignInFailureLooksTheSame() throws Exception {
        String email = newName();
        registered(email);
        String googleEmail = newName() + "@example.com";
        call(POST, "/api/v1/auth/google", null, Map.of("idToken", "fake:sub-" + UUID.randomUUID() + ":" + googleEmail + ":G"));

        List<MvcResult> failures = List.of(login(email, "wrong password!"), login(newName(), PASSWORD),
                login(googleEmail, PASSWORD), login("not a name", PASSWORD), login(email, "x".repeat(200)));
        for (MvcResult r : failures) {
            assertThat(status(r)).isEqualTo(401);
            assertThat(code(r)).isEqualTo("UNAUTHORIZED");
        }
        assertThat(failures.stream().map(r -> {
            try {
                JsonNode b = body(r);
                return b.get("title").asText() + "|" + b.path("detail").asText();
            } catch (Exception e) {
                throw new AssertionError(e);
            }
        }).distinct()).as("the cause is never disclosed").hasSize(1);
    }

    @Test
    void fiveFailuresLockTheAccountForFifteenMinutesAndASuccessResetsTheCounter() throws Exception {
        String email = newName();
        registered(email);

        for (int i = 0; i < 4; i++) {
            assertThat(status(login(email, "wrong password " + i))).isEqualTo(401);
        }
        assertThat(status(login(email, PASSWORD))).as("4 failures do not lock").isEqualTo(200);
        for (int i = 0; i < 4; i++) {
            assertThat(status(login(email, "wrong again " + i))).isEqualTo(401);
        }
        assertThat(status(login(email, PASSWORD))).as("the success reset the counter").isEqualTo(200);

        for (int i = 0; i < 5; i++) {
            login(email, "wrong " + i);
        }
        MvcResult locked = login(email, PASSWORD);
        assertThat(status(locked)).as("locked: even the right password is refused, with the same answer").isEqualTo(401);
        assertThat(code(locked)).isEqualTo("UNAUTHORIZED");

        clock.advance(Duration.ofMinutes(14));
        assertThat(status(login(email, PASSWORD))).isEqualTo(401);
        clock.advance(Duration.ofMinutes(2));
        assertThat(status(login(email, PASSWORD))).as("the lock ended").isEqualTo(200);
    }

    // ---- change password ----------------------------------------------------------------------------------

    @Test
    void changingThePasswordEndsOtherSessionsAndKeepsThisOne() throws Exception {
        String email = newName();
        JsonNode first = registered(email);
        JsonNode second = body(login(email, PASSWORD));          // another device
        Session me = sessionOf(second);

        MvcResult wrong = call(POST, "/api/v1/me/password", me, Map.of("currentPassword", "not my password", "newPassword", "a brand new passphrase"));
        assertThat(status(wrong)).as("a wrong current password is a validation error, not a session 401").isEqualTo(422);
        assertThat(status(call(GET, "/api/v1/me", me, null))).as("the session continues").isEqualTo(200);

        MvcResult weak = call(POST, "/api/v1/me/password", me, Map.of("currentPassword", PASSWORD, "newPassword", "password1"));
        assertThat(status(weak)).isEqualTo(422);

        MvcResult changed = call(POST, "/api/v1/me/password", me, Map.of("currentPassword", PASSWORD, "newPassword", "a brand new passphrase"));
        assertThat(status(changed)).isEqualTo(200);
        assertThat(status(refresh(body(changed).get("refreshToken").asText()))).as("this session got fresh tokens").isEqualTo(200);
        assertThat(status(refresh(first.get("refreshToken").asText()))).as("the other session ended").isEqualTo(401);
        assertThat(status(refresh(second.get("refreshToken").asText()))).isEqualTo(401);
        assertThat(status(login(email, PASSWORD))).isEqualTo(401);
        assertThat(status(login(email, "a brand new passphrase"))).isEqualTo(200);
    }

    @Test
    void aGoogleAccountCannotChangeAPassword() throws Exception {
        Session google = newUser();
        MvcResult r = call(POST, "/api/v1/me/password", google, Map.of("currentPassword", PASSWORD, "newPassword", "a brand new passphrase"));
        assertThat(status(r)).isEqualTo(422);
        assertThat(status(call(POST, "/api/v1/me/password", null, Map.of("currentPassword", PASSWORD, "newPassword", "a brand new passphrase")))).isEqualTo(401);
    }

    // ---- forgot / reset -----------------------------------------------------------------------------------

    @Test
    void forgotPasswordAlwaysAnswers204AndOnlyEmailsRealAccounts() throws Exception {
        String name = newName();
        String email = name + "@example.com";
        registered(name);
        attachEmail(name, email);
        String unknown = newName() + "@example.com";

        assertThat(status(call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", unknown)))).isEqualTo(204);
        assertThat(status(call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", "garbage")))).isEqualTo(204);
        assertThat(mails.to(unknown, "reset")).isEmpty();

        assertThat(status(call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", " " + email.toUpperCase())))).isEqualTo(204);
        assertThat(mails.to(email, "reset")).hasSize(1);
    }

    @Test
    void aResetLinkWorksOnceEndsEverySessionAndAWeakPasswordDoesNotUseItUp() throws Exception {
        String name = newName();
        String email = name + "@example.com";
        JsonNode session = registered(name);
        attachEmail(name, email);
        call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", email));
        String token = mails.lastToken(email, "reset");

        MvcResult weak = call(POST, "/api/v1/auth/password/reset", null, Map.of("token", token, "newPassword", "12345678"));
        assertThat(status(weak)).isEqualTo(422);
        MvcResult asEmail = call(POST, "/api/v1/auth/password/reset", null, Map.of("token", token, "newPassword", email));
        assertThat(status(asEmail)).as("refused after the link was read, so the link must still be usable").isEqualTo(422);

        MvcResult ok = call(POST, "/api/v1/auth/password/reset", null, Map.of("token", token, "newPassword", "my fresh passphrase"));
        assertThat(status(ok)).isEqualTo(204);
        assertThat(status(call(POST, "/api/v1/auth/password/reset", null, Map.of("token", token, "newPassword", "yet another passphrase")))).as("replay").isEqualTo(422);
        assertThat(status(refresh(session.get("refreshToken").asText()))).as("every session ended").isEqualTo(401);
        assertThat(status(login(name, PASSWORD))).isEqualTo(401);
        MvcResult in = login(name, "my fresh passphrase");
        assertThat(status(in)).isEqualTo(200);
        assertThat(body(in).get("user").get("emailVerified").asBoolean()).as("the link proved the address").isTrue();
    }

    @Test
    void resetLinksExpireAndANewLinkReplacesTheOldOne() throws Exception {
        String name = newName();
        String email = name + "@example.com";
        registered(name);
        attachEmail(name, email);
        call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", email));
        String old = mails.lastToken(email, "reset");
        call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", email));
        String fresh = mails.lastToken(email, "reset");
        assertThat(fresh).isNotEqualTo(old);
        assertThat(status(call(POST, "/api/v1/auth/password/reset", null, Map.of("token", old, "newPassword", "my fresh passphrase")))).isEqualTo(422);

        clock.advance(Duration.ofMinutes(31));
        assertThat(status(call(POST, "/api/v1/auth/password/reset", null, Map.of("token", fresh, "newPassword", "my fresh passphrase")))).as("expired").isEqualTo(422);
        assertThat(status(call(POST, "/api/v1/auth/password/reset", null, Map.of("token", "unknown-token", "newPassword", "my fresh passphrase")))).isEqualTo(422);
    }

    @Test
    void parallelUsesOfOneResetLinkSucceedExactlyOnce() throws Exception {
        String name = newName();
        String email = name + "@example.com";
        registered(name);
        attachEmail(name, email);
        call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", email));
        String token = mails.lastToken(email, "reset");
        ExecutorService pool = Executors.newFixedThreadPool(6);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            String password = "passphrase number " + i;
            futures.add(pool.submit(() -> {
                go.await();
                return call(POST, "/api/v1/auth/password/reset", null, Map.of("token", token, "newPassword", password));
            }));
        }
        go.countDown();
        int ok = 0;
        for (Future<MvcResult> f : futures) {
            int s = status(f.get());
            assertThat(s).isIn(204, 422);
            if (s == 204) {
                ok++;
            }
        }
        pool.shutdown();
        assertThat(ok).isEqualTo(1);
    }

    // ---- verify the address -------------------------------------------------------------------------------

    @Test
    void theVerificationLinkWorksOnceAndResendReplacesIt() throws Exception {
        String name = newName();
        String email = name + "@example.com";
        JsonNode auth = registered(name);
        Session me = sessionOf(auth);
        assertThat(mails.sent).as("registering sends no email").noneMatch(m -> m.to().equals(email));

        assertThat(status(call(POST, "/api/v1/auth/email/verify/resend", me, null))).as("no address on file: nothing to send").isEqualTo(204);
        assertThat(mails.to(email, "verification")).isEmpty();
        attachEmail(name, email);

        assertThat(status(call(POST, "/api/v1/auth/email/verify/resend", null, null))).as("needs a session").isEqualTo(401);
        assertThat(status(call(POST, "/api/v1/auth/email/verify/resend", me, null))).isEqualTo(204);
        String first = mails.lastToken(email, "verification");
        assertThat(status(call(POST, "/api/v1/auth/email/verify/resend", me, null))).isEqualTo(204);
        String second = mails.lastToken(email, "verification");
        assertThat(second).isNotEqualTo(first);
        assertThat(status(call(POST, "/api/v1/auth/email/verify", null, Map.of("token", first)))).as("replaced").isEqualTo(422);

        assertThat(status(call(POST, "/api/v1/auth/email/verify", null, Map.of("token", second)))).isEqualTo(204);
        assertThat(body(call(GET, "/api/v1/me", me, null)).get("emailVerified").asBoolean()).isTrue();
        assertThat(status(call(POST, "/api/v1/auth/email/verify", null, Map.of("token", second)))).as("replay").isEqualTo(422);

        int before = mails.sent.size();
        assertThat(status(call(POST, "/api/v1/auth/email/verify/resend", me, null))).isEqualTo(204);
        assertThat(mails.sent).as("nothing to send once verified").hasSize(before);
    }

    @Test
    void credentialCarryingRequestsRedactThemselves() {
        String secret = "super-secret-value";
        assertThat(new app.qesma.api.PasswordAuthController.RegisterRequest("someone", secret, "n").toString()).doesNotContain(secret).doesNotContain("someone");
        assertThat(new app.qesma.api.PasswordAuthController.LoginRequest("someone", secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.PasswordAuthController.ForgotPasswordRequest("a@b.com").toString()).doesNotContain("a@b.com");
        assertThat(new app.qesma.api.PasswordAuthController.ResetPasswordRequest(secret, secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.PasswordAuthController.VerifyEmailRequest(secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.MeController.ChangePasswordRequest(secret, secret).toString()).doesNotContain(secret);
    }

    private static String everything(ILoggingEvent e) {
        StringBuilder sb = new StringBuilder(e.getFormattedMessage()).append('\n').append(e.getMDCPropertyMap());
        if (e.getKeyValuePairs() != null) {
            e.getKeyValuePairs().forEach(kv -> sb.append('\n').append(kv.key).append('=').append(kv.value));
        }
        for (IThrowableProxy t = e.getThrowableProxy(); t != null; t = t.getCause()) {
            sb.append('\n').append(t.getClassName()).append(':').append(t.getMessage());
        }
        return sb.toString();
    }

    @Test
    void noPasswordUsernameEmailTokenOrLinkReachesTheLogs() throws Exception {
        String tag = UUID.randomUUID().toString().substring(0, 8);
        String username = "leak-" + tag;
        String email = username + "@example.com";
        String password = "Pw-" + tag + "-secret passphrase";
        String newPassword = "NewPw-" + tag + "-secret passphrase";
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        List<String> secrets = new ArrayList<>(List.of(username, email, password, newPassword));
        try {
            JsonNode auth = body(register(username, password));
            secrets.add(auth.get("accessToken").asText());
            secrets.add(auth.get("refreshToken").asText());
            attachEmail(username, email);
            call(POST, "/api/v1/auth/email/verify/resend", sessionOf(auth), null);
            secrets.add(mails.lastToken(email, "verification"));
            login(username, "wrong " + password);
            login(username, password);
            call(POST, "/api/v1/auth/password/forgot", null, Map.of("email", email));
            String resetToken = mails.lastToken(email, "reset");
            secrets.add(resetToken);
            call(POST, "/api/v1/auth/password/reset", null, Map.of("token", resetToken, "newPassword", newPassword));
            call(POST, "/api/v1/auth/email/verify", null, Map.of("token", "bogus-" + tag));
            for (int i = 0; i < 6; i++) {
                login(username, "wrong " + i + password);   // reaches the lockout
            }
        } finally {
            root.detachAppender(appender);
        }
        assertThat(appender.list).as("something was logged").isNotEmpty();
        for (ILoggingEvent event : appender.list) {
            String text = everything(event);
            for (String secret : secrets) {
                assertThat(text).as("log event from " + event.getLoggerName()).doesNotContain(secret);
            }
        }
    }
}
