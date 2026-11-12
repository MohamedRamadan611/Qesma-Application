package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;

/** V13: the shape of an invite and of a join request is enforced by the database, not only by the services. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class InviteConstraintsIT extends AbstractApiIT {

    private record Ids(String gid, String ownerMember, String userId) {
    }

    private Ids group() throws Exception {
        Session owner = newUser();
        var created = createGroup(owner, "Constraints " + UUID.randomUUID());
        return new Ids(created.get("id").asText(), created.get("yourMemberId").asText(), owner.userId().toString());
    }

    private void insertInvite(Ids ids, String code, String expires, Integer maxUses, int useCount) {
        jdbc.update("insert into group_invites (id, group_id, code, created_by_member_id, created_at, expires_at, max_uses, "
                + "use_count, requires_approval) values (?, ?::uuid, ?, ?::uuid, now(), " + expires + ", ?, ?, false)",
                UUID.randomUUID(), ids.gid(), code, ids.ownerMember(), maxUses, useCount);
    }

    @Test
    void aWellFormedInviteIsAccepted() throws Exception {
        Ids ids = group();
        insertInvite(ids, "ABCD2345", "now() + interval '1 day'", 3, 3);
        assertThat(jdbc.queryForObject("select count(*) from group_invites where code = 'ABCD2345'", Long.class)).isEqualTo(1L);
    }

    @Test
    void badCodesExpiryAndCountersAreRejected() throws Exception {
        Ids ids = group();
        for (String bad : new String[] {"abcd2345", "ABCD234", "ABCD23456", "ABCD-234", "ABCDO345", "ABCD1345"}) {
            assertThatThrownBy(() -> insertInvite(ids, bad, "now() + interval '1 day'", null, 0))
                    .as("code " + bad).isInstanceOf(DataIntegrityViolationException.class);
        }
        assertThatThrownBy(() -> insertInvite(ids, "EFGH2345", "now() - interval '1 day'", null, 0))
                .as("expiry before creation").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertInvite(ids, "EFGH2346", "now() + interval '1 day'", 0, 0))
                .as("max_uses 0").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertInvite(ids, "EFGH2347", "now() + interval '1 day'", 1001, 0))
                .as("max_uses over the limit").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertInvite(ids, "EFGH2348", "now() + interval '1 day'", 2, 3))
                .as("use_count above max_uses").isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertInvite(ids, "EFGH2349", "now() + interval '1 day'", null, -1))
                .as("negative use_count").isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void aCodeIsUnique() throws Exception {
        Ids ids = group();
        insertInvite(ids, "JKLM2345", "now() + interval '1 day'", null, 0);
        assertThatThrownBy(() -> insertInvite(ids, "JKLM2345", "now() + interval '1 day'", null, 0))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private UUID inviteWithRequest(Ids ids, String code) {
        insertInvite(ids, code, "now() + interval '1 day'", null, 0);
        return jdbc.queryForObject("select id from group_invites where code = ?", UUID.class, code);
    }

    private void insertRequest(Ids ids, UUID invite, String claim, String name, String status, boolean decided) {
        jdbc.update("insert into join_requests (id, invite_id, group_id, user_id, claim_member_id, new_member_name, status, "
                + "decided_at) values (?, ?, ?::uuid, ?::uuid, ?::uuid, ?, ?, " + (decided ? "now()" : "null") + ")",
                UUID.randomUUID(), invite, ids.gid(), ids.userId(), claim, name, status);
    }

    @Test
    void aJoinRequestNamesExactlyOneTargetHasAKnownStatusAndOnlyOneIsOpenPerUser() throws Exception {
        Ids ids = group();
        UUID invite = inviteWithRequest(ids, "NPQR2345");
        assertThatThrownBy(() -> insertRequest(ids, invite, null, null, "PENDING", false)).as("neither target")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertRequest(ids, invite, ids.ownerMember(), "Both", "PENDING", false)).as("both targets")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertRequest(ids, invite, null, "  ", "PENDING", false)).as("blank name")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertRequest(ids, invite, null, "Name", "MAYBE", false)).as("unknown status")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertRequest(ids, invite, null, "Name", "APPROVED", false)).as("decided without a time")
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> insertRequest(ids, invite, null, "Name", "PENDING", true)).as("pending with a decision time")
                .isInstanceOf(DataIntegrityViolationException.class);

        insertRequest(ids, invite, null, "Open One", "PENDING", false);
        assertThatThrownBy(() -> insertRequest(ids, invite, null, "Open Two", "PENDING", false))
                .as("a second open request of the same user for the same invite").isInstanceOf(DataIntegrityViolationException.class);
        insertRequest(ids, invite, null, "Decided", "REJECTED", true);                        // history may repeat
        assertThat(jdbc.queryForObject("select count(*) from join_requests where invite_id = ?", Long.class, invite)).isEqualTo(2L);
    }
}
