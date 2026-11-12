package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.POST;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B11 races: the invite row lock, the conditional claim and the unique indexes make parallel joins safe.
 * Every scenario releases all threads at the same instant and asserts the exact outcome, not "at most".
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class InviteConcurrencyIT extends AbstractApiIT {

    private static final int THREADS = 6;

    /** Runs the calls together and returns "status code" -> how many answers had it. */
    private Map<String, Integer> race(List<Callable<MvcResult>> calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(calls.size());
        CountDownLatch ready = new CountDownLatch(calls.size());
        CountDownLatch go = new CountDownLatch(1);
        List<Future<String>> results = new ArrayList<>();
        try {
            for (Callable<MvcResult> c : calls) {
                results.add(pool.submit(() -> {
                    ready.countDown();
                    go.await();
                    MvcResult r = c.call();
                    String code = r.getResponse().getContentAsString().contains("\"code\"")
                            ? " " + json.readTree(r.getResponse().getContentAsString()).path("code").asText() : "";
                    return r.getResponse().getStatus() + code;
                }));
            }
            ready.await();
            go.countDown();
            Map<String, Integer> counts = new TreeMap<>();
            for (Future<String> f : results) {
                counts.merge(f.get(), 1, Integer::sum);
            }
            return counts;
        } finally {
            pool.shutdownNow();
        }
    }

    private String newGroup(Session owner) throws Exception {
        return createGroup(owner, "Race " + UUID.randomUUID()).get("id").asText();
    }

    private String inviteCode(Session owner, String gid, Map<String, Object> body) throws Exception {
        MvcResult r = call(POST, "/api/v1/groups/" + gid + "/invites", owner, body, "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(status(r)).isEqualTo(201);
        return body(r).get("code").asText();
    }

    private Callable<MvcResult> join(Session as, String code, Object body) {
        return () -> call(POST, "/api/v1/invites/" + code + "/join", as, body, "Idempotency-Key", UUID.randomUUID().toString());
    }

    @Test
    void ofManyPeopleClaimingTheSameGhostExactlyOneWins() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        String ghost = addMember(owner, gid, "Ghost").get("id").asText();
        String code = inviteCode(owner, gid, Map.of());
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < THREADS; i++) {
            calls.add(join(newUser(), code, Map.of("claimMemberId", ghost)));
        }

        Map<String, Integer> outcome = race(calls);

        assertThat(outcome).containsEntry("201", 1).containsEntry("409 MEMBER_ALREADY_CLAIMED", THREADS - 1).hasSize(2);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id is not null and role = 'MEMBER'",
                Long.class, gid)).isEqualTo(1L);
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code)).isEqualTo(1);
    }

    @Test
    void maxUsesHoldsUnderParallelJoins() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        String code = inviteCode(owner, gid, Map.of("maxUses", 3));
        List<Callable<MvcResult>> calls = new ArrayList<>();
        for (int i = 0; i < THREADS; i++) {
            calls.add(join(newUser(), code, Map.of("newMemberName", "Guest " + i)));
        }

        Map<String, Integer> outcome = race(calls);

        assertThat(outcome).containsEntry("201", 3).containsEntry("410 INVITE_EXPIRED", THREADS - 3).hasSize(2);
        assertThat(jdbc.queryForObject("select use_count from group_invites where code = ?", Integer.class, code)).isEqualTo(3);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Long.class, gid))
                .as("the owner plus exactly three joiners").isEqualTo(4L);
        assertThat(jdbc.queryForObject("select count(distinct sort_order) from members where group_id = ?::uuid", Long.class, gid))
                .as("sort orders are never repeated").isEqualTo(4L);
    }

    @Test
    void oneAccountJoiningTwiceAtOnceBecomesOneMember() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        String code = inviteCode(owner, gid, Map.of());
        Session joiner = newUser();

        Map<String, Integer> outcome = race(List.of(
                join(joiner, code, Map.of("newMemberName", "Same A")),
                join(joiner, code, Map.of("newMemberName", "Same B")),
                join(joiner, code, Map.of("newMemberName", "Same C"))));

        assertThat(outcome).containsEntry("201", 1).containsEntry("409 ALREADY_MEMBER", 2).hasSize(2);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id = ?::uuid", Long.class,
                gid, joiner.userId().toString())).isEqualTo(1L);
    }

    @Test
    void oneAccountUsingTwoInvitesOfTheSameGroupAtOnceBecomesOneMember() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        String first = inviteCode(owner, gid, Map.of());
        String second = inviteCode(owner, gid, Map.of());
        Session joiner = newUser();

        Map<String, Integer> outcome = race(List.of(
                join(joiner, first, Map.of("newMemberName", "Via First")),
                join(joiner, second, Map.of("newMemberName", "Via Second"))));

        assertThat(outcome).as("different invite rows, so the unique index is the last defense")
                .containsEntry("201", 1).containsEntry("409 ALREADY_MEMBER", 1).hasSize(2);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and user_id = ?::uuid", Long.class,
                gid, joiner.userId().toString())).isEqualTo(1L);
    }

    @Test
    void approvingAndRevokingAtOnceNeverLeavesAHalfDoneRequest() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        MvcResult created = call(POST, "/api/v1/groups/" + gid + "/invites", owner, Map.of("requiresApproval", true),
                "Idempotency-Key", UUID.randomUUID().toString());
        String code = body(created).get("code").asText();
        String iid = body(created).get("id").asText();
        String rid = body(call(POST, "/api/v1/invites/" + code + "/join", newUser(), Map.of("newMemberName", "Wants In"),
                "Idempotency-Key", UUID.randomUUID().toString())).get("requestId").asText();

        Map<String, Integer> outcome = race(List.of(
                () -> call(POST, "/api/v1/groups/" + gid + "/join-requests/" + rid + "/approve", owner, null),
                () -> call(org.springframework.http.HttpMethod.DELETE, "/api/v1/groups/" + gid + "/invites/" + iid, owner, null)));

        assertThat(outcome).containsEntry("200", 1).containsEntry("204", 1).hasSize(2);
        assertThat(jdbc.queryForObject("select status from join_requests where id = ?::uuid", String.class, rid))
                .as("an approval of an already existing request is not blocked by a revoke").isEqualTo("APPROVED");
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Long.class, gid)).isEqualTo(2L);
    }
}
