package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import jakarta.persistence.EntityManagerFactory;
import java.util.ArrayList;
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

/** The expense list must cost a fixed number of statements however many expenses a page holds (no N+1). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class ExpenseListQueryCountIT extends AbstractApiIT {

    /** group lookup + caller's member row (B10 authorization) + page + count + payers + splits + members. */
    private static final int EXPECTED_STATEMENTS = 7;

    @Autowired EntityManagerFactory emf;

    private long statementsFor(Session as, String url) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        MvcResult r = call(GET, url, as, null);
        assertThat(status(r)).isEqualTo(200);
        return stats.getPrepareStatementCount();
    }

    @Test
    void listCostsTheSameFewStatementsForOneExpenseAsForFifty() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Many " + UUID.randomUUID()).get("id").asText();
        List<String> members = new ArrayList<>();
        for (String n : List.of("A", "B", "C", "D")) {
            members.add(member(ali, gid, n).get("id").asText());
        }
        for (int i = 0; i < 50; i++) {
            createExpense(ali, gid, equalBody("e" + i, 1000 + i, null, members.get(i % 4), 1000L + i));
        }
        String base = "/api/v1/groups/" + gid + "/expenses";

        long one = statementsFor(ali, base + "?size=1");
        long fifty = statementsFor(ali, base + "?size=50");
        long empty = statementsFor(ali, base + "?page=5&size=50");

        assertThat(fifty).as("statements for 50 expenses").isEqualTo(one);
        assertThat(one).as("statements per list call").isLessThanOrEqualTo(EXPECTED_STATEMENTS);
        assertThat(empty).as("an empty page does not query children").isLessThan(one);
    }

    /** Itemized pages add exactly two more statements (items, assignees), however many bills the page holds. */
    private static final int EXPECTED_STATEMENTS_WITH_ITEMS = EXPECTED_STATEMENTS + 2;

    @Test
    void aPageWithItemizedBillsCostsTwoMoreStatementsNotOnePerBill() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Bills " + UUID.randomUUID()).get("id").asText();
        String a = member(ali, gid, "A").get("id").asText();
        String b = member(ali, gid, "B").get("id").asText();
        for (int i = 0; i < 30; i++) {
            Map<String, Object> bill = new java.util.LinkedHashMap<>();
            bill.put("title", "bill" + i);
            bill.put("expenseDate", "2026-10-18");
            bill.put("splitType", "ITEMIZED");
            bill.put("payers", List.of(Map.of("memberId", a, "amountMinor", 3000L + i)));
            bill.put("items", List.of(Map.of("name", "x", "amountMinor", 1000L + i, "assigneeMemberIds", List.of(a, b)),
                    Map.of("name", "y", "amountMinor", 2000L, "assigneeMemberIds", List.of(b))));
            createExpense(ali, gid, bill);
        }
        String base = "/api/v1/groups/" + gid + "/expenses";

        long one = statementsFor(ali, base + "?size=1");
        long thirty = statementsFor(ali, base + "?size=30");

        assertThat(thirty).as("statements for 30 itemized bills").isEqualTo(one);
        assertThat(one).isLessThanOrEqualTo(EXPECTED_STATEMENTS_WITH_ITEMS);
    }

    @Test
    void settlementListCostsTheSameFewStatementsForOneSettlementAsForThirty() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Pay " + UUID.randomUUID()).get("id").asText();
        String a = member(ali, gid, "A").get("id").asText();
        String b = member(ali, gid, "B").get("id").asText();
        for (int i = 0; i < 30; i++) {
            MvcResult r = call(org.springframework.http.HttpMethod.POST, "/api/v1/groups/" + gid + "/settlements", ali,
                    Map.of("fromMemberId", a, "toMemberId", b, "amountMinor", 100L + i, "settledOn", "2026-10-20"),
                    "Idempotency-Key", UUID.randomUUID().toString());
            assertThat(status(r)).isEqualTo(201);
        }
        String url = "/api/v1/groups/" + gid + "/settlements";
        long one = statementsFor(ali, url + "?size=1");
        long thirty = statementsFor(ali, url + "?size=30");
        assertThat(thirty).as("statements for 30 settlements").isEqualTo(one);
        assertThat(one).as("group lookup + caller member + page + count").isLessThanOrEqualTo(4);
    }

    @Test
    void revisionsAndGroupDetailCostAFixedNumberOfStatementsWhateverTheirSize() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Detail " + UUID.randomUUID()).get("id").asText();
        String a = member(ali, gid, "A").get("id").asText();
        String eid = createExpense(ali, gid, equalBody("e", 1000, null, a, 1000L)).get("id").asText();
        String revisions = "/api/v1/groups/" + gid + "/expenses/" + eid + "/revisions";
        String detail = "/api/v1/groups/" + gid;
        long revisionsFew = statementsFor(ali, revisions);
        long detailFew = statementsFor(ali, detail);

        for (int v = 1; v <= 12; v++) {
            MvcResult r = call(org.springframework.http.HttpMethod.PUT, "/api/v1/groups/" + gid + "/expenses/" + eid, ali,
                    equalBody("e" + v, 1000 + v, null, a, 1000L + v), "If-Match", "\"" + v + "\"");
            assertThat(status(r)).isEqualTo(200);
        }
        for (int m = 0; m < 14; m++) {
            member(ali, gid, "M" + m);
        }

        assertThat(statementsFor(ali, revisions)).as("revisions: 13 entries cost the same as 1").isEqualTo(revisionsFew);
        assertThat(statementsFor(ali, detail)).as("group detail: 15 members cost the same as 1").isEqualTo(detailFew);
        assertThat(detailFew).isLessThanOrEqualTo(4);
        assertThat(revisionsFew).isLessThanOrEqualTo(3);
    }

    @Test
    void groupListCostsOneSelectPlusOneCountRegardlessOfGroupCount() throws Exception {
        Session ali = newUser();
        for (int i = 0; i < 12; i++) {
            String gid = createGroup(ali, "G" + i).get("id").asText();
            member(ali, gid, "A");
        }
        long few = statementsFor(ali, "/api/v1/groups?size=1");
        long many = statementsFor(ali, "/api/v1/groups?size=12");
        assertThat(many).isEqualTo(few);
        assertThat(many).isLessThanOrEqualTo(2); // page select (members and totals are subqueries) + count
    }
}
