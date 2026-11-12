package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;

import app.qesma.persistence.YourNetQuery;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MvcResult;

/**
 * B9: the creator of a group is its first member ("you"), that member cannot be removed, and the group list/detail
 * tell the caller how much they are owed or owe in each group, computed in one statement per page.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class OwnerMemberIT extends AbstractApiIT {

    private static final String GROUPS = "/api/v1/groups";

    @MockitoSpyBean YourNetQuery yourNet;

    private Session userNamed(String displayName) throws Exception {
        String sub = "sub-" + UUID.randomUUID();
        MvcResult r = call(POST, "/api/v1/auth/google", null,
                Map.of("idToken", "fake:" + sub + ":" + sub + "@example.com:" + displayName));
        JsonNode b = body(r);
        return new Session(b.get("accessToken").asText(), UUID.fromString(b.get("user").get("id").asText()));
    }

    // ---- the owner is member #1 ----------------------------------------------------------------------------

    @Test
    void creatingAGroupMakesTheCreatorItsFirstMemberLinkedToTheirAccount() throws Exception {
        Session ali = userNamed("Ali Hassan");
        JsonNode group = createGroup(ali, "Dahab " + UUID.randomUUID());

        assertThat(group.get("members")).hasSize(1);
        JsonNode owner = group.get("members").get(0);
        assertThat(owner.get("isYou").asBoolean()).isTrue();
        assertThat(owner.get("sortOrder").asInt()).isEqualTo(1);
        assertThat(owner.get("displayName").asText()).isEqualTo("Ali Hassan");
        assertThat(owner.has("userId")).as("account ids are never exposed").isFalse();
        assertThat(group.get("yourMemberId").asText()).isEqualTo(owner.get("id").asText());
        assertThat(group.get("yourNetMinor").asLong()).isZero();

        String gid = group.get("id").asText();
        assertThat(jdbc.queryForObject("select user_id::text from members where id = ?::uuid", String.class,
                owner.get("id").asText())).isEqualTo(ali.userId().toString());
        assertThat(jdbc.queryForObject("select member_seq from expense_groups where id = ?::uuid", Integer.class, gid))
                .isEqualTo(1);
        JsonNode next = addMember(ali, gid, "Sara");
        assertThat(next.get("sortOrder").asInt()).isEqualTo(2);
        assertThat(next.get("isYou").asBoolean()).isFalse();
        assertThat(jdbc.queryForObject("select user_id from members where id = ?::uuid", String.class,
                next.get("id").asText())).isNull();
    }

    @Test
    void aLongProfileNameIsCutToTheMemberLimitOfFortyCharacters() throws Exception {
        Session u = userNamed("ع".repeat(60));
        JsonNode owner = createGroup(u, "Long name").get("members").get(0);
        assertThat(owner.get("displayName").asText().codePointCount(0, owner.get("displayName").asText().length()))
                .isEqualTo(40);
    }

    @Test
    void theOwnerMemberCanBeRenamedButNotDeleted() throws Exception {
        Session ali = newUser();
        JsonNode group = createGroup(ali, "Protected");
        String gid = group.get("id").asText();
        String me = group.get("members").get(0).get("id").asText();

        MvcResult rename = call(PATCH, GROUPS + "/" + gid + "/members/" + me, ali, Map.of("displayName", "Me, the organizer"));
        assertThat(status(rename)).isEqualTo(200);
        assertThat(body(rename).get("isYou").asBoolean()).isTrue();
        assertThat(body(rename).get("sortOrder").asInt()).isEqualTo(1);

        MvcResult delete = call(DELETE, GROUPS + "/" + gid + "/members/" + me, ali, null);
        assertThat(status(delete)).isEqualTo(409);
        assertThat(code(delete)).isEqualTo("OWNER_MEMBER_PROTECTED");
        JsonNode after = body(call(GET, GROUPS + "/" + gid, ali, null));
        assertThat(after.get("members")).hasSize(1);
        assertThat(after.get("members").get(0).get("displayName").asText()).isEqualTo("Me, the organizer");
    }

    @Test
    void anEmptyGroupCanStillBeDeletedWithItsOwnerMemberAndAGroupWithExpensesCannot() throws Exception {
        Session ali = newUser();
        String empty = createGroup(ali, "Empty").get("id").asText();
        assertThat(status(call(DELETE, GROUPS + "/" + empty, ali, null))).isEqualTo(204);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid", Long.class, empty)).isZero();

        String busy = createGroup(ali, "Busy").get("id").asText();
        String m = body(call(GET, GROUPS + "/" + busy, ali, null)).get("yourMemberId").asText();
        createExpense(ali, busy, equalBody("x", 100, null, m, 100L));
        MvcResult blocked = call(DELETE, GROUPS + "/" + busy, ali, null);
        assertThat(status(blocked)).isEqualTo(409);
        assertThat(code(blocked)).isEqualTo("GROUP_NOT_EMPTY");
    }

    @Test
    void theDatabaseAllowsAUserToBeOnlyOneMemberOfAGroupButAnyNumberOfGhosts() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Unique").get("id").asText();
        String insert = "insert into members (id, group_id, display_name, user_id, sort_order) "
                + "values (?::uuid, ?::uuid, ?, ?::uuid, ?)";

        assertThatThrownBy(() -> jdbc.update(insert, UUID.randomUUID().toString(), gid, "Second me",
                ali.userId().toString(), 50)).isInstanceOf(DataIntegrityViolationException.class);
        assertThat(jdbc.update(insert, UUID.randomUUID().toString(), gid, "Ghost 1", null, 51)).isEqualTo(1);
        assertThat(jdbc.update(insert, UUID.randomUUID().toString(), gid, "Ghost 2", null, 52)).isEqualTo(1);
    }

    // ---- yourNetMinor -----------------------------------------------------------------------------------------

    @Test
    void yourNetFollowsExpensesAndSettlementsInTheGroupDetailAndTheList() throws Exception {
        Session ali = newUser();
        JsonNode group = createGroup(ali, "V1 " + UUID.randomUUID());
        String gid = group.get("id").asText();
        String m = group.get("yourMemberId").asText();                 // the owner plays M of the spec V1
        String a = addMember(ali, gid, "A").get("id").asText();
        String s = addMember(ali, gid, "S").get("id").asText();

        String e1 = createExpense(ali, gid, exactBody("E1", 10000, List.of(a, 5000L, s, 5000L), m, 10000L)).get("id").asText();
        createExpense(ali, gid, exactBody("E2", 3000, List.of(a, 3000L), s, 3000L));
        assertThat(yourNetInDetail(ali, gid)).isEqualTo(10000L);                    // M +100.00
        assertThat(yourNetInList(ali, gid)).isEqualTo(10000L);

        call(POST, GROUPS + "/" + gid + "/settlements", ali,
                Map.of("fromMemberId", a, "toMemberId", m, "amountMinor", 8000L, "settledOn", "2026-10-20"),
                "Idempotency-Key", UUID.randomUUID().toString());
        assertThat(yourNetInDetail(ali, gid)).isEqualTo(2000L);                     // V2: M +20.00
        assertThat(yourNetInList(ali, gid)).isEqualTo(2000L);

        assertThat(status(call(DELETE, GROUPS + "/" + gid + "/expenses/" + e1, ali, null, "If-Match", "\"1\""))).isEqualTo(204);
        assertThat(yourNetInDetail(ali, gid)).isEqualTo(-8000L);                    // only E2 and the payment remain
    }

    private long yourNetInDetail(Session as, String gid) throws Exception {
        return body(call(GET, GROUPS + "/" + gid, as, null)).get("yourNetMinor").asLong();
    }

    private long yourNetInList(Session as, String gid) throws Exception {
        for (JsonNode item : body(call(GET, GROUPS + "?size=100", as, null)).get("items")) {
            if (item.get("id").asText().equals(gid)) {
                return item.get("yourNetMinor").asLong();
            }
        }
        throw new AssertionError("group not in the list");
    }

    @Test
    void aGroupWithoutAMemberLinkedToTheCallerIsNotReachableAnyMore() throws Exception {
        // B10 (A65, A68): access needs an ACTIVE linked member, so a pre-B9 group (no member linked to its creator, which
        // V12 refuses to migrate) is invisible, even to its creator. Before B10 this answered 200 with null yourNetMinor.
        Session ali = newUser();
        String gid = UUID.randomUUID().toString();
        jdbc.update("insert into expense_groups (id, owner_user_id, name, type, currency_code) "
                + "values (?::uuid, ?::uuid, 'Legacy', 'TRIP', 'EGP')", gid, ali.userId().toString());

        assertThat(status(call(GET, GROUPS + "/" + gid, ali, null))).isEqualTo(404);
        for (JsonNode item : body(call(GET, GROUPS + "?size=100", ali, null)).get("items")) {
            assertThat(item.get("id").asText()).isNotEqualTo(gid);
        }
    }

    @Test
    void theGroupListNeedsExactlyOneYourNetStatementWhetherItHoldsOneGroupOrThirty() throws Exception {
        Session ali = newUser();
        createGroup(ali, "First");
        clearInvocations(yourNet);
        assertThat(status(call(GET, GROUPS + "?size=100", ali, null))).isEqualTo(200);
        verify(yourNet, times(1)).forGroups(org.mockito.ArgumentMatchers.eq(ali.userId()),
                org.mockito.ArgumentMatchers.anyCollection());

        for (int i = 0; i < 29; i++) {
            createGroup(ali, "G" + i);
        }
        clearInvocations(yourNet);
        JsonNode page = body(call(GET, GROUPS + "?size=100", ali, null));
        assertThat(page.get("items")).hasSize(30);
        verify(yourNet, times(1)).forGroups(org.mockito.ArgumentMatchers.eq(ali.userId()),
                org.mockito.ArgumentMatchers.anyCollection());
        for (JsonNode item : page.get("items")) {
            assertThat(item.get("yourNetMinor").asLong()).isZero();
        }
    }

    @Test
    void nobodyCanSetTheLinkOrTheBalanceThroughTheApi() throws Exception {
        Session ali = newUser();
        Session eve = newUser();
        String gid = createGroup(ali, "No link").get("id").asText();
        MvcResult r = call(POST, GROUPS + "/" + gid + "/members", ali, Map.of("displayName", "Ghost", "isYou", true,
                "userId", eve.userId().toString(), "yourMemberId", UUID.randomUUID().toString(), "yourNetMinor", 999));

        assertThat(status(r)).isEqualTo(201);
        assertThat(body(r).get("isYou").asBoolean()).isFalse();
        assertThat(jdbc.queryForObject("select user_id from members where id = ?::uuid", String.class,
                body(r).get("id").asText())).isNull();
        assertThat(jdbc.queryForObject("select count(*) from members where user_id = ?::uuid", Long.class, eve.userId()))
                .isZero();
    }
}
