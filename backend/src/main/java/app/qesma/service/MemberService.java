package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.MemberRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ghost members of a group (spec 7.10). Every mutation first locks the group row, which serializes:
 * sort_order assignment, case-insensitive duplicate checks, and delete-versus-add races. Future ledger code
 * (B4/B7) should take the same lock before writing rows that reference members.
 */
@Service
public class MemberService {

    private static final Logger log = LoggerFactory.getLogger(MemberService.class);
    private static final UUID NO_MEMBER = new UUID(0L, 0L);

    private final GroupAccessService access;
    private final ExpenseGroupRepository groups;
    private final MemberRepository members;
    private final MemberUsageChecker usage;
    private final Clock clock;
    private final MeterRegistry metrics;

    public MemberService(GroupAccessService access, ExpenseGroupRepository groups, MemberRepository members,
                         ObjectProvider<MemberUsageChecker> usage, Clock clock, MeterRegistry metrics) {
        this.access = access;
        this.groups = groups;
        this.members = members;
        this.usage = usage.getIfAvailable(() -> MemberUsageChecker.UNUSED);
        this.clock = clock;
        this.metrics = metrics;
    }

    @Transactional
    public Member add(UUID userId, UUID groupId, String rawName) {
        ExpenseGroup group = access.requireForUpdate(userId, groupId, Permission.MANAGE_MEMBERS).group();
        String name = FieldRules.name(rawName, FieldRules.MEMBER_NAME_MAX, "displayName");
        requireNameFree(groupId, name, NO_MEMBER);

        int sortOrder = group.getMemberSeq() + 1; // read under the row lock, so no one else can take it
        groups.setMemberSeq(groupId, sortOrder);  // the counter only moves forward: numbers are never reused
        Member member = members.save(new Member(UUID.randomUUID(), groupId, name, sortOrder, clock.instant()));
        record("created", userId, groupId, member.getId());
        return member;
    }

    /**
     * Creates the member of a person who joined through an invitation (B11): linked to their account, role MEMBER,
     * next {@code sort_order}. The caller is not a member yet; the invite (already locked by the caller) is the
     * capability. Takes the group row lock, so the counter and the duplicate-name check cannot race.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public Member createJoined(UUID groupId, String rawName, UUID accountId, java.time.Instant now) {
        ExpenseGroup group = groups.findByIdForUpdate(groupId).orElseThrow(ApiException::notFound);
        String name = FieldRules.name(rawName, FieldRules.MEMBER_NAME_MAX, "newMemberName");
        requireNameFree(groupId, name, NO_MEMBER);
        int sortOrder = group.getMemberSeq() + 1;
        groups.setMemberSeq(groupId, sortOrder);
        return members.saveAndFlush(Member.forJoined(UUID.randomUUID(), groupId, name, sortOrder, accountId, now));
    }

    /**
     * Links an account to an existing ghost member (B11). The conditional update makes it atomic: a member that is
     * not in this group is 422, one somebody else claimed first is 409. The member keeps all its history.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public Member claimGhost(UUID groupId, UUID memberId, UUID accountId, java.time.Instant now) {
        groups.findByIdForUpdate(groupId).orElseThrow(ApiException::notFound);
        if (members.findByIdAndGroupId(memberId, groupId).isEmpty()) {
            throw new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                    "A referenced member is not part of this group");
        }
        if (members.claim(memberId, groupId, accountId, now) == 0) {
            throw ApiException.conflict(ErrorCode.MEMBER_ALREADY_CLAIMED, "This member was already claimed");
        }
        return members.findById(memberId).orElseThrow(ApiException::notFound);
    }

    /** Is this account already an ACTIVE member of the group? */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public boolean isActiveMember(UUID groupId, UUID accountId) {
        return members.hasActiveLink(groupId, accountId);
    }

    /** The name a joiner would get is free in the group (case-insensitive), or 409 {@code DUPLICATE_MEMBER_NAME}. */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public String requireFreeName(UUID groupId, String rawName) {
        String name = FieldRules.name(rawName, FieldRules.MEMBER_NAME_MAX, "newMemberName");
        requireNameFree(groupId, name, NO_MEMBER);
        return name;
    }

    /** The member exists in the group and nobody has claimed it yet, or 422 / 409. */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public void requireUnclaimed(UUID groupId, UUID memberId) {
        Member m = members.findByIdAndGroupId(memberId, groupId).orElseThrow(() -> new ApiException(
                ErrorCode.MEMBER_NOT_IN_GROUP, org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                "A referenced member is not part of this group"));
        if (m.getUserId() != null) {
            throw ApiException.conflict(ErrorCode.MEMBER_ALREADY_CLAIMED, "This member was already claimed");
        }
    }

    /**
     * Detaches the account from a member (Owner/Admin). The member, its history and its balance stay; the person loses
     * access at once and the member becomes a claimable ghost again. The owner's member is protected, and only the
     * owner may unlink an admin. Unlinking a member without an account does nothing.
     */
    @Transactional
    public void unlink(UUID userId, UUID groupId, UUID memberId) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.UNLINK_MEMBER);
        Member member = access.requireMemberInGroup(ctx, memberId);
        if (Member.ROLE_OWNER.equals(member.getRole())) {
            throw ApiException.conflict(ErrorCode.OWNER_MEMBER_PROTECTED, "The owner's member cannot be unlinked");
        }
        if (member.getUserId() == null) {
            return;
        }
        if (Member.ROLE_ADMIN.equals(member.getRole()) && ctx.role() != Role.OWNER) {
            throw ApiException.forbidden();
        }
        members.unlink(memberId, groupId);
        record("unlinked", userId, groupId, memberId);
    }

    @Transactional
    public Member rename(UUID userId, UUID groupId, UUID memberId, String rawName) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.MANAGE_MEMBERS);
        Member member = access.requireMemberInGroup(ctx, memberId);
        String name = FieldRules.name(rawName, FieldRules.MEMBER_NAME_MAX, "displayName");
        requireNameFree(groupId, name, memberId);
        if (!name.equals(member.getDisplayName())) {
            member.rename(name);
            record("renamed", userId, groupId, memberId);
        }
        return member;
    }

    @Transactional
    public void delete(UUID userId, UUID groupId, UUID memberId) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.MANAGE_MEMBERS);
        Member member = access.requireMemberInGroup(ctx, memberId);
        if (member.getUserId() != null) {
            throw ApiException.conflict(ErrorCode.OWNER_MEMBER_PROTECTED,
                    "The group owner's own member cannot be removed (it can be renamed)");
        }
        if (usage.isUsed(groupId, memberId)) {
            throw ApiException.conflict(ErrorCode.MEMBER_HAS_TRANSACTIONS,
                    "The member appears in expenses or settlements and cannot be removed");
        }
        members.delete(member);
        record("deleted", userId, groupId, memberId);
    }

    private void requireNameFree(UUID groupId, String name, UUID excludeMemberId) {
        if (members.nameTaken(groupId, name, excludeMemberId)) {
            throw ApiException.conflict(ErrorCode.DUPLICATE_MEMBER_NAME,
                    "A member with this name already exists in the group");
        }
    }

    private void record(String op, UUID userId, UUID groupId, UUID memberId) {
        metrics.counter("qesma.members", "op", op).increment();
        log.atInfo().addKeyValue("event", "member." + op).addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("memberId", memberId)
                .log("member.{} userId={} groupId={} memberId={}", op, userId, groupId, memberId);
    }
}
