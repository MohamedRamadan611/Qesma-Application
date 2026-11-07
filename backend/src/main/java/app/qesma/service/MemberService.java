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
        ExpenseGroup group = access.requireOwnedForUpdate(userId, groupId);
        String name = FieldRules.name(rawName, FieldRules.MEMBER_NAME_MAX, "displayName");
        requireNameFree(groupId, name, NO_MEMBER);

        int sortOrder = group.getMemberSeq() + 1; // read under the row lock, so no one else can take it
        groups.setMemberSeq(groupId, sortOrder);  // the counter only moves forward: numbers are never reused
        Member member = members.save(new Member(UUID.randomUUID(), groupId, name, sortOrder, clock.instant()));
        record("created", userId, groupId, member.getId());
        return member;
    }

    @Transactional
    public Member rename(UUID userId, UUID groupId, UUID memberId, String rawName) {
        ExpenseGroup group = access.requireOwnedForUpdate(userId, groupId);
        Member member = access.requireMember(group, memberId);
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
        ExpenseGroup group = access.requireOwnedForUpdate(userId, groupId);
        Member member = access.requireMember(group, memberId);
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
