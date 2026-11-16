package app.qesma.security;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.time.Clock;
import javax.crypto.SecretKey;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import app.qesma.service.UserService;
import java.util.UUID;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
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
    JwtDecoder accessTokenDecoder(SecretKey accessTokenKey, UserService users) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(accessTokenKey)
                .macAlgorithm(MacAlgorithm.HS256).build();
        // Default validators: expiry / not-before (60 s skew) plus the issuer check.
        // Plus: a deleted account is refused at once, not when its 15-minute token expires (B17, A115). A primary-key
        // probe per request; the failure is the same generic 401 as any bad token.
        OAuth2TokenValidator<Jwt> accountNotDeleted = jwt -> {
            try {
                if (users.isDeleted(UUID.fromString(jwt.getSubject()))) {
                    return OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "account deleted", null));
                }
            } catch (IllegalArgumentException | NullPointerException e) {
                return OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "bad subject", null));
            }
            return OAuth2TokenValidatorResult.success();
        };
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(AccessTokenService.ISSUER), accountNotDeleted));
        return decoder;
    }
}
