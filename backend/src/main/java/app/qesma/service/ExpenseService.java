package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Expense;
import app.qesma.domain.ExpenseItem;
import app.qesma.domain.ExpenseItemAssignee;
import app.qesma.domain.ExpensePayer;
import app.qesma.domain.ExpenseSplit;
import app.qesma.domain.Member;
import app.qesma.engine.Payer;
import app.qesma.persistence.ExpenseItemAssigneeRepository;
import app.qesma.persistence.ExpenseItemRepository;
import app.qesma.persistence.ExpensePayerRepository;
import app.qesma.persistence.ExpenseRepository;
import app.qesma.persistence.ExpenseRevisionStore;
import app.qesma.persistence.ExpenseSplitRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Expenses of a group (spec 3.1, 8.2): EQUAL, EXACT and ITEMIZED with one or more payers, plus the preview.
 * This class validates and persists; every money rule is delegated to the pure engine through
 * {@link ExpenseCalculator}, which create and preview share. Ownership is decided only by
 * {@link GroupAccessService}.
 */
@Service
public class ExpenseService {

    static final String CREATE_ENDPOINT = "POST /api/v1/groups/{gid}/expenses";
    private static final String CREATE = "CREATE";
    private static final String UPDATE = "UPDATE";
    private static final String DELETE = "DELETE";
    /** Wide bounds standing in for "no date filter" (see ExpenseRepository.findPage). */
    private static final LocalDate OPEN_FROM = LocalDate.of(1900, 1, 1);
    private static final LocalDate OPEN_TO = LocalDate.of(2200, 1, 1);

    private static final Logger log = LoggerFactory.getLogger(ExpenseService.class);

    private final GroupAccessService access;
    private final ExpenseRepository expenses;
    private final ExpensePayerRepository payers;
    private final ExpenseSplitRepository splits;
    private final ExpenseItemRepository items;
    private final ExpenseItemAssigneeRepository assignees;
    private final ExpenseRevisionStore revisions;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public ExpenseService(GroupAccessService access, ExpenseRepository expenses, ExpensePayerRepository payers,
                          ExpenseSplitRepository splits, ExpenseItemRepository items,
                          ExpenseItemAssigneeRepository assignees, ExpenseRevisionStore revisions,
                          IdempotencyService idempotency,
                          RequestHasher hasher, ObjectMapper mapper, Clock clock, MeterRegistry metrics) {
        this.access = access;
        this.expenses = expenses;
        this.payers = payers;
        this.splits = splits;
        this.items = items;
        this.assignees = assignees;
        this.revisions = revisions;
        this.idempotency = idempotency;
        this.hasher = hasher;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    /**
     * Creates an expense exactly once per Idempotency-Key. One transaction: key lock, group lock, replay check,
     * validation, engine, expense + payers + resolved splits (+ items), key row. A replay returns the stored
     * response and writes nothing; the same key with a different request is IDEMPOTENCY_KEY_REUSED.
     */
    @Transactional
    public IdempotencyService.Outcome create(UUID userId, UUID groupId, UUID idempotencyKey, ExpenseCommand command) {
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);                                         // 1. same-key requests run one at a time
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.ADD_EXPENSE); // 2. membership (404), role (403) + group row lock

        ExpenseValidator.Valid request = ExpenseValidator.validate(command);   // 3. shape validation, no I/O
        String requestHash = hasher.hash(CREATE_ENDPOINT, groupId, request);
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, CREATE_ENDPOINT, requestHash);
        if (replay.isPresent()) {                                              // 4. replay: no writes at all
            log.atInfo().addKeyValue("event", "expense.replayed").addKeyValue("userId", userId)
                    .addKeyValue("groupId", groupId).log("expense.replayed userId={} groupId={}", userId, groupId);
            return replay.get();
        }

        List<Member> members = access.listMembers(ctx);                        // 5. business write
        ExpenseCalculator.Computation calc = ExpenseCalculator.compute(request, members);
        ExpenseCalculator.requirePayersMatch(calc);

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);          // PostgreSQL stores microseconds
        UUID expenseId = UUID.randomUUID();
        Expense expense = newExpense(expenseId, groupId, userId, request, calc, now);
        expenses.saveAndFlush(expense);                                        // the revision row (plain SQL) references it
        ExpenseView view = persistChildren(expense, request, calc, members);
        String body = toJson(view);
        revisions.insert(expenseId, expense.getVersion(), CREATE, body, userId, now);  // history v1, same tx
        idempotency.store(userId, key, CREATE_ENDPOINT, requestHash, HttpStatus.CREATED.value(), body); // 6. same tx
        metrics.counter("qesma.expenses", "op", "created", "splitType", request.splitType()).increment();
        log.atInfo().addKeyValue("event", "expense.created").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("expenseId", expenseId)
                .addKeyValue("splitType", request.splitType())
                .log("expense.created userId={} groupId={} expenseId={}", userId, groupId, expenseId);
        return new IdempotencyService.Outcome(HttpStatus.CREATED.value(), body, false);
    }

    /**
     * Computes the split for the same body as create and saves nothing (spec 8.2). No idempotency key, no group
     * lock, safe to call repeatedly. Payers are optional here; {@code payersTotalMatches} reports the state.
     */
    @Transactional(readOnly = true)
    public ExpensePreview preview(UUID userId, UUID groupId, ExpenseCommand command) {
        GroupContext ctx = access.requireMember(userId, groupId);
        ExpenseValidator.Valid request = ExpenseValidator.validate(command, false);
        ExpenseCalculator.Computation calc = ExpenseCalculator.compute(request, access.listMembers(ctx));
        boolean payersMatch = ExpenseCalculator.payersMatch(calc);
        metrics.counter("qesma.expense_previews", "splitType", request.splitType()).increment();
        return new ExpensePreview(calc.totalMinor(), calc.subtotalMinor(),
                calc.itemized() ? calc.serviceMinor() : null, calc.itemized() ? calc.taxMinor() : null,
                calc.itemized() ? calc.adjustmentMinor() : null, calc.shares(), payersMatch);
    }

    /**
     * Replaces an expense (spec 7.9) through the same validation and engine pipeline as create. One transaction:
     * the group row lock serializes every ledger writer of the group, the expense's version is compared to the
     * client's under that lock (so "check, then write" cannot race), then the header, payers, shares and items are
     * replaced, the version goes up by one and a revision with the full snapshot is appended.
     */
    @Transactional
    public ExpenseView update(UUID userId, UUID groupId, UUID expenseId, int expectedVersion,
                              ExpenseCommand command) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.READ_GROUP);
        Expense expense = expenses.findActive(expenseId, groupId).orElseThrow(ApiException::notFound);
        ctx.requireModify(expense.getCreatedByUserId(), Permission.EDIT_OWN_EXPENSE, Permission.EDIT_ANY_EXPENSE);
        requireVersion(expense, expectedVersion);

        ExpenseValidator.Valid request = ExpenseValidator.validate(command);
        List<Member> members = access.listMembers(ctx);
        // A member who left may stay in an expense that already has them, but cannot be added (B12, A79).
        ExpenseCalculator.Computation calc = ExpenseCalculator.compute(request, members, memberIdsOf(expenseId));
        ExpenseCalculator.requirePayersMatch(calc);

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        expense.replaceWith(newExpense(expenseId, groupId, userId, request, calc, now), now);
        // Bulk deletes flush the header change first; children go in FK order. History lives in revisions.
        assignees.deleteAllOf(expenseId);
        items.deleteAllOf(expenseId);
        splits.deleteAllOf(expenseId);
        payers.deleteAllOf(expenseId);
        ExpenseView view = persistChildren(expense, request, calc, members);
        revisions.insert(expenseId, expense.getVersion(), UPDATE, toJson(view), userId, now);

        metrics.counter("qesma.expenses", "op", "updated", "splitType", request.splitType()).increment();
        log.atInfo().addKeyValue("event", "expense.updated").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("expenseId", expenseId)
                .addKeyValue("version", expense.getVersion())
                .log("expense.updated userId={} groupId={} expenseId={}", userId, groupId, expenseId);
        return view;
    }

    /**
     * Soft delete (spec 7.9): {@code deleted_at} is set, the version goes up by one and a DELETE revision keeps the
     * last state. Deleting an already deleted expense is a plain 404 (it is no longer reachable).
     */
    @Transactional
    public int delete(UUID userId, UUID groupId, UUID expenseId, int expectedVersion) {
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.READ_GROUP);
        Expense expense = expenses.findActive(expenseId, groupId).orElseThrow(ApiException::notFound);
        ctx.requireModify(expense.getCreatedByUserId(), Permission.EDIT_OWN_EXPENSE, Permission.EDIT_ANY_EXPENSE);
        requireVersion(expense, expectedVersion);

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        expense.markDeleted(now);
        ExpenseView last = new PageMapper(List.of(expense), access.listMembers(ctx)).view(expense);
        revisions.insert(expenseId, expense.getVersion(), DELETE, toJson(last), userId, now);

        metrics.counter("qesma.expenses", "op", "deleted", "splitType", expense.getSplitType()).increment();
        log.atInfo().addKeyValue("event", "expense.deleted").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("expenseId", expenseId)
                .addKeyValue("version", expense.getVersion())
                .log("expense.deleted userId={} groupId={} expenseId={}", userId, groupId, expenseId);
        return expense.getVersion();
    }

    /** History of an expense, oldest first. Still available after the expense was deleted. */
    @Transactional(readOnly = true)
    public List<ExpenseRevisionView> revisions(UUID userId, UUID groupId, UUID expenseId) {
        access.requireMember(userId, groupId);
        if (!expenses.existsByIdAndGroupId(expenseId, groupId)) {
            throw ApiException.notFound();
        }
        return revisions.findByExpense(expenseId).stream().map(r -> new ExpenseRevisionView(r.version(),
                r.changeType(), r.changedAt(), r.changedByUserId(), readTree(r.snapshot()))).toList();
    }

    /** Called under the group lock, so the comparison and the write that follows cannot be interleaved. */
    private void requireVersion(Expense expense, int expected) {
        if (expense.getVersion() != expected) {
            metrics.counter("qesma.version_conflicts", "resource", "expense").increment();
            throw ApiException.conflict(ErrorCode.VERSION_CONFLICT, "The expense was modified by someone else");
        }
    }

    private com.fasterxml.jackson.databind.JsonNode readTree(String json) {
        try {
            return mapper.readTree(json);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored revision is not valid JSON", e);
        }
    }

    @Transactional(readOnly = true)
    public Page<ExpenseView> list(UUID userId, UUID groupId, int page, int size, LocalDate fromDate, LocalDate toDate,
                                  UUID memberId) {
        FieldRules.page(page, size);
        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            throw ApiException.validation("fromDate must not be after toDate");
        }
        GroupContext ctx = access.requireMember(userId, groupId);
        LocalDate from = fromDate == null ? OPEN_FROM : fromDate;
        LocalDate to = toDate == null ? OPEN_TO : toDate;
        PageRequest paging = PageRequest.of(page, size);
        Page<Expense> found = memberId == null
                ? expenses.findPage(groupId, from, to, paging)
                : expenses.findPageForMember(groupId, from, to, memberId, paging);
        List<Member> members = access.listMembers(ctx);
        return found.map(new PageMapper(found.getContent(), members)::view);
    }

    @Transactional(readOnly = true)
    public ExpenseView get(UUID userId, UUID groupId, UUID expenseId) {
        GroupContext ctx = access.requireMember(userId, groupId);
        Expense expense = expenses.findActive(expenseId, groupId).orElseThrow(ApiException::notFound);
        return new PageMapper(List.of(expense), access.listMembers(ctx)).view(expense);
    }

    // ---- helpers ------------------------------------------------------------------------------------------

    /** Every member the stored expense references: payers, shares and item assignees (called under the group lock). */
    private java.util.Set<UUID> memberIdsOf(UUID expenseId) {
        List<UUID> one = List.of(expenseId);
        java.util.Set<UUID> ids = new java.util.HashSet<>();
        payers.findByExpenseIdIn(one).forEach(p -> ids.add(p.getMemberId()));
        splits.findByExpenseIdIn(one).forEach(s -> ids.add(s.getMemberId()));
        List<UUID> itemIds = items.findByExpenseIdIn(one).stream().map(ExpenseItem::getId).toList();
        if (!itemIds.isEmpty()) {
            assignees.findByItemIdIn(itemIds).forEach(a -> ids.add(a.getMemberId()));
        }
        return ids;
    }

    private static Expense newExpense(UUID id, UUID groupId, UUID userId, ExpenseValidator.Valid request,
                                      ExpenseCalculator.Computation calc, Instant now) {
        if (calc.itemized()) {
            return Expense.itemized(id, groupId, request.title(), calc.totalMinor(), request.expenseDate(), userId,
                    now, calc.subtotalMinor(), calc.serviceBps(), calc.serviceMinor(), calc.taxBps(), calc.taxMinor(),
                    calc.taxBase(), calc.adjustmentMinor());
        }
        return new Expense(id, groupId, request.title(), request.splitType(), calc.totalMinor(),
                request.expenseDate(), userId, now);
    }

    private static ExpenseSplit split(UUID expenseId, ExpenseView.ShareView s) {
        if (s.itemsMinor() == null) {
            return new ExpenseSplit(expenseId, s.memberId(), s.owedMinor());
        }
        return new ExpenseSplit(expenseId, s.memberId(), s.owedMinor(), s.itemsMinor(), s.serviceMinor(),
                s.taxMinor(), s.adjustmentMinor());
    }

    /** Writes payers, resolved shares and (ITEMIZED) items, and returns the expense as the API shows it. */
    private ExpenseView persistChildren(Expense expense, ExpenseValidator.Valid request,
                                        ExpenseCalculator.Computation calc, List<Member> members) {
        UUID expenseId = expense.getId();
        for (Payer p : calc.payers()) {
            payers.save(new ExpensePayer(expenseId, UUID.fromString(p.memberId()), p.amountMinor()));
        }
        for (ExpenseView.ShareView s : calc.shares()) {
            splits.save(split(expenseId, s));
        }
        Map<UUID, Integer> order = sortOrders(members);
        List<ExpenseView.ItemView> itemViews = calc.itemized() ? saveItems(expenseId, request.items(), order) : null;
        return new ExpenseView(expenseId, expense.getGroupId(), expense.getTitle(), expense.getSplitType(),
                calc.totalMinor(), expense.getExpenseDate(), payerViews(calc.payers(), order), calc.shares(),
                expense.getCreatedAt(), expense.getVersion(), itemViews, calc.itemized() ? charges(calc) : null);
    }

    /** Items keep the order the client sent; each item's assignees are listed in member sort order. */
    private List<ExpenseView.ItemView> saveItems(UUID expenseId, List<ExpenseCommand.ItemInput> inputs,
                                                 Map<UUID, Integer> order) {
        List<ExpenseView.ItemView> views = new java.util.ArrayList<>();
        int position = 0;
        for (ExpenseCommand.ItemInput input : inputs) {
            UUID itemId = UUID.randomUUID();
            items.save(new ExpenseItem(itemId, expenseId, input.name(), input.amountMinor(), position++));
            for (UUID memberId : input.assigneeMemberIds()) {
                assignees.save(new ExpenseItemAssignee(itemId, memberId));
            }
            views.add(new ExpenseView.ItemView(itemId, input.name(), input.amountMinor(),
                    byMemberOrder(input.assigneeMemberIds(), order)));
        }
        return views;
    }

    private static ExpenseView.Charges charges(ExpenseCalculator.Computation c) {
        return new ExpenseView.Charges(c.subtotalMinor(),
                c.serviceBps() == null ? null : new ExpenseView.ServiceCharge(c.serviceBps(), c.serviceMinor()),
                c.taxBps() == null ? null : new ExpenseView.TaxCharge(c.taxBps(), c.taxBase(), c.taxMinor()),
                c.adjustmentMinor());
    }

    private String toJson(ExpenseView view) {
        try {
            return mapper.writeValueAsString(view);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize expense response", e);
        }
    }

    private static Map<UUID, Integer> sortOrders(List<Member> members) {
        return members.stream().collect(Collectors.toMap(Member::getId, Member::getSortOrder));
    }

    private static List<UUID> byMemberOrder(Collection<UUID> memberIds, Map<UUID, Integer> order) {
        return memberIds.stream()
                .sorted(Comparator.comparingInt((UUID id) -> order.getOrDefault(id, Integer.MAX_VALUE)))
                .toList();
    }

    private static List<ExpenseView.PayerView> payerViews(List<Payer> payers, Map<UUID, Integer> order) {
        return payers.stream()
                .map(p -> new ExpenseView.PayerView(UUID.fromString(p.memberId()), p.amountMinor()))
                .sorted(Comparator.comparingInt((ExpenseView.PayerView p) -> order.get(p.memberId())))
                .toList();
    }

    /**
     * Builds views for a page of expenses with a fixed number of child queries (payers, splits, and, only when the
     * page holds an ITEMIZED expense, items and assignees), whatever the page size.
     */
    private final class PageMapper {
        private final Map<UUID, List<ExpensePayer>> payersByExpense;
        private final Map<UUID, List<ExpenseSplit>> splitsByExpense;
        private final Map<UUID, List<ExpenseItem>> itemsByExpense;
        private final Map<UUID, List<ExpenseItemAssignee>> assigneesByItem;
        private final Map<UUID, Integer> order;

        PageMapper(List<Expense> page, List<Member> members) {
            List<UUID> ids = page.stream().map(Expense::getId).toList();
            List<UUID> itemizedIds = page.stream().filter(e -> Expense.ITEMIZED.equals(e.getSplitType()))
                    .map(Expense::getId).toList();
            if (ids.isEmpty()) {
                payersByExpense = Map.of();
                splitsByExpense = Map.of();
            } else {
                payersByExpense = payers.findByExpenseIdIn(ids).stream()
                        .collect(Collectors.groupingBy(ExpensePayer::getExpenseId, HashMap::new, Collectors.toList()));
                splitsByExpense = splits.findByExpenseIdIn(ids).stream()
                        .collect(Collectors.groupingBy(ExpenseSplit::getExpenseId, HashMap::new, Collectors.toList()));
            }
            if (itemizedIds.isEmpty()) {
                itemsByExpense = Map.of();
                assigneesByItem = Map.of();
            } else {
                List<ExpenseItem> found = items.findByExpenseIdIn(itemizedIds);
                itemsByExpense = found.stream()
                        .collect(Collectors.groupingBy(ExpenseItem::getExpenseId, HashMap::new, Collectors.toList()));
                assigneesByItem = assignees.findByItemIdIn(found.stream().map(ExpenseItem::getId).toList()).stream()
                        .collect(Collectors.groupingBy(ExpenseItemAssignee::getItemId, HashMap::new,
                                Collectors.toList()));
            }
            this.order = sortOrders(members);
        }

        ExpenseView view(Expense e) {
            List<ExpenseView.PayerView> payerViews = payersByExpense.getOrDefault(e.getId(), List.of()).stream()
                    .map(p -> new ExpenseView.PayerView(p.getMemberId(), p.getAmountMinor()))
                    .sorted(Comparator.comparingInt(p -> order.getOrDefault(p.memberId(), Integer.MAX_VALUE)))
                    .toList();
            List<ExpenseView.ShareView> shareViews = splitsByExpense.getOrDefault(e.getId(), List.of()).stream()
                    .map(s -> new ExpenseView.ShareView(s.getMemberId(), s.getOwedMinor(), s.getItemsMinor(),
                            s.getServiceMinor(), s.getTaxMinor(), s.getAdjustmentMinor()))
                    .sorted(Comparator.comparingInt(s -> order.getOrDefault(s.memberId(), Integer.MAX_VALUE)))
                    .toList();
            boolean itemized = Expense.ITEMIZED.equals(e.getSplitType());
            return new ExpenseView(e.getId(), e.getGroupId(), e.getTitle(), e.getSplitType(), e.getTotalMinor(),
                    e.getExpenseDate(), payerViews, shareViews, e.getCreatedAt(), e.getVersion(),
                    itemized ? itemViews(e) : null, itemized ? charges(e) : null);
        }

        private List<ExpenseView.ItemView> itemViews(Expense e) {
            return itemsByExpense.getOrDefault(e.getId(), List.of()).stream()
                    .sorted(Comparator.comparingInt(ExpenseItem::getSortOrder))
                    .map(i -> new ExpenseView.ItemView(i.getId(), i.getName(), i.getAmountMinor(),
                            byMemberOrder(assigneesByItem.getOrDefault(i.getId(), List.of()).stream()
                                    .map(ExpenseItemAssignee::getMemberId).toList(), order)))
                    .toList();
        }

        private ExpenseView.Charges charges(Expense e) {
            return new ExpenseView.Charges(e.getSubtotalMinor(),
                    e.getServiceBps() == null ? null : new ExpenseView.ServiceCharge(e.getServiceBps(), e.getServiceMinor()),
                    e.getTaxBps() == null ? null
                            : new ExpenseView.TaxCharge(e.getTaxBps(), e.getTaxBase(), e.getTaxMinor()),
                    e.getAdjustmentMinor());
        }
    }
}
