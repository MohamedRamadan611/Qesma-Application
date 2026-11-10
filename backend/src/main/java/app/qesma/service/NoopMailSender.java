package app.qesma.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Default sender until a mail provider is configured: nothing is sent, and nothing sensitive is logged. */
@Component
@Profile("!dev-mail")
public class NoopMailSender implements MailSender {

    private static final Logger log = LoggerFactory.getLogger(NoopMailSender.class);

    @Override
    public void sendVerification(String to, String link) {
        log.atWarn().addKeyValue("event", "mail.not_configured").addKeyValue("kind", "verification")
                .log("mail.not_configured kind=verification (no mail provider is configured, nothing was sent)");
    }

    @Override
    public void sendPasswordReset(String to, String link) {
        log.atWarn().addKeyValue("event", "mail.not_configured").addKeyValue("kind", "password_reset")
                .log("mail.not_configured kind=password_reset (no mail provider is configured, nothing was sent)");
    }
}
