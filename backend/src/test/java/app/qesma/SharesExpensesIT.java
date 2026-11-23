package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * SHARES expenses end to end on real PostgreSQL (BSA3, STANDALONE_SPEC 19, A185-A189): spec vectors through the API,
 * preview == create, edit to and from SHARES with revisions, idempotent replay, and the validation matrix.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class SharesExpensesIT extends AbstractApiIT {

    /** [groupId, A, B, C] with A, B, C in sort order (A is the caller's own member). */
    private List<String> abc(Session owner) throws Exception {
        String gid = createGroup(owner, "G " + UUID.randomUUID()).get("id").asText();
        return List.of(gid, member(owner, gid, "A").get("id").asText(), member(owner, gid, "B").get("id").asText(),
                member(owner, gid, "C").get("id").asText());
    }

    private static Map<String, Object> participant(String memberId, Object units, String from, String to) {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("memberId", memberId);
        p.put("shareUnits", units);
        if (from != null) {
            p.put("presentFrom", from);
        }
        if (to != null) {
            p.put("presentTo", to);
        }
        return p;
    }

    private static Map<String, Object> shares(long total, String periodFrom, String periodTo,
                                              List<Map<String, Object>> participants, String payer) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("title", "Rent");
        body.put("expenseDate", "2026-12-01");
        body.put("splitType", "SHARES");
        body.put("totalMinor", total);
        body.put("payers", List.of(Map.of("memberId", payer, "amountMinor", total)));
        if (periodFrom != null) {
            body.put("periodFrom", periodFrom);
        }
        if (periodTo != null) {
            body.put("periodTo", periodTo);
        }
        body.put("shareParticipants", participants);
        return body;
    }

    /** V23: rent 9,000.00 for November, units 2 / 1 / 1, C present from the 12th. */
    private static Map<String, Object> rent(List<String> g) {
        return shares(900000, "2026-11-01", "2026-11-30", List.of(participant(g.get(1), 2, null, null),
                participant(g.get(2), 1, null, null), participant(g.get(3), 1, "2026-11-12", null)), g.get(1));
    }

    private static List<Long> owed(JsonNode shares) {
        List<Long> out = new ArrayList<>();
        shares.forEach(s -> out.add(s.get("owedMinor").asLong()));
        return out;
    }

    private JsonNode preview(Session as, String gid, Object body) throws Exception {
        MvcResult r = call(POST, "/api/v1/groups/" + gid + "/expenses/preview", as, body);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        return body(r);
    }

    private String url(String gid, String eid) {
        return "/api/v1/groups/" + gid + "/expenses/" + eid;
    }

    @Test
    void v23ThroughTheApiStoresUnitsAndNormalizedPresenceAndPreviewEqualsCreate() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);

        JsonNode previewed = preview(ali, g.get(0), rent(g));
        JsonNode created = createExpense(ali, g.get(0), rent(g));

        assertThat(created.get("splitType").asText()).isEqualTo("SHARES");
        assertThat(created.get("periodFrom").asText()).isEqualTo("2026-11-01");
        assertThat(created.get("periodTo").asText()).isEqualTo("2026-11-30");
        assertThat(owed(created.get("shares"))).containsExactly(495413L, 247706L, 156881L);
        JsonNode c = created.get("shares").get(2);
        assertThat(c.get("shareUnits").asInt()).isEqualTo(1);
        assertThat(c.get("presentFrom").asText()).isEqualTo("2026-11-12");
        assertThat(c.get("presentTo").asText()).as("defaulted to the period end").isEqualTo("2026-11-30");
        assertThat(created.get("shares").get(0).get("presentFrom").asText()).isEqualTo("2026-11-01");
        assertThat(created.get("shares").get(0).get("itemsMinor").isNull()).isTrue();
        assertThat(created.get("items").isNull()).isTrue();

        assertThat(previewed.get("members")).isEqualTo(created.get("shares"));
        assertThat(previewed.get("periodFrom").asText()).isEqualTo("2026-11-01");
        assertThat(previewed.get("subtotalMinor").isNull()).isTrue();

        JsonNode read = body(call(GET, url(g.get(0), created.get("id").asText()), ali, null));
        assertThat(read.get("shares")).isEqualTo(created.get("shares"));
        assertThat(read.get("periodTo").asText()).isEqualTo("2026-11-30");

        // Balances read owed_minor only: A paid 9,000.00 and owes 4,954.13.
        JsonNode balances = body(call(GET, "/api/v1/groups/" + g.get(0) + "/balances", ali, null));
        Map<String, Long> nets = new LinkedHashMap<>();
        balances.get("nets").forEach(n -> nets.put(n.get("memberId").asText(), n.get("netMinor").asLong()));
        assertThat(nets).containsEntry(g.get(1), 900000L - 495413L).containsEntry(g.get(2), -247706L)
                .containsEntry(g.get(3), -156881L);
    }

    @Test
    void withoutAPeriodUnitsOneEqualsEqualAndPresenceIsNull() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        JsonNode s = createExpense(ali, g.get(0), shares(10000, null, null, List.of(participant(g.get(1), 1, null, null),
                participant(g.get(2), 1, null, null), participant(g.get(3), 1, null, null)), g.get(1)));
        JsonNode e = createExpense(ali, g.get(0), equalBody("Dinner", 10000, null, g.get(1), 10000L));
        assertThat(owed(s.get("shares"))).isEqualTo(owed(e.get("shares"))).containsExactly(3334L, 3333L, 3333L);
        assertThat(s.get("periodFrom").isNull()).isTrue();
        assertThat(s.get("shares").get(0).get("presentFrom").isNull()).isTrue();
        assertThat(e.get("shares").get(0).get("shareUnits").isNull()).isTrue();
        assertThat(jdbc.queryForList("select share_units from expense_splits where expense_id = ?::uuid", Integer.class,
                e.get("id").asText())).containsOnlyNulls();
    }

    @Test
    void editToAndFromSharesKeepsEveryRevisionReadable() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String eid = createExpense(ali, g.get(0), equalBody("Rent", 900000, null, g.get(1), 900000L)).get("id").asText();

        MvcResult toShares = call(PUT, url(g.get(0), eid), ali, rent(g), "If-Match", "\"1\"");
        assertThat(status(toShares)).as(toShares.getResponse().getContentAsString()).isEqualTo(200);
        assertThat(owed(body(toShares).get("shares"))).containsExactly(495413L, 247706L, 156881L);

        MvcResult back = call(PUT, url(g.get(0), eid), ali, equalBody("Rent", 900000, null, g.get(1), 900000L),
                "If-Match", "\"2\"");
        assertThat(status(back)).isEqualTo(200);
        assertThat(body(back).get("periodFrom").isNull()).isTrue();
        assertThat(jdbc.queryForObject("select period_from from expenses where id = ?::uuid", java.sql.Date.class, eid))
                .isNull();
        assertThat(jdbc.queryForList("select share_units from expense_splits where expense_id = ?::uuid", Integer.class,
                eid)).containsOnlyNulls();

        JsonNode revs = body(call(GET, url(g.get(0), eid) + "/revisions", ali, null));
        assertThat(revs).hasSize(3);
        assertThat(revs.get(0).get("snapshot").get("splitType").asText()).isEqualTo("EQUAL");
        assertThat(revs.get(0).get("snapshot").get("shares").get(0).get("shareUnits").isNull()).isTrue();
        JsonNode v2 = revs.get(1).get("snapshot");
        assertThat(v2.get("splitType").asText()).isEqualTo("SHARES");
        assertThat(v2.get("periodFrom").asText()).isEqualTo("2026-11-01");
        assertThat(v2.get("shares").get(2).get("presentFrom").asText()).isEqualTo("2026-11-12");
        assertThat(v2.get("shares").get(0).get("shareUnits").asInt()).isEqualTo(2);
        assertThat(revs.get(2).get("snapshot").get("periodFrom").isNull()).isTrue();
    }

    @Test
    void replayReturnsTheStoredAnswerAndADifferentBodyIsKeyReuse() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String key = UUID.randomUUID().toString();
        MvcResult first = postExpense(ali, g.get(0), key, rent(g));
        assertThat(status(first)).isEqualTo(201);

        // Presence given explicitly as the period bounds means the same request (normalized before hashing).
        Map<String, Object> explicit = shares(900000, "2026-11-01", "2026-11-30", List.of(
                participant(g.get(3), 1, "2026-11-12", "2026-11-30"), participant(g.get(2), 1, "2026-11-01", null),
                participant(g.get(1), 2, null, "2026-11-30")), g.get(1));
        MvcResult replay = postExpense(ali, g.get(0), key, explicit);
        assertThat(status(replay)).isEqualTo(201);
        assertThat(replay.getResponse().getHeader("Idempotency-Replayed")).isEqualTo("true");
        assertThat(body(replay)).isEqualTo(body(first));

        Map<String, Object> otherUnits = shares(900000, "2026-11-01", "2026-11-30", List.of(
                participant(g.get(1), 3, null, null), participant(g.get(2), 1, null, null),
                participant(g.get(3), 1, "2026-11-12", null)), g.get(1));
        MvcResult reused = postExpense(ali, g.get(0), key, otherUnits);
        assertThat(status(reused)).isEqualTo(422);
        assertThat(code(reused)).isEqualTo("IDEMPOTENCY_KEY_REUSED");

        Map<String, Object> otherPeriod = rent(g);
        otherPeriod.put("periodTo", "2026-11-29");
        assertThat(code(postExpense(ali, g.get(0), key, otherPeriod))).isEqualTo("IDEMPOTENCY_KEY_REUSED");
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }

    @Test
    void aMemberOfAnotherGroupIsRejected() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        List<String> other = abc(ali);
        MvcResult r = postExpense(ali, g.get(0), UUID.randomUUID().toString(), shares(1000, null, null,
                List.of(participant(g.get(1), 1, null, null), participant(other.get(2), 1, null, null)), g.get(1)));
        assertThat(status(r)).isEqualTo(422);
        assertThat(code(r)).isEqualTo("MEMBER_NOT_IN_GROUP");
    }

    @Test
    void everySharesRuleIsAValidationErrorAndNothingIsStored() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        String a = g.get(1);
        String b = g.get(2);
        Map<String, Consumer<Map<String, Object>>> cases = new LinkedHashMap<>();
        cases.put("units 0", body -> body.put("shareParticipants", List.of(participant(a, 0, null, null))));
        cases.put("units 101", body -> body.put("shareParticipants", List.of(participant(a, 101, null, null))));
        cases.put("units missing", body -> body.put("shareParticipants", List.of(participant(a, null, null, null))));
        cases.put("duplicate member", body -> body.put("shareParticipants",
                List.of(participant(a, 1, null, null), participant(a, 2, null, null))));
        cases.put("no participants", body -> body.put("shareParticipants", List.of()));
        cases.put("participants missing", body -> body.remove("shareParticipants"));
        cases.put("memberId missing", body -> body.put("shareParticipants", List.of(participant(null, 1, null, null))));
        cases.put("presence without a period", body -> body.put("shareParticipants",
                List.of(participant(a, 1, "2026-11-05", null))));
        cases.put("presence before the period", body -> {
            withPeriod(body, "2026-11-01", "2026-11-30");
            body.put("shareParticipants", List.of(participant(a, 1, "2026-10-31", null)));
        });
        cases.put("presence after the period", body -> {
            withPeriod(body, "2026-11-01", "2026-11-30");
            body.put("shareParticipants", List.of(participant(a, 1, null, "2026-12-01")));
        });
        cases.put("reversed presence", body -> {
            withPeriod(body, "2026-11-01", "2026-11-30");
            body.put("shareParticipants", List.of(participant(a, 1, "2026-11-20", "2026-11-10")));
        });
        cases.put("only periodFrom", body -> body.put("periodFrom", "2026-11-01"));
        cases.put("only periodTo", body -> body.put("periodTo", "2026-11-30"));
        cases.put("reversed period", body -> withPeriod(body, "2026-11-30", "2026-11-01"));
        cases.put("367 days", body -> withPeriod(body, "2026-01-01", "2027-01-02"));
        cases.put("period before 2000", body -> withPeriod(body, "1999-12-31", "2000-01-02"));
        cases.put("participantMemberIds on SHARES", body -> body.put("participantMemberIds", List.of(a)));
        cases.put("shares on SHARES", body -> body.put("shares", List.of(Map.of("memberId", a, "amountMinor", 1000))));
        cases.put("items on SHARES", body -> body.put("items", List.of(Map.of("name", "x", "amountMinor", 1000,
                "assigneeMemberIds", List.of(a)))));
        cases.put("deliveryMinor on SHARES", body -> body.put("deliveryMinor", 100));
        cases.put("shareParticipants on EQUAL", body -> body.put("splitType", "EQUAL"));
        cases.put("period on EQUAL", body -> {
            body.put("splitType", "EQUAL");
            body.remove("shareParticipants");
            withPeriod(body, "2026-11-01", "2026-11-30");
        });
        cases.put("shareParticipants on EXACT", body -> {
            body.put("splitType", "EXACT");
            body.put("shares", List.of(Map.of("memberId", a, "amountMinor", 1000)));
        });
        cases.put("periodTo on ITEMIZED", body -> {
            body.put("splitType", "ITEMIZED");
            body.remove("shareParticipants");
            body.put("items", List.of(Map.of("name", "x", "amountMinor", 1000, "assigneeMemberIds", List.of(a))));
            body.put("periodTo", "2026-11-30");
        });
        cases.put("total missing", body -> body.remove("totalMinor"));

        for (Map.Entry<String, Consumer<Map<String, Object>>> c : cases.entrySet()) {
            Map<String, Object> body = shares(1000, null, null,
                    List.of(participant(a, 1, null, null), participant(b, 1, null, null)), a);
            c.getValue().accept(body);
            MvcResult r = postExpense(ali, g.get(0), UUID.randomUUID().toString(), body);
            assertThat(status(r)).as(c.getKey() + ": " + r.getResponse().getContentAsString()).isEqualTo(422);
            assertThat(code(r)).as(c.getKey()).isEqualTo("VALIDATION_ERROR");
            MvcResult p = call(POST, "/api/v1/groups/" + g.get(0) + "/expenses/preview", ali, body);
            assertThat(code(p)).as("preview: " + c.getKey()).isEqualTo("VALIDATION_ERROR");
        }
        assertThat(countExpenses(g.get(0))).isZero();
        // the boundaries that ARE allowed: units 1 and 100, a 366-day period, a one-day presence
        Map<String, Object> ok = shares(36600, "2026-01-01", "2027-01-01",
                List.of(participant(a, 100, null, null), participant(b, 1, "2027-01-01", "2027-01-01")), a);
        assertThat(status(postExpense(ali, g.get(0), UUID.randomUUID().toString(), ok))).isEqualTo(201);
    }

    @Test
    void aFieldPathIsNamedInTheMessage() throws Exception {
        Session ali = newUser();
        List<String> g = abc(ali);
        MvcResult r = postExpense(ali, g.get(0), UUID.randomUUID().toString(), shares(1000, null, null,
                List.of(participant(g.get(1), 1, null, null), participant(g.get(2), 101, null, null)), g.get(1)));
        assertThat(body(r).get("title").asText()).contains("shareParticipants[1].shareUnits");
    }

    private static void withPeriod(Map<String, Object> body, String from, String to) {
        body.put("periodFrom", from);
        body.put("periodTo", to);
    }
}
