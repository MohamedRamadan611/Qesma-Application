package app.qesma.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import app.qesma.security.AccessTokenService;
import app.qesma.security.AuthProperties;
import app.qesma.security.CurrentUser;
import app.qesma.security.JwtConfig;
import app.qesma.security.ProblemJsonWriter;
import app.qesma.security.SecurityConfig;
import app.qesma.service.BalanceService;
import app.qesma.service.BalanceView;
import app.qesma.service.IdempotencyService;
import app.qesma.service.SettlementCommand;
import app.qesma.service.SettlementService;
import app.qesma.service.SettlementView;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** HTTP contract of the settlement and balance controllers with mocked services: runs without Docker. */
@WebMvcTest(controllers = {SettlementController.class, BalanceController.class})
@Import({SecurityConfig.class, JwtConfig.class, AccessTokenService.class, ProblemJsonWriter.class,
        CurrentUser.class, RequestIdFilter.class})
@ActiveProfiles("test")
class SettlementApiSliceTest {

    @TestConfiguration
    @EnableConfigurationProperties({AuthProperties.class, app.qesma.service.InviteProperties.class})
    static class Beans {
        @Bean
        MeterRegistry meterRegistry() {
            return new SimpleMeterRegistry();
        }
    }

    @Autowired MockMvc mvc;
    @Autowired AccessTokenService accessTokens;
    @Autowired ObjectMapper json;
    @MockitoBean SettlementService settlements;
    @MockitoBean BalanceService balances;

    private final UUID me = UUID.randomUUID();
    private final UUID gid = UUID.randomUUID();
    private final UUID sid = UUID.randomUUID();
    private final UUID key = UUID.randomUUID();
    private final UUID alice = UUID.randomUUID();
    private final UUID bob = UUID.randomUUID();

    private MockHttpServletRequestBuilder authed(MockHttpServletRequestBuilder b) {
        return b.header("Authorization", "Bearer " + accessTokens.issue(me)).contentType(MediaType.APPLICATION_JSON);
    }

    private String body() {
        return "{\"fromMemberId\":\"" + alice + "\",\"toMemberId\":\"" + bob
                + "\",\"amountMinor\":8000,\"settledOn\":\"2026-10-20\",\"note\":\"cash\"}";
    }

    private SettlementView view() {
        return new SettlementView(sid, gid, alice, bob, 8000, LocalDate.of(2026, 10, 20), "cash",
                Instant.parse("2026-10-20T10:00:00Z"), "PENDING", false, alice,
                Instant.parse("2026-10-20T10:00:00Z"), null, null, null);
    }

    private JsonNode node(MvcResult r) throws Exception {
        return json.readTree(r.getResponse().getContentAsString());
    }

    @Test
    void createReturns201WithLocationAndBindsTheBody() throws Exception {
        when(settlements.create(eq(me), eq(gid), eq(key), any()))
                .thenReturn(new IdempotencyService.Outcome(201, json.writeValueAsString(view()), false));

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/settlements"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        assertThat(r.getResponse().getHeader("Location")).isEqualTo("/api/v1/groups/" + gid + "/settlements/" + sid);
        assertThat(r.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(node(r).get("amountMinor").asLong()).isEqualTo(8000);
        ArgumentCaptor<SettlementCommand> captured = ArgumentCaptor.forClass(SettlementCommand.class);
        verify(settlements).create(eq(me), eq(gid), eq(key), captured.capture());
        assertThat(captured.getValue().fromMemberId()).isEqualTo(alice);
        assertThat(captured.getValue().toMemberId()).isEqualTo(bob);
        assertThat(captured.getValue().amountMinor()).isEqualTo(8000L);
        assertThat(captured.getValue().settledOn()).isEqualTo(LocalDate.of(2026, 10, 20));
    }

    @Test
    void aReplayIsMarkedWithAHeader() throws Exception {
        when(settlements.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, json.writeValueAsString(view()), true));
        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/settlements"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();
        assertThat(r.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
    }

    @Test
    void aMissingOrMalformedKeyIs422AndNothingReachesTheService() throws Exception {
        for (String bad : new String[] {null, "", "nope"}) {
            MockHttpServletRequestBuilder req = authed(post("/api/v1/groups/" + gid + "/settlements")).content(body());
            if (bad != null) {
                req.header("Idempotency-Key", bad);
            }
            MvcResult r = mvc.perform(req).andReturn();
            assertThat(r.getResponse().getStatus()).as("[" + bad + "]").isEqualTo(422);
        }
        verifyNoInteractions(settlements);
    }

    @Test
    void domainErrorsAreProblemJson() throws Exception {
        when(settlements.create(any(), any(), any(), any())).thenThrow(new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP,
                org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY, "x"));
        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/settlements"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(422);
        assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(node(r).get("code").asText()).isEqualTo("MEMBER_NOT_IN_GROUP");
    }

    @Test
    void listIsPaged() throws Exception {
        when(settlements.list(me, gid, List.of("PENDING", "DISPUTED"), 1, 10))
                .thenReturn(new PageImpl<>(List.of(view()), PageRequest.of(1, 10), 11));
        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid + "/settlements?status=PENDING&status=DISPUTED&page=1&size=10"))).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        assertThat(node(r).get("items")).hasSize(1);
        assertThat(node(r).get("totalElements").asLong()).isEqualTo(11);
    }

    @Test
    void theThreeActionsAreWiredAndAnInvalidTransitionIsProblemJson409() throws Exception {
        when(settlements.confirm(me, gid, sid)).thenReturn(view());
        when(settlements.dispute(me, gid, sid)).thenReturn(view());
        when(settlements.cancel(me, gid, sid)).thenThrow(new ApiException(ErrorCode.INVALID_STATE_TRANSITION,
                org.springframework.http.HttpStatus.CONFLICT, "x"));

        for (String action : List.of("confirm", "dispute")) {
            MvcResult ok = mvc.perform(authed(post("/api/v1/groups/" + gid + "/settlements/" + sid + "/" + action)))
                    .andReturn();
            assertThat(ok.getResponse().getStatus()).as(action).isEqualTo(200);
            assertThat(node(ok).get("id").asText()).isEqualTo(sid.toString());
        }
        MvcResult bad = mvc.perform(authed(post("/api/v1/groups/" + gid + "/settlements/" + sid + "/cancel")))
                .andReturn();
        assertThat(bad.getResponse().getStatus()).isEqualTo(409);
        assertThat(bad.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(node(bad).get("code").asText()).isEqualTo("INVALID_STATE_TRANSITION");
    }

    @Test
    void thePhase1DeleteRouteIsGone() throws Exception {
        MvcResult r = mvc.perform(authed(delete("/api/v1/groups/" + gid + "/settlements/" + sid))).andReturn();
        assertThat(r.getResponse().getStatus()).isIn(404, 405);
        verifyNoInteractions(settlements);
    }

    @Test
    void balancesReturnNetsAndTransfers() throws Exception {
        when(balances.balances(me, gid)).thenReturn(new BalanceView(
                List.of(new BalanceView.Net(alice, -8000), new BalanceView.Net(bob, 8000)),
                List.of(new BalanceView.TransferView(alice, bob, 8000, 3000, true, List.of(sid)))));
        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid + "/balances"))).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode b = node(r);
        assertThat(b.get("nets")).hasSize(2);
        assertThat(b.get("nets").get(0).get("netMinor").asLong()).isEqualTo(-8000);
        assertThat(b.get("transfers").get(0).get("fromMemberId").asText()).isEqualTo(alice.toString());
        assertThat(b.get("transfers").get(0).get("amountMinor").asLong()).isEqualTo(8000);
        assertThat(b.get("transfers").get(0).get("pendingMinor").asLong()).isEqualTo(3000);
        assertThat(b.get("transfers").get(0).get("hasDispute").asBoolean()).isTrue();
        assertThat(b.get("transfers").get(0).get("openSettlementIds").get(0).asText()).isEqualTo(sid.toString());
    }

    @Test
    void everyEndpointRequiresAuthentication() throws Exception {
        for (MockHttpServletRequestBuilder call : List.of(post("/api/v1/groups/" + gid + "/settlements"),
                get("/api/v1/groups/" + gid + "/settlements"),
                post("/api/v1/groups/" + gid + "/settlements/" + sid + "/confirm"),
                post("/api/v1/groups/" + gid + "/settlements/" + sid + "/dispute"),
                post("/api/v1/groups/" + gid + "/settlements/" + sid + "/cancel"),
                get("/api/v1/groups/" + gid + "/balances"))) {
            MvcResult r = mvc.perform(call.contentType(MediaType.APPLICATION_JSON).content("{}")
                    .header("Idempotency-Key", key.toString())).andReturn();
            assertThat(r.getResponse().getStatus()).isEqualTo(401);
        }
        verifyNoInteractions(settlements, balances);
    }
}
