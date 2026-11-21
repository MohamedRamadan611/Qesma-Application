package app.qesma.service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * The create/preview-expense request body (spec 8.4). Wrapper types so a missing field is detected and reported
 * as a validation error rather than silently becoming 0. Bound directly from JSON; it has no fields a client
 * could use to set ids, owner, version or derived amounts.
 *
 * @param splitType            EQUAL, EXACT or ITEMIZED
 * @param totalMinor           required for EQUAL/EXACT; for ITEMIZED optional (the engine computes it) and, when
 *                             given, must equal the computed total
 * @param participantMemberIds EQUAL only; null means "all current members" (resolved and stored explicitly)
 * @param shares               EXACT only
 * @param items                ITEMIZED only
 * @param service              ITEMIZED only; absent = no service charge
 * @param tax                  ITEMIZED only; absent = no tax
 * @param adjustmentMinor      ITEMIZED only; signed, absent = 0
 * @param category             optional expense category; absent = OTHER
 * @param paidFromPool         optional; true only when the group has a treasurer who is the single payer (BSA1)
 * @param discount             ITEMIZED only; absent = no discount (BSA2, A171)
 * @param deliveryMinor        ITEMIZED only; absent = no delivery (A180): outside discount, service and tax
 */
public record ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                             List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares,
                             List<ItemInput> items, ServiceInput service, TaxInput tax, Long adjustmentMinor,
                             String category, Boolean paidFromPool, DiscountInput discount, Long deliveryMinor) {

    /** Without the delivery charge. */
    public ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                          List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares,
                          List<ItemInput> items, ServiceInput service, TaxInput tax, Long adjustmentMinor,
                          String category, Boolean paidFromPool, DiscountInput discount) {
        this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items, service, tax,
                adjustmentMinor, category, paidFromPool, discount, null);
    }

    /** Without the BSA2 discount. */
    public ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                          List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares,
                          List<ItemInput> items, ServiceInput service, TaxInput tax, Long adjustmentMinor,
                          String category, Boolean paidFromPool) {
        this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items, service, tax,
                adjustmentMinor, category, paidFromPool, null);
    }

    /** Without category / paidFromPool (defaults OTHER and false). */
    public ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                          List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares,
                          List<ItemInput> items, ServiceInput service, TaxInput tax, Long adjustmentMinor) {
        this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, items, service, tax,
                adjustmentMinor, null, null);
    }

    /** EQUAL/EXACT shape (no itemized fields). */
    public ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                          List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares) {
        this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, null, null, null, null);
    }

    public record PayerInput(UUID memberId, Long amountMinor) {
    }

    public record ShareInput(UUID memberId, Long amountMinor) {
    }

    /**
     * One bill line: either legacy {@code amountMinor} (quantity 1) or {@code unitAmountMinor} with an optional
     * {@code quantity} 1..999 (default 1), never both (A172).
     */
    public record ItemInput(String name, Long amountMinor, Long unitAmountMinor, Integer quantity,
                            List<UUID> assigneeMemberIds) {

        /** Legacy line given by its amount. */
        public ItemInput(String name, Long amountMinor, List<UUID> assigneeMemberIds) {
            this(name, amountMinor, null, null, assigneeMemberIds);
        }
    }

    /** {@code bps} (0..10000) or {@code amountMinor} (>= 1), exactly one (A173). */
    public record ServiceInput(Integer bps, Long amountMinor) {

        public ServiceInput(Integer bps) {
            this(bps, null);
        }
    }

    /**
     * {@code bps} or {@code amountMinor}, exactly one (A173). {@code base} is SUBTOTAL or SUBTOTAL_PLUS_SERVICE; null
     * means SUBTOTAL_PLUS_SERVICE (Decision A1). In the amount form the base only sets the allocation weights.
     */
    public record TaxInput(Integer bps, Long amountMinor, String base) {

        public TaxInput(Integer bps, String base) {
            this(bps, null, base);
        }
    }

    /** One discount on the whole bill: {@code bps} (1..9999) or {@code amountMinor} (>= 1), exactly one (A171). */
    public record DiscountInput(Integer bps, Long amountMinor) {
    }
}
