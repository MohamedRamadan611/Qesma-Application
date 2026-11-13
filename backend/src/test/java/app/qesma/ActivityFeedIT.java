package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;

import com.fasterxml.jackson.databind.JsonNode;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** B15: keyset pagination of the group feed (A101), who may read it (A102) and how names are resolved (A100). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ActivityFeedIT extends AbstractActivityIT {

    private record Group(Session owner, String gid, String ownerMid) {
        String feed() {
            return "/api/v1/groups/" + gid + "/activity";
        }
    }

    private Group group() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Feed " + UUID.randomUUID()).get("id").asText();
        return new Group(owner, gid, member(owner, gid, "Owner").get("id").asText());
    }

    private static String cursor(String text) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(text.getBytes(StandardCharsets.UTF_8));
    }

    private void insertEvent(String gid, UUID id, Instant at) {
        jdbc.update("insert into group_events (id, group_id, type, payload, created_at) "
                + "values (?, ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, ?)", id, gid, Timestamp.from(at));
    }

    // ---- pagination ---------------------------------------------------------------------------------------------------

    @Test
    void pagesAreStableAndCompleteEvenWhenManyEventsShareOneTimestamp() throws Exception {
        Group g = group();
        Instant same = Instant.parse("2026-10-01T10:00:00.123456Z");
        List<UUID> all = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            UUID id = UUID.randomUUID();
            all.add(id);
            insertEvent(g.gid(), id, same);                    // seven rows with an identical created_at
        }
        for (int i = 0; i < 3; i++) {
            UUID id = UUID.randomUUID();
            all.add(id);
            insertEvent(g.gid(), id, same.plusSeconds(60L * (i + 1)).plusNanos(1_000));
        }
        List<String> expected = all.stream().sorted(Comparator.comparing((UUID id) -> createdAt(id))
                .thenComparing(UUID::toString).reversed()).map(UUID::toString).toList();

        List<String> seen = new ArrayList<>();
        String before = null;
        int pages = 0;
        do {
            JsonNode page = feed(g.owner(), g.gid(), "?limit=3" + (before == null ? "" : "&before=" + before));
            seen.addAll(idsOf(page.get("items")));
            before = page.get("nextBefore").isNull() ? null : page.get("nextBefore").asText();
            pages++;
        } while (before != null && pages < 10);

        assertThat(pages).isEqualTo(4);                          // 3 + 3 + 3 + 1
        assertThat(seen).as("no duplicate and no gap across page boundaries").containsExactlyElementsOf(expected);
    }

    private Instant createdAt(UUID eventId) {
        return jdbc.queryForObject("select created_at from group_events where id = ?", Timestamp.class, eventId).toInstant();
    }

    @Test
    void theLastPageHasANullNextBeforeAndAnExactFullPageToo() throws Exception {
        Group g = group();
        for (int i = 0; i < 3; i++) {
            insertEvent(g.gid(), UUID.randomUUID(), Instant.parse("2026-10-01T10:00:00Z").plusSeconds(i));
        }
        JsonNode exact = feed(g.owner(), g.gid(), "?limit=3");
        assertThat(exact.get("items")).hasSize(3);
        assertThat(exact.get("nextBefore").isNull()).as("exactly one full page: nothing more").isTrue();
        JsonNode first = feed(g.owner(), g.gid(), "?limit=2");
        assertThat(first.get("nextBefore").isNull()).isFalse();
        JsonNode rest = feed(g.owner(), g.gid(), "?limit=2&before=" + first.get("nextBefore").asText());
        assertThat(rest.get("items")).hasSize(1);
        assertThat(rest.get("nextBefore").isNull()).isTrue();
        assertThat(feed(g.owner(), g.gid(), "").get("items")).as("default limit 20").hasSize(3);
    }

    @Test
    void limitIsBoundedAndABadCursorIsA422ValidationError() throws Exception {
        Group g = group();
        assertThat(status(call(GET, g.feed() + "?limit=abc", g.owner(), null))).as("not a number").isEqualTo(400);
        for (String bad : List.of("?limit=0", "?limit=-1", "?limit=51")) {
            MvcResult r = call(GET, g.feed() + bad, g.owner(), null);
            assertThat(status(r)).as(bad).isEqualTo(422);
            assertThat(code(r)).as(bad).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(status(call(GET, g.feed() + "?limit=50", g.owner(), null))).isEqualTo(200);
        assertThat(status(call(GET, g.feed() + "?limit=1", g.owner(), null))).isEqualTo(200);

        String uuid = UUID.randomUUID().toString();
        List<String> cursors = List.of("not-a-cursor", "!!!", cursor("nocolon"), cursor("abc:" + uuid), cursor("123:not-a-uuid"),
                cursor("-5:" + uuid), cursor("999999999999999999:" + uuid), cursor(":" + uuid), "x".repeat(300));
        for (String bad : cursors) {
            MvcResult r = call(GET, g.feed() + "?before=" + bad, g.owner(), null);
            assertThat(status(r)).as("cursor " + bad).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
            assertThat(r.getResponse().getContentAsString()).doesNotContain("Exception");
        }
        assertThat(status(call(GET, g.feed() + "?before=" + cursor("1700000000000000:" + uuid), g.owner(), null)))
                .as("a well-formed cursor is fine").isEqualTo(200);
    }

    // ---- authorization -------------------------------------------------------------------------------------------------

    @Test
    void membersReadTheFeedWhileAStrangerAndAMemberWhoLeftGetTheSame404AsAnUnknownGroup() throws Exception {
        Group g = group();
        Session member = newUser();
        Session left = newUser();
        Session stranger = newUser();
        linkUser(g.gid(), member, "MEMBER", "ACTIVE", "Member");
        linkUser(g.gid(), left, "MEMBER", "LEFT", "Gone");
        insertEvent(g.gid(), UUID.randomUUID(), Instant.parse("2026-10-01T10:00:00Z"));

        assertThat(status(call(GET, g.feed(), g.owner(), null))).isEqualTo(200);
        assertThat(status(call(GET, g.feed(), member, null))).isEqualTo(200);
        MvcResult missing = call(GET, "/api/v1/groups/" + UUID.randomUUID() + "/activity", stranger, null);
        assertThat(status(missing)).isEqualTo(404);
        for (Session s : List.of(stranger, left)) {
            MvcResult r = call(GET, g.feed(), s, null);
            assertThat(status(r)).isEqualTo(404);
            assertThat(problemWithoutRequestId(r)).isEqualTo(problemWithoutRequestId(missing));
        }
        assertThat(status(call(GET, g.feed(), null, null))).isEqualTo(401);
    }

    @Test
    void aMemberReadsTheWholeHistoryNotOnlyWhatHappenedAfterTheyJoined() throws Exception {
        Group g = group();
        insertEvent(g.gid(), UUID.randomUUID(), Instant.parse("2020-01-01T10:00:00Z"));
        Session late = newUser();
        linkUser(g.gid(), late, "MEMBER", "ACTIVE", "Late");
        assertThat(feed(late, g.gid(), "").get("items")).hasSize(1);
    }

    // ---- read model ----------------------------------------------------------------------------------------------------

    @Test
    void subjectIsTheExpenseTitleAlsoAfterASoftDeleteAndTheMembersCurrentNameForMemberEvents() throws Exception {
        Group g = group();
        Session alice = newUser();
        String aliceMid = linkUser(g.gid(), alice, "MEMBER", "ACTIVE", "Alice");
        String eid = createExpense(g.owner(), g.gid(), equalBody("Fish dinner", 1000, List.of(g.ownerMid(), aliceMid),
                g.ownerMid(), 1000L)).get("id").asText();
        assertThat(status(call(PATCH, "/api/v1/groups/" + g.gid() + "/members/" + aliceMid, g.owner(),
                Map.of("role", "ADMIN")))).isEqualTo(200);
        assertThat(status(call(DELETE, "/api/v1/groups/" + g.gid() + "/expenses/" + eid, g.owner(), null,
                "If-Match", "\"1\""))).isEqualTo(204);
        assertThat(status(call(PATCH, "/api/v1/groups/" + g.gid() + "/members/" + aliceMid, g.owner(),
                Map.of("displayName", "Alice Renamed")))).isEqualTo(200);

        JsonNode items = feed(g.owner(), g.gid(), "").get("items");
        assertThat(items).hasSize(3);
        JsonNode deleted = items.get(0);
        JsonNode role = items.get(1);
        JsonNode added = items.get(2);
        assertThat(deleted.get("type").asText()).isEqualTo("EXPENSE_DELETED");
        assertThat(deleted.get("subject").asText()).as("a soft-deleted expense keeps its title").isEqualTo("Fish dinner");
        assertThat(added.get("type").asText()).isEqualTo("EXPENSE_ADDED");
        assertThat(added.get("subject").asText()).isEqualTo("Fish dinner");
        assertThat(added.get("actorMemberId").asText()).isEqualTo(g.ownerMid());
        assertThat(added.get("payload").get("expenseId").asText()).isEqualTo(eid);
        assertThat(added.get("payload").get("totalMinor").asLong()).isEqualTo(1000L);
        assertThat(role.get("type").asText()).isEqualTo("ROLE_CHANGED");
        assertThat(role.get("subject").asText()).as("resolved at read time: the new name").isEqualTo("Alice Renamed");
        assertThat(role.get("payload").get("role").asText()).isEqualTo("ADMIN");
    }

    @Test
    void settlementEventsHaveNoSubject() throws Exception {
        Group g = group();
        Session alice = newUser();
        String aliceMid = linkUser(g.gid(), alice, "MEMBER", "ACTIVE", "Alice");
        call(org.springframework.http.HttpMethod.POST, "/api/v1/groups/" + g.gid() + "/settlements", alice,
                Map.of("fromMemberId", aliceMid, "toMemberId", g.ownerMid(), "amountMinor", 100L, "settledOn", "2026-10-20"),
                "Idempotency-Key", UUID.randomUUID().toString());
        JsonNode item = feed(alice, g.gid(), "").get("items").get(0);
        assertThat(item.get("type").asText()).isEqualTo("SETTLEMENT_PENDING");
        assertThat(item.get("subject").isNull()).isTrue();
        assertThat(item.get("payload").get("amountMinor").asLong()).isEqualTo(100L);
    }
}
