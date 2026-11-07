package app.qesma.security;

import java.security.interfaces.RSAPublicKey;
import java.time.Duration;
import java.util.List;
import java.util.Set;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Real Google ID-token verification: RS256 signature against Google's published keys, issuer, audience
 * (our client ids), expiry (60 s clock skew) and a non-blank subject. No custom cryptography.
 */
public class NimbusGoogleIdTokenVerifier implements GoogleIdTokenVerifier {

    private static final Set<String> ISSUERS = Set.of("https://accounts.google.com", "accounts.google.com");
    private static final int MAX_TOKEN_LENGTH = 4096;
    private static final Duration CLOCK_SKEW = Duration.ofSeconds(60);

    private final JwtDecoder decoder;

    NimbusGoogleIdTokenVerifier(JwtDecoder decoder) {
        this.decoder = decoder;
    }

    /** Production wiring: keys fetched from Google's JWKS endpoint (cached by Nimbus), short network timeouts. */
    public static NimbusGoogleIdTokenVerifier forJwkSetUri(String jwkSetUri, List<String> clientIds) {
        requireClientIds(clientIds);
        var rest = new RestTemplateBuilder().connectTimeout(Duration.ofSeconds(3)).readTimeout(Duration.ofSeconds(3))
                .build();
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).restOperations(rest).build();
        decoder.setJwtValidator(validators(clientIds));
        return new NimbusGoogleIdTokenVerifier(decoder);
    }

    /** Test wiring: a fixed public key instead of the network. Exercises the same validators. */
    static NimbusGoogleIdTokenVerifier forPublicKey(RSAPublicKey key, List<String> clientIds) {
        requireClientIds(clientIds);
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withPublicKey(key).build();
        decoder.setJwtValidator(validators(clientIds));
        return new NimbusGoogleIdTokenVerifier(decoder);
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        if (idToken == null || idToken.isBlank() || idToken.length() > MAX_TOKEN_LENGTH) {
            throw new InvalidIdTokenException();
        }
        Jwt jwt;
        try {
            jwt = decoder.decode(idToken);
        } catch (BadJwtException e) { // malformed, bad signature, or a validator rejected it
            throw new InvalidIdTokenException();
        } catch (JwtException e) { // anything else is key retrieval / infrastructure
            throw new AuthProviderUnavailableException(e);
        }
        String subject = jwt.getSubject();
        if (subject == null || subject.isBlank()) {
            throw new InvalidIdTokenException();
        }
        boolean emailVerified = Boolean.TRUE.equals(jwt.getClaimAsBoolean("email_verified"));
        String email = emailVerified ? jwt.getClaimAsString("email") : null;
        return new GoogleIdentity(subject, email, jwt.getClaimAsString("name"));
    }

    private static void requireClientIds(List<String> clientIds) {
        if (clientIds == null || clientIds.isEmpty() || clientIds.stream().anyMatch(String::isBlank)) {
            throw new IllegalStateException("qesma.auth.google-client-ids (GOOGLE_CLIENT_IDS) must list at least one client id");
        }
    }

    private static OAuth2TokenValidator<Jwt> validators(List<String> clientIds) {
        // getClaimAsString, not getIssuer(): the latter parses a URL and throws for the bare "accounts.google.com".
        OAuth2TokenValidator<Jwt> issuer = token -> ISSUERS.contains(token.getClaimAsString("iss"))
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token"));
        OAuth2TokenValidator<Jwt> audience = token -> token.getAudience() != null
                && token.getAudience().stream().anyMatch(clientIds::contains)
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token"));
        return new DelegatingOAuth2TokenValidator<>(new JwtTimestampValidator(CLOCK_SKEW), issuer, audience);
    }
}
