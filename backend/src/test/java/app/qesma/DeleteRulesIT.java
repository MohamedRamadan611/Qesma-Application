package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;

import app.qesma.service.GroupUsageChecker;
import app.qesma.service.MemberUsageChecker;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Delete rules that depend on tables created later (expenses, settlements). The checkers are the extension
 * points B4/B7 will implement; here they are stubbed to prove the rules are wired in.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"test", "fake-auth"})
class DeleteRulesIT extends AbstractApiIT {

    @MockitoBean MemberUsageChecker memberUsage;
    @MockitoBean GroupUsageChecker groupUsage;

    @Test
    void memberInUseCannotBeDeletedButAnUnusedOneCan() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Rules").get("id").asText();
        String used = addMember(ali, gid, "Used").get("id").asText();
        String free = addMember(ali, gid, "Free").get("id").asText();
        when(memberUsage.isUsed(any(), any())).thenReturn(false);
        when(memberUsage.isUsed(java.util.UUID.fromString(gid), java.util.UUID.fromString(used))).thenReturn(true);

        MvcResult blocked = call(DELETE, "/api/v1/groups/" + gid + "/members/" + used, ali, null);
        assertThat(status(blocked)).isEqualTo(409);
        assertThat(code(blocked)).isEqualTo("MEMBER_HAS_TRANSACTIONS");
        assertThat(status(call(DELETE, "/api/v1/groups/" + gid + "/members/" + free, ali, null))).isEqualTo(204);

        assertThat(body(call(GET, "/api/v1/groups/" + gid, ali, null)).get("members")).hasSize(1);
    }

    @Test
    void groupWithLedgerDataCannotBeDeletedAndKeepsItsMembers() throws Exception {
        Session ali = newUser();
        String gid = createGroup(ali, "Busy").get("id").asText();
        addMember(ali, gid, "Someone");
        when(groupUsage.hasLedgerData(java.util.UUID.fromString(gid))).thenReturn(true);

        MvcResult blocked = call(DELETE, "/api/v1/groups/" + gid, ali, null);
        assertThat(status(blocked)).isEqualTo(409);
        assertThat(code(blocked)).isEqualTo("GROUP_NOT_EMPTY");

        JsonNodeHolder after = new JsonNodeHolder(body(call(GET, "/api/v1/groups/" + gid, ali, null)));
        assertThat(after.membersCount()).isEqualTo(1);

        when(groupUsage.hasLedgerData(java.util.UUID.fromString(gid))).thenReturn(false);
        assertThat(status(call(DELETE, "/api/v1/groups/" + gid, ali, null))).isEqualTo(204);
    }

    private record JsonNodeHolder(com.fasterxml.jackson.databind.JsonNode node) {
        int membersCount() {
            return node.get("members").size();
        }
    }
}
