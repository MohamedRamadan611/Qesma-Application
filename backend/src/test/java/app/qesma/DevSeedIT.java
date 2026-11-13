package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import app.qesma.dev.DevSeedRunner;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** The Dahab sample from docs/STITCH_PROMPTS.md, created by the local seed profile, with its documented balances. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "local", "seed", "fake-auth"})
class DevSeedIT extends AbstractApiIT {

    @Autowired DevSeedRunner seeder;

    private Session signIn() throws Exception {
        MvcResult r = call(POST, "/api/v1/auth/google", null, Map.of("idToken", DevSeedRunner.FAKE_ID_TOKEN));
        JsonNode b = body(r);
        return new Session(b.get("accessToken").asText(), java.util.UUID.fromString(b.get("user").get("id").asText()));
    }

    @Test
    void theSeedCreatesTheDahabTripWithTheDocumentedBalancesAndIsSafeToRunAgain() throws Exception {
        Session owner = signIn();
        JsonNode groups = body(call(GET, "/api/v1/groups", owner, null)).get("items");
        assertThat(groups).hasSize(1);
        JsonNode summary = groups.get(0);
        assertThat(summary.get("name").asText()).isEqualTo("رحلة دهب");
        assertThat(summary.get("memberCount").asInt()).isEqualTo(4);   // كريم left (B12): not counted, still listed
        assertThat(summary.get("totalSpentMinor").asLong()).isEqualTo(60000 + 300000 + 56179);
        String gid = summary.get("id").asText();

        JsonNode group = body(call(GET, "/api/v1/groups/" + gid, owner, null));
        Map<String, String> nameById = new LinkedHashMap<>();
        group.get("members").forEach(m -> nameById.put(m.get("id").asText(), m.get("displayName").asText()));
        assertThat(nameById.values()).containsExactly("محمد", "عاصم", "محسن", "يوسف", "كريم");

        Map<String, String> roleAndStatus = new LinkedHashMap<>();
        group.get("members").forEach(m -> roleAndStatus.put(m.get("displayName").asText(),
                m.get("role").asText() + "/" + m.get("status").asText()));
        assertThat(roleAndStatus).containsEntry("محمد", "OWNER/ACTIVE").containsEntry("عاصم", "ADMIN/ACTIVE")
                .containsEntry("كريم", "MEMBER/LEFT").containsEntry("محسن", "MEMBER/ACTIVE");

        JsonNode balances = body(call(GET, "/api/v1/groups/" + gid + "/balances", owner, null));
        Map<String, Long> nets = new LinkedHashMap<>();
        balances.get("nets").forEach(n -> nets.put(nameById.get(n.get("memberId").asText()), n.get("netMinor").asLong()));
        assertThat(nets).containsExactly(Map.entry("محمد", 101401L), Map.entry("عاصم", 111402L),
                Map.entry("محسن", -68803L), Map.entry("يوسف", -72000L), Map.entry("كريم", -72000L));
        List<String> transfers = new java.util.ArrayList<>();
        balances.get("transfers").forEach(t -> transfers.add(nameById.get(t.get("fromMemberId").asText()) + ">"
                + nameById.get(t.get("toMemberId").asText()) + ":" + t.get("amountMinor").asLong()));
        assertThat(transfers).containsExactlyInAnyOrder("يوسف>عاصم:72000", "كريم>محمد:72000", "محسن>عاصم:39402",
                "محسن>محمد:29401");

        // B13: one PENDING and one DISPUTED example, neither of which moved the nets asserted above
        assertThat(jdbc.queryForList("select status from settlements where group_id = ?::uuid order by amount_minor desc",
                String.class, gid)).containsExactly("PENDING", "DISPUTED");
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid and status = 'CONFIRMED'",
                Long.class, gid)).isZero();

        JsonNode dinner = null;
        for (JsonNode e : body(call(GET, "/api/v1/groups/" + gid + "/expenses", owner, null)).get("items")) {
            if (e.get("splitType").asText().equals("ITEMIZED")) {
                dinner = e;
            }
        }
        assertThat(dinner).isNotNull();
        assertThat(dinner.get("totalMinor").asLong()).isEqualTo(56179);
        assertThat(dinner.get("shares").findValues("owedMinor").stream().map(JsonNode::asLong).toList())
                .containsExactly(16599L, 16598L, 22982L);

        // running the seeder again changes nothing
        seeder.run(new DefaultApplicationArguments());
        assertThat(body(call(GET, "/api/v1/groups", owner, null)).get("items")).hasSize(1);
        assertThat(jdbc.queryForObject("select count(*) from expenses where group_id = ?::uuid", Long.class, gid)).isEqualTo(3L);
    }
}
