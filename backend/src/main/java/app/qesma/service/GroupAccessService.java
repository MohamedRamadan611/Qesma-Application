package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.MemberRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * THE authorization point for group-scoped data (spec 12, Phase 2 PHASE2_SPEC section 2, Decisions A65-A67).
 *
 * <ul>
 *   <li>A caller reaches a group only through an ACTIVE member linked to their account. Everyone else (strangers, LEFT
 *       members, unknown ids) gets the same 404 as for a group that does not exist: no oracle, and no row lock is taken
 *       for them.</li>
 *   <li>A member whose role lacks the permission gets 403 {@code FORBIDDEN}.</li>
 *   <li>Precedence: 401 (security filter), 404 (not a member), 403 (no permission), then validation and conflicts.</li>
 * </ul>
 *
 * <p>Every group-scoped service goes through here; controllers and services never compare roles themselves. Methods
 * require a surrounding transaction so a row lock taken here is held by the caller until commit.
 */
@Service
public class GroupAccessService {

    private static final Logger log = LoggerFactory.getLogger(GroupAccessService.class);

    private final ExpenseGroupRepository groups;
    private final MemberRepository members;
    private final MeterRegistry metrics;

    public GroupAccessService(ExpenseGroupRepository groups, MemberRepository members, MeterRegistry metrics) {
        this.groups = groups;
        this.members = members;
        this.metrics = metrics;
    }

    /** Any ACTIVE member of the group. */
    @Transactional(propagation = Propagation.MANDATORY)
    public GroupContext requireMember(UUID userId, UUID groupId) {
        return require(userId, groupId, Permission.READ_GROUP);
    }

    /** An ACTIVE member whose role has {@code permission}. */
    @Transactional(propagation = Propagation.MANDATORY)
    public GroupContext require(UUID userId, UUID groupId, Permission permission) {
        ExpenseGroup group = groups.findReachable(groupId, userId).orElseThrow(() -> denied(userId, groupId, "not_member", permission));
        return context(userId, group, permission);
    }

    /** Same check, additionally locking the group row until the surrounding transaction ends. */
    @Transactional(propagation = Propagation.MANDATORY)
    public GroupContext requireForUpdate(UUID userId, UUID groupId, Permission permission) {
        ExpenseGroup group = groups.findReachableForUpdate(groupId, userId)
                .orElseThrow(() -> denied(userId, groupId, "not_member", permission));
        return context(userId, group, permission);
    }

    private GroupContext context(UUID userId, ExpenseGroup group, Permission permission) {
        Member me = members.findActiveLink(group.getId(), userId)
                .orElseThrow(() -> denied(userId, group.getId(), "not_member", permission));
        Role role = Role.valueOf(me.getRole());
        if (!role.allows(permission)) {
            throw denied(userId, group.getId(), "forbidden", permission, true);
        }
        return new GroupContext(group, me, role);
    }

    /** All members of a group the caller may reach, in {@code sort_order}. */
    @Transactional(propagation = Propagation.MANDATORY)
    public List<Member> listMembers(GroupContext ctx) {
        return members.findByGroupIdOrderBySortOrderAsc(ctx.groupId());
    }

    /** A member, addressable only through the group it belongs to (a member id of another group is a 404). */
    @Transactional(propagation = Propagation.MANDATORY)
    public Member requireMemberInGroup(GroupContext ctx, UUID memberId) {
        return members.findByIdAndGroupId(memberId, ctx.groupId()).orElseThrow(ApiException::notFound);
    }

    private ApiException denied(UUID userId, UUID groupId, String reason, Permission permission) {
        return denied(userId, groupId, reason, permission, false);
    }

    private ApiException denied(UUID userId, UUID groupId, String reason, Permission permission, boolean forbidden) {
        metrics.counter("qesma.authz.denied", "reason", reason, "permission", permission.name()).increment();
        log.atInfo().addKeyValue("event", "authz.denied").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("permission", permission)
                .log("authz.denied reason={} userId={} groupId={} permission={}", reason, userId, groupId, permission);
        return forbidden ? ApiException.forbidden() : ApiException.notFound();
    }
}
