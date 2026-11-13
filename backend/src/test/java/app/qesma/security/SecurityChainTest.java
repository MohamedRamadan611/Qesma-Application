package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import app.qesma.api.ApiException;
import app.qesma.api.AuthController;
import app.qesma.api.MeController;
import app.qesma.domain.User;
import app.qesma.service.AuthService;
import app.qesma.service.PasswordAuthService;
import app.qesma.service.PaymentHandleService;
import app.qesma.service.UserService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/**
 * The real security filter chain, request-id filter, problem+json handler and controllers, with the services
 * mocked: runs without Docker. Proves the 401 behaviour for every kind of bad token is identical.
 */
@WebMvcTest(controllers = {AuthController.class, MeController.class})
@Import({SecurityConfig.class, JwtConfig.class, AccessTokenService.class, ProblemJsonWriter.class,
        CurrentUser.class, app.qesma.api.RequestIdFilter.class})
@ActiveProfiles("test")
class SecurityChainTest {

    @TestConfiguration
    @org.springframework.boot.context.properties.EnableConfigurationProperties({AuthProperties.class, app.qesma.service.InviteProperties.class})
    static class Beans {
        @Bean
        MeterRegistry meterRegistry() {
            return new SimpleMeterRegistry();
        }
    }

    @Autowired MockMvc mvc;
    @Autowired AccessTokenService accessTokens;
    @Autowired ObjectMapper json;
    @MockitoBean UserService users;
    @MockitoBean AuthService auth;
    @MockitoBean PasswordAuthService passwordAuth;
    @MockitoBean PaymentHandleService paymentHandles;

    private static final String TEST_SECRET_B64 =
            "dGVzdC1vbmx5LXNlY3JldC1mb3ItaW50ZWdyYXRpb24tdGVzdHMtMDEyMzQ1Njc4OQ==";

    /** Signs an access-token-shaped JWT with the given key/issuer/expiry (to forge or age tokens). */
    private static String token(String base64Key, String issuer, Instant exp, UUID sub) {
        var key = new SecretKeySpec(Base64.getDecoder().decode(base64Key), "HmacSHA256");
        var encoder = new NimbusJwtEncoder(new ImmutableSecret<>(key));
        JwtClaimsSet claims = JwtClaimsSet.builder().issuer(issuer).subject(sub.toString())
                .issuedAt(exp.minusSeconds(900)).expiresAt(exp).build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
    }

    private JsonNode bodyOf(MvcResult r) throws Exception {
        return json.readTree(r.getResponse().getContentAsString());
    }

    private static User user(UUID id, String name) {
        User u = org.mockito.Mockito.mock(User.class);
        when(u.getId()).thenReturn(id);
        when(u.getDisplayName()).thenReturn(name);
        when(u.getEmail()).thenReturn("ali@example.com");
        return u;
    }

    // ---- every authentication failure looks the same ------------------------------------------

    @Test
    void missingAndBadTokensAllGetTheSameGeneric401() throws Exception {
        UUID id = UUID.randomUUID();
        String otherKey = Base64.getEncoder().encodeToString("another-secret-another-secret-12345".getBytes());
        String[] bearers = {
                null,                                                                       // no header
                "garbage",                                                                  // not a JWT
                token(TEST_SECRET_B64, "qesma", Instant.now().minusSeconds(3600), id),      // expired
                token(otherKey, "qesma", Instant.now().plusSeconds(600), id),              // forged signature
                token(TEST_SECRET_B64, "someone-else", Instant.now().plusSeconds(600), id), // wrong issuer
        };
        JsonNode reference = null;
        for (String bearer : bearers) {
            var req = get("/api/v1/me");
            if (bearer != null) {
                req.header("Authorization", "Bearer " + bearer);
            }
            MvcResult result = mvc.perform(req).andReturn();

            assertThat(result.getResponse().getStatus()).isEqualTo(401);
            assertThat(result.getResponse().getContentType()).startsWith("application/problem+json");
            assertThat(result.getResponse().getHeader("WWW-Authenticate")).as("no error detail leaked").isNull();
            JsonNode body = bodyOf(result);
            assertThat(body.get("code").asText()).isEqualTo("UNAUTHORIZED");
            assertThat(body.get("requestId").asText()).isNotBlank();
            ((com.fasterxml.jackson.databind.node.ObjectNode) body).remove("requestId");
            if (reference == null) {
                reference = body;
            }
            assertThat(body).isEqualTo(reference);
        }
    }

    @Test
    void unknownProtectedPathWithoutTokenIs401NotA404() throws Exception {
        assertThat(mvc.perform(get("/api/v1/groups")).andReturn().getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void corsIsDisabled() throws Exception {
        MvcResult r = mvc.perform(get("/api/v1/me").header("Origin", "https://evil.example.com")).andReturn();
        assertThat(r.getResponse().getHeader("Access-Control-Allow-Origin")).isNull();
    }

    // ---- authenticated flow -----------------------------------------------------------------

    @Test
    void validAccessTokenReachesMeAndActsOnTheTokenSubject() throws Exception {
        UUID id = UUID.randomUUID();
        User ali = user(id, "Ali Hassan");
        when(users.get(id)).thenReturn(ali);

        MvcResult r = mvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + accessTokens.issue(id)))
                .andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = bodyOf(r);
        assertThat(body.get("id").asText()).isEqualTo(id.toString());
        assertThat(body.get("displayName").asText()).isEqualTo("Ali Hassan");
    }

    @Test
    void patchMeUsesTheTokenSubjectAndSurfacesValidationErrorsAs422() throws Exception {
        UUID id = UUID.randomUUID();
        when(users.updateDisplayName(id, "  ")).thenThrow(ApiException.validation("displayName must not be blank"));

        MvcResult r = mvc.perform(patch("/api/v1/me")
                .header("Authorization", "Bearer " + accessTokens.issue(id))
                .contentType(MediaType.APPLICATION_JSON).content("{\"displayName\":\"  \"}")).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(422);
        assertThat(bodyOf(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    // ---- public auth endpoints ----------------------------------------------------------------

    @Test
    void googleLoginIsPublicAndReturnsTokensAndUser() throws Exception {
        UUID id = UUID.randomUUID();
        User ali = user(id, "Ali");
        when(auth.loginWithGoogle("the-id-token")).thenReturn(new AuthService.Login("access", "refresh", ali));

        MvcResult r = mvc.perform(post("/api/v1/auth/google").contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"the-id-token\"}")).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = bodyOf(r);
        assertThat(body.get("accessToken").asText()).isEqualTo("access");
        assertThat(body.get("refreshToken").asText()).isEqualTo("refresh");
        assertThat(body.get("user").get("id").asText()).isEqualTo(id.toString());
    }

    @Test
    void failedLoginIsTheGeneric401ProblemJson() throws Exception {
        when(auth.loginWithGoogle(any())).thenThrow(ApiException.unauthorized());

        MvcResult r = mvc.perform(post("/api/v1/auth/google").contentType(MediaType.APPLICATION_JSON)
                .content("{\"idToken\":\"x\"}")).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(401);
        assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(bodyOf(r).get("code").asText()).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void blankOrMissingFieldsAre422ValidationErrors() throws Exception {
        for (String path : new String[] {"/api/v1/auth/google", "/api/v1/auth/refresh", "/api/v1/auth/logout"}) {
            for (String body : new String[] {"{}", "{\"idToken\":\"\",\"refreshToken\":\"\"}"}) {
                MvcResult r = mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON).content(body)).andReturn();
                assertThat(r.getResponse().getStatus()).as(path + " " + body).isEqualTo(422);
                assertThat(bodyOf(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
            }
        }
    }

    @Test
    void malformedJsonIs400ProblemJsonWithoutDetails() throws Exception {
        MvcResult r = mvc.perform(post("/api/v1/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                .content("{not json")).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(400);
        assertThat(bodyOf(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
        assertThat(r.getResponse().getContentAsString()).doesNotContain("Exception").doesNotContain("not json");
    }

    @Test
    void logoutAndRefreshArePublicEndpoints() throws Exception {
        when(auth.refresh("r1")).thenReturn(new AuthService.Refreshed("a2", "r2"));

        MvcResult refresh = mvc.perform(post("/api/v1/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                .content("{\"refreshToken\":\"r1\"}")).andReturn();
        assertThat(refresh.getResponse().getStatus()).isEqualTo(200);
        assertThat(bodyOf(refresh).get("refreshToken").asText()).isEqualTo("r2");

        MvcResult logout = mvc.perform(post("/api/v1/auth/logout").contentType(MediaType.APPLICATION_JSON)
                .content("{\"refreshToken\":\"r1\"}")).andReturn();
        assertThat(logout.getResponse().getStatus()).isEqualTo(204);
    }
}
