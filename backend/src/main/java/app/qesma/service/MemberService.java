package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.MemberRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
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
    private final GroupEventRecorder events;

    public MemberService(GroupAccessService access, ExpenseGroupRepository groups, MemberRepository members,
                         ObjectProvider<MemberUsageChecker> usage, Clock clock, MeterRegistry metrics,
                         GroupEventRecorder events) {
        this.events = events;
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
        access.requireMayManage(ctx, userId, member, Permission.UNLINK_MEMBER);   // only the owner may unlink an admin
        members.unlink(memberId, groupId);
        record("unlinked", userId, groupId, memberId);
        events.record(groupId, ctx.me().getId(), EventType.MEMBER_UNLINKED, EventPayload.member(memberId),
                GroupEventRecorder.Recipients.none());           // feed only: the account has no access any more
    }

    /** The fields of {@code PATCH /members/{mid}}; null means "not sent". Nothing else can be set (B12, A80). */
    public record MemberPatch(String displayName, String role, String status) {
    }

    /**
     * Changes a member's name, role and/or status (B12). Every present field is authorized on its own (name:
     * MANAGE_MEMBERS, role: CHANGE_ROLE, status: MANAGE_MEMBER_STATUS), all checks run before the first write, so a
     * rejected field means nothing is applied. Precedence: 404, 403, then 409/422.
     */
    @Transactional
    public Member update(UUID userId, UUID groupId, UUID memberId, MemberPatch patch) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.READ_GROUP);
        Member member = access.requireMemberInGroup(ctx, memberId);
        if (patch == null || patch.displayName() == null && patch.role() == null && patch.status() == null) {
            throw ApiException.validation("Send at least one of displayName, role or status");
        }
        if (patch.displayName() != null) {
            access.requireAlso(ctx, userId, Permission.MANAGE_MEMBERS);
        }
        if (patch.role() != null) {
            access.requireAlso(ctx, userId, Permission.CHANGE_ROLE);
        }
        if (patch.status() != null) {
            access.requireAlso(ctx, userId, Permission.MANAGE_MEMBER_STATUS);
        }

        String newRole = patch.role() == null ? null : parseRole(patch.role());
        String newStatus = patch.status() == null ? null : parseStatus(patch.status());
        if (newRole != null || newStatus != null) {
            if (!member.getId().equals(ctx.me().getId())) {                  // the hierarchy rule is about OTHER members
                access.requireMayManage(ctx, userId, member, newRole != null ? Permission.CHANGE_ROLE
                        : Permission.MANAGE_MEMBER_STATUS);
            }
            if (Member.ROLE_OWNER.equals(member.getRole())) {
                throw ApiException.conflict(ErrorCode.OWNER_MEMBER_PROTECTED,
                        "The owner's role and status cannot be changed (use transfer-ownership)");
            }
            if (member.getUserId() == null) {
                throw ApiException.validation("A member without an account has no role or status; rename or delete it");
            }
            if (Member.STATUS_LEFT.equals(newStatus) && member.getId().equals(ctx.me().getId())) {
                throw ApiException.validation("Use POST /leave to leave a group");
            }
            String resulting = newStatus != null ? newStatus : member.getStatus();
            if (newRole != null && !Member.STATUS_ACTIVE.equals(resulting)) {
                throw ApiException.validation("Only an active member can get a role");
            }
        }
        String name = null;
        if (patch.displayName() != null) {
            name = FieldRules.name(patch.displayName(), FieldRules.MEMBER_NAME_MAX, "displayName");
            requireNameFree(groupId, name, memberId);
        }

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        if (name != null && !name.equals(member.getDisplayName())) {
            member.rename(name);
            record("renamed", userId, groupId, memberId);
        }
        UUID actor = ctx.me().getId();
        if (Member.STATUS_LEFT.equals(newStatus) && !Member.STATUS_LEFT.equals(member.getStatus())) {
            Role previous = Role.valueOf(member.getRole());
            member.markLeft(now);
            record("removed", userId, groupId, memberId);
            events.record(groupId, actor, EventType.MEMBER_LEFT,         // the removed member has no access: not notified
                    EventPayload.member(memberId).withRoles(null, previous), GroupEventRecorder.Recipients.managers());
        } else if (Member.STATUS_ACTIVE.equals(newStatus) && Member.STATUS_LEFT.equals(member.getStatus())) {
            member.reactivate();
            record("reactivated", userId, groupId, memberId);
            events.record(groupId, actor, EventType.MEMBER_REACTIVATED, EventPayload.member(memberId),
                    GroupEventRecorder.Recipients.members(java.util.Set.of(memberId)));
        }
        if (newRole != null && !newRole.equals(member.getRole())) {
            Role previous = Role.valueOf(member.getRole());
            member.changeRole(newRole);
            record("role_changed", userId, groupId, memberId);
            events.record(groupId, actor, EventType.ROLE_CHANGED,
                    EventPayload.member(memberId).withRoles(Role.valueOf(newRole), previous),
                    GroupEventRecorder.Recipients.members(java.util.Set.of(memberId)));
        }
        return member;
    }

    /** The caller leaves the group. The row, history and balance stay; the Owner must transfer ownership first. */
    @Transactional
    public void leave(UUID userId, UUID groupId) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.LEAVE_GROUP);
        if (ctx.role() == Role.OWNER) {
            throw ApiException.conflict(ErrorCode.OWNER_MUST_TRANSFER, "Transfer ownership before leaving the group");
        }
        ctx.me().markLeft(clock.instant().truncatedTo(ChronoUnit.MICROS));
        record("left", userId, groupId, ctx.me().getId());
        events.record(groupId, ctx.me().getId(), EventType.MEMBER_LEFT,
                EventPayload.member(ctx.me().getId()).withRoles(null, ctx.role()),
                GroupEventRecorder.Recipients.managers());
    }

    /**
     * Makes another ACTIVE linked member the owner and the old owner an ADMIN, in one transaction. The group row lock
     * serializes parallel transfers (the second caller is an Admin by then: 403). The old owner is demoted first so
     * the one-OWNER unique index is never violated between the two statements.
     */
    @Transactional
    public void transferOwnership(UUID userId, UUID groupId, UUID toMemberId) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.TRANSFER_OWNERSHIP);
        if (toMemberId == null) {
            throw ApiException.validation("toMemberId is required");
        }
        Member target = access.requireMemberInGroup(ctx, toMemberId);
        if (target.getId().equals(ctx.me().getId())) {
            throw ApiException.validation("You already own this group");
        }
        if (Member.STATUS_LEFT.equals(target.getStatus())) {
            throw inactive();
        }
        if (target.getUserId() == null) {
            throw ApiException.validation("Ownership can only go to a member with an account");
        }
        UUID oldOwner = ctx.me().getId();
        Role previous = Role.valueOf(target.getRole());
        if (members.demoteOwner(oldOwner, groupId) != 1 || members.promoteOwner(toMemberId, groupId) != 1) {
            throw ApiException.conflict(ErrorCode.VERSION_CONFLICT, "The members changed; try again"); // rolls back
        }
        record("ownership_transferred", userId, groupId, toMemberId);
        events.record(groupId, oldOwner, EventType.OWNERSHIP_TRANSFERRED,
                EventPayload.member(toMemberId).withRoles(null, previous),
                GroupEventRecorder.Recipients.members(java.util.Set.of(toMemberId)));
    }

    static ApiException inactive() {
        return new ApiException(ErrorCode.MEMBER_INACTIVE, org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                "A member who left the group cannot be used in new records");
    }

    private static String parseRole(String raw) {
        if (Member.ROLE_ADMIN.equals(raw) || Member.ROLE_MEMBER.equals(raw)) {
            return raw;
        }
        throw ApiException.validation(Member.ROLE_OWNER.equals(raw)
                ? "Ownership moves only through transfer-ownership" : "role must be ADMIN or MEMBER");
    }

    private static String parseStatus(String raw) {
        if (Member.STATUS_ACTIVE.equals(raw) || Member.STATUS_LEFT.equals(raw)) {
            return raw;
        }
        throw ApiException.validation("status must be ACTIVE or LEFT");
    }

    /**
     * A person who left comes back through a new invite: their own LEFT member is reactivated (role MEMBER), no second
     * row is created. Empty when the account has no LEFT member in the group.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public java.util.Optional<Member> reactivateIfLeft(UUID groupId, UUID accountId, Instant now) {
        groups.findByIdForUpdate(groupId).orElseThrow(ApiException::notFound);
        java.util.Optional<Member> left = members.findLeftLink(groupId, accountId);
        left.ifPresent(m -> {
            m.rejoin(now);
            record("rejoined", accountId, groupId, m.getId());
        });
        return left;
    }

    /** The account's own LEFT member in the group, if any. */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public java.util.Optional<Member> findLeft(UUID groupId, UUID accountId) {
        return members.findLeftLink(groupId, accountId);
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
