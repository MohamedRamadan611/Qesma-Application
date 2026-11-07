package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.service.IdempotencyCleanupJob;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** Spec 8.3: replay, key reuse, concurrent duplicates, expiry and cleanup, against real PostgreSQL. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ExpenseIdempotencyIT extends AbstractApiIT {

    @Autowired IdempotencyCleanupJob cleanup;

    private List<String> groupWith(Session owner, String... names) throws Exception {
        List<String> ids = new ArrayList<>();
        ids.add(createGroup(owner, "G " + UUID.randomUUID()).get("id").asText());
        for (String n : names) {
            ids.add(member(owner, ids.get(0), n).get("id").asText());
        }
        return ids;
    }

    private int keyRows(Session s, String key) {
        return jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?",
                Integer.class, s.userId(), key);
    }

    @Test
    void theSameKeyAndBodyTwiceCreatesOneExpenseAndReturnsTheSameResponse() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B");
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Dinner", 10001, null, g.get(1), 10001L);

        MvcResult first = postExpense(ali, g.get(0), key, body);
        MvcResult second = postExpense(ali, g.get(0), key, body);

        assertThat(status(first)).isEqualTo(201);
        assertThat(status(second)).isEqualTo(201);
        assertThat(first.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(second.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(second)).isEqualTo(body(first)); // same content (the jsonb column normalizes formatting)
        assertThat(second.getResponse().getHeader("Location")).isEqualTo(first.getResponse().getHeader("Location"));
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
        assertThat(keyRows(ali, key)).isEqualTo(1);
    }

    @Test
    void keyCaseAndRequestOrderDoNotMatter() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B");
        String key = UUID.randomUUID().toString();
        MvcResult first = postExpense(ali, g.get(0), key,
                equalBody("Dinner", 100, List.of(g.get(1), g.get(2)), g.get(1), 60L, g.get(2), 40L));
        MvcResult second = postExpense(ali, g.get(0), key.toUpperCase(),
                equalBody("Dinner", 100, List.of(g.get(2), g.get(1)), g.get(2), 40L, g.get(1), 60L));

        assertThat(status(second)).isEqualTo(201);
        assertThat(second.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(second).get("id").asText()).isEqualTo(body(first).get("id").asText());
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void twentyParallelRequestsWithTheSameKeyCreateExactlyOneExpense() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A", "B", "C");
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Parallel", 30000, null, g.get(1), 30000L);

        ExecutorService pool = Executors.newFixedThreadPool(20);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            Callable<MvcResult> call = () -> {
                go.await();
                return postExpense(ali, g.get(0), key, body);
            };
            futures.add(pool.submit(call));
        }
        go.countDown();
        List<MvcResult> results = new ArrayList<>();
        for (Future<MvcResult> f : futures) {
            results.add(f.get());
        }
        pool.shutdown();

        assertThat(countExpenses(g.get(0))).isEqualTo(1);
        assertThat(keyRows(ali, key)).isEqualTo(1);
        Integer splitRows = jdbc.queryForObject(
                "select count(*) from expense_splits s join expenses e on e.id = s.expense_id where e.group_id = ?::uuid",
                Integer.class, g.get(0));
        assertThat(splitRows).isEqualTo(3); // children were not duplicated either
        String id = null;
        long replays = 0;
        for (MvcResult r : results) {
            assertThat(status(r)).isEqualTo(201);
            String thisId = body(r).get("id").asText();
            id = id == null ? thisId : id;
            assertThat(thisId).isEqualTo(id);
            if ("true".equals(r.getResponse().getHeader("Idempotency-Replayed"))) {
                replays++;
            }
        }
        assertThat(replays).isEqualTo(19);
    }

    @Test
    void parallelSameKeyRequestsForDifferentBodiesYieldOneWinnerAndTheRestAreKeyReuse() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String key = UUID.randomUUID().toString();
        ExecutorService pool = Executors.newFixedThreadPool(6);
        CountDownLatch go = new CountDownLatch(1);
        List<Future<MvcResult>> futures = new ArrayList<>();
        for (int i = 0; i < 6; i++) {
            long total = 1000L + i; // six different bodies, one key
            futures.add(pool.submit(() -> {
                go.await();
                return postExpense(ali, g.get(0), key, equalBody("Race", total, null, g.get(1), total));
            }));
        }
        go.countDown();
        int created = 0;
        int reused = 0;
        for (Future<MvcResult> f : futures) {
            MvcResult r = f.get();
            if (status(r) == 201) {
                created++;
            } else {
                assertThat(status(r)).isEqualTo(422);
                assertThat(code(r)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
                reused++;
            }
        }
        pool.shutdown();
        assertThat(created).isEqualTo(1);
        assertThat(reused).isEqualTo(5);
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void theSameKeyWithADifferentBodyOrGroupIsKeyReuseAndCreatesNothing() throws Exception {
        Session ali = newUser();
        List<String> g1 = groupWith(ali, "A", "B");
        List<String> g2 = groupWith(ali, "A", "B");
        String key = UUID.randomUUID().toString();
        assertThat(status(postExpense(ali, g1.get(0), key, equalBody("One", 100, null, g1.get(1), 100L)))).isEqualTo(201);

        for (MvcResult r : List.of(
                postExpense(ali, g1.get(0), key, equalBody("One", 101, null, g1.get(1), 101L)),      // total
                postExpense(ali, g1.get(0), key, equalBody("Two", 100, null, g1.get(1), 100L)),      // title
                postExpense(ali, g1.get(0), key, equalBody("One", 100, null, g1.get(2), 100L)),      // payer
                postExpense(ali, g2.get(0), key, equalBody("One", 100, null, g2.get(1), 100L)))) {   // other group
            assertThat(status(r)).isEqualTo(422);
            assertThat(code(r)).isEqualTo("IDEMPOTENCY_KEY_REUSED");
        }
        assertThat(countExpenses(g1.get(0))).isEqualTo(1);
        assertThat(countExpenses(g2.get(0))).isZero();
    }

    @Test
    void aFailedRequestStoresNoKeySoACorrectedRetryWithTheSameKeySucceeds() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String key = UUID.randomUUID().toString();

        MvcResult bad = postExpense(ali, g.get(0), key, equalBody("x", 100, null, g.get(1), 99L));
        assertThat(status(bad)).isEqualTo(422);
        assertThat(code(bad)).isEqualTo("PAYERS_TOTAL_MISMATCH");
        assertThat(keyRows(ali, key)).isZero();

        MvcResult fixed = postExpense(ali, g.get(0), key, equalBody("x", 100, null, g.get(1), 100L));
        assertThat(status(fixed)).isEqualTo(201);
        assertThat(fixed.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void anExpiredKeyIsTreatedAsNeverSeenEvenBeforeTheCleanupJobRuns() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String key = UUID.randomUUID().toString();
        JsonNode old = body(postExpense(ali, g.get(0), key, equalBody("old", 100, null, g.get(1), 100L)));
        jdbc.update("update idempotency_keys set created_at = now() - interval '25 hours' where user_id = ? and key = ?",
                ali.userId(), key);

        MvcResult again = postExpense(ali, g.get(0), key, equalBody("new body", 200, null, g.get(1), 200L));

        assertThat(status(again)).isEqualTo(201);
        assertThat(again.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(body(again).get("id").asText()).isNotEqualTo(old.get("id").asText());
        assertThat(countExpenses(g.get(0))).isEqualTo(2);
        assertThat(keyRows(ali, key)).isEqualTo(1); // the expired row was replaced
    }

    @Test
    void aKeyJustInsideTheWindowIsStillReplayed() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String key = UUID.randomUUID().toString();
        Object body = equalBody("recent", 100, null, g.get(1), 100L);
        postExpense(ali, g.get(0), key, body);
        jdbc.update("update idempotency_keys set created_at = now() - interval '23 hours' where user_id = ? and key = ?",
                ali.userId(), key);

        MvcResult again = postExpense(ali, g.get(0), key, body);
        assertThat(again.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void theCleanupJobDeletesOnlyKeysOlderThan24Hours() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String oldKey = UUID.randomUUID().toString();
        String freshKey = UUID.randomUUID().toString();
        postExpense(ali, g.get(0), oldKey, equalBody("old", 100, null, g.get(1), 100L));
        postExpense(ali, g.get(0), freshKey, equalBody("fresh", 100, null, g.get(1), 100L));
        jdbc.update("update idempotency_keys set created_at = now() - interval '48 hours' where user_id = ? and key = ?",
                ali.userId(), oldKey);

        int deleted = cleanup.runOnce();

        assertThat(deleted).isGreaterThanOrEqualTo(1);
        assertThat(keyRows(ali, oldKey)).isZero();
        assertThat(keyRows(ali, freshKey)).isEqualTo(1);
        assertThat(countExpenses(g.get(0))).isEqualTo(2); // expenses are never touched by the cleanup
    }

    @Test
    void theStoredResponseSurvivesLaterGroupChangesAndIsServedAsCreated() throws Exception {
        Session ali = newUser();
        List<String> g = groupWith(ali, "A");
        String key = UUID.randomUUID().toString();
        Object body = equalBody("snapshot", 100, null, g.get(1), 100L);
        JsonNode created = body(postExpense(ali, g.get(0), key, body));

        member(ali, g.get(0), "Joined later");
        JsonNode replayed = body(postExpense(ali, g.get(0), key, body));

        assertThat(replayed).isEqualTo(created);
        assertThat(replayed.get("shares")).hasSize(1); // still the creation-time snapshot
    }
}
