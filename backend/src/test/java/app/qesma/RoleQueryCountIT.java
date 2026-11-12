package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import jakarta.persistence.EntityManagerFactory;
import java.util.ArrayList;
import java.util.List;
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

/**
 * B10: authorization must not add a query per group, member or expense. The caller is OWNER in some groups and
 * ADMIN/MEMBER in others; the statement count of the list and the detail is the same for 1 and for 50 rows. (Hibernate
 * statistics count JPA statements; the one JDBC statement behind {@code yourNetMinor} is constant by construction.)
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class RoleQueryCountIT extends AbstractApiIT {

    @Autowired EntityManagerFactory emf;

    private long statementsFor(Session as, String url) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        MvcResult r = call(GET, url, as, null);
        assertThat(status(r)).isEqualTo(200);
        return stats.getPrepareStatementCount();
    }

    @Test
    void groupListCostsTheSameStatementsForOneGroupAsForFiftyWhateverTheRoles() throws Exception {
        Session me = newUser();
        String[] roles = {"OWNER", "ADMIN", "MEMBER"};
        for (int i = 0; i < 50; i++) {
            String role = roles[i % 3];
            if (role.equals("OWNER")) {
                createGroup(me, "Mine " + i);
            } else {
                Session other = newUser();
                String gid = createGroup(other, "Theirs " + i).get("id").asText();
                linkUser(gid, me, role, "ACTIVE", "Me");
            }
        }
        long one = statementsFor(me, "/api/v1/groups?size=1");
        long fifty = statementsFor(me, "/api/v1/groups?size=50");
        assertThat(fifty).as("statements for 50 groups").isEqualTo(one);
        assertThat(one).as("page + count").isLessThanOrEqualTo(2);
    }

    @Test
    void groupDetailCostsTheSameStatementsForTwoMembersAsForFifty() throws Exception {
        Session owner = newUser();
        Session guest = newUser();
        String small = createGroup(owner, "Small " + UUID.randomUUID()).get("id").asText();
        linkUser(small, guest, "MEMBER", "ACTIVE", "Guest");
        String big = createGroup(owner, "Big " + UUID.randomUUID()).get("id").asText();
        linkUser(big, guest, "MEMBER", "ACTIVE", "Guest");
        List<String> names = new ArrayList<>();
        for (int i = 0; i < 48; i++) {
            names.add(addMember(owner, big, "M" + i).get("id").asText());
        }
        long few = statementsFor(guest, "/api/v1/groups/" + small);
        long many = statementsFor(guest, "/api/v1/groups/" + big);
        assertThat(many).as("statements for a 50-member group").isEqualTo(few);
    }

    /** B12: roles and LEFT members in the member list add no statements (the list is one query, whatever the mix). */
    @Test
    void groupDetailCostsTheSameStatementsWithManyAdminsAndLeftMembers() throws Exception {
        Session owner = newUser();
        Session guest = newUser();
        String small = createGroup(owner, "Small " + UUID.randomUUID()).get("id").asText();
        linkUser(small, guest, "MEMBER", "ACTIVE", "Guest");
        String mixed = createGroup(owner, "Mixed " + UUID.randomUUID()).get("id").asText();
        linkUser(mixed, guest, "MEMBER", "ACTIVE", "Guest");
        for (int i = 0; i < 30; i++) {
            linkUser(mixed, newUser(), i % 2 == 0 ? "ADMIN" : "MEMBER", i % 3 == 0 ? "LEFT" : "ACTIVE", "P" + i);
        }
        long few = statementsFor(guest, "/api/v1/groups/" + small);
        long many = statementsFor(guest, "/api/v1/groups/" + mixed);
        assertThat(many).as("statements for a group with admins and LEFT members").isEqualTo(few);
    }

    @Test
    void expenseListForAMemberCostsTheSameStatementsForOneExpenseAsForFifty() throws Exception {
        Session owner = newUser();
        Session guest = newUser();
        String gid = createGroup(owner, "Many " + UUID.randomUUID()).get("id").asText();
        String a = member(owner, gid, "A").get("id").asText();
        linkUser(gid, guest, "MEMBER", "ACTIVE", "Guest");
        for (int i = 0; i < 50; i++) {
            createExpense(owner, gid, equalBody("e" + i, 1000 + i, null, a, 1000L + i));
        }
        String base = "/api/v1/groups/" + gid + "/expenses";
        long one = statementsFor(guest, base + "?size=1");
        long fifty = statementsFor(guest, base + "?size=50");
        assertThat(fifty).as("statements for 50 expenses as a MEMBER").isEqualTo(one);
    }
}
