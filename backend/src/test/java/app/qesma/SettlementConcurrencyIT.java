package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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
 * B13 / A84: two simultaneous transitions on the same settlement are decided by the conditional UPDATE. Confirm racing
 * cancel: exactly one wins (200) and the loser gets 409 INVALID_STATE_TRANSITION; the stored status is the winner's.
 * The same action twice at once is idempotent: both get 200 and see one and the same timestamp.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class SettlementConcurrencyIT extends AbstractApiIT {

    private static final int ROUNDS = 25;

    private record Raced(int status, String code, JsonNode body) {
    }

    private Raced raced(Session as, String gid, String sid, String action) throws Exception {
        MvcResult r = call(POST, "/api/v1/groups/" + gid + "/settlements/" + sid + "/" + action, as, null);
        return new Raced(status(r), status(r) == 200 ? "" : code(r), status(r) == 200 ? body(r) : null);
    }

    private List<Raced> race(List<Callable<Raced>> tasks) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(tasks.size());
        try {
            CountDownLatch ready = new CountDownLatch(tasks.size());
            CountDownLatch go = new CountDownLatch(1);
            List<Future<Raced>> futures = new ArrayList<>();
            for (Callable<Raced> t : tasks) {
                futures.add(pool.submit(() -> {
                    ready.countDown();
                    go.await();
                    return t.call();
                }));
            }
            ready.await();
            go.countDown();
            List<Raced> out = new ArrayList<>();
            for (Future<Raced> f : futures) {
                out.add(f.get());
            }
            return out;
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void confirmRacingCancelHasExactlyOneWinnerEveryRound() throws Exception {
        Session owner = newUser();
        Session payer = newUser();
        Session receiver = newUser();
        String gid = createGroup(owner, "Race " + UUID.randomUUID()).get("id").asText();
        member(owner, gid, "Owner");
        String payerMid = linkUser(gid, payer, "MEMBER", "ACTIVE", "Payer");
        String receiverMid = linkUser(gid, receiver, "MEMBER", "ACTIVE", "Receiver");
        int confirmWins = 0;
        int cancelWins = 0;

        for (int round = 0; round < ROUNDS; round++) {
            JsonNode created = body(call(POST, "/api/v1/groups/" + gid + "/settlements", payer,
                    Map.of("fromMemberId", payerMid, "toMemberId", receiverMid, "amountMinor", 1000L,
                            "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString()));
            String sid = created.get("id").asText();

            List<Raced> results = race(List.of(() -> raced(receiver, gid, sid, "confirm"),
                    () -> raced(payer, gid, sid, "cancel")));
            Raced confirm = results.get(0);
            Raced cancel = results.get(1);

            String stored = jdbc.queryForObject("select status from settlements where id = ?::uuid", String.class, sid);
            assertThat(List.of(confirm.status(), cancel.status())).as("round " + round).containsExactlyInAnyOrder(200, 409);
            if (confirm.status() == 200) {
                confirmWins++;
                assertThat(stored).isEqualTo("CONFIRMED");
                assertThat(cancel.code()).isEqualTo("INVALID_STATE_TRANSITION");
            } else {
                cancelWins++;
                assertThat(stored).isEqualTo("CANCELLED");
                assertThat(confirm.code()).isEqualTo("INVALID_STATE_TRANSITION");
            }
            assertThat(jdbc.queryForObject("select (confirmed_at is not null) <> (cancelled_at is not null) "
                    + "from settlements where id = ?::uuid", Boolean.class, sid)).as("never both timestamps").isTrue();
        }
        System.out.println("SETTLEMENT RACE confirm wins=" + confirmWins + " cancel wins=" + cancelWins);
    }

    @Test
    void theSameActionAtTheSameTimeIsIdempotent() throws Exception {
        Session owner = newUser();
        Session payer = newUser();
        Session receiver = newUser();
        String gid = createGroup(owner, "Twice " + UUID.randomUUID()).get("id").asText();
        member(owner, gid, "Owner");
        String payerMid = linkUser(gid, payer, "MEMBER", "ACTIVE", "Payer");
        String receiverMid = linkUser(gid, receiver, "MEMBER", "ACTIVE", "Receiver");

        for (int round = 0; round < ROUNDS; round++) {
            String sid = body(call(POST, "/api/v1/groups/" + gid + "/settlements", payer,
                    Map.of("fromMemberId", payerMid, "toMemberId", receiverMid, "amountMinor", 500L,
                            "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString()))
                    .get("id").asText();

            List<Raced> results = race(List.of(() -> raced(receiver, gid, sid, "confirm"),
                    () -> raced(owner, gid, sid, "confirm"), () -> raced(receiver, gid, sid, "confirm")));

            for (Raced r : results) {
                assertThat(r.status()).as("round " + round).isEqualTo(200);
                assertThat(r.body().get("status").asText()).isEqualTo("CONFIRMED");
                assertThat(r.body().get("confirmedAt").asText()).isEqualTo(results.get(0).body().get("confirmedAt").asText());
            }
        }
    }
}
