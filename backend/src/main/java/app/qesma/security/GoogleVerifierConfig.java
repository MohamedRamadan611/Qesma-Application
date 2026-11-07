package app.qesma.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/** Wires the real Google verifier unless the local-only {@code fake-auth} profile is active. */
@Configuration
public class GoogleVerifierConfig {

    @Bean
    @Profile("!fake-auth")
    GoogleIdTokenVerifier googleIdTokenVerifier(AuthProperties props) {
        return NimbusGoogleIdTokenVerifier.forJwkSetUri(props.googleJwkSetUri(), props.googleClientIds());
    }
}
