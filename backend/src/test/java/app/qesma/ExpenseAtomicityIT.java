package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;

import app.qesma.persistence.IdempotencyKeyStore;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MvcResult;

/**
 * AGENTS.md invariant 6: the key write and the business write share one transaction. If storing the key fails
 * after the expense rows were written, nothing may remain. Own class because it spies on a shared bean (own context).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class ExpenseAtomicityIT extends AbstractApiIT {

    @MockitoSpyBean IdempotencyKeyStore keyStore;

    @AfterEach
    void restore() {
        Mockito.reset(keyStore);
    }

    @Test
    void ifTheKeyRowCannotBeWrittenTheExpenseAndItsChildrenAreRolledBackToo() throws Exception {
        Session ali = newUser();
        List<String> g = new ArrayList<>();
        g.add(createGroup(ali, "Atomic " + UUID.randomUUID()).get("id").asText());
        g.add(addMember(ali, g.get(0), "A").get("id").asText());
        g.add(addMember(ali, g.get(0), "B").get("id").asText());
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Doomed", 100, null, g.get(1), 100L);

        doThrow(new IllegalStateException("simulated failure while storing the key"))
                .when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());

        MvcResult failed = postExpense(ali, g.get(0), key, body);

        assertThat(status(failed)).isEqualTo(500);
        assertThat(code(failed)).isEqualTo("INTERNAL_ERROR");
        assertThat(failed.getResponse().getContentAsString()).doesNotContain("simulated failure"); // nothing leaks
        assertThat(countExpenses(g.get(0))).isZero();
        assertThat(jdbc.queryForObject("select count(*) from expense_payers p join expenses e on e.id = p.expense_id "
                + "where e.group_id = ?::uuid", Integer.class, g.get(0))).isZero();
        assertThat(jdbc.queryForObject("select count(*) from expense_splits s join expenses e on e.id = s.expense_id "
                + "where e.group_id = ?::uuid", Integer.class, g.get(0))).isZero();
        assertThat(jdbc.queryForObject("select count(*) from expense_revisions r join expenses e on e.id = r.expense_id "
                + "where e.group_id = ?::uuid", Integer.class, g.get(0))).isZero();   // history rolls back too
        assertThat(jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?",
                Integer.class, ali.userId(), key)).isZero();

        // the failure left nothing behind, so the same key and body now succeed normally
        doCallRealMethod().when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(),
                any());
        MvcResult retry = postExpense(ali, g.get(0), key, body);
        assertThat(status(retry)).isEqualTo(201);
        assertThat(retry.getResponse().getHeader("Idempotency-Replayed")).isNull();
        assertThat(countExpenses(g.get(0))).isEqualTo(1);
    }
}
