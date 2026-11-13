package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;

import app.qesma.service.EventType;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B15 / PHASE2_SPEC section 3: a stored payload carries ids, versions and integer amounts only, never a name or a title.
 * The scenario produces every event type with distinctive names and checks the stored jsonb of each.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class EventPayloadPrivacyIT extends AbstractActivityIT {

    private static final Set<String> ALLOWED_KEYS = Set.of("expenseId", "settlementId", "memberId", "requestId",
            "inviteId", "fromMemberId", "toMemberId", "version", "totalMinor", "amountMinor", "role", "previousRole");

    @Test
    void storedPayloadsOfEveryEventTypeHoldOnlyAllowedKeysAndNoNameOrTitle() throws Exception {
        String title = "Zanzibar secret dinner";
        Session owner = newUser();
        Session admin = newUser();
        Session alice = newUser();
        Session bob = newUser();
        String gid = createGroup(owner, "Privacy " + UUID.randomUUID()).get("id").asText();
        String base = "/api/v1/groups/" + gid;
        String ownerMid = member(owner, gid, "Orville Ownerson").get("id").asText();
        String adminMid = linkUser(gid, admin, "ADMIN", "ACTIVE", "Adela Adminova");
        String aliceMid = linkUser(gid, alice, "MEMBER", "ACTIVE", "Alicia Wonderland");
        String bobMid = linkUser(gid, bob, "MEMBER", "ACTIVE", "Roberto Builderson");
        String ghostMid = addMember(owner, gid, "Gustavo Ghostly").get("id").asText();

        String eid = createExpense(owner, gid, equalBody(title, 3000, List.of(ownerMid, aliceMid, bobMid), ownerMid, 3000L))
                .get("id").asText();
        assertThat(status(call(org.springframework.http.HttpMethod.PUT, base + "/expenses/" + eid, owner,
                equalBody(title, 2000, List.of(ownerMid, aliceMid), ownerMid, 2000L), "If-Match", "\"1\""))).isEqualTo(200);
        assertThat(status(call(DELETE, base + "/expenses/" + eid, owner, null, "If-Match", "\"2\""))).isEqualTo(204);

        String s1 = body(call(POST, base + "/settlements", alice, Map.of("fromMemberId", aliceMid, "toMemberId", bobMid,
                "amountMinor", 500L, "settledOn", "2026-10-20", "note", "Zanzibar secret note"),
                "Idempotency-Key", UUID.randomUUID().toString())).get("id").asText();
        String s2 = body(call(POST, base + "/settlements", alice, Map.of("fromMemberId", aliceMid, "toMemberId", bobMid,
                "amountMinor", 600L, "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString()))
                .get("id").asText();
        String s3 = body(call(POST, base + "/settlements", alice, Map.of("fromMemberId", aliceMid, "toMemberId", bobMid,
                "amountMinor", 700L, "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString()))
                .get("id").asText();
        call(POST, base + "/settlements/" + s1 + "/confirm", bob, null);
        call(POST, base + "/settlements/" + s2 + "/dispute", bob, null);
        call(POST, base + "/settlements/" + s3 + "/cancel", alice, null);
        call(POST, base + "/settlements", bob, Map.of("fromMemberId", aliceMid, "toMemberId", bobMid,
                "amountMinor", 800L, "settledOn", "2026-10-20"), "Idempotency-Key", UUID.randomUUID().toString());
        // B16: bob owes alice 1300 now; the owner reminds him (REMINDER event)
        assertThat(status(call(POST, base + "/transfers/remind", owner, Map.of("fromMemberId", bobMid, "toMemberId", aliceMid),
                "Idempotency-Key", UUID.randomUUID().toString()))).isEqualTo(201);

        JsonNode open = body(call(POST, base + "/invites", owner, Map.of("requiresApproval", false),
                "Idempotency-Key", UUID.randomUUID().toString()));
        JsonNode approval = body(call(POST, base + "/invites", owner, Map.of("requiresApproval", true),
                "Idempotency-Key", UUID.randomUUID().toString()));
        Session joiner = newUser();
        call(POST, "/api/v1/invites/" + open.get("code").asText() + "/join", joiner,
                Map.of("newMemberName", "Jonathan Joiner"), "Idempotency-Key", UUID.randomUUID().toString());
        Session asker = newUser();
        MvcResult asked = call(POST, "/api/v1/invites/" + approval.get("code").asText() + "/join", asker,
                Map.of("claimMemberId", ghostMid), "Idempotency-Key", UUID.randomUUID().toString());
        call(POST, base + "/join-requests/" + body(asked).get("requestId").asText() + "/approve", owner, null);

        call(POST, base + "/leave", bob, null);
        call(PATCH, base + "/members/" + bobMid, admin, Map.of("status", "ACTIVE"));
        call(PATCH, base + "/members/" + aliceMid, owner, Map.of("role", "ADMIN"));
        call(POST, base + "/members/" + aliceMid + "/unlink", owner, null);
        call(POST, base + "/transfer-ownership", owner, Map.of("toMemberId", adminMid));

        Set<String> typesSeen = new TreeSet<>(jdbc.queryForList(
                "select distinct type from group_events where group_id = ?::uuid", String.class, gid));
        Set<String> expected = new TreeSet<>();
        for (EventType t : EventType.values()) {
            expected.add(t.name());
        }
        assertThat(typesSeen).as("the scenario covers every event type").containsAll(expected);

        List<String> payloads = jdbc.queryForList("select payload::text from group_events where group_id = ?::uuid",
                String.class, gid);
        assertThat(payloads).isNotEmpty();
        List<String> names = new ArrayList<>(List.of("Orville", "Adela", "Alicia", "Roberto", "Gustavo", "Jonathan",
                "Zanzibar", "Ownerson", "Wonderland", "Privacy"));
        for (String text : payloads) {
            JsonNode node = json.readTree(text);
            node.fieldNames().forEachRemaining(k -> assertThat(ALLOWED_KEYS).as("key " + k + " in " + text).contains(k));
            node.fields().forEachRemaining(f -> assertThat(f.getValue().isTextual() || f.getValue().isNumber())
                    .as(f.getKey()).isTrue());
            for (String name : names) {
                assertThat(text).as("payload must not hold a name or title").doesNotContain(name);
            }
        }
    }
}
