package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Invariant 10 (AGENTS.md): never log Authorization headers, tokens or personal data beyond ids. A full flow with
 * recognizable secrets runs at the most verbose levels; nothing recognizable may appear in any log event (message,
 * arguments, key-values, MDC or exception text) from any logger.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = {"logging.level.app.qesma=DEBUG",
        "logging.level.org.springframework.security=DEBUG", "logging.level.org.hibernate.SQL=DEBUG"})
class NoSensitiveDataInLogsIT extends AbstractApiIT {

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

    /** Frameworks print request and response objects when a log level is raised: credentials must not be readable. */
    @Test
    void credentialCarryingObjectsRedactThemselvesInToString() {
        String secret = "super-secret-value";
        assertThat(new app.qesma.api.AuthController.GoogleLoginRequest(secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.AuthController.RefreshRequest(secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.AuthController.TokenResponse(secret, secret).toString()).doesNotContain(secret);
        assertThat(new app.qesma.api.AuthController.AuthResponse(secret, secret, null).toString())
                .doesNotContain(secret);
    }

    @Test
    void secretsAndPersonalDataNeverReachTheLogs() throws Exception {
        String tag = UUID.randomUUID().toString().substring(0, 8);
        String subject = "subj-" + tag;
        String email = "leak-" + tag + "@example.com";
        String displayName = "Zebra" + tag;
        String idToken = "fake:" + subject + ":" + email + ":" + displayName;
        String title = "Title-" + tag;
        String itemName = "Item-" + tag;
        String note = "Note-" + tag;
        String memberA = "MemA" + tag;
        String memberB = "MemB" + tag;
        String groupName = "Grp" + tag;

        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Level before = root.getLevel();
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        List<String> secrets = new ArrayList<>(List.of(subject, email, displayName, title, itemName, note, memberA,
                memberB, groupName, idToken));
        try {
            MvcResult login = mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                    .post("/api/v1/auth/google").contentType("application/json")
                    .content("{\"idToken\":\"" + idToken + "\"}")).andReturn();
            JsonNode auth = json.readTree(login.getResponse().getContentAsString());
            String access = auth.get("accessToken").asText();
            String refresh = auth.get("refreshToken").asText();
            secrets.addAll(List.of(access, refresh, "Bearer " + access));
            Session me = new Session(access, UUID.fromString(auth.get("user").get("id").asText()));

            call(PATCH, "/api/v1/me", me, Map.of("displayName", displayName + "2"));
            secrets.add(displayName + "2");
            String gid = createGroup(me, groupName).get("id").asText();
            String a = addMember(me, gid, memberA).get("id").asText();
            String b = addMember(me, gid, memberB).get("id").asText();
            JsonNode expense = createExpense(me, gid, equalBody(title, 3000, null, a, 3000L));
            String eid = expense.get("id").asText();
            call(PUT, "/api/v1/groups/" + gid + "/expenses/" + eid, me, equalBody(title + "x", 4000, null, b, 4000L),
                    "If-Match", "\"1\"");
            secrets.add(title + "x");
            Map<String, Object> bill = Map.of("title", title, "expenseDate", "2026-10-18", "splitType", "ITEMIZED",
                    "payers", List.of(Map.of("memberId", a, "amountMinor", 1000L)),
                    "items", List.of(Map.of("name", itemName, "amountMinor", 1000L, "assigneeMemberIds", List.of(a))));
            createExpense(me, gid, bill);
            call(POST, "/api/v1/groups/" + gid + "/expenses/preview", me, bill);
            call(POST, "/api/v1/groups/" + gid + "/settlements", me,
                    Map.of("fromMemberId", a, "toMemberId", b, "amountMinor", 500L, "settledOn", "2026-10-20",
                            "note", note), "Idempotency-Key", UUID.randomUUID().toString());
            call(GET, "/api/v1/groups/" + gid + "/balances", me, null);
            call(GET, "/api/v1/groups/" + gid + "/expenses/" + eid + "/revisions", me, null);
            // failures: bad bodies, other users, bad and stale tokens
            call(POST, "/api/v1/groups", me, Map.of("name", " ", "type", "TRIP"));
            call(POST, "/api/v1/groups/" + gid + "/expenses", me, equalBody(title + "bad", 10, null, a, 5L),
                    "Idempotency-Key", UUID.randomUUID().toString());
            Session stranger = newUser();
            call(GET, "/api/v1/groups/" + gid, stranger, null);
            call(DELETE, "/api/v1/groups/" + gid + "/expenses/" + eid, stranger, null, "If-Match", "\"1\"");
            call(GET, "/api/v1/groups", new Session(access + "tampered", me.userId()), null);
            call(POST, "/api/v1/auth/google", null, "{\"idToken\":\"fake:evil:" + email + ":x\"}");
            call(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", refresh));
            call(POST, "/api/v1/auth/refresh", null, Map.of("refreshToken", refresh));        // reuse: family revoked
            call(POST, "/api/v1/auth/logout", null, Map.of("refreshToken", refresh));
        } finally {
            root.detachAppender(appender);
            root.setLevel(before);
        }

        List<ILoggingEvent> events = new ArrayList<>(appender.list);
        assertThat(events).as("the flow produced log events to inspect").hasSizeGreaterThan(30);
        for (ILoggingEvent event : events) {
            String text = everything(event);
            for (String secret : secrets) {
                assertThat(text).as("secret leaked by logger " + event.getLoggerName() + ": " + event.getFormattedMessage())
                        .doesNotContain(secret);
            }
            assertThat(text.toLowerCase()).as("logger " + event.getLoggerName()).doesNotContain("authorization:")
                    .doesNotContain("bearer ey");
        }
    }
}
