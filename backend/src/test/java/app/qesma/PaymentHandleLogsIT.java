package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.core.read.ListAppender;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

/**
 * B14 / A92: handle values are personal data and never reach any log event of ours: set, replace, remove, validation
 * failures, malformed bodies, balances reads (allowed and denied), at DEBUG level.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "logging.level.app.qesma=DEBUG")
class PaymentHandleLogsIT extends AbstractHandlesIT {

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
    void theHandleValuesNeverReachAnyAppLog() throws Exception {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Level before = root.getLevel();
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        root.addAppender(appender);
        List<String> secrets = new ArrayList<>(List.of(INSTAPAY, WALLET, "otherhandle@otherbank", "01155443322",
                "badvalue-no-at", "0131234567x", "leaked@malformed"));
        try {
            Scenario s = scenario();                                                         // sets INSTAPAY / WALLET
            String url = "/api/v1/me/payment-handles";
            call(PUT, url, s.receiver(), Map.of("instapay", "otherhandle@otherbank", "wallet", "01155443322"));   // replace
            call(PUT, url, s.receiver(), Map.of("instapay", INSTAPAY, "wallet", WALLET));                          // back
            call(PUT, url, s.receiver(), Map.of("instapay", "badvalue-no-at", "wallet", "01012345678"));           // 422
            call(PUT, url, s.receiver(), Map.of("instapay", "ok@bank", "wallet", "0131234567x"));                  // 422
            call(PUT, url, s.receiver(), "{\"instapay\": \"leaked@malformed\", \"wallet\": ");                     // 400
            call(GET, url, s.receiver(), null);
            call(GET, url, null, null);                                                                           // 401
            balances(s.payer(), s.gid());                                                                         // shown
            balances(s.member(), s.gid());                                                                        // hidden
            call(GET, "/api/v1/groups/" + s.gid() + "/balances", newUser(), null);                                // 404
            call(PUT, url, s.receiver(), "{}");                                                                   // remove
        } finally {
            root.detachAppender(appender);
            root.setLevel(before);
        }

        List<ILoggingEvent> events = new ArrayList<>(appender.list);
        assertThat(events).as("the flow produced log events to inspect").hasSizeGreaterThan(10);
        assertThat(events.stream().map(ILoggingEvent::getFormattedMessage)).as("our own event was logged")
                .anyMatch(m -> m.startsWith("payment_handles.updated"));
        for (ILoggingEvent event : events) {
            String text = everything(event);
            for (String secret : secrets) {
                assertThat(text).as("log event of " + event.getLoggerName()).doesNotContain(secret);
            }
        }
    }
}
