package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.POST;

import jakarta.persistence.EntityManagerFactory;
import java.util.Map;
import java.util.UUID;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import app.qesma.persistence.InviteStore;
import app.qesma.persistence.JoinRequestStore;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B11: the preview, the invite list and the request list cost the same number of statements for 2 and for 50 rows
 * (no per-member and no per-request query). Hibernate statistics count the JPA statements; the JDBC stores add a fixed
 * handful, so the assertion compares a small and a large group instead of a hard number.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class InviteQueryCountIT extends AbstractApiIT {

    @Autowired EntityManagerFactory emf;
    @Autowired org.springframework.jdbc.core.JdbcTemplate template;
    @MockitoSpyBean InviteStore inviteStore;
    @MockitoSpyBean JoinRequestStore requestStore;

    private long statementsFor(Session as, String url) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        Mockito.clearInvocations(inviteStore, requestStore);
        MvcResult r = call(GET, url, as, null);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        // JPA statements plus calls of the two SQL stores (each store method is one statement by construction)
        return stats.getPrepareStatementCount() + Mockito.mockingDetails(inviteStore).getInvocations().size()
                + Mockito.mockingDetails(requestStore).getInvocations().size();
    }

    @Test
    void previewCostsTheSameForTwoGhostsAsForFifty() throws Exception {
        Session owner = newUser();
        String small = createGroup(owner, "Small " + UUID.randomUUID()).get("id").asText();
        addMember(owner, small, "G0");
        String big = createGroup(owner, "Big " + UUID.randomUUID()).get("id").asText();
        for (int i = 0; i < 50; i++) {
            addMember(owner, big, "Ghost " + i);
        }
        String smallCode = body(call(POST, "/api/v1/groups/" + small + "/invites", owner, Map.of(), "Idempotency-Key",
                UUID.randomUUID().toString())).get("code").asText();
        String bigCode = body(call(POST, "/api/v1/groups/" + big + "/invites", owner, Map.of(), "Idempotency-Key",
                UUID.randomUUID().toString())).get("code").asText();
        Session joiner = newUser();

        long few = statementsFor(joiner, "/api/v1/invites/" + smallCode);
        long many = statementsFor(joiner, "/api/v1/invites/" + bigCode);

        assertThat(many).as("statements with 50 unclaimed members").isEqualTo(few);
        assertThat(template.queryForObject("select count(*) from members where group_id = ?::uuid and user_id is null",
                Long.class, big)).isEqualTo(50L);
    }

    @Test
    void requestListAndInviteListCostTheSameForOneRowAsForThirty() throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Requests " + UUID.randomUUID()).get("id").asText();
        MvcResult created = call(POST, "/api/v1/groups/" + gid + "/invites", owner, Map.of("requiresApproval", true),
                "Idempotency-Key", UUID.randomUUID().toString());
        String code = body(created).get("code").asText();
        for (int i = 0; i < 30; i++) {
            call(POST, "/api/v1/invites/" + code + "/join", newUser(), Map.of("newMemberName", "Asker " + i),
                    "Idempotency-Key", UUID.randomUUID().toString());
            call(POST, "/api/v1/groups/" + gid + "/invites", owner, Map.of(), "Idempotency-Key", UUID.randomUUID().toString());
        }
        String requests = "/api/v1/groups/" + gid + "/join-requests";
        String invites = "/api/v1/groups/" + gid + "/invites";

        assertThat(statementsFor(owner, requests + "?size=30")).isEqualTo(statementsFor(owner, requests + "?size=1"));
        assertThat(statementsFor(owner, invites + "?size=30")).isEqualTo(statementsFor(owner, invites + "?size=1"));
    }
}
