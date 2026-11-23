package app.qesma.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * An expense as returned by the API: payers and per-member shares ordered by member {@code sort_order}.
 * {@code items} and {@code charges} are null unless ITEMIZED; {@code periodFrom}/{@code periodTo} are null unless SHARES
 * with a period (A186).
 */
public record ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                          LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                          Instant createdAt, int version, List<ItemView> items, Charges charges,
                          String category, boolean paidFromPool, LocalDate periodFrom, LocalDate periodTo) {

    /** Without the SHARES period (BSA3). */
    public ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                       LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                       Instant createdAt, int version, List<ItemView> items, Charges charges,
                       String category, boolean paidFromPool) {
        this(id, groupId, title, splitType, totalMinor, expenseDate, payers, shares, createdAt, version, items,
                charges, category, paidFromPool, null, null);
    }

    /** Without category / pool flag (OTHER, false). */
    public ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                       LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                       Instant createdAt, int version, List<ItemView> items, Charges charges) {
        this(id, groupId, title, splitType, totalMinor, expenseDate, payers, shares, createdAt, version, items,
                charges, "OTHER", false);
    }

    /** EQUAL/EXACT shape. */
    public ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                       LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                       Instant createdAt, int version) {
        this(id, groupId, title, splitType, totalMinor, expenseDate, payers, shares, createdAt, version, null, null);
    }

    public record PayerView(UUID memberId, long amountMinor) {
    }

    /**
     * What one member owes. The six breakdown fields are set for ITEMIZED expenses only
     * (owed = items - discount + service + tax + delivery + adjustment) and are null otherwise. {@code shareUnits},
     * {@code presentFrom} and {@code presentTo} are set for SHARES only; the presence is the normalized one (both
     * bounds when the expense has a period, null without one; A195).
     */
    public record ShareView(UUID memberId, long owedMinor, Long itemsMinor, Long discountMinor, Long serviceMinor,
                            Long taxMinor, Long adjustmentMinor, Long deliveryMinor, Integer shareUnits,
                            LocalDate presentFrom, LocalDate presentTo) {

        /** Without the SHARES fields. */
        public ShareView(UUID memberId, long owedMinor, Long itemsMinor, Long discountMinor, Long serviceMinor,
                         Long taxMinor, Long adjustmentMinor, Long deliveryMinor) {
            this(memberId, owedMinor, itemsMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor,
                    deliveryMinor, null, null, null);
        }

        /** SHARES: owed with the units and the normalized presence. */
        public static ShareView shares(UUID memberId, long owedMinor, int shareUnits, LocalDate presentFrom,
                                       LocalDate presentTo) {
            return new ShareView(memberId, owedMinor, null, null, null, null, null, null, shareUnits, presentFrom,
                    presentTo);
        }

        public ShareView(UUID memberId, long owedMinor) {
            this(memberId, owedMinor, null, null, null, null, null, null);
        }

        /** ITEMIZED without delivery (A180): the delivery part is 0. */
        public ShareView(UUID memberId, long owedMinor, Long itemsMinor, Long discountMinor, Long serviceMinor,
                         Long taxMinor, Long adjustmentMinor) {
            this(memberId, owedMinor, itemsMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor,
                    itemsMinor == null ? null : 0L);
        }

        /** ITEMIZED without a discount. */
        public ShareView(UUID memberId, long owedMinor, Long itemsMinor, Long serviceMinor, Long taxMinor,
                         Long adjustmentMinor) {
            this(memberId, owedMinor, itemsMinor, itemsMinor == null ? null : 0L, serviceMinor, taxMinor,
                    adjustmentMinor);
        }
    }

    /** One bill line; {@code amountMinor} = quantity x unitAmountMinor (BSA2). */
    public record ItemView(UUID id, String name, int quantity, long unitAmountMinor, long amountMinor,
                           List<UUID> assigneeMemberIds) {
    }

    /**
     * ITEMIZED totals. {@code discount}/{@code service}/{@code tax} are null when that charge was not applied.
     * {@code subtotalMinor} is the item sum before the discount.
     */
    public record Charges(long subtotalMinor, DiscountCharge discount, ServiceCharge service, TaxCharge tax,
                          long adjustmentMinor, long deliveryMinor) {

        /** Without delivery (0). */
        public Charges(long subtotalMinor, DiscountCharge discount, ServiceCharge service, TaxCharge tax,
                       long adjustmentMinor) {
            this(subtotalMinor, discount, service, tax, adjustmentMinor, 0);
        }
    }

    /** {@code bps} is null when the discount was given as an amount. */
    public record DiscountCharge(Integer bps, long amountMinor) {
    }

    /** {@code bps} is null when the service charge was given as an amount. */
    public record ServiceCharge(Integer bps, long amountMinor) {
    }

    /** {@code bps} is null when the tax was given as an amount ({@code base} then sets only the weights). */
    public record TaxCharge(Integer bps, String base, long amountMinor) {
    }
}
