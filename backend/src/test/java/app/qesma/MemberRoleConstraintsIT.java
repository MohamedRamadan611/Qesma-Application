package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/** The role rules live in the database (V12), so a bug in the application cannot create an impossible member. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class MemberRoleConstraintsIT extends AbstractApiIT {

    private String newGroup(Session owner) throws Exception {
        return createGroup(owner, "Rules " + UUID.randomUUID()).get("id").asText();
    }

    @Test
    void creatingAGroupGivesItExactlyOneOwnerWhoIsLinkedAndActive() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        assertThat(jdbc.queryForObject("select count(*) from members where group_id = ?::uuid and role = 'OWNER' "
                + "and user_id = ?::uuid and status = 'ACTIVE'", Long.class, gid, owner.userId().toString())).isEqualTo(1L);
        assertThat(jdbc.queryForObject("select joined_at is not null from members where group_id = ?::uuid", Boolean.class, gid)).isTrue();
    }

    @Test
    void aSecondOwnerIsRejectedByTheDatabase() throws Exception {
        Session owner = newUser();
        Session other = newUser();
        String gid = newGroup(owner);
        assertThatThrownBy(() -> linkUser(gid, other, "OWNER", "ACTIVE", "Second")).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void anOwnerWithoutAnAccountOrWhoHasLeftIsRejected() throws Exception {
        Session owner = newUser();
        String gid = newGroup(owner);
        assertThatThrownBy(() -> jdbc.update("update members set user_id = null where group_id = ?::uuid and role = 'OWNER'", gid))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update members set status = 'LEFT', left_at = now() where group_id = ?::uuid "
                + "and role = 'OWNER'", gid)).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void leftAtGoesTogetherWithStatusLeft() throws Exception {
        Session owner = newUser();
        Session other = newUser();
        String gid = newGroup(owner);
        String mid = linkUser(gid, other, "MEMBER", "ACTIVE", "Guest");
        assertThatThrownBy(() -> jdbc.update("update members set status = 'LEFT' where id = ?::uuid", mid))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update members set left_at = now() where id = ?::uuid", mid))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThatThrownBy(() -> jdbc.update("update members set role = 'BOSS' where id = ?::uuid", mid))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
