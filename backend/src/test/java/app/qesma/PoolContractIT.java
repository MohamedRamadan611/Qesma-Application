package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.EntityManagerFactory;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/** BSA1: category, paidFromPool, settlement kind, the treasurer and the pool meter (A135-A138). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class PoolContractIT extends AbstractApiIT {

    @Autowired EntityManagerFactory emf;

    /** Owner (member "T"), ghosts A and B. */
    private final class Ctx {
        final Session owner;
        final String gid;
        final String t;
        final String a;
        final String b;

        Ctx() throws Exception {
            owner = newUser();
            gid = createGroup(owner, "Pool " + UUID.randomUUID()).get("id").asText();
            t = member(owner, gid, "T").get("id").asText();
            a = member(owner, gid, "A").get("id").asText();
            b = member(owner, gid, "B").get("id").asText();
        }

        String path(String suffix) {
            return "/api/v1/groups/" + gid + suffix;
        }

        JsonNode group() throws Exception {
            return body(call(GET, path(""), owner, null));
        }

        MvcResult setTreasurer(Session as, String member) throws Exception {
            int version = group().get("version").asInt();
            return call(PATCH, path(""), as, Map.of("treasurerMemberId", member), "If-Match", "\"" + version + "\"");
        }

        MvcResult deposit(String from, String to, long amount) throws Exception {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("fromMemberId", from);
            body.put("toMemberId", to);
            body.put("amountMinor", amount);
            body.put("settledOn", "2026-10-20");
            body.put("kind", "POOL_DEPOSIT");
            return call(POST, path("/settlements"), owner, body, "Idempotency-Key", UUID.randomUUID().toString());
        }

        MvcResult payment(String from, String to, long amount) throws Exception {
            Map<String, Object> body = Map.of("fromMemberId", from, "toMemberId", to, "amountMinor", amount,
                    "settledOn", "2026-10-20");
            return call(POST, path("/settlements"), owner, body, "Idempotency-Key", UUID.randomUUID().toString());
        }

        Map<String, Object> poolExpense(long total, String payer, boolean pool) {
            Map<String, Object> body = equalBody("pool", total, null, payer, total);
            body.put("paidFromPool", pool);
            return body;
        }

        Object meter() throws Exception {
            JsonNode n = group().get("poolBalanceMinor");
            return n == null || n.isNull() ? null : n.asLong();
        }
    }

    @Test
    void existingShapeDefaultsToOtherAndCategoryFilterAndSnapshotWork() throws Exception {
        Ctx c = new Ctx();
        JsonNode plain = createExpense(c.owner, c.gid, equalBody("plain", 3000, null, c.t, 3000L));
        assertThat(plain.get("category").asText()).isEqualTo("OTHER");
        assertThat(plain.get("paidFromPool").asBoolean()).isFalse();
        Map<String, Object> fuel = equalBody("fuel", 6000, null, c.t, 6000L);
        fuel.put("category", "FUEL");
        JsonNode created = createExpense(c.owner, c.gid, fuel);
        assertThat(created.get("category").asText()).isEqualTo("FUEL");

        JsonNode filtered = body(call(GET, c.path("/expenses?category=FUEL"), c.owner, null));
        assertThat(filtered.get("items")).hasSize(1);
        assertThat(filtered.get("items").get(0).get("title").asText()).isEqualTo("fuel");
        assertThat(body(call(GET, c.path("/expenses"), c.owner, null)).get("items")).hasSize(2);
        assertThat(status(call(GET, c.path("/expenses?category=NOPE"), c.owner, null))).isEqualTo(422);

        JsonNode history = body(call(GET, c.path("/expenses/" + created.get("id").asText() + "/revisions"), c.owner, null));
        assertThat(history.get(0).get("snapshot").get("category").asText()).isEqualTo("FUEL");

        Map<String, Object> bad = equalBody("x", 1000, null, c.t, 1000L);
        bad.put("category", "PIZZA");
        MvcResult r = postExpense(c.owner, c.gid, UUID.randomUUID().toString(), bad);
        assertThat(status(r)).isEqualTo(422);
        assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
    }

    @Test
    void paidFromPoolAndDepositValidationMatrix() throws Exception {
        Ctx c = new Ctx();
        // no treasurer yet
        assertThat(code(postExpense(c.owner, c.gid, UUID.randomUUID().toString(), c.poolExpense(1000, c.t, true))))
                .isEqualTo("VALIDATION_ERROR");
        assertThat(code(c.deposit(c.a, c.t, 5000))).isEqualTo("VALIDATION_ERROR");           // deposit, no treasurer

        assertThat(status(c.setTreasurer(c.owner, c.t))).isEqualTo(200);
        assertThat(c.group().get("treasurerMemberId").asText()).isEqualTo(c.t);

        assertThat(status(c.deposit(c.a, c.b, 5000))).as("deposit to a non-treasurer").isEqualTo(422);
        assertThat(status(c.deposit(c.t, c.t, 5000))).as("treasurer to self").isEqualTo(422);
        assertThat(status(c.deposit(c.a, c.t, 5000))).as("valid deposit").isEqualTo(201);

        assertThat(status(postExpense(c.owner, c.gid, UUID.randomUUID().toString(), c.poolExpense(1000, c.a, true))))
                .as("wrong payer").isEqualTo(422);
        Map<String, Object> two = c.poolExpense(1000, c.t, true);
        two.put("payers", List.of(Map.of("memberId", c.t, "amountMinor", 500L), Map.of("memberId", c.a, "amountMinor", 500L)));
        assertThat(status(postExpense(c.owner, c.gid, UUID.randomUUID().toString(), two))).as("two payers").isEqualTo(422);
        assertThat(status(postExpense(c.owner, c.gid, UUID.randomUUID().toString(), c.poolExpense(1000, c.t, true))))
                .as("valid pool expense").isEqualTo(201);
        // the same payer without the flag is an ordinary expense
        assertThat(status(postExpense(c.owner, c.gid, UUID.randomUUID().toString(), c.poolExpense(1000, c.a, false))))
                .isEqualTo(201);
    }

    @Test
    void treasurerIsLockedAfterTheFirstDepositOrPoolExpenseEvenWhenCancelledOrDeleted() throws Exception {
        Ctx c = new Ctx();
        assertThat(status(c.setTreasurer(c.owner, c.t))).isEqualTo(200);
        assertThat(status(c.setTreasurer(c.owner, c.a))).as("no pool activity yet").isEqualTo(200);
        assertThat(status(c.setTreasurer(c.owner, c.t))).isEqualTo(200);

        // a cancelled deposit still locks: a linked member's deposit is PENDING, which can be cancelled
        Session bob = newUser();
        String bobMember = linkUser(c.gid, bob, "MEMBER", "ACTIVE", "Bob");
        Map<String, Object> depBody = Map.of("fromMemberId", bobMember, "toMemberId", c.t, "amountMinor", 4000L,
                "settledOn", "2026-10-20", "kind", "POOL_DEPOSIT");
        JsonNode dep = body(call(POST, c.path("/settlements"), bob, depBody, "Idempotency-Key", UUID.randomUUID().toString()));
        assertThat(dep.get("status").asText()).isEqualTo("PENDING");
        assertThat(status(call(POST, c.path("/settlements/" + dep.get("id").asText() + "/cancel"), bob, null))).isEqualTo(200);
        MvcResult locked = c.setTreasurer(c.owner, c.a);
        assertThat(status(locked)).isEqualTo(409);
        assertThat(code(locked)).isEqualTo("INVALID_STATE_TRANSITION");
        assertThat(c.group().get("treasurerMemberId").asText()).isEqualTo(c.t);

        // a second group: a soft-deleted pool expense locks too
        Ctx d = new Ctx();
        assertThat(status(d.setTreasurer(d.owner, d.t))).isEqualTo(200);
        JsonNode e = createExpense(d.owner, d.gid, d.poolExpense(1000, d.t, true));
        assertThat(status(call(DELETE, d.path("/expenses/" + e.get("id").asText()), d.owner, null,
                "If-Match", "\"" + e.get("version").asInt() + "\""))).isEqualTo(204);
        assertThat(code(d.setTreasurer(d.owner, d.a))).isEqualTo("INVALID_STATE_TRANSITION");

        // a nonexistent or foreign member is a validation error, not a lock
        Ctx f = new Ctx();
        assertThat(status(f.setTreasurer(f.owner, c.a))).isEqualTo(422);
    }

    @Test
    void poolMeterIsConfirmedDepositsMinusLivePoolExpensesAndCostsConstantStatements() throws Exception {
        Ctx c = new Ctx();
        assertThat(c.meter()).as("no treasurer").isNull();
        assertThat(status(c.setTreasurer(c.owner, c.t))).isEqualTo(200);
        assertThat(c.meter()).isEqualTo(0L);

        assertThat(status(c.deposit(c.a, c.t, 10_000))).isEqualTo(201);
        assertThat(c.meter()).isEqualTo(10_000L);
        JsonNode big = createExpense(c.owner, c.gid, c.poolExpense(12_000, c.t, true));
        assertThat(c.meter()).as("negative is allowed").isEqualTo(-2_000L);
        assertThat(status(call(DELETE, c.path("/expenses/" + big.get("id").asText()), c.owner, null,
                "If-Match", "\"" + big.get("version").asInt() + "\""))).isEqualTo(204);
        assertThat(c.meter()).as("soft-deleted pool expense is not counted").isEqualTo(10_000L);

        // an ordinary expense paid by the treasurer does not touch the pool
        createExpense(c.owner, c.gid, c.poolExpense(3_000, c.t, false));
        assertThat(c.meter()).isEqualTo(10_000L);

        // a PENDING declaration from a member with an account is not counted until confirmed
        Session bob = newUser();
        String bobMember = linkUser(c.gid, bob, "MEMBER", "ACTIVE", "Bob");
        Map<String, Object> declared = Map.of("fromMemberId", bobMember, "toMemberId", c.t, "amountMinor", 700L,
                "settledOn", "2026-10-20", "kind", "POOL_DEPOSIT");
        assertThat(status(call(POST, c.path("/settlements"), bob, declared, "Idempotency-Key", UUID.randomUUID().toString())))
                .isEqualTo(201);
        assertThat(c.meter()).as("PENDING deposit").isEqualTo(10_000L);

        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        assertThat(status(call(GET, c.path(""), c.owner, null))).isEqualTo(200);
        long few = stats.getPrepareStatementCount();
        List<MvcResult> many = new ArrayList<>();
        for (int i = 0; i < 50; i++) {
            many.add(c.deposit(c.a, c.t, 100));
        }
        assertThat(many).allSatisfy(r -> assertThat(status(r)).isEqualTo(201));
        stats.clear();
        assertThat(status(call(GET, c.path(""), c.owner, null))).isEqualTo(200);
        assertThat(stats.getPrepareStatementCount()).as("group read with 51 deposits vs 1").isEqualTo(few);
        assertThat(c.meter()).isEqualTo(15_000L);
    }

    @Test
    void depositAndPaymentOfTheSameAmountMoveBalancesIdentically() throws Exception {
        Ctx pay = new Ctx();
        Ctx dep = new Ctx();
        assertThat(status(dep.setTreasurer(dep.owner, dep.t))).isEqualTo(200);
        for (Ctx c : List.of(pay, dep)) {
            createExpense(c.owner, c.gid, equalBody("dinner", 9000, null, c.t, 9000L));
        }
        assertThat(status(pay.payment(pay.a, pay.t, 2500))).isEqualTo(201);
        assertThat(status(dep.deposit(dep.a, dep.t, 2500))).isEqualTo(201);
        assertThat(nets(pay)).isEqualTo(nets(dep));
        assertThat(nets(dep)).containsExactly(3500L, -500L, -3000L);
    }

    private List<Long> nets(Ctx c) throws Exception {
        List<Long> out = new ArrayList<>();
        body(call(GET, c.path("/balances"), c.owner, null)).get("nets").forEach(n -> out.add(n.get("netMinor").asLong()));
        return out;
    }

    @Test
    void createReplayWithNewFieldsIsIdempotentAndAChangedFieldIsReused() throws Exception {
        Ctx c = new Ctx();
        assertThat(status(c.setTreasurer(c.owner, c.t))).isEqualTo(200);
        Map<String, Object> body = c.poolExpense(2000, c.t, true);
        body.put("category", "FOOD");
        String key = UUID.randomUUID().toString();
        MvcResult one = postExpense(c.owner, c.gid, key, body);
        MvcResult two = postExpense(c.owner, c.gid, key, body);
        assertThat(status(one)).isEqualTo(201);
        assertThat(status(two)).isEqualTo(201);
        assertThat(body(two)).isEqualTo(body(one));
        assertThat(countExpenses(c.gid)).isEqualTo(1);

        body.put("category", "BILLS");
        MvcResult changed = postExpense(c.owner, c.gid, key, body);
        assertThat(status(changed)).isEqualTo(422);
        assertThat(code(changed)).isEqualTo("IDEMPOTENCY_KEY_REUSED");

        Map<String, Object> flag = c.poolExpense(2000, c.t, false);
        flag.put("category", "FOOD");
        assertThat(code(postExpense(c.owner, c.gid, key, flag))).isEqualTo("IDEMPOTENCY_KEY_REUSED");
        assertThat(c.meter()).isEqualTo(-2000L);
    }

    @Test
    void onlyRolesThatMayEditTheGroupCanSetTheTreasurer() throws Exception {
        Ctx c = new Ctx();
        Session member = newUser();
        linkUser(c.gid, member, "MEMBER", "ACTIVE", "M");
        Session admin = newUser();
        linkUser(c.gid, admin, "ADMIN", "ACTIVE", "Ad");
        Session stranger = newUser();

        assertThat(status(c.setTreasurer(member, c.t))).isEqualTo(403);
        assertThat(status(c.setTreasurer(stranger, c.t))).isEqualTo(404);
        assertThat(status(c.setTreasurer(admin, c.t))).isEqualTo(200);
        assertThat(c.group().get("treasurerMemberId").asText()).isEqualTo(c.t);
    }
}
