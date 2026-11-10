package app.qesma.service;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Fails startup if the console mail sender (which prints credentials) is combined with the production profile. */
@Component
@Profile("dev-mail & prod")
public class DevMailProdGuard {

    public DevMailProdGuard() {
        throw new IllegalStateException("The 'dev-mail' profile must never be active together with 'prod'");
    }
}
