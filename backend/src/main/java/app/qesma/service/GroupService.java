package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.ExpenseRepository;
import app.qesma.persistence.GroupSummaryRow;
import app.qesma.persistence.GroupTotals;
import app.qesma.persistence.MemberRepository;
import app.qesma.persistence.UserRepository;
import app.qesma.persistence.YourNetQuery;
import app.qesma.domain.User;
import app.qesma.engine.BalanceCalculator;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Groups (spec 3.1, 8.2). Access and roles are decided only by {@link GroupAccessService}. */
@Service
public class GroupService {

    private static final Logger log = LoggerFactory.getLogger(GroupService.class);

    /** One row of the group list. */
    /** {@code yourNetMinor}: what the caller is owed (positive) or owes (negative); null when they have no member in the group. */
    public record GroupSummary(UUID id, String name, String type, String currencyCode, long memberCount,
                               long totalSpentMinor, java.time.Instant lastExpenseAt, Long yourNetMinor,
                               String yourRole) {
    }

    /**
     * A group together with its members in {@code sort_order} and its expense totals (non-deleted expenses);
     * {@code yourRole} is the caller's role (OWNER, ADMIN or MEMBER).
     */
    public record GroupDetail(ExpenseGroup group, List<Member> members, long totalSpentMinor,
                              java.time.Instant lastExpenseAt, UUID yourMemberId, Long yourNetMinor, String yourRole) {
    }

    private final GroupAccessService access;
    private final ExpenseGroupRepository groups;
    private final MemberRepository members;
    private final ExpenseRepository expenses;
    private final UserRepository users;
    private final YourNetQuery yourNet;
    private final GroupUsageChecker usage;
    private final Clock clock;
    private final MeterRegistry metrics;

    public GroupService(GroupAccessService access, ExpenseGroupRepository groups, MemberRepository members,
                        ExpenseRepository expenses, UserRepository users, YourNetQuery yourNet,
                        ObjectProvider<GroupUsageChecker> usage, Clock clock, MeterRegistry metrics) {
        this.access = access;
        this.groups = groups;
        this.members = members;
        this.expenses = expenses;
        this.users = users;
        this.yourNet = yourNet;
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
        groups.setMemberSeq(id, 1);                              // the owner is member #1 (Decision A53)
        members.save(Member.forOwner(UUID.randomUUID(), id, ownerMemberName(userId), userId, clock.instant()));
        ExpenseGroup created = groups.findById(id)
                .orElseThrow(() -> new IllegalStateException("Group missing right after insert"));
        record("created", userId, id);
        return created;
    }

    @Transactional(readOnly = true)
    public Page<GroupSummary> list(UUID userId, int page, int size) {
        FieldRules.page(page, size);
        Page<GroupSummaryRow> found = groups.findSummaries(userId, PageRequest.of(page, size));
        // one statement for the whole page: the caller's own balance in each group
        Map<UUID, YourNetQuery.YourTotals> mine = yourNet.forGroups(userId,
                found.getContent().stream().map(GroupSummaryRow::id).toList());
        return found.map(r -> new GroupSummary(r.id(), r.name(), r.type(), r.currencyCode(), r.memberCount(),
                r.totalSpentMinor(), r.lastExpenseAt(), netOf(mine.get(r.id())), r.role()));
    }

    @Transactional(readOnly = true)
    public GroupDetail get(UUID userId, UUID groupId) {
        GroupContext ctx = access.requireMember(userId, groupId);
        GroupTotals totals = expenses.totals(groupId);
        YourNetQuery.YourTotals mine = yourNet.forGroups(userId, List.of(groupId)).get(groupId);
        return new GroupDetail(ctx.group(), access.listMembers(ctx), totals.totalSpentMinor(),
                totals.lastExpenseAt(), ctx.me().getId(), netOf(mine), ctx.role().name());
    }

    /**
     * Edits name and/or type. {@code expectedVersion} comes from If-Match; a stale value is a
     * VERSION_CONFLICT, and Hibernate's version check catches a race between this check and the write.
     * Ownership (404) is decided before anything about versions or input is revealed.
     */
    @Transactional
    public ExpenseGroup update(UUID userId, UUID groupId, int expectedVersion, String rawName, String rawType) {
        ExpenseGroup group = access.require(userId, groupId, Permission.EDIT_GROUP).group();
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
        ExpenseGroup group = access.requireForUpdate(userId, groupId, Permission.DELETE_GROUP).group();
        if (usage.hasLedgerData(groupId)) {
            throw ApiException.conflict(ErrorCode.GROUP_NOT_EMPTY, "The group has expenses or settlements");
        }
        if (members.hasLinkedNonOwner(groupId)) {                // B12 (A23): people who joined, even if they left, keep it
            throw ApiException.conflict(ErrorCode.GROUP_NOT_EMPTY, "The group has other members with an account");
        }
        members.deleteAllByGroup(groupId);
        groups.delete(group);
        record("deleted", userId, groupId);
    }

    private static Long netOf(YourNetQuery.YourTotals mine) {
        return mine == null ? null : BalanceCalculator.memberNet(mine.totals());
    }

    /** The owner's member name: their display name cut to the member limit (40 code points), "Me" if blank. */
    private String ownerMemberName(UUID userId) {
        String name = users.findById(userId).map(User::getDisplayName).map(String::strip).orElse("");
        if (name.isEmpty()) {
            return "Me";
        }
        int cut = name.offsetByCodePoints(0, Math.min(FieldRules.MEMBER_NAME_MAX, name.codePointCount(0, name.length())));
        return name.substring(0, cut).strip();
    }

    private void record(String op, UUID userId, UUID groupId) {
        metrics.counter("qesma.groups", "op", op).increment();
        log.atInfo().addKeyValue("event", "group." + op).addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).log("group.{} userId={} groupId={}", op, userId, groupId);
    }
}
