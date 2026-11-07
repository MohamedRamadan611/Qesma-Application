package app.qesma.security;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Fails startup if the fake Google verifier is ever combined with the production profile. */
@Component
@Profile("fake-auth & prod")
public class FakeAuthProdGuard {

    public FakeAuthProdGuard() {
        throw new IllegalStateException("The 'fake-auth' profile must never be active together with 'prod'");
    }
}
