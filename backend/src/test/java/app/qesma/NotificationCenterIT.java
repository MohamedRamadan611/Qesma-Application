package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** B15: the per-user notification center: list, unread count, mark read, isolation between users (A100-A103). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class NotificationCenterIT extends AbstractActivityIT {

    private static final String LIST = "/api/v1/notifications";
    private static final String COUNT = "/api/v1/notifications/unread-count";
    private static final String READ = "/api/v1/notifications/read";

    private final class Cast {
        final Session owner = newUser();
        final Session alice = newUser();
        final Session bob = newUser();
        final String gid;
        final String ownerMid;
        final String aliceMid;
        final String bobMid;

        Cast(int expenses) throws Exception {
            gid = createGroup(owner, "Center " + UUID.randomUUID()).get("id").asText();
            ownerMid = member(owner, gid, "Owner").get("id").asText();
            aliceMid = linkUser(gid, alice, "MEMBER", "ACTIVE", "Alice");
            bobMid = linkUser(gid, bob, "MEMBER", "ACTIVE", "Bob");
            for (int i = 0; i < expenses; i++) {
                createExpense(owner, gid, equalBody("Dinner " + i, 1000, List.of(ownerMid, aliceMid, bobMid), ownerMid, 1000L));
            }
        }

        JsonNode list(Session as, String query) throws Exception {
            MvcResult r = call(GET, LIST + query, as, null);
            assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
            return body(r);
        }

        long unread(Session as) throws Exception {
            return body(call(GET, COUNT, as, null)).get("count").asLong();
        }
    }

    @Test
    void theCenterListsMyNotificationsNewestFirstWithGroupNameActorAndSubjectAndNobodyElses() throws Exception {
        Cast c = new Cast(2);
        JsonNode items = c.list(c.alice, "").get("items");

        assertThat(items).hasSize(2);
        JsonNode newest = items.get(0);
        assertThat(newest.get("type").asText()).isEqualTo("EXPENSE_ADDED");
        assertThat(newest.get("groupId").asText()).isEqualTo(c.gid);
        assertThat(newest.get("groupName").asText()).startsWith("Center ");
        assertThat(newest.get("actorName").asText()).isEqualTo("Owner");
        assertThat(newest.get("actorMemberId").asText()).isEqualTo(c.ownerMid);
        assertThat(newest.get("subject").asText()).isEqualTo("Dinner 1");
        assertThat(newest.get("readAt").isNull()).isTrue();
        assertThat(newest.get("payload").get("totalMinor").asLong()).isEqualTo(1000L);
        assertThat(items.get(1).get("subject").asText()).isEqualTo("Dinner 0");

        assertThat(c.list(c.owner, "").get("items")).as("the actor is never notified of their own action").isEmpty();
        assertThat(c.list(newUser(), "").get("items")).isEmpty();
        List<String> aliceIds = idsOf(items);
        assertThat(idsOf(c.list(c.bob, "").get("items"))).as("separate rows per user").doesNotContainAnyElementsOf(aliceIds);
        assertThat(c.unread(c.alice)).isEqualTo(2);
    }

    @Test
    void markingByIdsMarksOnlyThoseAndAllMarksTheRestAndRepeatingChangesNothing() throws Exception {
        Cast c = new Cast(3);
        JsonNode items = c.list(c.alice, "").get("items");
        String first = items.get(0).get("id").asText();
        String second = items.get(1).get("id").asText();

        MvcResult one = call(POST, READ, c.alice, Map.of("ids", List.of(first, second)));
        assertThat(status(one)).isEqualTo(200);
        assertThat(body(one).get("marked").asInt()).isEqualTo(2);
        assertThat(body(one).get("unreadCount").asLong()).isEqualTo(1);
        assertThat(c.unread(c.alice)).isEqualTo(1);

        MvcResult again = call(POST, READ, c.alice, Map.of("ids", List.of(first)));
        assertThat(body(again).get("marked").asInt()).as("already read: not counted again").isZero();
        assertThat(body(again).get("unreadCount").asLong()).isEqualTo(1);
        JsonNode afterOne = c.list(c.alice, "").get("items");
        assertThat(afterOne.get(0).get("readAt").isNull()).isFalse();
        assertThat(afterOne.get(2).get("readAt").isNull()).isTrue();

        MvcResult all = call(POST, READ, c.alice, Map.of("all", true));
        assertThat(body(all).get("marked").asInt()).isEqualTo(1);
        assertThat(body(all).get("unreadCount").asLong()).isZero();
        assertThat(c.unread(c.bob)).as("Bob's rows were not touched by Alice's calls").isEqualTo(3);
    }

    @Test
    void anotherUsersOrUnknownIdsAreIgnoredWithTheSameAnswerAndTheirRowStaysUnread() throws Exception {
        Cast c = new Cast(1);
        String bobsId = c.list(c.bob, "").get("items").get(0).get("id").asText();

        MvcResult foreign = call(POST, READ, c.alice, Map.of("ids", List.of(bobsId)));
        MvcResult unknown = call(POST, READ, c.alice, Map.of("ids", List.of(UUID.randomUUID().toString())));

        assertThat(status(foreign)).isEqualTo(200);
        assertThat(body(foreign).get("marked").asInt()).isZero();
        assertThat(body(foreign)).as("identical for a foreign and an unknown id").isEqualTo(body(unknown));
        assertThat(c.unread(c.bob)).as("Bob's notification is still unread").isEqualTo(1);
        assertThat(jdbc.queryForObject("select read_at is null from notifications where id = ?::uuid", Boolean.class,
                bobsId)).isTrue();
    }

    @Test
    void theMarkReadBodyNeedsExactlyOneOfIdsOrAllWithinBounds() throws Exception {
        Cast c = new Cast(0);
        List<Object> badBodies = new ArrayList<>();
        badBodies.add(Map.of());
        badBodies.add(Map.of("all", false));
        badBodies.add(Map.of("ids", List.of(), "all", false));
        badBodies.add(Map.of("ids", List.of()));
        badBodies.add(Map.of("ids", List.of(UUID.randomUUID().toString()), "all", true));
        badBodies.add(Map.of("ids", java.util.stream.IntStream.range(0, 101).mapToObj(i -> UUID.randomUUID().toString()).toList()));
        for (Object bad : badBodies) {
            MvcResult r = call(POST, READ, c.alice, bad);
            assertThat(status(r)).as(bad.toString()).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(status(call(POST, READ, c.alice, Map.of("ids", java.util.stream.IntStream.range(0, 100)
                .mapToObj(i -> UUID.randomUUID().toString()).toList())))).as("100 ids is the maximum").isEqualTo(200);
        assertThat(status(call(POST, READ, c.alice, Map.of("ids", List.of("not-a-uuid"))))).as("malformed JSON value").isEqualTo(400);
        assertThat(status(call(POST, READ, null, Map.of("all", true)))).isEqualTo(401);
        assertThat(status(call(GET, LIST, null, null))).isEqualTo(401);
        assertThat(status(call(GET, COUNT, null, null))).isEqualTo(401);
    }

    @Test
    void theListPagesWithAnOpaqueCursorAndRejectsABadOne() throws Exception {
        Cast c = new Cast(5);
        JsonNode first = c.list(c.alice, "?limit=2");
        assertThat(first.get("items")).hasSize(2);
        String next = first.get("nextBefore").asText();
        JsonNode second = c.list(c.alice, "?limit=2&before=" + next);
        JsonNode third = c.list(c.alice, "?limit=2&before=" + second.get("nextBefore").asText());
        assertThat(third.get("items")).hasSize(1);
        assertThat(third.get("nextBefore").isNull()).isTrue();
        List<String> all = new ArrayList<>(idsOf(first.get("items")));
        all.addAll(idsOf(second.get("items")));
        all.addAll(idsOf(third.get("items")));
        assertThat(all).doesNotHaveDuplicates().containsExactlyElementsOf(idsOf(c.list(c.alice, "").get("items")));

        for (String bad : List.of("?limit=0", "?limit=51", "?before=garbage")) {
            MvcResult r = call(GET, LIST + bad, c.alice, null);
            assertThat(status(r)).as(bad).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
    }

    @Test
    void aUserWhoLeftStillListsTheirNotificationsButNamesAreNoLongerResolved() throws Exception {
        Cast c = new Cast(1);
        assertThat(status(call(PATCH, "/api/v1/groups/" + c.gid + "/members/" + c.ownerMid, c.owner,
                Map.of("displayName", "Owner Renamed")))).isEqualTo(200);
        assertThat(c.list(c.alice, "").get("items").get(0).get("actorName").asText()).isEqualTo("Owner Renamed");
        assertThat(status(call(POST, "/api/v1/groups/" + c.gid + "/leave", c.alice, null))).isEqualTo(204);

        JsonNode items = c.list(c.alice, "").get("items");
        JsonNode expense = null;
        for (JsonNode i : items) {
            if (i.get("type").asText().equals("EXPENSE_ADDED")) {
                expense = i;
            }
        }
        assertThat(expense).as("still listed after leaving").isNotNull();
        assertThat(expense.get("groupName").asText()).startsWith("Center ");
        assertThat(expense.get("subject").isNull()).as("no subject for a LEFT user").isTrue();
        assertThat(expense.get("actorName").isNull()).as("no actor name for a LEFT user").isTrue();
        assertThat(expense.get("actorMemberId").asText()).isEqualTo(c.ownerMid);
        assertThat(c.unread(c.alice)).isEqualTo(1);
    }
}
