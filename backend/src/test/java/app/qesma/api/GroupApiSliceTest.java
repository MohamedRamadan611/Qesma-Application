package app.qesma.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.security.AccessTokenService;
import app.qesma.security.AuthProperties;
import app.qesma.security.CurrentUser;
import app.qesma.security.JwtConfig;
import app.qesma.security.ProblemJsonWriter;
import app.qesma.security.SecurityConfig;
import app.qesma.service.GroupService;
import app.qesma.service.MemberService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
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

/** HTTP contract of the group/member controllers with mocked services: runs without Docker. */
@WebMvcTest(controllers = {GroupController.class, MemberController.class})
@Import({SecurityConfig.class, JwtConfig.class, AccessTokenService.class, ProblemJsonWriter.class,
        CurrentUser.class, RequestIdFilter.class})
@ActiveProfiles("test")
class GroupApiSliceTest {

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
    @MockitoBean GroupService groups;
    @MockitoBean MemberService members;

    private final UUID me = UUID.randomUUID();
    private final UUID gid = UUID.randomUUID();

    private MockHttpServletRequestBuilder authed(MockHttpServletRequestBuilder b) {
        return b.header("Authorization", "Bearer " + accessTokens.issue(me)).contentType(MediaType.APPLICATION_JSON);
    }

    private JsonNode body(MvcResult r) throws Exception {
        return json.readTree(r.getResponse().getContentAsString());
    }

    private ExpenseGroup group(int version) {
        ExpenseGroup g = Mockito.mock(ExpenseGroup.class);
        when(g.getId()).thenReturn(gid);
        when(g.getName()).thenReturn("Dahab");
        when(g.getType()).thenReturn("TRIP");
        when(g.getCurrencyCode()).thenReturn("EGP");
        when(g.getVersion()).thenReturn(version);
        when(g.getCreatedAt()).thenReturn(Instant.parse("2026-01-01T00:00:00Z"));
        when(g.getUpdatedAt()).thenReturn(Instant.parse("2026-01-01T00:00:00Z"));
        return g;
    }

    private Member member(UUID id, String name, int sortOrder) {
        return member(id, name, sortOrder, null);
    }

    /** {@code linkedUserId} non-null = the member is linked to that account (the group owner). */
    private Member member(UUID id, String name, int sortOrder, UUID linkedUserId) {
        Member m = Mockito.mock(Member.class);
        when(m.getUserId()).thenReturn(linkedUserId);
        when(m.getId()).thenReturn(id);
        when(m.getDisplayName()).thenReturn(name);
        when(m.getSortOrder()).thenReturn(sortOrder);
        when(m.getCreatedAt()).thenReturn(Instant.parse("2026-01-01T00:00:00Z"));
        return m;
    }

    // ---- groups -----------------------------------------------------------------------------

    @Test
    void createReturns201WithLocationEtagAndOnlyUsesClientEditableFields() throws Exception {
        ExpenseGroup created = group(1);
        UUID ownerMember = UUID.randomUUID();
        when(groups.create(any(), any(), any(), any())).thenReturn(created);
        // the owner is member #1 and linked to the caller: the response shows it as "you"
        Member ownerRow = member(ownerMember, "Me", 1, me);   // build the mock before stubbing with it
        when(groups.get(me, gid)).thenReturn(new GroupService.GroupDetail(created, List.of(ownerRow), 0L, null,
                ownerMember, 0L, "OWNER"));

        // The client tries to smuggle in owner, version and id: they have nowhere to go.
        String evil = "{\"name\":\"Dahab\",\"type\":\"TRIP\",\"currencyCode\":\"EGP\","
                + "\"ownerUserId\":\"" + UUID.randomUUID() + "\",\"version\":99,\"id\":\"" + UUID.randomUUID() + "\"}";
        MvcResult r = mvc.perform(authed(post("/api/v1/groups")).content(evil)).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        assertThat(r.getResponse().getHeader("Location")).isEqualTo("/api/v1/groups/" + gid);
        assertThat(r.getResponse().getHeader("ETag")).isEqualTo("\"1\"");
        assertThat(body(r).get("members")).hasSize(1);
        assertThat(body(r).get("members").get(0).get("isYou").asBoolean()).isTrue();
        assertThat(body(r).get("yourMemberId").asText()).isEqualTo(ownerMember.toString());
        assertThat(body(r).get("yourNetMinor").asLong()).isZero();
        assertThat(body(r).get("members").get(0).has("userId")).isFalse();   // account ids are never exposed
        verify(groups).create(eq(me), eq("Dahab"), eq("TRIP"), eq("EGP")); // owner is always the token's subject
    }

    @Test
    void getReturnsMembersInOrderAndAnEtagMatchingTheVersion() throws Exception {
        UUID m1 = UUID.randomUUID();
        UUID m2 = UUID.randomUUID();
        ExpenseGroup g = group(4);
        Member a = member(m1, "Ali", 1);
        Member b = member(m2, "Sara", 2);
        when(groups.get(me, gid)).thenReturn(new GroupService.GroupDetail(g, List.of(a, b), 125_050L, Instant.parse("2026-02-03T04:05:06Z"), m1, -2_500L, "OWNER"));

        MvcResult r = mvc.perform(authed(get("/api/v1/groups/" + gid))).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        assertThat(r.getResponse().getHeader("ETag")).isEqualTo("\"4\"");
        JsonNode body = body(r);
        assertThat(body.get("version").asInt()).isEqualTo(4);
        assertThat(body.get("totalSpentMinor").asLong()).isEqualTo(125_050L);
        assertThat(body.get("lastExpenseAt").asText()).isEqualTo("2026-02-03T04:05:06Z");
        assertThat(body.get("members")).hasSize(2);
        assertThat(body.get("members").get(0).get("sortOrder").asInt()).isEqualTo(1);
        assertThat(body.has("ownerUserId")).as("owner id is not exposed").isFalse();
    }

    @Test
    void listIsPagedAndCarriesTheUiFields() throws Exception {
        var row = new GroupService.GroupSummary(gid, "Dahab", "TRIP", "EGP", 5, 9_900L, Instant.parse("2026-02-03T04:05:06Z"), -2_500L, "OWNER");
        when(groups.list(me, 2, 10)).thenReturn(new PageImpl<>(List.of(row), PageRequest.of(2, 10), 21));

        MvcResult r = mvc.perform(authed(get("/api/v1/groups?page=2&size=10"))).andReturn();

        JsonNode body = body(r);
        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        assertThat(body.get("page").asInt()).isEqualTo(2);
        assertThat(body.get("size").asInt()).isEqualTo(10);
        assertThat(body.get("totalElements").asLong()).isEqualTo(21);
        assertThat(body.get("totalPages").asInt()).isEqualTo(3);
        JsonNode item = body.get("items").get(0);
        assertThat(item.get("memberCount").asLong()).isEqualTo(5);
        assertThat(item.get("totalSpentMinor").asLong()).isEqualTo(9_900L);
        assertThat(item.get("lastExpenseAt").asText()).isEqualTo("2026-02-03T04:05:06Z");
    }

    @Test
    void listUsesDefaultPagingWhenNoneGiven() throws Exception {
        when(groups.list(me, 0, 20)).thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));
        assertThat(mvc.perform(authed(get("/api/v1/groups"))).andReturn().getResponse().getStatus()).isEqualTo(200);
        verify(groups).list(me, 0, 20);
    }

    @Test
    void patchRequiresIfMatch() throws Exception {
        MvcResult none = mvc.perform(authed(patch("/api/v1/groups/" + gid)).content("{\"name\":\"X\"}")).andReturn();
        assertThat(none.getResponse().getStatus()).isEqualTo(428);
        assertThat(body(none).get("code").asText()).isEqualTo("VALIDATION_ERROR");

        MvcResult star = mvc.perform(authed(patch("/api/v1/groups/" + gid)).header("If-Match", "*")
                .content("{\"name\":\"X\"}")).andReturn();
        assertThat(star.getResponse().getStatus()).isEqualTo(422);
    }

    @Test
    void patchPassesTheParsedVersionAndReturnsTheNewEtag() throws Exception {
        ExpenseGroup updated = group(4);
        when(groups.update(me, gid, 3, "New", null)).thenReturn(updated);
        Member kept = member(UUID.randomUUID(), "Ali", 1);
        when(groups.get(me, gid)).thenReturn(new GroupService.GroupDetail(updated, List.of(kept), 500L, null, null, null, "OWNER"));

        MvcResult r = mvc.perform(authed(patch("/api/v1/groups/" + gid)).header("If-Match", "\"3\"")
                .content("{\"name\":\"New\"}")).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        assertThat(r.getResponse().getHeader("ETag")).isEqualTo("\"4\"");
        // the body is the full group (same as GET): real members and totals, not an empty member list
        assertThat(body(r).get("members")).hasSize(1);
        assertThat(body(r).get("totalSpentMinor").asLong()).isEqualTo(500L);
    }

    @Test
    void staleVersionIs409VersionConflict() throws Exception {
        when(groups.update(any(), any(), any(Integer.class), any(), any()))
                .thenThrow(ApiException.conflict(ErrorCode.VERSION_CONFLICT, "stale"));

        MvcResult r = mvc.perform(authed(patch("/api/v1/groups/" + gid)).header("If-Match", "\"1\"")
                .content("{\"name\":\"New\"}")).andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(409);
        assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(body(r).get("code").asText()).isEqualTo("VERSION_CONFLICT");
    }

    @Test
    void notFoundAndNotEmptyAreMappedToTheirCodes() throws Exception {
        when(groups.get(any(), any())).thenThrow(ApiException.notFound());
        MvcResult nf = mvc.perform(authed(get("/api/v1/groups/" + gid))).andReturn();
        assertThat(nf.getResponse().getStatus()).isEqualTo(404);
        assertThat(body(nf).get("code").asText()).isEqualTo("NOT_FOUND");

        Mockito.doThrow(ApiException.conflict(ErrorCode.GROUP_NOT_EMPTY, "x")).when(groups).delete(me, gid);
        MvcResult ne = mvc.perform(authed(delete("/api/v1/groups/" + gid))).andReturn();
        assertThat(ne.getResponse().getStatus()).isEqualTo(409);
        assertThat(body(ne).get("code").asText()).isEqualTo("GROUP_NOT_EMPTY");
    }

    @Test
    void deleteReturns204() throws Exception {
        assertThat(mvc.perform(authed(delete("/api/v1/groups/" + gid))).andReturn().getResponse().getStatus())
                .isEqualTo(204);
        verify(groups).delete(me, gid);
    }

    @Test
    void malformedGroupIdIsA400ProblemJson() throws Exception {
        MvcResult r = mvc.perform(authed(get("/api/v1/groups/not-a-uuid"))).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(400);
        assertThat(r.getResponse().getContentType()).startsWith("application/problem+json");
        assertThat(body(r).get("code").asText()).isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void everyGroupAndMemberEndpointRequiresAuthentication() throws Exception {
        UUID mid = UUID.randomUUID();
        MockHttpServletRequestBuilder[] calls = {
                post("/api/v1/groups"), get("/api/v1/groups"), get("/api/v1/groups/" + gid),
                patch("/api/v1/groups/" + gid), delete("/api/v1/groups/" + gid),
                post("/api/v1/groups/" + gid + "/members"),
                patch("/api/v1/groups/" + gid + "/members/" + mid),
                delete("/api/v1/groups/" + gid + "/members/" + mid)};
        for (MockHttpServletRequestBuilder call : calls) {
            MvcResult r = mvc.perform(call.contentType(MediaType.APPLICATION_JSON).content("{}")).andReturn();
            assertThat(r.getResponse().getStatus()).isEqualTo(401);
        }
        Mockito.verifyNoInteractions(groups, members);
    }

    // ---- members ----------------------------------------------------------------------------

    @Test
    void addMemberReturns201WithTheAssignedSortOrder() throws Exception {
        UUID mid = UUID.randomUUID();
        Member created = member(mid, "Ali", 3);
        when(members.add(me, gid, "Ali")).thenReturn(created);

        MvcResult r = mvc.perform(authed(post("/api/v1/groups/" + gid + "/members"))
                .content("{\"displayName\":\"Ali\",\"sortOrder\":99,\"userId\":\"" + UUID.randomUUID() + "\"}"))
                .andReturn();

        assertThat(r.getResponse().getStatus()).isEqualTo(201);
        assertThat(r.getResponse().getHeader("Location")).isEqualTo("/api/v1/groups/" + gid + "/members/" + mid);
        assertThat(body(r).get("sortOrder").asInt()).as("client-supplied sortOrder is ignored").isEqualTo(3);
    }

    @Test
    void duplicateNameAndMemberInUseAre409WithTheirCodes() throws Exception {
        UUID mid = UUID.randomUUID();
        when(members.add(any(), any(), any()))
                .thenThrow(ApiException.conflict(ErrorCode.DUPLICATE_MEMBER_NAME, "dup"));
        MvcResult dup = mvc.perform(authed(post("/api/v1/groups/" + gid + "/members"))
                .content("{\"displayName\":\"Ali\"}")).andReturn();
        assertThat(dup.getResponse().getStatus()).isEqualTo(409);
        assertThat(body(dup).get("code").asText()).isEqualTo("DUPLICATE_MEMBER_NAME");

        Mockito.doThrow(ApiException.conflict(ErrorCode.MEMBER_HAS_TRANSACTIONS, "used"))
                .when(members).delete(me, gid, mid);
        MvcResult used = mvc.perform(authed(delete("/api/v1/groups/" + gid + "/members/" + mid))).andReturn();
        assertThat(used.getResponse().getStatus()).isEqualTo(409);
        assertThat(body(used).get("code").asText()).isEqualTo("MEMBER_HAS_TRANSACTIONS");
    }

    @Test
    void renameAndDeleteMemberGoThroughTheServiceWithTheTokenUser() throws Exception {
        UUID mid = UUID.randomUUID();
        Member renamed = member(mid, "Sara", 2);
        when(members.update(me, gid, mid, new app.qesma.service.MemberService.MemberPatch("Sara", null, null))).thenReturn(renamed);

        MvcResult r = mvc.perform(authed(patch("/api/v1/groups/" + gid + "/members/" + mid))
                .content("{\"displayName\":\"Sara\"}")).andReturn();
        assertThat(r.getResponse().getStatus()).isEqualTo(200);
        assertThat(body(r).get("displayName").asText()).isEqualTo("Sara");

        assertThat(mvc.perform(authed(delete("/api/v1/groups/" + gid + "/members/" + mid))).andReturn()
                .getResponse().getStatus()).isEqualTo(204);
        verify(members).delete(me, gid, mid);
    }
}
