package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B13 / A83 through the API with the Phase 1 vectors V1 and V2: nets and suggested transfers move only when a
 * settlement is CONFIRMED; PENDING and DISPUTED ones only change {@code pendingMinor}, {@code hasDispute} and
 * {@code openSettlementIds} of the transfer between exactly that pair; {@code yourNetMinor} follows the same rule.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class SettlementBalanceRuleIT extends AbstractApiIT {

    private final class Trip {
        final Session m = newUser();           // the owner, member "M"
        final Session a = newUser();           // linked member "A" who pays
        final String gid;
        final String mMid;
        final String aMid;
        final String sMid;                     // ghost "S"

        Trip() throws Exception {
            gid = createGroup(m, "Rule " + UUID.randomUUID()).get("id").asText();
            mMid = member(m, gid, "M").get("id").asText();
            aMid = linkUser(gid, a, "MEMBER", "ACTIVE", "A");
            sMid = addMember(m, gid, "S").get("id").asText();
            // V1: E1 paid by M 100.00 (A 50.00, S 50.00); E2 paid by S 30.00 (A 30.00)
            createExpense(m, gid, exactBody("E1", 10000, List.of(aMid, 5000L, sMid, 5000L), mMid, 10000L));
            createExpense(m, gid, exactBody("E2", 3000, List.of(aMid, 3000L), sMid, 3000L));
        }

        JsonNode balances() throws Exception {
            return body(call(GET, "/api/v1/groups/" + gid + "/balances", m, null));
        }

        String declare(long amount) throws Exception {
            MvcResult r = call(POST, "/api/v1/groups/" + gid + "/settlements", a,
                    Map.of("fromMemberId", aMid, "toMemberId", mMid, "amountMinor", amount, "settledOn", "2026-10-20"),
                    "Idempotency-Key", UUID.randomUUID().toString());
            assertThat(status(r)).isEqualTo(201);
            assertThat(body(r).get("status").asText()).isEqualTo("PENDING");
            return body(r).get("id").asText();
        }

        MvcResult act(Session as, String sid, String action) throws Exception {
            return call(POST, "/api/v1/groups/" + gid + "/settlements/" + sid + "/" + action, as, null);
        }

        long yourNet(Session as) throws Exception {
            return body(call(GET, "/api/v1/groups/" + gid, as, null)).get("yourNetMinor").asLong();
        }

        JsonNode transfer(JsonNode balances, String from, String to) {
            for (JsonNode t : balances.get("transfers")) {
                if (t.get("fromMemberId").asText().equals(from) && t.get("toMemberId").asText().equals(to)) {
                    return t;
                }
            }
            throw new AssertionError("no transfer " + from + " > " + to + " in " + balances);
        }
    }

    private static Map<String, Long> netsOf(JsonNode balances) {
        Map<String, Long> nets = new LinkedHashMap<>();
        balances.get("nets").forEach(n -> nets.put(n.get("memberId").asText(), n.get("netMinor").asLong()));
        return nets;
    }

    private static List<String> ids(JsonNode array) {
        List<String> out = new ArrayList<>();
        array.forEach(n -> out.add(n.asText()));
        return out;
    }

    @Test
    void phase1VectorV1IsUnchangedAndItsTransfersCarryNoOpenInformation() throws Exception {
        Trip t = new Trip();
        JsonNode b = t.balances();
        assertThat(netsOf(b)).containsExactly(Map.entry(t.mMid, 10000L), Map.entry(t.aMid, -8000L), Map.entry(t.sMid, -2000L));
        assertThat(b.get("transfers")).hasSize(2);
        for (JsonNode tr : b.get("transfers")) {
            assertThat(tr.get("pendingMinor").asLong()).isZero();
            assertThat(tr.get("hasDispute").asBoolean()).isFalse();
            assertThat(tr.get("openSettlementIds")).isEmpty();
        }
        assertThat(t.yourNet(t.m)).isEqualTo(10000L);
        assertThat(t.yourNet(t.a)).isEqualTo(-8000L);
    }

    @Test
    void aPendingPaymentIsInformationOnlyUntilTheReceiverConfirmsIt() throws Exception {
        Trip t = new Trip();
        String first = t.declare(8000);                                  // A says "I paid M 80.00"

        JsonNode pending = t.balances();
        assertThat(netsOf(pending)).as("nets do not move on PENDING")
                .containsExactly(Map.entry(t.mMid, 10000L), Map.entry(t.aMid, -8000L), Map.entry(t.sMid, -2000L));
        JsonNode am = t.transfer(pending, t.aMid, t.mMid);
        assertThat(am.get("amountMinor").asLong()).as("the suggested amount is not reduced").isEqualTo(8000L);
        assertThat(am.get("pendingMinor").asLong()).isEqualTo(8000L);
        assertThat(am.get("hasDispute").asBoolean()).isFalse();
        assertThat(ids(am.get("openSettlementIds"))).containsExactly(first);
        assertThat(t.transfer(pending, t.sMid, t.mMid).get("pendingMinor").asLong()).as("another pair").isZero();
        assertThat(t.yourNet(t.a)).as("yourNet follows the same rule").isEqualTo(-8000L);

        assertThat(status(t.act(t.m, first, "confirm"))).isEqualTo(200);   // V2: A paid M 80.00
        JsonNode confirmed = t.balances();
        assertThat(netsOf(confirmed)).containsExactly(Map.entry(t.mMid, 2000L), Map.entry(t.aMid, 0L), Map.entry(t.sMid, -2000L));
        assertThat(confirmed.get("transfers")).hasSize(1);
        assertThat(t.transfer(confirmed, t.sMid, t.mMid).get("amountMinor").asLong()).isEqualTo(2000L);
        assertThat(t.yourNet(t.m)).isEqualTo(2000L);
        assertThat(t.yourNet(t.a)).isZero();
    }

    @Test
    void aDisputedPaymentShowsTheFlagAndNeverMovesMoney() throws Exception {
        Trip t = new Trip();
        String first = t.declare(8000);
        String second = t.declare(1500);                                  // partial second declaration, same pair

        JsonNode two = t.balances().get("transfers").get(0);
        assertThat(two.get("pendingMinor").asLong()).as("sum of the PENDING ones").isEqualTo(9500L);
        assertThat(ids(two.get("openSettlementIds"))).as("oldest first").containsExactly(first, second);

        assertThat(status(t.act(t.m, first, "dispute"))).isEqualTo(200);
        JsonNode disputed = t.balances();
        JsonNode am = t.transfer(disputed, t.aMid, t.mMid);
        assertThat(am.get("hasDispute").asBoolean()).isTrue();
        assertThat(am.get("pendingMinor").asLong()).as("only the undisputed second one is still pending").isEqualTo(1500L);
        assertThat(ids(am.get("openSettlementIds"))).containsExactly(first, second);
        assertThat(netsOf(disputed)).containsExactly(Map.entry(t.mMid, 10000L), Map.entry(t.aMid, -8000L), Map.entry(t.sMid, -2000L));

        assertThat(status(t.act(t.a, first, "cancel"))).isEqualTo(200);   // the payer withdraws the disputed one
        assertThat(status(t.act(t.a, second, "cancel"))).isEqualTo(200);
        JsonNode cancelled = t.balances();
        JsonNode clean = t.transfer(cancelled, t.aMid, t.mMid);
        assertThat(clean.get("pendingMinor").asLong()).isZero();
        assertThat(clean.get("hasDispute").asBoolean()).isFalse();
        assertThat(clean.get("openSettlementIds")).isEmpty();
        assertThat(netsOf(cancelled)).containsExactly(Map.entry(t.mMid, 10000L), Map.entry(t.aMid, -8000L), Map.entry(t.sMid, -2000L));
    }

    @Test
    void aDisputedPaymentThatTheReceiverLaterConfirmsMovesTheBalances() throws Exception {
        Trip t = new Trip();
        String sid = t.declare(8000);
        t.act(t.m, sid, "dispute");
        assertThat(netsOf(t.balances()).get(t.aMid)).isEqualTo(-8000L);
        assertThat(status(t.act(t.m, sid, "confirm"))).isEqualTo(200);
        assertThat(netsOf(t.balances()).get(t.aMid)).isZero();
    }
}
