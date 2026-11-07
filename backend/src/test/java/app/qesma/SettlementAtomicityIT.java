package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;

import app.qesma.persistence.IdempotencyKeyStore;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MvcResult;

/**
 * AGENTS.md invariant 6 for settlements: the key write and the business write share one transaction. Own class
 * because it spies on a shared bean (own Spring context).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class SettlementAtomicityIT extends AbstractApiIT {

    @MockitoSpyBean IdempotencyKeyStore keyStore;

    @AfterEach
    void restore() {
        Mockito.reset(keyStore);
    }

    @Test
    void ifTheKeyRowCannotBeWrittenTheSettlementIsRolledBackAndTheSameKeyThenWorks() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Atomic " + UUID.randomUUID()).get("id").asText();
        String a = addMember(ali, gid, "A").get("id").asText();
        String b = addMember(ali, gid, "B").get("id").asText();
        String key = UUID.randomUUID().toString();
        Map<String, Object> body = Map.of("fromMemberId", a, "toMemberId", b, "amountMinor", 500L,
                "settledOn", "2026-10-20");

        doThrow(new IllegalStateException("simulated failure while storing the key"))
                .when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(), any());
        MvcResult failed = call(HttpMethod.POST, "/api/v1/groups/" + gid + "/settlements", ali, body,
                "Idempotency-Key", key);

        assertThat(status(failed)).isEqualTo(500);
        assertThat(code(failed)).isEqualTo("INTERNAL_ERROR");
        assertThat(failed.getResponse().getContentAsString()).doesNotContain("simulated failure");
        assertThat(jdbc.queryForObject("select count(*) from settlements where group_id = ?::uuid", Integer.class, gid))
                .isZero();
        assertThat(jdbc.queryForObject("select count(*) from idempotency_keys where user_id = ? and key = ?",
                Integer.class, ali.userId(), key)).isZero();

        doCallRealMethod().when(keyStore).insert(any(), anyString(), anyString(), anyString(), anyInt(), anyString(),
                any());
        MvcResult retry = call(HttpMethod.POST, "/api/v1/groups/" + gid + "/settlements", ali, body,
                "Idempotency-Key", key);
        assertThat(status(retry)).isEqualTo(201);
        assertThat(retry.getResponse().getHeader("Idempotency-Replayed")).isNull();
    }
}
