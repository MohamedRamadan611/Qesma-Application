package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;

import app.qesma.persistence.IdempotencyKeyStore;
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
 * B15 / AGENTS.md invariant 6 (spy on the key store like ExpenseAtomicityIT): the event and its notifications are written in the business transaction. The key row is
 * stored AFTER the recorder, so a failure there must roll back the expense, its event and its notifications together.
 * Own class because it spies on a shared bean (own context).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class EventAtomicityIT extends AbstractActivityIT {

    @MockitoSpyBean IdempotencyKeyStore keyStore;

    @AfterEach
    void restore() {
        Mockito.reset(keyStore);
    }

    @Test
    void ifStoringTheKeyFailsAfterTheEventWasWrittenNoExpenseEventOrNotificationRemains() throws Exception {
        Session owner = newUser();
        Session friend = newUser();
        String gid = createGroup(owner, "Atomic events " + UUID.randomUUID()).get("id").asText();
        String ownerMid = member(owner, gid, "Owner").get("id").asText();
        String friendMid = linkUser(gid, friend, "MEMBER", "ACTIVE", "Friend");
        String key = UUID.randomUUID().toString();
        Object body = equalBody("Doomed", 100, List.of(ownerMid, friendMid), ownerMid, 100L);

        doThrow(new IllegalStateException("simulated failure while storing the key"))
                .when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());

        MvcResult failed = postExpense(owner, gid, key, body);

        assertThat(status(failed)).isEqualTo(500);
        assertThat(code(failed)).isEqualTo("INTERNAL_ERROR");
        assertThat(countExpenses(gid)).isZero();
        assertThat(eventCount(gid)).as("no event").isZero();
        assertThat(notificationCount(gid)).as("no notification").isZero();

        doCallRealMethod().when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());
        MvcResult retry = postExpense(owner, gid, key, body);
        assertThat(status(retry)).isEqualTo(201);
        assertThat(eventsOf(gid, "EXPENSE_ADDED")).hasSize(1);
        assertThat(notificationCount(gid)).isEqualTo(1);       // Friend only: the owner is the actor
    }
}
