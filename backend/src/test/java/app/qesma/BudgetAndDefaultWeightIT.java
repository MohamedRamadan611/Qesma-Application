package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.HashMap;
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
 * BSA3 settings through PATCH (A188, A190, A193): the group trip budget and dates, and the member default weight. Set,
 * clear with the explicit flags, a value with its clear flag, ranges, the resulting-state date rule, and the
 * unchanged authorization (404 for a stranger, 403 for a member without the permission).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class BudgetAndDefaultWeightIT extends AbstractApiIT {

    private String path(String gid) {
        return "/api/v1/groups/" + gid;
    }

    private MvcResult patchGroup(Session as, String gid, Map<String, Object> body) throws Exception {
        int version = body(call(GET, path(gid), as, null)).get("version").asInt();
        return call(PATCH, path(gid), as, body, "If-Match", "\"" + version + "\"");
    }

    private static Map<String, Object> map(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i + 1 < kv.length; i += 2) {
            m.put((String) kv[i], kv[i + 1]);
        }
        return m;
    }

    @Test
    void budgetAndTripDatesCanBeSetChangedAndClearedAtAnyTime() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Trip " + UUID.randomUUID()).get("id").asText();
        JsonNode fresh = body(call(GET, path(gid), owner, null));
        assertThat(fresh.get("budgetMinor").isNull()).isTrue();
        assertThat(fresh.get("tripStartDate").isNull()).isTrue();
        assertThat(fresh.get("tripEndDate").isNull()).isTrue();

        MvcResult set = patchGroup(owner, gid, map("budgetMinor", 1_000_000, "tripStartDate", "2026-11-01",
                "tripEndDate", "2026-11-05"));
        assertThat(status(set)).as(set.getResponse().getContentAsString()).isEqualTo(200);
        assertThat(body(set).get("budgetMinor").asLong()).isEqualTo(1_000_000L);
        assertThat(body(set).get("tripStartDate").asText()).isEqualTo("2026-11-01");
        assertThat(body(set).get("tripEndDate").asText()).isEqualTo("2026-11-05");
        assertThat(body(set).get("version").asInt()).isEqualTo(fresh.get("version").asInt() + 1);

        // Absent = no change; only the end date moves.
        MvcResult moved = patchGroup(owner, gid, map("tripEndDate", "2026-11-06"));
        assertThat(body(moved).get("budgetMinor").asLong()).isEqualTo(1_000_000L);
        assertThat(body(moved).get("tripEndDate").asText()).isEqualTo("2026-11-06");

        // A no-op patch does not bump the version.
        int before = body(moved).get("version").asInt();
        assertThat(body(patchGroup(owner, gid, map("budgetMinor", 1_000_000))).get("version").asInt()).isEqualTo(before);

        MvcResult cleared = patchGroup(owner, gid, map("clearBudget", true, "clearTripStartDate", true));
        assertThat(status(cleared)).isEqualTo(200);
        assertThat(body(cleared).get("budgetMinor").isNull()).isTrue();
        assertThat(body(cleared).get("tripStartDate").isNull()).isTrue();
        assertThat(body(cleared).get("tripEndDate").asText()).as("each date is optional").isEqualTo("2026-11-06");
        assertThat(body(patchGroup(owner, gid, map("clearTripEndDate", true))).get("tripEndDate").isNull()).isTrue();

        // The cap is allowed; every group type may carry a budget.
        assertThat(status(patchGroup(owner, gid, map("budgetMinor", 1_000_000_000_000L, "type", "HOUSING"))))
                .isEqualTo(200);
    }

    @Test
    void invalidBudgetSettingsAreValidationErrorsAndChangeNothing() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Trip " + UUID.randomUUID()).get("id").asText();
        assertThat(status(patchGroup(owner, gid, map("budgetMinor", 500, "tripStartDate", "2026-11-05")))).isEqualTo(200);

        Map<String, Map<String, Object>> cases = new LinkedHashMap<>();
        cases.put("budget 0", map("budgetMinor", 0));
        cases.put("budget negative", map("budgetMinor", -1));
        cases.put("budget above the cap", map("budgetMinor", 1_000_000_000_001L));
        cases.put("value and clear flag", map("budgetMinor", 100, "clearBudget", true));
        cases.put("date and clear flag", map("tripEndDate", "2026-11-09", "clearTripEndDate", true));
        cases.put("end before start in the request", map("tripStartDate", "2026-11-05", "tripEndDate", "2026-11-04"));
        cases.put("end before the stored start", map("tripEndDate", "2026-11-04"));
        cases.put("date before 2000", map("tripStartDate", "1999-12-31"));
        for (Map.Entry<String, Map<String, Object>> c : cases.entrySet()) {
            MvcResult r = patchGroup(owner, gid, c.getValue());
            assertThat(status(r)).as(c.getKey() + ": " + r.getResponse().getContentAsString()).isEqualTo(422);
            assertThat(code(r)).as(c.getKey()).isEqualTo("VALIDATION_ERROR");
        }
        JsonNode after = body(call(GET, path(gid), owner, null));
        assertThat(after.get("budgetMinor").asLong()).isEqualTo(500L);
        assertThat(after.get("tripStartDate").asText()).isEqualTo("2026-11-05");
        assertThat(after.get("tripEndDate").isNull()).isTrue();
        // Clearing the start makes an earlier end valid (the rule is on the resulting state).
        assertThat(status(patchGroup(owner, gid, map("clearTripStartDate", true, "tripEndDate", "2026-11-04"))))
                .isEqualTo(200);
    }

    @Test
    void budgetNeedsEditGroupAndIsInvisibleToStrangers() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Trip " + UUID.randomUUID()).get("id").asText();
        Session plain = newUser();
        linkUser(gid, plain, "MEMBER", "ACTIVE", "Plain");
        Session stranger = newUser();
        int version = body(call(GET, path(gid), owner, null)).get("version").asInt();

        MvcResult forbidden = call(PATCH, path(gid), plain, map("budgetMinor", 100), "If-Match", "\"" + version + "\"");
        assertThat(status(forbidden)).isEqualTo(403);
        assertThat(code(forbidden)).isEqualTo("FORBIDDEN");
        assertThat(status(call(PATCH, path(gid), stranger, map("budgetMinor", 100), "If-Match", "\"" + version + "\"")))
                .isEqualTo(404);
        assertThat(body(call(GET, path(gid), owner, null)).get("budgetMinor").isNull()).isTrue();
    }

    @Test
    void defaultWeightIsAPrefillOnlyAndCanBeSetAndCleared() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Flat " + UUID.randomUUID()).get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String b = member(owner, gid, "B").get("id").asText();
        String memberPath = path(gid) + "/members/" + b;
        assertThat(body(call(GET, path(gid), owner, null)).get("members").get(1).get("defaultShareUnits").isNull())
                .isTrue();

        // A SHARES expense stored before the default changes.
        Map<String, Object> body = new HashMap<>();
        body.put("title", "Rent");
        body.put("expenseDate", "2026-12-01");
        body.put("splitType", "SHARES");
        body.put("totalMinor", 3000);
        body.put("payers", List.of(Map.of("memberId", a, "amountMinor", 3000)));
        body.put("shareParticipants", List.of(Map.of("memberId", a, "shareUnits", 1), Map.of("memberId", b, "shareUnits", 2)));
        JsonNode expense = createExpense(owner, gid, body);

        MvcResult set = call(PATCH, memberPath, owner, map("defaultShareUnits", 3));
        assertThat(status(set)).as(set.getResponse().getContentAsString()).isEqualTo(200);
        assertThat(body(set).get("defaultShareUnits").asInt()).isEqualTo(3);
        assertThat(body(set).get("displayName").asText()).isEqualTo("B");

        JsonNode reread = body(call(GET, path(gid) + "/expenses/" + expense.get("id").asText(), owner, null));
        assertThat(reread.get("shares")).as("the default never changes a stored expense").isEqualTo(expense.get("shares"));
        assertThat(reread.get("version").asInt()).isEqualTo(1);

        for (Map<String, Object> bad : List.of(map("defaultShareUnits", 0), map("defaultShareUnits", 101),
                map("defaultShareUnits", 2, "clearDefaultShareUnits", true))) {
            MvcResult r = call(PATCH, memberPath, owner, bad);
            assertThat(status(r)).as(bad.toString()).isEqualTo(422);
            assertThat(code(r)).isEqualTo("VALIDATION_ERROR");
        }
        MvcResult cleared = call(PATCH, memberPath, owner, map("clearDefaultShareUnits", true));
        assertThat(status(cleared)).isEqualTo(200);
        assertThat(body(cleared).get("defaultShareUnits").isNull()).isTrue();
        assertThat(status(call(PATCH, memberPath, owner, map()))).as("an empty patch").isEqualTo(422);

        // The same permission as a rename: a plain member gets 403, a stranger 404.
        Session plain = newUser();
        linkUser(gid, plain, "MEMBER", "ACTIVE", "Plain");
        assertThat(status(call(PATCH, memberPath, plain, map("defaultShareUnits", 2)))).isEqualTo(403);
        assertThat(status(call(PATCH, memberPath, newUser(), map("defaultShareUnits", 2)))).isEqualTo(404);
    }

    @Test
    void anUnchangedSharesEditStillUsesTheStoredUnitsNotTheDefault() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Flat " + UUID.randomUUID()).get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        String b = member(owner, gid, "B").get("id").asText();
        call(PATCH, path(gid) + "/members/" + b, owner, map("defaultShareUnits", 9));
        Map<String, Object> body = new HashMap<>();
        body.put("title", "Rent");
        body.put("expenseDate", "2026-12-01");
        body.put("splitType", "SHARES");
        body.put("totalMinor", 3000);
        body.put("payers", List.of(Map.of("memberId", a, "amountMinor", 3000)));
        body.put("shareParticipants", List.of(Map.of("memberId", a, "shareUnits", 1), Map.of("memberId", b, "shareUnits", 2)));
        String eid = createExpense(owner, gid, body).get("id").asText();
        MvcResult edited = call(PUT, path(gid) + "/expenses/" + eid, owner, body, "If-Match", "\"1\"");
        assertThat(body(edited).get("shares").findValues("owedMinor").stream().map(JsonNode::asLong).toList())
                .containsExactly(1000L, 2000L);
    }
}
