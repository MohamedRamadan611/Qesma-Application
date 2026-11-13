package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B14 / A91 JSON field-set test: the handle values may appear ONLY in {@code GET /me/payment-handles} (to their owner)
 * and in {@code transfers[].receiverHandles} of the balances (to the payer, Owner, Admin). Every other read the
 * receiver's co-members can make, and every error body, is scanned for the values.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class PaymentHandleExposureIT extends AbstractHandlesIT {

    private record Probe(String label, HttpMethod method, String url, Object body, String... headers) {
    }

    private List<Probe> probes(Scenario s) {
        String g = "/api/v1/groups/" + s.gid();
        List<Probe> list = new ArrayList<>(List.of(
                new Probe("groups list", GET, "/api/v1/groups", null),
                new Probe("group detail (members)", GET, g, null),
                new Probe("expenses list", GET, g + "/expenses", null),
                new Probe("settlements list", GET, g + "/settlements", null),
                new Probe("invites list", GET, g + "/invites", null),
                new Probe("join requests", GET, g + "/join-requests", null),
                new Probe("me", GET, "/api/v1/me", null),
                new Probe("rename member", PATCH, g + "/members/" + s.receiverMid(), Map.of("displayName", "Receiver")),
                new Probe("create invite", POST, g + "/invites", Map.of("requiresApproval", false),
                        "Idempotency-Key", UUID.randomUUID().toString()),
                new Probe("unknown group", GET, "/api/v1/groups/" + UUID.randomUUID(), null),
                new Probe("unknown invite", GET, "/api/v1/invites/ZZZZZZZZ", null),
                new Probe("validation error", POST, g + "/members", Map.of("displayName", " ")),
                new Probe("malformed json", PUT, "/api/v1/me", "{\"displayName\": ")));
        return list;
    }

    @Test
    void theValuesAppearOnlyWhereTheyAreAllowed() throws Exception {
        Scenario s = scenario();
        // an invite and its preview, so those DTOs exist for the scan too
        MvcResult inv = call(POST, "/api/v1/groups/" + s.gid() + "/invites", s.owner(), Map.of("requiresApproval", false),
                "Idempotency-Key", UUID.randomUUID().toString());
        String code = body(inv).get("code").asText();

        int scanned = 0;
        for (Session viewer : List.of(s.owner(), s.admin(), s.member(), s.payer(), newUser())) {
            for (Probe p : probes(s)) {
                MvcResult r = call(p.method(), p.url(), viewer, p.body(), p.headers());
                String text = r.getResponse().getContentAsString();
                assertThat(text).as(p.label() + " as " + viewer.userId()).doesNotContain(INSTAPAY).doesNotContain(WALLET);
                scanned++;
            }
            MvcResult preview = call(GET, "/api/v1/invites/" + code, viewer, null);
            assertThat(preview.getResponse().getContentAsString()).as("invite preview").doesNotContain(INSTAPAY)
                    .doesNotContain(WALLET);
        }
        assertThat(scanned).isGreaterThan(40);
        // the receiver's own groups list and group detail do not carry their handles either
        for (Probe p : probes(s)) {
            if (p.label().equals("me") || p.label().startsWith("group") || p.label().contains("list")) {
                assertThat(call(p.method(), p.url(), s.receiver(), p.body(), p.headers()).getResponse().getContentAsString())
                        .as(p.label() + " as the receiver").doesNotContain(INSTAPAY).doesNotContain(WALLET);
            }
        }

        // the two allowed places
        assertThat(call(GET, "/api/v1/me/payment-handles", s.receiver(), null).getResponse().getContentAsString())
                .contains(INSTAPAY).contains(WALLET);
        assertThat(call(GET, "/api/v1/groups/" + s.gid() + "/balances", s.payer(), null).getResponse().getContentAsString())
                .contains(INSTAPAY).contains(WALLET);
        // a member who may not see them: the balances body has neither value
        assertThat(call(GET, "/api/v1/groups/" + s.gid() + "/balances", s.member(), null).getResponse().getContentAsString())
                .doesNotContain(INSTAPAY).doesNotContain(WALLET);
        // another user's /me/payment-handles is theirs alone
        assertThat(call(GET, "/api/v1/me/payment-handles", s.payer(), null).getResponse().getContentAsString())
                .doesNotContain(INSTAPAY).doesNotContain(WALLET);
    }

    @Test
    void theTransferFieldSetIsExactlyTheDocumentedOne() throws Exception {
        Scenario s = scenario();
        JsonNode asPayer = transfer(s.payer(), s);
        assertThat(keys(asPayer)).containsExactly("amountMinor", "fromMemberId", "hasDispute", "openSettlementIds",
                "pendingMinor", "receiverHandles", "toMemberId");
        assertThat(keys(asPayer.get("receiverHandles"))).containsExactly("instapay", "wallet");
        // the same keys for a viewer who may not see the values: the shape never reveals who may
        assertThat(keys(transfer(s.member(), s))).containsExactly("amountMinor", "fromMemberId", "hasDispute",
                "openSettlementIds", "pendingMinor", "receiverHandles", "toMemberId");

        JsonNode me = body(call(GET, "/api/v1/groups/" + s.gid(), s.payer(), null));
        for (JsonNode m : me.get("members")) {
            assertThat(keys(m)).as("MemberDto never carries handles").doesNotContain("receiverHandles", "instapay",
                    "wallet", "handles", "paymentHandles");
        }
        assertThat(keys(me)).doesNotContain("instapay", "wallet", "handles", "paymentHandles");
    }

    private static TreeSet<String> keys(JsonNode node) {
        TreeSet<String> set = new TreeSet<>();
        node.fieldNames().forEachRemaining(set::add);
        return set;
    }
}
