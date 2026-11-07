package app.qesma.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import app.qesma.security.AccessTokenService;
import app.qesma.security.AuthProperties;
import app.qesma.security.CurrentUser;
import app.qesma.security.JwtConfig;
import app.qesma.security.ProblemJsonWriter;
import app.qesma.security.SecurityConfig;
import app.qesma.service.ExpenseCommand;
import app.qesma.service.ExpensePreview;
import app.qesma.service.ExpenseService;
import app.qesma.service.ExpenseView;
import app.qesma.service.IdempotencyService;
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

/** HTTP contract of the expense controller with a mocked service: runs without Docker. */
@WebMvcTest(controllers = ExpenseController.class)
@Import({SecurityConfig.class, JwtConfig.class, AccessTokenService.class, ProblemJsonWriter.class,
        CurrentUser.class, RequestIdFilter.class})
@ActiveProfiles("test")
class ExpenseApiSliceTest {

    @TestConfiguration
    @EnableConfigurationProperties(AuthProperties.class)
    static class Beans {
        @Bean
        MeterRegistry meterRegistry() {
            return new SimpleMeterRegistry();
        }
    }

    @Autowired MockMvc mvc;
    @Autowired AccessTokenService accessTokens;
    @Autowired ObjectMapper json;
    @MockitoBean ExpenseService expenses;

    private final UUID me = UUID.randomUUID();
    private final UUID gid = UUID.randomUUID();
    private final UUID eid = UUID.randomUUID();
    private final UUID key = UUID.randomUUID();
    private final UUID alice = UUID.randomUUID();
    private final UUID bob = UUID.randomUUID();

    private static final String BODY = "{\"title\":\"Dinner\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\","
            + "\"totalMinor\":10000,\"payers\":[{\"memberId\":\"%s\",\"amountMinor\":10000}]}";

    private MockHttpServletRequestBuilder authed(MockHttpServletRequestBuilder b) {
        return b.header("Authorization", "Bearer " + accessTokens.issue(me)).contentType(MediaType.APPLICATION_JSON);
    }

    private String body() {
        return BODY.formatted(alice);
    }

    private String storedBody() throws Exception {
        return json.writeValueAsString(view());
    }

    private ExpenseView view() {
        return new ExpenseView(eid, gid, "Dinner", "EQUAL", 10000, LocalDate.of(2026, 10, 18),
                List.of(new ExpenseView.PayerView(alice, 10000)),
                List.of(new ExpenseView.ShareView(alice, 5000), new ExpenseView.ShareView(bob, 5000)),
                Instant.parse("2026-10-18T10:00:00Z"), 1);
    }

    private JsonNode node(MvcResult r) throws Exception {
        return json.readTree(r.getResponse().getContentAsString());
    }

    @Test
    void createReturns201WithLocationAndTheStoredBody() throws Exception {
        when(expenses.create(eq(me), eq(gid), eq(key), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), false));

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        assertThat(r.getResponse().getContentType()).startsWith("application/json");
        assertThat(r.getResponse().getHeader("Location")).isEqualTo("/api/v1/groups/" + gid + "/expenses/" + eid);
        assertThat(r.getResponse().getHeader("Idempotency-Replayed")).isNull();
        JsonNode b = node(r);
        assertThat(b.get("id").asText()).isEqualTo(eid.toString());
        assertThat(b.get("totalMinor").asLong()).isEqualTo(10000);
        assertThat(b.get("shares")).hasSize(2);
        assertThat(b.get("expenseDate").asText()).isEqualTo("2026-10-18");
    }

    @Test
    void aReplayIsMarkedWithAHeaderAndKeepsTheStatus() throws Exception {
        when(expenses.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), true));

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        assertThat(r.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
    }

    @Test
    void keyIsNormalizedToLowerCaseBeforeTheServiceSeesIt() throws Exception {
        when(expenses.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), false));

        mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                .header("Idempotency-Key", key.toString().toUpperCase()).content(body())).andReturn();

        verify(expenses).create(eq(me), eq(gid), eq(key), any());
    }

    @Test
    void missingBlankOrMalformedKeyIs422AndNothingReachesTheService() throws Exception {
        String[] keys = {null, "", "   ", "not-a-uuid", "12345"};
        for (String bad : keys) {
            MockHttpServletRequestBuilder req = authed(post("/api/v1/groups/" + gid + "/expenses")).content(body());
            if (bad != null) {
                req.header("Idempotency-Key", bad);
            }
            MvcResult r = mvc.perform(req).andReturn();
            assertThat(r.getResponse().getStatus()).as("[" + bad + "]").isEqualTo(422);
            assertThat(node(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
        }
        verifyNoInteractions(expenses);
    }

    @Test
    void theRequestBodyIsBoundWithoutAnyServerControlledField() throws Exception {
        when(expenses.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), false));
        String evil = "{\"title\":\"X\",\"expenseDate\":\"2026-10-18\",\"splitType\":\"EQUAL\",\"totalMinor\":100,"
                + "\"payers\":[{\"memberId\":\"" + alice + "\",\"amountMinor\":100}],"
                + "\"id\":\"" + UUID.randomUUID() + "\",\"createdByUserId\":\"" + UUID.randomUUID() + "\","
                + "\"version\":9,\"deletedAt\":\"2020-01-01T00:00:00Z\",\"groupId\":\"" + UUID.randomUUID() + "\"}";

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                .header("Idempotency-Key", key.toString()).content(evil)).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        ArgumentCaptor<ExpenseCommand> captured = ArgumentCaptor.forClass(ExpenseCommand.class);
        verify(expenses).create(eq(me), eq(gid), eq(key), captured.capture()); // group and user come from path/token
        assertThat(captured.getValue().title()).isEqualTo("X");
    }

    @Test
    void domainErrorsFromTheServiceAreProblemJsonWithTheirCodes() throws Exception {
        record Case(ErrorCode code, int status) { }
        for (Case c : List.of(new Case(ErrorCode.SPLIT_TOTAL_MISMATCH, 422), new Case(ErrorCode.PAYERS_TOTAL_MISMATCH, 422),
                new Case(ErrorCode.MEMBER_NOT_IN_GROUP, 422), new Case(ErrorCode.IDEMPOTENCY_KEY_REUSED, 422),
                new Case(ErrorCode.NOT_FOUND, 404))) {
            org.mockito.Mockito.reset(expenses);
            when(expenses.create(any(), any(), any(), any())).thenThrow(
                    new ApiException(c.code(), org.springframework.http.HttpStatus.valueOf(c.status()), "x"));
            MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                    .header("Idempotency-Key", key.toString()).content(body())).andReturn();
            assertThat(r.getResponse().getStatus()).as(c.code().name()).isEqualTo(c.status());
            assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
            assertThat(node(r).get("code").asText()).isEqualTo(c.code().name());
        }
    }

    @Test
    void malformedBodiesAreRejectedBeforeTheService() throws Exception {
        for (String bad : new String[] {"{not json", "{\"expenseDate\":\"18/10/2026\"}",
                "{\"payers\":[{\"memberId\":\"nope\"}]}", "{\"totalMinor\":\"abc\"}"}) {
            MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                    .header("Idempotency-Key", key.toString()).content(bad)).andReturn();
            assertThat(r.getResponse().getStatus()).as(bad).isEqualTo(400);
            assertThat(node(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
        }
        verify(expenses, never()).create(any(), any(), any(), any());
    }

    @Test
    void listIsPagedAndPassesFiltersToTheService() throws Exception {
        UUID member = UUID.randomUUID();
        when(expenses.list(me, gid, 1, 10, LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31), member))
                .thenReturn(new PageImpl<>(List.of(view()), PageRequest.of(1, 10), 11));

        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses"
                + "?page=1&size=10&fromDate=2026-01-01&toDate=2026-12-31&memberId=" + member))).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode b = node(r);
        assertThat(b.get("items")).hasSize(1);
        assertThat(b.get("totalElements").asLong()).isEqualTo(11);
        assertThat(b.get("totalPages").asInt()).isEqualTo(2);
        assertThat(b.get("items").get(0).get("payers").get(0).get("amountMinor").asLong()).isEqualTo(10000);
    }

    @Test
    void listDefaultsAndBadFilterFormatsBehave() throws Exception {
        when(expenses.list(me, gid, 0, 20, null, null, null))
                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));
        assertThat(mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses"))).andReturn().getResponse().getStatus())
                .isEqualTo(200);
        for (String bad : new String[] {"?fromDate=yesterday", "?toDate=2026-13-45", "?memberId=abc", "?size=x"}) {
            assertThat(mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses" + bad))).andReturn()
                    .getResponse().getStatus()).as(bad).isEqualTo(400);
        }
    }

    @Test
    void detailReturnsTheExpenseOr404() throws Exception {
        when(expenses.get(me, gid, eid)).thenReturn(view());
        MvcResult ok = mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses/" + eid))).andReturn();
        assertThat(ok.getResponse().getStatus()).isEqualTo(200);
        assertThat(node(ok).get("title").asText()).isEqualTo("Dinner");

        when(expenses.get(any(), any(), any())).thenThrow(ApiException.notFound());
        MvcResult nf = mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses/" + UUID.randomUUID()))).andReturn();
        assertThat(nf.getResponse().getStatus()).isEqualTo(404);
        assertThat(node(nf).get("code").asText()).isEqualTo("NOT_FOUND");
    }

    private static final String ITEMIZED_BODY = "{\"title\":\"Dinner\",\"expenseDate\":\"2026-10-18\","
            + "\"splitType\":\"ITEMIZED\",\"payers\":[{\"memberId\":\"%1$s\",\"amountMinor\":44000}],"
            + "\"items\":[{\"name\":\"Pizza\",\"amountMinor\":20000,\"assigneeMemberIds\":[\"%1$s\",\"%2$s\"]}],"
            + "\"service\":{\"bps\":1200},\"tax\":{\"bps\":1400,\"base\":\"SUBTOTAL\"},\"adjustmentMinor\":-5}";

    @Test
    void itemizedFieldsAreBoundFromJsonIntoTheCommand() throws Exception {
        when(expenses.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), false));

        mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses")).header("Idempotency-Key", key.toString())
                .content(ITEMIZED_BODY.formatted(alice, bob))).andReturn();

        ArgumentCaptor<ExpenseCommand> captured = ArgumentCaptor.forClass(ExpenseCommand.class);
        verify(expenses).create(eq(me), eq(gid), eq(key), captured.capture());
        ExpenseCommand c = captured.getValue();
        assertThat(c.splitType()).isEqualTo("ITEMIZED");
        assertThat(c.totalMinor()).isNull();
        assertThat(c.items()).hasSize(1);
        assertThat(c.items().get(0).assigneeMemberIds()).containsExactly(alice, bob);
        assertThat(c.service().bps()).isEqualTo(1200);
        assertThat(c.tax().bps()).isEqualTo(1400);
        assertThat(c.tax().base()).isEqualTo("SUBTOTAL");
        assertThat(c.adjustmentMinor()).isEqualTo(-5L);
    }

    @Test
    void previewNeedsNoIdempotencyKeyAndReturnsTheComputedBreakdown() throws Exception {
        when(expenses.preview(eq(me), eq(gid), any())).thenReturn(new ExpensePreview(56179L, 44000L, 5280L, 6899L, 0L,
                List.of(new ExpenseView.ShareView(alice, 16599, 13000L, 1560L, 2039L, 0L)), true));

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses/preview"))
                .content(ITEMIZED_BODY.formatted(alice, bob))).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode b = node(r);
        assertThat(b.get("totalMinor").asLong()).isEqualTo(56179);
        assertThat(b.get("subtotalMinor").asLong()).isEqualTo(44000);
        assertThat(b.get("serviceMinor").asLong()).isEqualTo(5280);
        assertThat(b.get("taxMinor").asLong()).isEqualTo(6899);
        assertThat(b.get("payersTotalMatches").asBoolean()).isTrue();
        JsonNode m = b.get("members").get(0);
        assertThat(m.get("memberId").asText()).isEqualTo(alice.toString());
        assertThat(m.get("itemsMinor").asLong()).isEqualTo(13000);
        assertThat(m.get("owedMinor").asLong()).isEqualTo(16599);
        verify(expenses, never()).create(any(), any(), any(), any());
    }

    @Test
    void previewErrorsAreProblemJson() throws Exception {
        when(expenses.preview(any(), any(), any())).thenThrow(ApiException.notFound());
        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses/preview")).content(body()))
                .andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(404);
        assertThat(node(r).get("code").asText()).isEqualTo("NOT_FOUND");
    }

    @Test
    void anOversizedBodyIs413BeforeAnythingElseRuns() throws Exception {
        String huge = "{\"title\":\"" + "x".repeat(70 * 1024) + "\"}";
        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses/preview")).content(huge)).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(413);
        assertThat(node(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
        verifyNoInteractions(expenses);
    }

    @Test
    void editNeedsIfMatchAndPassesTheVersionAndBodyToTheService() throws Exception {
        ExpenseView updated = new ExpenseView(eid, gid, "Dinner", "EQUAL", 10000, LocalDate.of(2026, 10, 18),
                List.of(new ExpenseView.PayerView(alice, 10000)), List.of(new ExpenseView.ShareView(alice, 10000)),
                Instant.parse("2026-10-18T10:00:00Z"), 4);
        when(expenses.update(eq(me), eq(gid), eq(eid), eq(3), any())).thenReturn(updated);
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;

        MvcResult missing = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .put(url)).content(body())).andReturn();
        assertThat(missing.getResponse().getStatus()).isEqualTo(428);
        MvcResult malformed = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .put(url)).header("If-Match", "latest").content(body())).andReturn();
        assertThat(malformed.getResponse().getStatus()).isEqualTo(422);
        verify(expenses, never()).update(any(), any(), any(), org.mockito.ArgumentMatchers.anyInt(), any());

        MvcResult ok = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .put(url)).header("If-Match", "\"3\"").content(body())).andReturn();
        assertThat(ok.getResponse().getStatus()).isEqualTo(200);
        assertThat(ok.getResponse().getHeader("ETag")).isEqualTo("\"4\"");
        assertThat(node(ok).get("version").asInt()).isEqualTo(4);
    }

    @Test
    void staleEditsAndDeletesAreProblemJson409() throws Exception {
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;
        when(expenses.update(any(), any(), any(), org.mockito.ArgumentMatchers.anyInt(), any())).thenThrow(
                ApiException.conflict(ErrorCode.VERSION_CONFLICT, "stale"));
        when(expenses.delete(any(), any(), any(), org.mockito.ArgumentMatchers.anyInt())).thenThrow(
                ApiException.conflict(ErrorCode.VERSION_CONFLICT, "stale"));

        MvcResult put = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .put(url)).header("If-Match", "1").content(body())).andReturn();
        MvcResult del = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .delete(url)).header("If-Match", "1")).andReturn();

        for (MvcResult r : List.of(put, del)) {
            assertThat(r.getResponse().getStatus()).isEqualTo(409);
            assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
            assertThat(node(r).get("code").asText()).isEqualTo("VERSION_CONFLICT");
        }
    }

    @Test
    void deleteReturns204WithTheNewETagAndNeedsIfMatch() throws Exception {
        when(expenses.delete(me, gid, eid, 2)).thenReturn(3);
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;

        MvcResult missing = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .delete(url))).andReturn();
        assertThat(missing.getResponse().getStatus()).isEqualTo(428);

        MvcResult ok = mvc.perform(authed(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .delete(url)).header("If-Match", "\"2\"")).andReturn();
        assertThat(ok.getResponse().getStatus()).isEqualTo(204);
        assertThat(ok.getResponse().getHeader("ETag")).isEqualTo("\"3\"");
        assertThat(ok.getResponse().getContentAsString()).isEmpty();
    }

    @Test
    void revisionsAreReturnedAsAnArrayWithTheSnapshotAsJson() throws Exception {
        when(expenses.revisions(me, gid, eid)).thenReturn(List.of(new app.qesma.service.ExpenseRevisionView(1, "CREATE",
                Instant.parse("2026-10-18T10:00:00Z"), me, json.readTree("{\"id\":\"" + eid + "\",\"version\":1}"))));

        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses/" + eid + "/revisions"))).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        JsonNode b = node(r);
        assertThat(b).hasSize(1);
        assertThat(b.get(0).get("changeType").asText()).isEqualTo("CREATE");
        assertThat(b.get(0).get("changedByUserId").asText()).isEqualTo(me.toString());
        assertThat(b.get(0).get("snapshot").get("version").asInt()).isEqualTo(1);   // an object, not an escaped string
    }

    @Test
    void detailCarriesTheVersionAsETag() throws Exception {
        when(expenses.get(me, gid, eid)).thenReturn(view());
        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid + "/expenses/" + eid))).andReturn();
        assertThat(r.getResponse().getHeader("ETag")).isEqualTo("\"1\"");
    }

    @Test
    void createCarriesTheVersionAsETag() throws Exception {
        when(expenses.create(any(), any(), any(), any()))
                .thenReturn(new IdempotencyService.Outcome(201, storedBody(), false));
        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/expenses"))
                .header("Idempotency-Key", key.toString()).content(body())).andReturn();
        assertThat(r.getResponse().getHeader("ETag")).isEqualTo("\"1\"");
    }

    @Test
    void editDeleteAndRevisionsRequireAuthentication() throws Exception {
        String url = "/api/v1/groups/" + gid + "/expenses/" + eid;
        for (MockHttpServletRequestBuilder call : List.of(
                org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(url),
                org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete(url),
                get(url + "/revisions"))) {
            MvcResult r = mvc.perform(call.contentType(MediaType.APPLICATION_JSON).content("{}")
                    .header("If-Match", "1")).andReturn();
            assertThat(r.getResponse().getStatus()).isEqualTo(401);
        }
        verifyNoInteractions(expenses);
    }

    @Test
    void everyExpenseEndpointRequiresAuthentication() throws Exception {
        for (MockHttpServletRequestBuilder call : List.of(
                post("/api/v1/groups/" + gid + "/expenses"), post("/api/v1/groups/" + gid + "/expenses/preview"),
                get("/api/v1/groups/" + gid + "/expenses"),
                get("/api/v1/groups/" + gid + "/expenses/" + eid))) {
            MvcResult r = mvc.perform(call.contentType(MediaType.APPLICATION_JSON).content("{}")
                    .header("Idempotency-Key", key.toString())).andReturn();
            assertThat(r.getResponse().getStatus()).isEqualTo(401);
        }
        verifyNoInteractions(expenses);
    }
}
