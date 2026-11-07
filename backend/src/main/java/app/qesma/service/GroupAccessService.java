package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.MemberRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * THE authorization point for group-scoped data (spec 12). Phase 1 rule: a group is visible only to its
 * owner; everyone else gets the same 404 as for a group that does not exist (no 403, no oracle). Every
 * group-scoped service goes through here; Phase 2 replaces this class with role-based checks.
 *
 * <p>Methods require a surrounding transaction so a row lock taken here is held by the caller until commit.
 */
@Service
public class GroupAccessService {

    private final ExpenseGroupRepository groups;
    private final MemberRepository members;

    public GroupAccessService(ExpenseGroupRepository groups, MemberRepository members) {
        this.groups = groups;
        this.members = members;
    }

    /** The group, if {@code userId} owns it. */
    @Transactional(propagation = Propagation.MANDATORY)
    public ExpenseGroup requireOwned(UUID userId, UUID groupId) {
        return groups.findByIdAndOwnerUserId(groupId, userId).orElseThrow(ApiException::notFound);
    }

    /** Same check, additionally locking the group row until the surrounding transaction ends. */
    @Transactional(propagation = Propagation.MANDATORY)
    public ExpenseGroup requireOwnedForUpdate(UUID userId, UUID groupId) {
        return groups.findOwnedForUpdate(groupId, userId).orElseThrow(ApiException::notFound);
    }

    /** All members of a group the caller already proved they own, in {@code sort_order}. */
    @Transactional(propagation = Propagation.MANDATORY)
    public java.util.List<Member> listMembers(ExpenseGroup ownedGroup) {
        return members.findByGroupIdOrderBySortOrderAsc(ownedGroup.getId());
    }

    /** A member, addressable only through the group it belongs to (a member id of another group is a 404). */
    @Transactional(propagation = Propagation.MANDATORY)
    public Member requireMember(ExpenseGroup ownedGroup, UUID memberId) {
        return members.findByIdAndGroupId(memberId, ownedGroup.getId()).orElseThrow(ApiException::notFound);
    }
}
