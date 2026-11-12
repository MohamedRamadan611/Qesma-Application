package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

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

/**
 * B11: the invite code is a secret (the capability to join). Whatever the application does with it, no log event of
 * any logger of ours may contain it: creation, preview, join, approval, failures and replays.
 *
 * <p>Known limit: Spring Security's own DEBUG line "Securing GET /api/v1/invites/CODE" prints the request path, so
 * its level must stay at INFO (the default); a reverse proxy that logs request paths would also show codes.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "logging.level.app.qesma=DEBUG")
class InviteLogsIT extends AbstractApiIT {

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
    void theInviteCodeNeverReachesAnyAppLog() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Level before = root.getLevel();
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        List<String> secrets = new ArrayList<>();
        try {
            Session owner = newUser();
            String gid = createGroup(owner, "Logs " + UUID.randomUUID()).get("id").asText();
            String ghost = addMember(owner, gid, "Ghost").get("id").asText();
            String g = "/api/v1/groups/" + gid;

            JsonNode invite = body(call(POST, g + "/invites", owner, Map.of("requiresApproval", false), "Idempotency-Key",
                    UUID.randomUUID().toString()));
            String code = invite.get("code").asText();
            secrets.add(code);
            secrets.add(code.substring(0, 4) + "-" + code.substring(4));
            secrets.add(invite.get("link").asText());
            JsonNode approval = body(call(POST, g + "/invites", owner, Map.of("requiresApproval", true), "Idempotency-Key",
                    UUID.randomUUID().toString()));
            String approvalCode = approval.get("code").asText();
            secrets.add(approvalCode);

            Session joiner = newUser();
            String key = UUID.randomUUID().toString();
            call(GET, "/api/v1/invites/" + code, joiner, null);
            call(POST, "/api/v1/invites/" + code + "/join", joiner, Map.of("claimMemberId", ghost), "Idempotency-Key", key);
            call(POST, "/api/v1/invites/" + code + "/join", joiner, Map.of("claimMemberId", ghost), "Idempotency-Key", key);   // replay
            call(POST, "/api/v1/invites/" + code + "/join", joiner, Map.of("newMemberName", "Again"),
                    "Idempotency-Key", UUID.randomUUID().toString());                                                          // already member
            call(GET, "/api/v1/invites/ZZZZZZZZ", joiner, null);                                                               // unknown
            Session asker = newUser();
            String rid = body(call(POST, "/api/v1/invites/" + approvalCode + "/join", asker, Map.of("newMemberName", "Asks"),
                    "Idempotency-Key", UUID.randomUUID().toString())).get("requestId").asText();
            call(POST, g + "/join-requests/" + rid + "/approve", owner, null);
            call(DELETE, g + "/invites/" + invite.get("id").asText(), owner, null);
            call(GET, "/api/v1/invites/" + code, newUser(), null);                                                             // revoked
            call(GET, g + "/invites", owner, null);
        } finally {
            root.detachAppender(appender);
            root.setLevel(before);
        }

        List<ILoggingEvent> events = new ArrayList<>(appender.list);
        assertThat(events).as("the flow produced log events to inspect").hasSizeGreaterThan(10);
        assertThat(events.stream().map(ILoggingEvent::getFormattedMessage)).as("our own events were logged")
                .anyMatch(m -> m.startsWith("invite.created")).anyMatch(m -> m.startsWith("join.joined"))
                .anyMatch(m -> m.startsWith("invite.lookup_failed")).anyMatch(m -> m.startsWith("join.decided"));
        for (ILoggingEvent event : events) {
            String text = everything(event);
            for (String secret : secrets) {
                assertThat(text).as("the code leaked through logger " + event.getLoggerName() + ": " + event.getFormattedMessage())
                        .doesNotContain(secret);
            }
        }
    }
}
