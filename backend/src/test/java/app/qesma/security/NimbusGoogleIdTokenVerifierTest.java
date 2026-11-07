package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.security.GoogleIdTokenVerifier.AuthProviderUnavailableException;
import app.qesma.security.GoogleIdTokenVerifier.InvalidIdTokenException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.PlainHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.PlainJWT;
import com.nimbusds.jwt.SignedJWT;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Date;
import java.util.List;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.JwtException;

/**
 * The real verifier's validation chain (signature, issuer, audience, expiry, subject) exercised with a
 * locally generated RSA key instead of Google's JWKS endpoint.
 */
class NimbusGoogleIdTokenVerifierTest {

    private static final String CLIENT_ID = "my-client.apps.googleusercontent.com";
    private static final String GOOGLE = "https://accounts.google.com";

    private static KeyPair signingKey;
    private static KeyPair otherKey;
    private static NimbusGoogleIdTokenVerifier verifier;

    @BeforeAll
    static void keys() throws Exception {
        KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
        gen.initialize(2048);
        signingKey = gen.generateKeyPair();
        otherKey = gen.generateKeyPair();
        verifier = NimbusGoogleIdTokenVerifier.forPublicKey((RSAPublicKey) signingKey.getPublic(), List.of(CLIENT_ID));
    }

    private static JWTClaimsSet.Builder validClaims() {
        Instant now = Instant.now();
        return new JWTClaimsSet.Builder()
                .issuer(GOOGLE).audience(CLIENT_ID).subject("1234567890")
                .issueTime(Date.from(now)).expirationTime(Date.from(now.plusSeconds(600)))
                .claim("email", "ali@example.com").claim("email_verified", true).claim("name", "Ali Hassan");
    }

    private static String sign(JWTClaimsSet claims, KeyPair key) throws Exception {
        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.RS256), claims);
        jwt.sign(new RSASSASigner((RSAPrivateKey) key.getPrivate()));
        return jwt.serialize();
    }

    private static void assertRejected(String token) {
        assertThatThrownBy(() -> verifier.verify(token)).isInstanceOf(InvalidIdTokenException.class);
    }

    @Test
    void acceptsValidTokenAndExtractsIdentity() throws Exception {
        GoogleIdentity id = verifier.verify(sign(validClaims().build(), signingKey));
        assertThat(id).isEqualTo(new GoogleIdentity("1234567890", "ali@example.com", "Ali Hassan"));
    }

    @Test
    void acceptsTheBareGoogleIssuerToo() throws Exception {
        assertThat(verifier.verify(sign(validClaims().issuer("accounts.google.com").build(), signingKey)).subject())
                .isEqualTo("1234567890");
    }

    @Test
    void dropsEmailThatGoogleDidNotVerify() throws Exception {
        GoogleIdentity id = verifier.verify(sign(validClaims().claim("email_verified", false).build(), signingKey));
        assertThat(id.email()).isNull();
        assertThat(id.subject()).isEqualTo("1234567890");
    }

    @Test
    void rejectsWrongAudience() throws Exception {
        assertRejected(sign(validClaims().audience("someone-elses-client").build(), signingKey));
    }

    @Test
    void rejectsWrongIssuer() throws Exception {
        assertRejected(sign(validClaims().issuer("https://evil.example.com").build(), signingKey));
    }

    @Test
    void rejectsExpiredToken() throws Exception {
        Instant past = Instant.now().minusSeconds(600);
        assertRejected(sign(validClaims().issueTime(Date.from(past.minusSeconds(600)))
                .expirationTime(Date.from(past)).build(), signingKey));
    }

    @Test
    void rejectsTokenSignedByAnotherKey() throws Exception {
        assertRejected(sign(validClaims().build(), otherKey));
    }

    @Test
    void rejectsMissingOrBlankSubject() throws Exception {
        assertRejected(sign(validClaims().subject(null).build(), signingKey));
        assertRejected(sign(validClaims().subject(" ").build(), signingKey));
    }

    @Test
    void rejectsUnsignedAlgNoneToken() {
        assertRejected(new PlainJWT(new PlainHeader(), validClaims().build()).serialize());
    }

    @Test
    void rejectsGarbageBlankAndOversizedInput() {
        assertRejected("not-a-jwt");
        assertRejected("");
        assertRejected("   ");
        assertRejected(null);
        assertRejected("a".repeat(5000));
    }

    @Test
    void reportsKeyRetrievalFailureAsProviderUnavailableNotAsInvalidToken() {
        var broken = new NimbusGoogleIdTokenVerifier(token -> {
            throw new JwtException("Couldn't retrieve remote JWK set");
        });
        assertThatThrownBy(() -> broken.verify("a.b.c")).isInstanceOf(AuthProviderUnavailableException.class);
    }

    @Test
    void refusesToStartWithoutClientIds() {
        assertThatThrownBy(() -> NimbusGoogleIdTokenVerifier.forPublicKey(
                (RSAPublicKey) signingKey.getPublic(), List.of())).isInstanceOf(IllegalStateException.class);
    }
}
