package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/** B14: set, replace, remove, validation over HTTP, and the database CHECK / UNIQUE constraints (A90, A92, A93). */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class PaymentHandlesIT extends AbstractApiIT {

    private static final String URL = "/api/v1/me/payment-handles";

    private static Map<String, Object> put(Object instapay, Object wallet) {
        Map<String, Object> m = new HashMap<>();
        m.put("instapay", instapay);
        m.put("wallet", wallet);
        return m;
    }

    private JsonNode get(Session as) throws Exception {
        MvcResult r = call(GET, URL, as, null);
        assertThat(status(r)).isEqualTo(200);
        return body(r);
    }

    @Test
    void aNewUserHasNoHandlesAndBothFieldsArePresentAsNull() throws Exception {
        JsonNode h = get(newUser());
        assertThat(h.has("instapay")).isTrue();
        assertThat(h.has("wallet")).isTrue();
        assertThat(h.get("instapay").isNull()).isTrue();
        assertThat(h.get("wallet").isNull()).isTrue();
    }

    @Test
    void setNormalisesReplaceOverwritesAndNullRemoves() throws Exception {
        Session me = newUser();

        MvcResult set = call(PUT, URL, me, put("Ali@InstaPay", "٠١٠ ١٢٣٤-٥٦٧٨"));
        assertThat(status(set)).isEqualTo(200);
        assertThat(body(set).get("instapay").asText()).isEqualTo("ali@instapay");
        assertThat(body(set).get("wallet").asText()).isEqualTo("01012345678");
        assertThat(get(me).get("wallet").asText()).isEqualTo("01012345678");

        // replace both: only one row per type remains
        assertThat(status(call(PUT, URL, me, put("sara@cib", "+201112345678")))).isEqualTo(200);
        assertThat(get(me).get("instapay").asText()).isEqualTo("sara@cib");
        assertThat(get(me).get("wallet").asText()).isEqualTo("01112345678");
        assertThat(jdbc.queryForObject("select count(*) from payment_handles where user_id = ?", Integer.class, me.userId()))
                .isEqualTo(2);

        // null removes one, an absent field and a blank string remove too (PUT replaces both)
        assertThat(status(call(PUT, URL, me, put("sara@cib", null)))).isEqualTo(200);
        assertThat(get(me).get("wallet").isNull()).isTrue();
        assertThat(get(me).get("instapay").asText()).isEqualTo("sara@cib");
        assertThat(status(call(PUT, URL, me, "{}"))).isEqualTo(200);
        assertThat(get(me).get("instapay").isNull()).isTrue();
        assertThat(status(call(PUT, URL, me, put("a@b", "01012345678")))).isEqualTo(200);
        assertThat(status(call(PUT, URL, me, put("  ", "")))).isEqualTo(200);
        assertThat(get(me).get("instapay").isNull()).isTrue();
        assertThat(get(me).get("wallet").isNull()).isTrue();
        assertThat(jdbc.queryForObject("select count(*) from payment_handles where user_id = ?", Integer.class, me.userId()))
                .as("removal really deletes the rows").isZero();
    }

    @Test
    void invalidInputIs422NamesTheFieldNeverEchoesTheValueAndChangesNothing() throws Exception {
        Session me = newUser();
        assertThat(status(call(PUT, URL, me, put("keep@bank", "01012345678")))).isEqualTo(200);

        String badWallet = "0131234567x";
        MvcResult w = call(PUT, URL, me, put("other@bank", badWallet));
        assertThat(status(w)).isEqualTo(422);
        assertThat(code(w)).isEqualTo("VALIDATION_ERROR");
        assertThat(body(w).get("title").asText()).contains("wallet");
        assertThat(w.getResponse().getContentAsString()).doesNotContain(badWallet).doesNotContain("other@bank");

        String badInstapay = "no-at-sign";
        MvcResult i = call(PUT, URL, me, put(badInstapay, "01112345678"));
        assertThat(status(i)).isEqualTo(422);
        assertThat(code(i)).isEqualTo("VALIDATION_ERROR");
        assertThat(body(i).get("title").asText()).contains("instapay");
        assertThat(i.getResponse().getContentAsString()).doesNotContain(badInstapay);

        JsonNode after = get(me);
        assertThat(after.get("instapay").asText()).as("a rejected request changes nothing").isEqualTo("keep@bank");
        assertThat(after.get("wallet").asText()).isEqualTo("01012345678");
    }

    @Test
    void malformedJsonIs400WithoutEchoingTheBody() throws Exception {
        Session me = newUser();
        MvcResult r = call(PUT, URL, me, "{\"instapay\": \"leak@bank\", \"wallet\": ");
        assertThat(status(r)).isEqualTo(400);
        assertThat(r.getResponse().getContentAsString()).doesNotContain("leak@bank");
    }

    @Test
    void anonymousCallsAre401AndUsersNeverSeeEachOthersHandles() throws Exception {
        assertThat(status(call(GET, URL, null, null))).isEqualTo(401);
        assertThat(status(call(PUT, URL, null, put("a@b", null)))).isEqualTo(401);

        Session a = newUser();
        Session b = newUser();
        assertThat(status(call(PUT, URL, a, put("alice@bank", "01012345678")))).isEqualTo(200);
        assertThat(get(b).get("instapay").isNull()).isTrue();
        assertThat(status(call(PUT, URL, b, put("bob@bank", null)))).isEqualTo(200);
        assertThat(get(a).get("instapay").asText()).isEqualTo("alice@bank");
    }

    @Test
    void theDatabaseRefusesMalformedOrDuplicateRowsEvenIfTheServiceIsBypassed() throws Exception {
        Session me = newUser();
        String insert = "insert into payment_handles (id, user_id, type, value) values (?, ?, ?, ?)";
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "WALLET", "12345"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "WALLET", "٠١٠١٢٣٤٥٦٧٨"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "INSTAPAY", "Upper@Case"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "INSTAPAY", "a@@b"))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "PAYPAL", "x@y"))
                .isInstanceOf(DataIntegrityViolationException.class);

        jdbc.update(insert, UUID.randomUUID(), me.userId(), "WALLET", "01012345678");
        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID(), me.userId(), "WALLET", "01112345678"))
                .as("one value per type per user").isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void concurrentPutsOfOneUserLeaveExactlyOneRequestsPair() throws Exception {
        Session me = newUser();
        Map<String, Object> first = put("first@bank", "01012345678");
        Map<String, Object> second = put("second@bank", "01112345678");
        java.util.concurrent.ExecutorService pool = java.util.concurrent.Executors.newFixedThreadPool(2);
        try {
            for (int round = 0; round < 10; round++) {
                var a = pool.submit(() -> status(call(PUT, URL, me, first)));
                var b = pool.submit(() -> status(call(PUT, URL, me, second)));
                assertThat(a.get()).isEqualTo(200);
                assertThat(b.get()).isEqualTo(200);
                JsonNode h = get(me);
                boolean one = h.get("instapay").asText().equals("first@bank") && h.get("wallet").asText().equals("01012345678");
                boolean two = h.get("instapay").asText().equals("second@bank") && h.get("wallet").asText().equals("01112345678");
                assertThat(one || two).as("a mix of both requests: " + h).isTrue();
            }
        } finally {
            pool.shutdownNow();
        }
    }
}
