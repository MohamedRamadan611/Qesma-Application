package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PUT;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B14 / A91 visibility matrix. A receiver's handles appear on the balances transfer only for the payer of that transfer
 * and for Owner/Admin; every other caller gets a null; non-members and LEFT or unlinked ex-members get 404.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class PaymentHandleVisibilityIT extends AbstractHandlesIT {

    private static final Map<String, String> RECEIVER_HANDLES = Map.of("instapay", INSTAPAY, "wallet", WALLET);

    @Test
    void thePayerSeesTheReceiversHandlesOnTheirOwnTransfer() throws Exception {
        Scenario s = scenario();
        assertThat(handlesOf(transfer(s.payer(), s))).isEqualTo(RECEIVER_HANDLES);
    }

    @Test
    void ownerAndAdminSeeThemOnEveryTransfer() throws Exception {
        Scenario s = scenario();
        assertThat(handlesOf(transfer(s.owner(), s))).isEqualTo(RECEIVER_HANDLES);
        assertThat(handlesOf(transfer(s.admin(), s))).isEqualTo(RECEIVER_HANDLES);
    }

    @Test
    void aPlainMemberWhoIsNotThePayerAndTheReceiverThemselvesGetNull() throws Exception {
        Scenario s = scenario();
        JsonNode asMember = transfer(s.member(), s);
        assertThat(asMember.has("receiverHandles")).as("the field is always present").isTrue();
        assertThat(asMember.get("receiverHandles").isNull()).isTrue();
        assertThat(transfer(s.receiver(), s).get("receiverHandles").isNull())
                .as("the receiver reads their own handles through /me, not through balances").isTrue();
    }

    @Test
    void aPayerSeesHandlesOnlyOfTheTransfersTheyPay() throws Exception {
        Scenario s = scenario();
        // a second debt in the same group: MEMBER owes ADMIN, and the admin has handles too
        setHandles(s.admin(), "admin@otherbank", "01255555555");
        createExpense(s.admin(), s.gid(), equalBody("Taxi", 2000, List.of(s.adminMid(), s.memberMid()), s.adminMid(), 2000L));

        JsonNode transfers = balances(s.payer(), s.gid()).get("transfers");
        assertThat(transfers).hasSize(2);
        for (JsonNode t : transfers) {
            if (t.get("toMemberId").asText().equals(s.receiverMid())) {
                assertThat(handlesOf(t)).isEqualTo(RECEIVER_HANDLES);
            } else {
                assertThat(t.get("receiverHandles").isNull()).as("not the payer's own transfer").isTrue();
            }
        }
        assertThat(body(call(GET, "/api/v1/groups/" + s.gid() + "/balances", s.payer(), null)).toString())
                .doesNotContain("admin@otherbank").doesNotContain("01255555555");
    }

    @Test
    void aStrangerAndAMemberOfAnotherGroupGet404WithTheSameBodyAsAnUnknownGroup() throws Exception {
        Scenario s = scenario();
        Session stranger = newUser();
        // another group in which the receiver is ALSO a member: sharing a different group grants nothing here
        Session other = newUser();
        String otherGroup = createGroup(other, "Other " + java.util.UUID.randomUUID()).get("id").asText();
        linkUser(otherGroup, s.receiver(), "MEMBER", "ACTIVE", "Receiver there");
        Session coMemberElsewhere = newUser();
        linkUser(otherGroup, coMemberElsewhere, "MEMBER", "ACTIVE", "Elsewhere");

        for (Session viewer : List.of(stranger, other, coMemberElsewhere)) {
            MvcResult r = call(GET, "/api/v1/groups/" + s.gid() + "/balances", viewer, null);
            assertThat(status(r)).isEqualTo(404);
            assertThat(r.getResponse().getContentAsString()).doesNotContain(INSTAPAY).doesNotContain(WALLET);
        }
        MvcResult unknown = call(GET, "/api/v1/groups/" + java.util.UUID.randomUUID() + "/balances", stranger, null);
        MvcResult real = call(GET, "/api/v1/groups/" + s.gid() + "/balances", stranger, null);
        assertThat(problemWithoutRequestId(real)).isEqualTo(problemWithoutRequestId(unknown));

        // inside the other group, a plain co-member of the receiver sees nothing of the receiver's handles either
        assertThat(balances(coMemberElsewhere, otherGroup).toString()).doesNotContain(INSTAPAY).doesNotContain(WALLET);
    }

    @Test
    void aLeftViewerAndAnUnlinkedExMemberGet404() throws Exception {
        Scenario s = scenario();
        Session left = newUser();
        linkUser(s.gid(), left, "MEMBER", "LEFT", "Left");
        assertThat(status(call(GET, "/api/v1/groups/" + s.gid() + "/balances", left, null))).isEqualTo(404);

        Session exMember = newUser();
        String exMid = linkUser(s.gid(), exMember, "MEMBER", "ACTIVE", "Ex");
        assertThat(status(call(GET, "/api/v1/groups/" + s.gid() + "/balances", exMember, null))).isEqualTo(200);
        jdbc.update("update members set user_id = null where id = ?::uuid", exMid);                      // unlinked: a ghost again
        assertThat(status(call(GET, "/api/v1/groups/" + s.gid() + "/balances", exMember, null))).isEqualTo(404);

        // a payer who left loses the view at once, even though the debt is still in the ledger
        jdbc.update("update members set status = 'LEFT', left_at = now() where id = ?::uuid", s.payerMid());
        assertThat(status(call(GET, "/api/v1/groups/" + s.gid() + "/balances", s.payer(), null))).isEqualTo(404);
    }

    @Test
    void handlesFollowTheReceiversStatusLinkAndRemovalImmediately() throws Exception {
        Scenario s = scenario();
        assertThat(handlesOf(transfer(s.payer(), s))).isEqualTo(RECEIVER_HANDLES);

        // the receiver leaves: the debt stays a real transfer, the handles stop being shown
        jdbc.update("update members set status = 'LEFT', left_at = now() where id = ?::uuid", s.receiverMid());
        assertThat(transfer(s.payer(), s).get("receiverHandles").isNull()).isTrue();
        assertThat(transfer(s.payer(), s).get("amountMinor").asLong()).isEqualTo(1500L);

        // reactivated: shown again
        jdbc.update("update members set status = 'ACTIVE', left_at = null where id = ?::uuid", s.receiverMid());
        assertThat(handlesOf(transfer(s.payer(), s))).isEqualTo(RECEIVER_HANDLES);

        // the receiver removes one handle: gone on the very next call
        assertThat(status(call(PUT, "/api/v1/me/payment-handles", s.receiver(), Map.of("instapay", INSTAPAY)))).isEqualTo(200);
        JsonNode partial = transfer(s.payer(), s).get("receiverHandles");
        assertThat(partial.get("instapay").asText()).isEqualTo(INSTAPAY);
        assertThat(partial.get("wallet").isNull()).as("removed wallet").isTrue();

        // removed entirely: the whole object is null
        assertThat(status(call(PUT, "/api/v1/me/payment-handles", s.receiver(), "{}"))).isEqualTo(200);
        assertThat(transfer(s.payer(), s).get("receiverHandles").isNull()).isTrue();

        // set again, then the account is unlinked from the member (a ghost again): never shown
        setHandles(s.receiver(), INSTAPAY, WALLET);
        assertThat(handlesOf(transfer(s.payer(), s))).isEqualTo(RECEIVER_HANDLES);
        jdbc.update("update members set user_id = null where id = ?::uuid", s.receiverMid());
        assertThat(transfer(s.payer(), s).get("receiverHandles").isNull()).isTrue();
        assertThat(transfer(s.owner(), s).get("receiverHandles").isNull()).as("not even for the owner").isTrue();
    }

    @Test
    void aGhostReceiverAndAReceiverWithoutHandlesGetNull() throws Exception {
        Session owner = newUser();
        Session payer = newUser();
        String gid = createGroup(owner, "Ghosts " + java.util.UUID.randomUUID()).get("id").asText();
        String ghost = addMember(owner, gid, "Ghost").get("id").asText();
        String payerMid = linkUser(gid, payer, "MEMBER", "ACTIVE", "Payer");
        createExpense(owner, gid, equalBody("Lunch", 2000, List.of(ghost, payerMid), ghost, 2000L));
        JsonNode t = balances(payer, gid).get("transfers").get(0);
        assertThat(t.get("toMemberId").asText()).isEqualTo(ghost);
        assertThat(t.get("receiverHandles").isNull()).isTrue();

        // a linked receiver with no handles
        Session noHandles = newUser();
        String mid = linkUser(gid, noHandles, "MEMBER", "ACTIVE", "NoHandles");
        createExpense(owner, gid, equalBody("Coffee", 1000, List.of(mid, payerMid), mid, 1000L));
        for (JsonNode tr : balances(payer, gid).get("transfers")) {
            assertThat(tr.get("receiverHandles").isNull()).isTrue();
        }
    }

    @Test
    void deletingTheHandlesOfAnAccountLeavesNothingBehind() throws Exception {
        Scenario s = scenario();
        assertThat(jdbc.queryForObject("select count(*) from payment_handles where user_id = ?", Integer.class,
                s.receiver().userId())).isEqualTo(2);
        // B17 will call PaymentHandleService.deleteAllFor on account deletion
        jdbc.update("delete from payment_handles where user_id = ?", s.receiver().userId());
        assertThat(transfer(s.payer(), s).get("receiverHandles").isNull()).isTrue();
        assertThat(call(DELETE, "/api/v1/me/payment-handles", s.receiver(), null).getResponse().getStatus())
                .as("no delete route exists: PUT with nulls is the removal").isIn(404, 405);
    }
}
