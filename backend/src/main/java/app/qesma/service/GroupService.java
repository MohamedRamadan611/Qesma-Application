package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.persistence.ExpenseGroupRepository;
import app.qesma.persistence.ExpenseRepository;
import app.qesma.persistence.GroupSummaryRow;
import app.qesma.persistence.GroupTotals;
import app.qesma.persistence.InviteStore;
import app.qesma.persistence.JoinRequestStore;
import app.qesma.persistence.MemberRepository;
import app.qesma.persistence.NotificationPrefStore;
import app.qesma.persistence.SettlementRepository;
import app.qesma.persistence.UserRepository;
import app.qesma.persistence.YourNetQuery;
import app.qesma.domain.User;
import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.Limits;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
                              java.time.Instant lastExpenseAt, UUID yourMemberId, Long yourNetMinor, String yourRole, boolean muted,
                              Long poolBalanceMinor) {

        /** Without the pool meter (no treasurer). */
        public GroupDetail(ExpenseGroup group, List<Member> members, long totalSpentMinor,
                           java.time.Instant lastExpenseAt, UUID yourMemberId, Long yourNetMinor, String yourRole,
                           boolean muted) {
            this(group, members, totalSpentMinor, lastExpenseAt, yourMemberId, yourNetMinor, yourRole, muted, null);
        }
    }

    private final GroupAccessService access;
    private final ExpenseGroupRepository groups;
    private final MemberRepository members;
    private final ExpenseRepository expenses;
    private final SettlementRepository settlements;
    private final UserRepository users;
    private final YourNetQuery yourNet;
    private final NotificationPrefStore prefs;
    private final GroupUsageChecker usage;
    private final InviteStore invites;
    private final JoinRequestStore joinRequests;
    private final Clock clock;
    private final MeterRegistry metrics;

    public GroupService(GroupAccessService access, ExpenseGroupRepository groups, MemberRepository members,
                        ExpenseRepository expenses, SettlementRepository settlements, UserRepository users, YourNetQuery yourNet, NotificationPrefStore prefs,
                        ObjectProvider<GroupUsageChecker> usage, InviteStore invites, JoinRequestStore joinRequests,
                        Clock clock, MeterRegistry metrics) {
        this.invites = invites;
        this.joinRequests = joinRequests;
        this.access = access;
        this.groups = groups;
        this.members = members;
        this.expenses = expenses;
        this.settlements = settlements;
        this.users = users;
        this.yourNet = yourNet;
        this.prefs = prefs;
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
                totals.lastExpenseAt(), ctx.me().getId(), netOf(mine), ctx.role().name(),
                prefs.isGroupMuted(userId, groupId),
                ctx.group().getTreasurerMemberId() == null ? null : settlements.poolBalanceMinor(groupId));
    }

    /**
     * Edits name and/or type. {@code expectedVersion} comes from If-Match; a stale value is a
     * VERSION_CONFLICT, and Hibernate's version check catches a race between this check and the write.
     * Ownership (404) is decided before anything about versions or input is revealed.
     */
    @Transactional // self-invocation bypasses the proxy, so this overload opens the transaction itself
    public ExpenseGroup update(UUID userId, UUID groupId, int expectedVersion, String rawName, String rawType,
                               UUID treasurerMemberId) {
        return update(userId, groupId, expectedVersion, rawName, rawType, treasurerMemberId, BudgetPatch.NONE);
    }

    /**
     * The trip budget settings of {@code PATCH /groups/{gid}} (A190, A193). A null value is "not sent"; a
     * {@code clear*} flag clears that field; a value and its clear flag together are a 422.
     */
    public record BudgetPatch(Long budgetMinor, boolean clearBudget, LocalDate tripStartDate,
                              boolean clearTripStartDate, LocalDate tripEndDate, boolean clearTripEndDate) {
        public static final BudgetPatch NONE = new BudgetPatch(null, false, null, false, null, false);
    }

    @Transactional
    public ExpenseGroup update(UUID userId, UUID groupId, int expectedVersion, String rawName, String rawType,
                               UUID treasurerMemberId, BudgetPatch budget) {
        // Row lock: deposits and pool expenses take the same lock, so the pool-untouched check below cannot race them.
        ExpenseGroup group = access.requireForUpdate(userId, groupId, Permission.EDIT_GROUP).group();
        if (group.getVersion() != expectedVersion) {
            throw ApiException.conflict(ErrorCode.VERSION_CONFLICT, "The group was modified by someone else");
        }
        String name = rawName == null ? group.getName() : FieldRules.name(rawName, FieldRules.GROUP_NAME_MAX, "name");
        String type = rawType == null ? group.getType() : FieldRules.groupType(rawType);
        boolean treasurerChanges = treasurerMemberId != null && !treasurerMemberId.equals(group.getTreasurerMemberId());
        if (treasurerChanges) {
            requireTreasurerChange(group, treasurerMemberId);
        }
        BudgetPatch b = budget == null ? BudgetPatch.NONE : budget;
        Long newBudget = resulting(b.budgetMinor(), b.clearBudget(), group.getBudgetMinor(), "budgetMinor");
        LocalDate newStart = resulting(b.tripStartDate(), b.clearTripStartDate(), group.getTripStartDate(),
                "tripStartDate");
        LocalDate newEnd = resulting(b.tripEndDate(), b.clearTripEndDate(), group.getTripEndDate(), "tripEndDate");
        if (newBudget != null && (newBudget < 1 || newBudget > Limits.MAX_AMOUNT_MINOR)) {
            throw ApiException.validation("budgetMinor must be between 1 and " + Limits.MAX_AMOUNT_MINOR);
        }
        requireTripDate(newStart, "tripStartDate");
        requireTripDate(newEnd, "tripEndDate");
        // Checked on the resulting state, so sending only one date cannot leave the stored pair reversed.
        if (newStart != null && newEnd != null && newEnd.isBefore(newStart)) {
            throw ApiException.validation("tripEndDate must not be before tripStartDate");
        }
        boolean budgetChanges = !Objects.equals(newBudget, group.getBudgetMinor())
                || !Objects.equals(newStart, group.getTripStartDate()) || !Objects.equals(newEnd, group.getTripEndDate());
        if (!name.equals(group.getName()) || !type.equals(group.getType()) || treasurerChanges || budgetChanges) {
            group.edit(name, type, clock.instant());
            if (treasurerChanges) {
                group.setTreasurer(treasurerMemberId, clock.instant());
            }
            if (budgetChanges) {
                group.setBudget(newBudget, newStart, newEnd, clock.instant());
            }
            group = groups.saveAndFlush(group); // flush now so the new version is known and a lost race throws here
            record("updated", userId, groupId);
        }
        return group;
    }

    /** A193: the value after the patch; a value together with its clear flag is a 422. */
    private static <T> T resulting(T sent, boolean clear, T stored, String field) {
        if (clear && sent != null) {
            throw ApiException.validation(field + " and its clear flag cannot both be sent");
        }
        if (clear) {
            return null;
        }
        return sent != null ? sent : stored;
    }

    private static void requireTripDate(LocalDate d, String field) {
        if (d != null && (d.isBefore(ExpenseValidator.MIN_DATE) || d.isAfter(ExpenseValidator.MAX_DATE))) {
            throw ApiException.validation(field + " must be between " + ExpenseValidator.MIN_DATE + " and "
                    + ExpenseValidator.MAX_DATE);
        }
    }

    /**
     * BSA1 (A137): the treasurer is an ACTIVE member of this group, and can change only while no pool deposit and no
     * pool expense exists, counting cancelled and soft-deleted rows. Setting the first treasurer is always allowed.
     */
    private void requireTreasurerChange(ExpenseGroup group, UUID memberId) {
        Member m = members.findByIdAndGroupId(memberId, group.getId()).orElseThrow(
                () -> ApiException.validation("treasurerMemberId must be a member of this group"));
        if (!"ACTIVE".equals(m.getStatus())) {
            throw ApiException.validation("The treasurer must be an active member");
        }
        if (settlements.existsPoolDeposit(group.getId()) || expenses.existsPoolExpense(group.getId())) {
            throw ApiException.conflict(ErrorCode.INVALID_STATE_TRANSITION,
                    "The treasurer cannot change once the pool has deposits or expenses");
        }
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
        removeEmptyGroup(group);
        record("deleted", userId, groupId);
    }

    /**
     * Removes a group that holds no ledger data. Join requests and invites reference the group and its members without
     * a cascade, so they go first (a group that ever had an invite could not be deleted before B17).
     */
    private void removeEmptyGroup(ExpenseGroup group) {
        joinRequests.deleteAllOfGroup(group.getId());
        invites.deleteAllOfGroup(group.getId());
        members.deleteAllByGroup(group.getId());
        groups.delete(group);
    }

    /**
     * Account deletion (B17, A116), inside the caller's transaction: frees every group from the account. Groups the
     * account owns that still depend on it (ledger history, or another ACTIVE linked member) are refused as
     * OWNER_MUST_TRANSFER, all of them listed; owned groups with no ledger data and nobody else active are deleted (a LEFT
     * member of such a group has no history to keep); every other member of the account is detached, keeping name and
     * history, so no balance changes. Groups are locked in id order.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.MANDATORY)
    public void releaseUser(UUID userId) {
        List<Member> linked = members.findAllLinkedTo(userId);
        List<UUID> ownedGroupIds = linked.stream().filter(m -> "OWNER".equals(m.getRole()))
                .map(Member::getGroupId).sorted().toList();
        List<Map<String, String>> blocked = new java.util.ArrayList<>();
        List<ExpenseGroup> deletable = new java.util.ArrayList<>();
        for (UUID groupId : ownedGroupIds) {
            ExpenseGroup group = groups.findByIdForUpdate(groupId).orElseThrow(() -> new IllegalStateException("Owner group missing"));
            if (usage.hasLedgerData(groupId) || members.hasOtherActiveLinked(groupId, userId)) {
                blocked.add(Map.of("id", group.getId().toString(), "name", group.getName()));
            } else {
                deletable.add(group);
            }
        }
        if (!blocked.isEmpty()) {
            throw ApiException.ownerMustTransfer(blocked);
        }
        for (ExpenseGroup group : deletable) {
            removeEmptyGroup(group);
            record("deleted", userId, group.getId());
        }
        members.unlinkAllOf(userId);
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
