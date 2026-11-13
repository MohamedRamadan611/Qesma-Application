package app.qesma;

import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;
import org.springframework.test.web.servlet.MvcResult;

/** Shared scenario of the B14 integration tests: one group in which PAYER owes RECEIVER, who has set both handles. */
abstract class AbstractHandlesIT extends AbstractApiIT {

    static final String INSTAPAY = "zzreceiver@zzbank";
    static final String WALLET = "01099887766";

    /** OWNER owns the group; ADMIN and MEMBER (not a party to the debt) have those roles; PAYER owes RECEIVER 1500. */
    protected record Scenario(String gid, Session owner, Session admin, Session member, Session payer, Session receiver,
                              String ownerMid, String adminMid, String memberMid, String payerMid, String receiverMid) {
    }

    protected void setHandles(Session as, String instapay, String wallet) throws Exception {
        java.util.Map<String, Object> body = new java.util.HashMap<>();
        body.put("instapay", instapay);
        body.put("wallet", wallet);
        MvcResult r = call(PUT, "/api/v1/me/payment-handles", as, body);
        if (status(r) != 200) {
            throw new AssertionError("set handles failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
    }

    protected Scenario scenario() throws Exception {
        Session owner = newUser();
        Session admin = newUser();
        Session member = newUser();
        Session payer = newUser();
        Session receiver = newUser();
        String gid = createGroup(owner, "Handles " + java.util.UUID.randomUUID()).get("id").asText();
        String ownerMid = body(call(GET, "/api/v1/groups/" + gid, owner, null)).get("members").get(0).get("id").asText();
        String adminMid = linkUser(gid, admin, "ADMIN", "ACTIVE", "Admin");
        String memberMid = linkUser(gid, member, "MEMBER", "ACTIVE", "Member");
        String payerMid = linkUser(gid, payer, "MEMBER", "ACTIVE", "Payer");
        String receiverMid = linkUser(gid, receiver, "MEMBER", "ACTIVE", "Receiver");
        createExpense(receiver, gid, equalBody("Dinner", 3000, List.of(receiverMid, payerMid), receiverMid, 3000L));
        setHandles(receiver, INSTAPAY, WALLET);
        return new Scenario(gid, owner, admin, member, payer, receiver, ownerMid, adminMid, memberMid, payerMid, receiverMid);
    }

    protected JsonNode balances(Session as, String gid) throws Exception {
        MvcResult r = call(GET, "/api/v1/groups/" + gid + "/balances", as, null);
        if (status(r) != 200) {
            throw new AssertionError("balances failed: " + status(r) + " " + r.getResponse().getContentAsString());
        }
        return body(r);
    }

    /** The one transfer of the scenario (payer to receiver). */
    protected JsonNode transfer(Session as, Scenario s) throws Exception {
        JsonNode transfers = balances(as, s.gid()).get("transfers");
        for (JsonNode t : transfers) {
            if (t.get("fromMemberId").asText().equals(s.payerMid()) && t.get("toMemberId").asText().equals(s.receiverMid())) {
                return t;
            }
        }
        throw new AssertionError("no payer -> receiver transfer in " + transfers);
    }

    protected static Map<String, String> handlesOf(JsonNode transfer) {
        JsonNode h = transfer.get("receiverHandles");
        if (h == null || h.isNull()) {
            return null;
        }
        return Map.of("instapay", h.get("instapay").asText(), "wallet", h.get("wallet").asText());
    }
}
