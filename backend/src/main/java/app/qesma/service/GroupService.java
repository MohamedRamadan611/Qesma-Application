package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.ExpenseRepository;
import app.qesma.persistence.GroupTotals;
import app.qesma.persistence.MemberRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Groups (spec 3.1, 8.2). All access is by owner id; ownership is decided only by {@link GroupAccessService}. */
@Service
public class GroupService {

    private static final Logger log = LoggerFactory.getLogger(GroupService.class);

    /** One row of the group list. */
    public record GroupSummary(UUID id, String name, String type, String currencyCode, long memberCount,
                               long totalSpentMinor, java.time.Instant lastExpenseAt) {
    }

    /** A group together with its members in {@code sort_order} and its expense totals (non-deleted expenses). */
    public record GroupDetail(ExpenseGroup group, List<Member> members, long totalSpentMinor,
                              java.time.Instant lastExpenseAt) {
    }

    private final GroupAccessService access;
    private final ExpenseGroupRepository groups;
    private final MemberRepository members;
    private final ExpenseRepository expenses;
    private final GroupUsageChecker usage;
    private final Clock clock;
    private final MeterRegistry metrics;

    public GroupService(GroupAccessService access, ExpenseGroupRepository groups, MemberRepository members,
                        ExpenseRepository expenses, ObjectProvider<GroupUsageChecker> usage, Clock clock,
                        MeterRegistry metrics) {
        this.access = access;
        this.groups = groups;
        this.members = members;
        this.expenses = expenses;
        this.usage = usage.getIfAvailable(() -> GroupUsageChecker.EMPTY);
        this.clock = clock;
        this.metrics = metrics;
    }

    @Transactional
    public ExpenseGroup create(UUID userId, String rawName, String rawType, String rawCurrency) {
        String name = FieldRules.name(rawName, FieldRules.GROUP_NAME_MAX, "name");
        String type = FieldRules.groupType(rawType);
        String currency = FieldRules.currency(rawCurrency);
        UUID id = UUID.randomUUID();
        groups.insertGroup(id, userId, name, type, currency);
        ExpenseGroup created = groups.findById(id)
                .orElseThrow(() -> new IllegalStateException("Group missing right after insert"));
        record("created", userId, id);
        return created;
    }

    @Transactional(readOnly = true)
    public Page<GroupSummary> list(UUID userId, int page, int size) {
        FieldRules.page(page, size);
        return groups.findSummaries(userId, PageRequest.of(page, size)).map(r ->
                new GroupSummary(r.id(), r.name(), r.type(), r.currencyCode(), r.memberCount(),
                        r.totalSpentMinor(), r.lastExpenseAt()));
    }

    @Transactional(readOnly = true)
    public GroupDetail get(UUID userId, UUID groupId) {
        ExpenseGroup group = access.requireOwned(userId, groupId);
        GroupTotals totals = expenses.totals(groupId);
        return new GroupDetail(group, members.findByGroupIdOrderBySortOrderAsc(groupId),
                totals.totalSpentMinor(), totals.lastExpenseAt());
    }

    /**
     * Edits name and/or type. {@code expectedVersion} comes from If-Match; a stale value is a
     * VERSION_CONFLICT, and Hibernate's version check catches a race between this check and the write.
     * Ownership (404) is decided before anything about versions or input is revealed.
     */
    @Transactional
    public ExpenseGroup update(UUID userId, UUID groupId, int expectedVersion, String rawName, String rawType) {
        ExpenseGroup group = access.requireOwned(userId, groupId);
        if (group.getVersion() != expectedVersion) {
            throw ApiException.conflict(ErrorCode.VERSION_CONFLICT, "The group was modified by someone else");
        }
        String name = rawName == null ? group.getName() : FieldRules.name(rawName, FieldRules.GROUP_NAME_MAX, "name");
        String type = rawType == null ? group.getType() : FieldRules.groupType(rawType);
        if (!name.equals(group.getName()) || !type.equals(group.getType())) {
            group.edit(name, type, clock.instant());
            group = groups.saveAndFlush(group); // flush now so the new version is known and a lost race throws here
            record("updated", userId, groupId);
        }
        return group;
    }

    /** Deletes a group that holds no ledger data, together with its (ledger-free) members. */
    @Transactional
    public void delete(UUID userId, UUID groupId) {
        ExpenseGroup group = access.requireOwnedForUpdate(userId, groupId);
        if (usage.hasLedgerData(groupId)) {
            throw ApiException.conflict(ErrorCode.GROUP_NOT_EMPTY, "The group has expenses or settlements");
        }
        members.deleteAllByGroup(groupId);
        groups.delete(group);
        record("deleted", userId, groupId);
    }

    private void record(String op, UUID userId, UUID groupId) {
        metrics.counter("qesma.groups", "op", op).increment();
        log.atInfo().addKeyValue("event", "group." + op).addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).log("group.{} userId={} groupId={}", op, userId, groupId);
    }
}
