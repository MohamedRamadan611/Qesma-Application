package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.EntityManagerFactory;
import java.util.List;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B14: handles on the transfers cost ONE batched statement however many transfers there are. Statements are counted from
 * both sides (Hibernate's JPA count and the invocations of the shared JdbcTemplate), for the payer and for an Admin who
 * sees every receiver.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class PaymentHandleQueryCountIT extends AbstractHandlesIT {

    @Autowired EntityManagerFactory emf;
    @MockitoSpyBean JdbcTemplate spiedJdbc;

    private record Count(long jpa, long jdbc) {
    }

    private Count statementsFor(Session as, String gid) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        Mockito.clearInvocations(spiedJdbc);
        MvcResult r = call(GET, "/api/v1/groups/" + gid + "/balances", as, null);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        long jdbcCalls = Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .filter(i -> i.getMethod().getName().startsWith("query") || i.getMethod().getName().startsWith("update")
                        || i.getMethod().getName().startsWith("execute") || i.getMethod().getName().startsWith("batch"))
                .count();
        return new Count(stats.getPrepareStatementCount(), jdbcCalls);
    }

    /** The calls of the last request that went through the handles query (a {@code query(PreparedStatementCreator, RowMapper)}). */
    private long handleQueries() {
        return Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .filter(i -> i.getMethod().getName().equals("query") && i.getMethod().getParameterCount() == 2
                        && i.getMethod().getParameterTypes()[0] == org.springframework.jdbc.core.PreparedStatementCreator.class
                        && i.getMethod().getParameterTypes()[1] == org.springframework.jdbc.core.RowMapper.class)
                .count();
    }

    /** The OWNER owes every receiver 1000: one transfer per receiver, every receiver with both handles. */
    private String groupWithReceivers(Session owner, int receivers) throws Exception {
        String gid = createGroup(owner, "Count " + java.util.UUID.randomUUID()).get("id").asText();
        String ownerMid = body(call(GET, "/api/v1/groups/" + gid, owner, null)).get("members").get(0).get("id").asText();
        for (int i = 0; i < receivers; i++) {
            Session r = newUser();
            String mid = linkUser(gid, r, "MEMBER", "ACTIVE", "Receiver " + i);
            createExpense(owner, gid, equalBody("Item " + i, 2000, List.of(mid, ownerMid), mid, 2000L));
            String phone = String.format("0101%07d", i);
            setHandles(r, "recv" + i + "@bank", phone);
        }
        return gid;
    }

    @Test
    void balancesCostTheSameStatementsForOneTransferAsForTwentyAndTheHandlesQueryRunsOnce() throws Exception {
        Session ownerSmall = newUser();
        Session ownerBig = newUser();
        String small = groupWithReceivers(ownerSmall, 1);
        String big = groupWithReceivers(ownerBig, 20);

        Count one = statementsFor(ownerSmall, small);
        long oneQueries = handleQueries();
        Count twenty = statementsFor(ownerBig, big);
        long twentyQueries = handleQueries();

        JsonNode transfers = body(call(GET, "/api/v1/groups/" + big + "/balances", ownerBig, null)).get("transfers");
        assertThat(transfers).as("20 suggested transfers").hasSize(20);
        for (JsonNode t : transfers) {
            assertThat(t.get("receiverHandles").isNull()).as("every receiver's handles are there").isFalse();
        }
        assertThat(twenty.jpa()).as("JPA statements, 20 vs 1 transfer").isEqualTo(one.jpa());
        assertThat(twenty.jdbc()).as("JDBC statements, 20 vs 1 transfer").isEqualTo(one.jdbc());
        assertThat(oneQueries).as("one batched handles statement for one transfer").isEqualTo(1L);
        assertThat(twentyQueries).as("one batched handles statement for twenty transfers").isEqualTo(1L);
    }

    @Test
    void anAdminWhoSeesEveryReceiverAlsoCostsOneStatement() throws Exception {
        Session owner = newUser();
        String gid = groupWithReceivers(owner, 20);
        Session admin = newUser();
        linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
        Session ownerOfSmall = newUser();
        String small = groupWithReceivers(ownerOfSmall, 1);
        Session adminSmall = newUser();
        linkUser(small, adminSmall, "ADMIN", "ACTIVE", "Admin");

        Count one = statementsFor(adminSmall, small);
        Count twenty = statementsFor(admin, gid);
        assertThat(handleQueries()).isEqualTo(1L);
        assertThat(twenty).as("admin: 20 vs 1 transfer").isEqualTo(one);
    }

    @Test
    void aViewerWhoMaySeeNoHandlesRunsNoHandlesStatementAtAll() throws Exception {
        Scenario s = scenario();
        Count member = statementsFor(s.member(), s.gid());
        assertThat(handleQueries()).as("a plain member is the payer of nothing: no receivers to ask for").isZero();
        Count payer = statementsFor(s.payer(), s.gid());
        assertThat(handleQueries()).isEqualTo(1L);
        assertThat(payer.jdbc()).as("the handles query is the extra work").isGreaterThan(member.jdbc());
    }
}
