package app.qesma.service;

import app.qesma.api.ApiException;
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
    static final String SUBTOTAL = "SUBTOTAL";
    static final String SUBTOTAL_PLUS_SERVICE = "SUBTOTAL_PLUS_SERVICE";
    static final LocalDate MIN_DATE = LocalDate.of(2000, 1, 1);
    static final LocalDate MAX_DATE = LocalDate.of(2100, 12, 31);

    /**
     * A request that passed shape validation, with normalized text.
     *
     * @param totalMinor     the client-stated total; 0 means "not stated" (only possible for ITEMIZED)
     * @param items          ITEMIZED only, in the order the client sent them
     * @param serviceBps     ITEMIZED only; null = no service charge
     * @param taxBps         ITEMIZED only; null = no tax
     * @param taxBase        present exactly when {@code taxBps} is; the default is made explicit
     * @param adjustmentMinor ITEMIZED only, 0 when absent
     */
    record Valid(String title, LocalDate expenseDate, String splitType, long totalMinor,
                 List<ExpenseCommand.PayerInput> payers, List<UUID> participantMemberIds,
                 List<ExpenseCommand.ShareInput> shares, List<ExpenseCommand.ItemInput> items, Integer serviceBps,
                 Integer taxBps, String taxBase, long adjustmentMinor) {

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

        return switch (type) {
            case "EQUAL" -> equal(c, title, date, total, payers);
            case "EXACT" -> exact(c, title, date, total, payers);
            default -> itemized(c, title, date, total, payers);
        };
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
            if (item == null || item.amountMinor() == null || item.assigneeMemberIds() == null) {
                throw ApiException.validation("Every item needs name, amountMinor and assigneeMemberIds");
            }
            String name = FieldRules.name(item.name(), MAX_ITEM_NAME, "item name");
            if (item.amountMinor() <= 0) {
                throw ApiException.validation("Item amounts must be greater than zero");
            }
            capped(item.amountMinor(), "item amountMinor");
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
            clean.add(new ExpenseCommand.ItemInput(name, item.amountMinor(), List.copyOf(assignees)));
        }

        Integer serviceBps = null;
        if (c.service() != null) {
            serviceBps = bps(c.service().bps(), "service.bps");
        }
        Integer taxBps = null;
        String taxBase = null;
        if (c.tax() != null) {
            taxBps = bps(c.tax().bps(), "tax.bps");
            taxBase = taxBase(c.tax().base());
        }
        long adjustment = c.adjustmentMinor() == null ? 0 : c.adjustmentMinor();
        if (adjustment > Limits.MAX_AMOUNT_MINOR || adjustment < -Limits.MAX_AMOUNT_MINOR) {
            throw ApiException.validation("adjustmentMinor must be between -" + Limits.MAX_AMOUNT_MINOR + " and "
                    + Limits.MAX_AMOUNT_MINOR);
        }
        return new Valid(title, date, "ITEMIZED", total, List.copyOf(payers), null, null, List.copyOf(clean),
                serviceBps, taxBps, taxBase, adjustment);
    }

    /** Review CP2-001: every amount has an upper bound so ledger sums cannot overflow. */
    static void capped(long amountMinor, String field) {
        if (amountMinor > Limits.MAX_AMOUNT_MINOR) {
            throw ApiException.validation(field + " must be at most " + Limits.MAX_AMOUNT_MINOR);
        }
    }

    private static void rejectItemizedFields(ExpenseCommand c, String type) {
        if (c.items() != null || c.service() != null || c.tax() != null || c.adjustmentMinor() != null) {
            throw ApiException.validation(
                    "items, service, tax and adjustmentMinor are only allowed for ITEMIZED expenses (this is " + type + ")");
        }
    }

    private static int bps(Integer value, String field) {
        if (value == null || value < 0 || value > MAX_BPS) {
            throw ApiException.validation(field + " must be between 0 and " + MAX_BPS);
        }
        return value;
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
