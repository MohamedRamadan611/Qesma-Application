package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.GET;

import jakarta.persistence.EntityManagerFactory;
import java.sql.Timestamp;
import java.time.Instant;
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
 * B15: the recorder costs the same statements for 2 and for 100 recipients (the notifications are ONE INSERT ... SELECT),
 * and a feed or center page is ONE query whatever the number of items. Counted from both sides like
 * PaymentHandleQueryCountIT: Hibernate's JPA statement count and the calls of the shared JdbcTemplate.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class ActivityQueryCountIT extends AbstractActivityIT {

    @Autowired EntityManagerFactory emf;
    @MockitoSpyBean JdbcTemplate spiedJdbc;

    private record Count(long jpa, long jdbc, long jdbcQueries) {
    }

    private Count measure(java.util.concurrent.Callable<MvcResult> request, int expectedStatus) throws Exception {
        Statistics stats = emf.unwrap(SessionFactory.class).getStatistics();
        stats.clear();
        Mockito.clearInvocations(spiedJdbc);
        MvcResult r = request.call();
        assertThat(status(r)).as(r.getResponse().getContentAsString()).isEqualTo(expectedStatus);
        List<String> names = Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .map(i -> i.getMethod().getName()).toList();
        long all = names.stream().filter(n -> n.startsWith("query") || n.startsWith("update")
                || n.startsWith("execute") || n.startsWith("batch")).count();
        long queries = Mockito.mockingDetails(spiedJdbc).getInvocations().stream()
                .filter(i -> isEntryQuery(i.getMethod())).count();
        return new Count(stats.getPrepareStatementCount(), all, queries);
    }

    /**
     * The calls our code makes: {@code query(String, RowMapper, Object...)} (a page) or {@code queryForObject(String,
     * Class, Object...)} (the unread count). JdbcTemplate calls its own overloads internally; those are not counted.
     */
    private static boolean isEntryQuery(java.lang.reflect.Method m) {
        Class<?>[] p = m.getParameterTypes();
        boolean page = m.getName().equals("query") && p.length == 3 && p[0] == String.class
                && p[1] == org.springframework.jdbc.core.RowMapper.class && p[2] == Object[].class;
        boolean scalar = m.getName().equals("queryForObject") && p.length == 3 && p[0] == String.class
                && p[1] == Class.class && p[2] == Object[].class;
        return page || scalar;
    }

    /** A group with the owner (the payer, not a participant) and {@code recipients} linked members sharing the bill. */
    private record Crowd(Session owner, String gid, List<String> participants, String ownerMid) {
    }

    private Crowd crowd(int recipients) throws Exception {
        Session owner = newUser();
        String gid = createGroup(owner, "Crowd " + UUID.randomUUID()).get("id").asText();
        String ownerMid = member(owner, gid, "Owner").get("id").asText();
        List<String> participants = new ArrayList<>();
        for (int i = 0; i < recipients; i++) {
            participants.add(linkUser(gid, newUser(), "MEMBER", "ACTIVE", "M" + i));
        }
        return new Crowd(owner, gid, participants, ownerMid);
    }

    private MvcResult addExpense(Crowd c) throws Exception {
        return postExpense(c.owner(), c.gid(), UUID.randomUUID().toString(),
                equalBody("Dinner", 100_000, c.participants(), c.ownerMid(), 100_000L));
    }

    @Test
    void recordingAnEventCostsTheSameStatementsForTwoAndForOneHundredRecipients() throws Exception {
        Crowd small = crowd(2);
        Crowd big = crowd(100);

        Count two = measure(() -> addExpense(small), 201);
        Count hundred = measure(() -> addExpense(big), 201);

        assertThat(notificationCount(small.gid())).isEqualTo(2);
        assertThat(notificationCount(big.gid())).isEqualTo(100);
        assertThat(hundred.jdbc()).as("JDBC statements, 100 vs 2 recipients").isEqualTo(two.jdbc());
        assertThat(hundred.jpa()).as("JPA statements, 100 vs 2 recipients").isEqualTo(two.jpa());
    }

    private void insertEvents(String gid, int n) {
        Instant base = Instant.parse("2026-10-01T10:00:00Z");
        List<Object[]> rows = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            rows.add(new Object[] {UUID.randomUUID(), gid, Timestamp.from(base.plusSeconds(i))});
        }
        jdbc.batchUpdate("insert into group_events (id, group_id, type, payload, created_at) "
                + "values (?, ?::uuid, 'MEMBER_LEFT', '{}'::jsonb, ?)", rows);
    }

    @Test
    void aFeedPageIsOneQueryForOneItemAndForFifty() throws Exception {
        Crowd one = crowd(0);
        Crowd fifty = crowd(0);
        insertEvents(one.gid(), 1);
        insertEvents(fifty.gid(), 60);

        Count single = measure(() -> call(GET, "/api/v1/groups/" + one.gid() + "/activity?limit=50", one.owner(), null), 200);
        Count many = measure(() -> call(GET, "/api/v1/groups/" + fifty.gid() + "/activity?limit=50", fifty.owner(), null), 200);

        assertThat(feed(fifty.owner(), fifty.gid(), "?limit=50").get("items")).hasSize(50);
        assertThat(single.jdbcQueries()).as("one feed statement").isEqualTo(1L);
        assertThat(many.jdbcQueries()).isEqualTo(1L);
        assertThat(many.jdbc()).isEqualTo(single.jdbc());
        assertThat(many.jpa()).isEqualTo(single.jpa());
    }

    @Test
    void aCenterPageIsOneQueryForOneItemAndForFifty() throws Exception {
        Session alice = newUser();
        Session bob = newUser();
        Crowd c = crowd(0);
        String aliceMid = linkUser(c.gid(), alice, "MEMBER", "ACTIVE", "Alice");
        String bobMid = linkUser(c.gid(), bob, "MEMBER", "ACTIVE", "Bob");
        insertEvents(c.gid(), 60);
        jdbc.update("insert into notifications (id, user_id, event_id, created_at) "
                + "select gen_random_uuid(), ?, id, created_at from group_events where group_id = ?::uuid", alice.userId(), c.gid());
        jdbc.update("insert into notifications (id, user_id, event_id, created_at) "
                + "select gen_random_uuid(), ?, id, created_at from group_events where group_id = ?::uuid limit 1",
                bob.userId(), c.gid());
        assertThat(aliceMid).isNotBlank();
        assertThat(bobMid).isNotBlank();

        Count single = measure(() -> call(GET, "/api/v1/notifications?limit=50", bob, null), 200);
        Count many = measure(() -> call(GET, "/api/v1/notifications?limit=50", alice, null), 200);

        assertThat(single.jdbcQueries()).as("one center statement").isEqualTo(1L);
        assertThat(many.jdbcQueries()).isEqualTo(1L);
        assertThat(many.jdbc()).isEqualTo(single.jdbc());
        assertThat(many.jpa()).isEqualTo(single.jpa());
        Count unread = measure(() -> call(GET, "/api/v1/notifications/unread-count", alice, null), 200);
        assertThat(unread.jdbcQueries()).isEqualTo(1L);
    }
}
