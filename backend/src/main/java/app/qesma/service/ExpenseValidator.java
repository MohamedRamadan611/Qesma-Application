package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.engine.EngineException;
import app.qesma.engine.ItemizedCalculator;
import app.qesma.engine.Limits;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/**
 * Shape validation of a create/preview-expense request that needs no database: required fields, bounds and list
 * sizes. Money rules (sums, rounding) are NOT here; they live in the engine. Group membership is checked by
 * the calculator against the roster.
 */
final class ExpenseValidator {

    static final int MAX_TITLE = 100;
    static final int MAX_ITEM_NAME = 100;
    static final int MAX_LIST = 100;
    static final int MAX_BPS = 10_000;
    static final int MAX_DISCOUNT_BPS = ItemizedCalculator.MAX_DISCOUNT_BPS;
    static final String DEFAULT_CATEGORY = "OTHER";
    static final java.util.Set<String> CATEGORIES = java.util.Set.of("FOOD", "TRANSPORT", "FUEL", "ACCOMMODATION",
            "GROCERIES", "SHOPPING", "ENTERTAINMENT", "BILLS", DEFAULT_CATEGORY);
    static final String SUBTOTAL = "SUBTOTAL";
    static final String SUBTOTAL_PLUS_SERVICE = "SUBTOTAL_PLUS_SERVICE";
    static final LocalDate MIN_DATE = LocalDate.of(2000, 1, 1);
    static final LocalDate MAX_DATE = LocalDate.of(2100, 12, 31);

    /**
     * A request that passed shape validation, with normalized text.
     *
     * @param totalMinor     the client-stated total; 0 means "not stated" (only possible for ITEMIZED)
     * @param items          ITEMIZED only, in the order the client sent them
     * @param items          normalized: every item carries quantity, unitAmountMinor and the line amountMinor
     * @param serviceBps     ITEMIZED only; null = no service charge in the percent form
     * @param serviceAmountMinor ITEMIZED only; the amount form of the service charge (BSA2); never with serviceBps
     * @param taxBps         ITEMIZED only; null = no tax in the percent form
     * @param taxAmountMinor ITEMIZED only; the amount form of the tax (BSA2); never with taxBps
     * @param taxBase        present exactly when a tax (either form) is; the default is made explicit
     * @param discountBps    ITEMIZED only; the percent form of the discount (BSA2)
     * @param discountAmountMinor ITEMIZED only; the amount form of the discount; never with discountBps
     * @param adjustmentMinor ITEMIZED only, 0 when absent
     */
    record Valid(String title, LocalDate expenseDate, String splitType, long totalMinor,
                 List<ExpenseCommand.PayerInput> payers, List<UUID> participantMemberIds,
                 List<ExpenseCommand.ShareInput> shares, List<ExpenseCommand.ItemInput> items, Integer serviceBps,
                 Long serviceAmountMinor, Integer taxBps, Long taxAmountMinor, String taxBase, Integer discountBps,
                 Long discountAmountMinor, long adjustmentMinor, String category, boolean paidFromPool) {

        /** Pre-BSA2 shape: percent charges only, no discount. */
        Valid(String title, LocalDate expenseDate, String splitType, long totalMinor,
              List<ExpenseCommand.PayerInput> payers, List<UUID> participantMemberIds,
              List<ExpenseCommand.ShareInput> shares, List<ExpenseCommand.ItemInput> items, Integer serviceBps,
              Integer taxBps, String taxBase, long adjustmentMinor, String category, boolean paidFromPool) {
            this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items, serviceBps,
                    null, taxBps, null, taxBase, null, null, adjustmentMinor, category, paidFromPool);
        }

        /** Itemized shape without category / pool flag. */
        Valid(String title, LocalDate expenseDate, String splitType, long totalMinor,
              List<ExpenseCommand.PayerInput> payers, List<UUID> participantMemberIds,
              List<ExpenseCommand.ShareInput> shares, List<ExpenseCommand.ItemInput> items, Integer serviceBps,
              Integer taxBps, String taxBase, long adjustmentMinor) {
            this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items, serviceBps,
                    taxBps, taxBase, adjustmentMinor, DEFAULT_CATEGORY, false);
        }

        Valid withPoolFields(String newCategory, boolean newPaidFromPool) {
            return new Valid(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items,
                    serviceBps, serviceAmountMinor, taxBps, taxAmountMinor, taxBase, discountBps, discountAmountMinor,
                    adjustmentMinor, newCategory, newPaidFromPool);
        }

        /** True when the tax is applied, in either form. */
        boolean hasTax() {
            return taxBps != null || taxAmountMinor != null;
        }

        /** EQUAL/EXACT shape. */
        Valid(String title, LocalDate expenseDate, String splitType, long totalMinor,
              List<ExpenseCommand.PayerInput> payers, List<UUID> participantMemberIds,
              List<ExpenseCommand.ShareInput> shares) {
            this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, null, null, null,
                    null, 0L);
        }
    }

    private ExpenseValidator() {
    }

    /** Create: at least one payer is required. */
    static Valid validate(ExpenseCommand c) {
        return validate(c, true);
    }

    /** Preview passes {@code requirePayers=false}: shares can be computed before anyone is marked as payer. */
    static Valid validate(ExpenseCommand c, boolean requirePayers) {
        if (c == null) {
            throw ApiException.validation("Request body is required");
        }
        String title = FieldRules.name(c.title(), MAX_TITLE, "title");

        LocalDate date = c.expenseDate();
        if (date == null) {
            throw ApiException.validation("expenseDate is required");
        }
        if (date.isBefore(MIN_DATE) || date.isAfter(MAX_DATE)) {
            throw ApiException.validation("expenseDate must be between " + MIN_DATE + " and " + MAX_DATE);
        }

        String type = c.splitType() == null ? "" : c.splitType().strip().toUpperCase(Locale.ROOT);
        boolean itemized = type.equals("ITEMIZED");
        if (!itemized && !type.equals("EQUAL") && !type.equals("EXACT")) {
            throw ApiException.validation("splitType must be EQUAL, EXACT or ITEMIZED");
        }

        long total = 0;
        if (itemized) {
            if (c.totalMinor() != null) {
                if (c.totalMinor() <= 0) {
                    throw ApiException.validation("totalMinor must be greater than zero when given");
                }
                capped(c.totalMinor(), "totalMinor");
                total = c.totalMinor();
            }
        } else {
            if (c.totalMinor() == null || c.totalMinor() <= 0) {
                throw ApiException.validation("totalMinor must be greater than zero");
            }
            capped(c.totalMinor(), "totalMinor");
            total = c.totalMinor();
        }

        List<ExpenseCommand.PayerInput> payers = c.payers() == null ? List.of() : c.payers();
        if (requirePayers && payers.isEmpty()) {
            throw ApiException.validation("At least one payer is required");
        }
        if (payers.size() > MAX_LIST) {
            throw ApiException.validation("At most " + MAX_LIST + " payers are allowed");
        }
        for (ExpenseCommand.PayerInput p : payers) {
            if (p == null || p.memberId() == null || p.amountMinor() == null) {
                throw ApiException.validation("Every payer needs memberId and amountMinor");
            }
            capped(p.amountMinor(), "payer amountMinor");
        }

        Valid shape = switch (type) {
            case "EQUAL" -> equal(c, title, date, total, payers);
            case "EXACT" -> exact(c, title, date, total, payers);
            default -> itemized(c, title, date, total, payers);
        };
        return shape.withPoolFields(category(c.category()), c.paidFromPool() != null && c.paidFromPool());
    }

    /** Null or blank = OTHER; anything outside the enum is a validation error (never silently coerced). */
    static String category(String raw) {
        if (raw == null || raw.isBlank()) {
            return DEFAULT_CATEGORY;
        }
        String value = raw.strip().toUpperCase(Locale.ROOT);
        if (!CATEGORIES.contains(value)) {
            throw ApiException.validation("category must be one of " + new java.util.TreeSet<>(CATEGORIES));
        }
        return value;
    }

    /**
     * BSA1: paidFromPool is valid only when the group has a treasurer and the expense has exactly one payer, who is
     * the treasurer. Needs the group, so the service calls it after {@link #validate}.
     */
    static void requirePoolRules(Valid v, UUID treasurerMemberId) {
        if (!v.paidFromPool()) {
            return;
        }
        if (treasurerMemberId == null) {
            throw ApiException.validation("paidFromPool needs a group treasurer");
        }
        if (v.payers().size() != 1 || !treasurerMemberId.equals(v.payers().get(0).memberId())) {
            throw ApiException.validation("A pool expense must have exactly one payer: the treasurer");
        }
    }

    private static Valid equal(ExpenseCommand c, String title, LocalDate date, long total,
                               List<ExpenseCommand.PayerInput> payers) {
        rejectItemizedFields(c, "EQUAL");
        if (c.shares() != null) {
            throw ApiException.validation("shares is only allowed for EXACT expenses");
        }
        List<UUID> participants = c.participantMemberIds();
        if (participants != null) {
            if (participants.isEmpty()) {
                throw ApiException.validation("participantMemberIds must not be empty (omit it for all members)");
            }
            if (participants.size() > MAX_LIST) {
                throw ApiException.validation("At most " + MAX_LIST + " participants are allowed");
            }
            if (participants.stream().anyMatch(Objects::isNull)) {
                throw ApiException.validation("participantMemberIds must not contain null");
            }
        }
        return new Valid(title, date, "EQUAL", total, List.copyOf(payers),
                participants == null ? null : List.copyOf(participants), null);
    }

    private static Valid exact(ExpenseCommand c, String title, LocalDate date, long total,
                               List<ExpenseCommand.PayerInput> payers) {
        rejectItemizedFields(c, "EXACT");
        if (c.participantMemberIds() != null) {
            throw ApiException.validation("participantMemberIds is only allowed for EQUAL expenses");
        }
        List<ExpenseCommand.ShareInput> shares = c.shares();
        if (shares == null || shares.isEmpty()) {
            throw ApiException.validation("shares is required for EXACT expenses");
        }
        if (shares.size() > MAX_LIST) {
            throw ApiException.validation("At most " + MAX_LIST + " shares are allowed");
        }
        for (ExpenseCommand.ShareInput s : shares) {
            if (s == null || s.memberId() == null || s.amountMinor() == null) {
                throw ApiException.validation("Every share needs memberId and amountMinor");
            }
            capped(s.amountMinor(), "share amountMinor");
        }
        return new Valid(title, date, "EXACT", total, List.copyOf(payers), null, List.copyOf(shares));
    }

    private static Valid itemized(ExpenseCommand c, String title, LocalDate date, long total,
                                  List<ExpenseCommand.PayerInput> payers) {
        if (c.participantMemberIds() != null) {
            throw ApiException.validation("participantMemberIds is only allowed for EQUAL expenses");
        }
        if (c.shares() != null) {
            throw ApiException.validation("shares is only allowed for EXACT expenses");
        }
        List<ExpenseCommand.ItemInput> items = c.items();
        if (items == null || items.isEmpty()) {
            throw ApiException.validation("items is required for ITEMIZED expenses");
        }
        if (items.size() > MAX_LIST) {
            throw ApiException.validation("At most " + MAX_LIST + " items are allowed");
        }
        List<ExpenseCommand.ItemInput> clean = new ArrayList<>();
        for (ExpenseCommand.ItemInput item : items) {
            if (item == null || item.assigneeMemberIds() == null) {
                throw ApiException.validation("Every item needs name, an amount and assigneeMemberIds");
            }
            String name = FieldRules.name(item.name(), MAX_ITEM_NAME, "item name");
            ItemizedCalculator.Item line = itemLine(name, item);
            List<UUID> assignees = item.assigneeMemberIds();
            if (assignees.isEmpty()) {
                throw ApiException.validation("Every item needs at least one assignee");
            }
            if (assignees.size() > MAX_LIST) {
                throw ApiException.validation("At most " + MAX_LIST + " assignees per item are allowed");
            }
            if (assignees.stream().anyMatch(Objects::isNull)) {
                throw ApiException.validation("assigneeMemberIds must not contain null");
            }
            clean.add(new ExpenseCommand.ItemInput(name, line.amountMinor(), line.unitAmountMinor(), line.quantity(),
                    List.copyOf(assignees)));
        }

        ItemizedCalculator.ChargeSpec service = null;
        if (c.service() != null) {
            service = charge(c.service().bps(), c.service().amountMinor(), "service", 0, MAX_BPS);
        }
        ItemizedCalculator.ChargeSpec tax = null;
        String taxBase = null;
        if (c.tax() != null) {
            tax = charge(c.tax().bps(), c.tax().amountMinor(), "tax", 0, MAX_BPS);
            taxBase = taxBase(c.tax().base());
        }
        ItemizedCalculator.ChargeSpec discount = null;
        if (c.discount() != null) {
            discount = charge(c.discount().bps(), c.discount().amountMinor(), "discount", 1, MAX_DISCOUNT_BPS);
        }
        long adjustment = c.adjustmentMinor() == null ? 0 : c.adjustmentMinor();
        if (adjustment > Limits.MAX_AMOUNT_MINOR || adjustment < -Limits.MAX_AMOUNT_MINOR) {
            throw ApiException.validation("adjustmentMinor must be between -" + Limits.MAX_AMOUNT_MINOR + " and "
                    + Limits.MAX_AMOUNT_MINOR);
        }
        return new Valid(title, date, "ITEMIZED", total, List.copyOf(payers), null, null, List.copyOf(clean),
                service == null ? null : service.bps(), service == null ? null : service.amountMinor(),
                tax == null ? null : tax.bps(), tax == null ? null : tax.amountMinor(), taxBase,
                discount == null ? null : discount.bps(), discount == null ? null : discount.amountMinor(),
                adjustment, DEFAULT_CATEGORY, false);
    }

    /**
     * A172 shape and ranges (BSA2): legacy amountMinor or unitAmountMinor with an optional quantity, never both;
     * quantity 1..999; unit price > 0 and within the cap; the line (computed exactly by the engine) within the cap.
     */
    private static ItemizedCalculator.Item itemLine(String name, ExpenseCommand.ItemInput item) {
        try {
            ItemizedCalculator.Item line = ItemizedCalculator.Item.of(name, item.amountMinor(), item.unitAmountMinor(),
                    item.quantity(), List.of());
            if (line.quantity() < ItemizedCalculator.MIN_QUANTITY || line.quantity() > ItemizedCalculator.MAX_QUANTITY) {
                throw ApiException.validation("Item quantity must be between " + ItemizedCalculator.MIN_QUANTITY
                        + " and " + ItemizedCalculator.MAX_QUANTITY);
            }
            if (line.unitAmountMinor() <= 0) {
                throw ApiException.validation("Item amounts must be greater than zero");
            }
            capped(line.unitAmountMinor(), "item amount");
            capped(line.amountMinor(), "item line amount (quantity x unitAmountMinor)");
            return line;
        } catch (EngineException e) {
            throw EngineErrors.toApi(e);
        }
    }

    /** A charge in exactly one form (A171, A173): bps within [minBps, maxBps] or an amount 1..cap. */
    private static ItemizedCalculator.ChargeSpec charge(Integer bps, Long amountMinor, String field, int minBps,
                                                        int maxBps) {
        if ((bps == null) == (amountMinor == null)) {
            throw ApiException.validation(field + " needs either bps or amountMinor, not both");
        }
        if (bps != null) {
            if (bps < minBps || bps > maxBps) {
                throw ApiException.validation(field + ".bps must be between " + minBps + " and " + maxBps);
            }
            return ItemizedCalculator.ChargeSpec.percent(bps);
        }
        if (amountMinor < 1 || amountMinor > Limits.MAX_AMOUNT_MINOR) {
            throw ApiException.validation(field + ".amountMinor must be between 1 and " + Limits.MAX_AMOUNT_MINOR);
        }
        return ItemizedCalculator.ChargeSpec.amount(amountMinor);
    }

    /** Review CP2-001: every amount has an upper bound so ledger sums cannot overflow. */
    static void capped(long amountMinor, String field) {
        if (amountMinor > Limits.MAX_AMOUNT_MINOR) {
            throw ApiException.validation(field + " must be at most " + Limits.MAX_AMOUNT_MINOR);
        }
    }

    private static void rejectItemizedFields(ExpenseCommand c, String type) {
        if (c.items() != null || c.service() != null || c.tax() != null || c.adjustmentMinor() != null
                || c.discount() != null) {
            throw ApiException.validation("items, discount, service, tax and adjustmentMinor are only allowed for "
                    + "ITEMIZED expenses (this is " + type + ")");
        }
    }

    /** Null defaults to SUBTOTAL_PLUS_SERVICE (Decision A1); the default is made explicit for storage and hashing. */
    private static String taxBase(String raw) {
        if (raw == null || raw.isBlank()) {
            return SUBTOTAL_PLUS_SERVICE;
        }
        String base = raw.strip().toUpperCase(Locale.ROOT);
        if (!base.equals(SUBTOTAL) && !base.equals(SUBTOTAL_PLUS_SERVICE)) {
            throw ApiException.validation("tax.base must be SUBTOTAL or SUBTOTAL_PLUS_SERVICE");
        }
        return base;
    }
}
