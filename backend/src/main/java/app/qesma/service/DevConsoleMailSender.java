package app.qesma.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * DEVELOPMENT ONLY ({@code dev-mail} profile): prints the link so a developer can click it. The link is a credential, so
 * {@link DevMailProdGuard} refuses to start with {@code prod}.
 */
@Component
@Profile("dev-mail")
public class DevConsoleMailSender implements MailSender {

    private static final Logger log = LoggerFactory.getLogger(DevConsoleMailSender.class);

    @Override
    public void sendVerification(String to, String link) {
        log.warn("DEV MAIL (not sent) verification for {}: {}", to, link);
    }

    @Override
    public void sendPasswordReset(String to, String link) {
        log.warn("DEV MAIL (not sent) password reset for {}: {}", to, link);
    }
}
