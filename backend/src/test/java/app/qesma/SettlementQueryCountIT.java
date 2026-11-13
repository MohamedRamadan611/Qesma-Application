package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.EntityManagerFactory;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
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
 * B13: pending information must not cost a statement per transfer or per settlement. The statements of one request are
 * counted from both sides: Hibernate's prepared-statement count (JPA) and the invocations of the shared
 * {@link JdbcTemplate} (the grouped totals query and the grouped pending-pairs query). Both are the same for 1 and for 50.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class SettlementQueryCountIT extends AbstractApiIT {

    @Autowired EntityManagerFactory emf;
    @MockitoSpyBean JdbcTemplate spiedJdbc;

    private record Count(long jpa, long jdbc) {
    }

    private Count statementsFor(Session as, String url) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        Mockito.clearInvocations(spiedJdbc);
        MvcResult r = call(GET, url, as, null);
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(200);
        long jdbcCalls = Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .filter(i -> i.getMethod().getName().startsWith("query") || i.getMethod().getName().startsWith("update")
                        || i.getMethod().getName().startsWith("execute") || i.getMethod().getName().startsWith("batch"))
                .count();
        return new Count(stats.getPrepareStatementCount(), jdbcCalls);
    }

    /** The explicit {@code query(sql, rowMapper, args...)} calls of the last request: our two grouped statements. */
    private long topLevelQueries() {
        return Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .filter(i -> i.getMethod().getName().equals("query") && i.getMethod().getParameterCount() == 3
                        && i.getMethod().getParameterTypes()[0] == String.class
                        && i.getMethod().getParameterTypes()[1] == org.springframework.jdbc.core.RowMapper.class)
                .count();
    }

    /** An owner and {@code ghosts} unlinked members; every ghost owes the owner, and every pair has an open settlement. */
    private String groupWithTransfers(Session owner, int ghosts, List<String> memberIds) throws Exception {
        String gid = createGroup(owner, "Count " + UUID.randomUUID()).get("id").asText();
        String ownerMid = member(owner, gid, "Owner").get("id").asText();
        memberIds.add(ownerMid);
        for (int i = 0; i < ghosts; i++) {
            memberIds.add(addMember(owner, gid, "Ghost " + i).get("id").asText());
        }
        long total = 1000L * (ghosts + 1);
        createExpense(owner, gid, equalBody("Shared", total, null, ownerMid, total));
        for (int i = 1; i <= ghosts; i++) {                                    // alternate PENDING and DISPUTED rows
            insertSettlement(gid, owner, memberIds.get(i), ownerMid, 10L + i, i % 2 == 0 ? "PENDING" : "DISPUTED");
        }
        for (int i = 1; i <= Math.min(ghosts, 5); i++) {                       // B16: recent reminders, read by ONE grouped statement
            jdbc.update("insert into remind_log (id, group_id, from_member_id, to_member_id, sent_by_user_id, created_at) "
                    + "values (?::uuid, ?::uuid, ?::uuid, ?::uuid, ?, now())", UUID.randomUUID().toString(), gid,
                    memberIds.get(i), ownerMid, owner.userId());
        }
        return gid;
    }

    private void insertSettlement(String gid, Session by, String from, String to, long amount, String status) {
        jdbc.update("""
                insert into settlements (id, group_id, from_member_id, to_member_id, amount_minor, settled_on,
                    created_by_user_id, status, declared_at, confirmed_at, disputed_at, cancelled_at)
                values (?::uuid, ?::uuid, ?::uuid, ?::uuid, ?, date '2026-10-20', ?, ?, now(),
                    case when ? = 'CONFIRMED' then now() end,
                    case when ? = 'DISPUTED' then now() end,
                    case when ? = 'CANCELLED' then now() end)""",
                UUID.randomUUID().toString(), gid, from, to, amount, by.userId(), status, status, status, status);
    }

    @Test
    void balancesWithPendingInformationCostTheSameStatementsForOneTransferAsForFifty() throws Exception {
        Session owner = newUser();
        List<String> smallMembers = new ArrayList<>();
        List<String> bigMembers = new ArrayList<>();
        String small = groupWithTransfers(owner, 1, smallMembers);
        String big = groupWithTransfers(owner, 50, bigMembers);

        Count one = statementsFor(owner, "/api/v1/groups/" + small + "/balances");
        long oneTopLevel = topLevelQueries();
        Count fifty = statementsFor(owner, "/api/v1/groups/" + big + "/balances");

        JsonNode transfers = body(call(GET, "/api/v1/groups/" + big + "/balances", owner, null)).get("transfers");
        assertThat(transfers).as("50 suggested transfers").hasSize(50);
        assertThat(transfers.get(0).get("pendingMinor").asLong() + transfers.get(1).get("pendingMinor").asLong())
                .as("the pending sums are really there").isGreaterThan(0);
        long withWindow = 0;
        for (JsonNode t : transfers) {
            withWindow += t.get("canRemindAt").isNull() ? 0 : 1;
        }
        assertThat(withWindow).as("canRemindAt comes from the grouped remind_log read").isEqualTo(5);
        assertThat(fifty.jpa()).as("JPA statements for 50 transfers").isEqualTo(one.jpa());
        assertThat(fifty.jdbc()).as("JDBC statements for 50 transfers").isEqualTo(one.jdbc());
        assertThat(oneTopLevel).as("the totals query and the pending-pairs query, once each").isEqualTo(2L);
    }

    @Test
    void theSettlementListCostsTheSameStatementsForOneRowAsForFiftyWhateverTheStatuses() throws Exception {
        Session owner = newUser();
        List<String> members = new ArrayList<>();
        String gid = groupWithTransfers(owner, 2, members);
        String url = "/api/v1/groups/" + gid + "/settlements";
        String[] statuses = {"PENDING", "CONFIRMED", "DISPUTED", "CANCELLED"};
        for (int i = 0; i < 50; i++) {
            insertSettlement(gid, owner, members.get(1 + i % 2), members.get(0), 5L + i, statuses[i % 4]);
        }

        Count one = statementsFor(owner, url + "?size=1");
        Count fifty = statementsFor(owner, url + "?size=50");
        Count filtered = statementsFor(owner, url + "?size=50&status=PENDING&status=DISPUTED");

        assertThat(fifty).as("50 rows vs 1 row").isEqualTo(one);
        assertThat(filtered.jpa()).as("a short page may skip the count query, never add one").isLessThanOrEqualTo(one.jpa());
        assertThat(one.jpa()).as("group + caller's member + page + count").isLessThanOrEqualTo(4);
    }
}
