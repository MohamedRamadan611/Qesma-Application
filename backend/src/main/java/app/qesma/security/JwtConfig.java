package app.qesma.security;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.time.Clock;
import javax.crypto.SecretKey;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

/** Our own access tokens: HS256 JWTs signed with a key from the environment. */
@Configuration
public class JwtConfig {

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }

    @Bean
    SecretKey accessTokenKey(AuthProperties props) {
        return JwtKeys.fromBase64(props.jwtSecret());
    }

    @Bean
    JwtEncoder accessTokenEncoder(SecretKey accessTokenKey) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(accessTokenKey));
    }

    /** The only {@link JwtDecoder} bean: validates bearer tokens on protected endpoints. */
    @Bean
    JwtDecoder accessTokenDecoder(SecretKey accessTokenKey) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(accessTokenKey)
                .macAlgorithm(MacAlgorithm.HS256).build();
        // Default validators: expiry / not-before (60 s skew) plus the issuer check.
        decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(AccessTokenService.ISSUER));
        return decoder;
    }
}
