package app.qesma.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * An expense as returned by the API: payers and per-member shares ordered by member {@code sort_order}.
 * {@code items} and {@code charges} are null for EQUAL and EXACT expenses.
 */
public record ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                          LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                          Instant createdAt, int version, List<ItemView> items, Charges charges) {

    /** EQUAL/EXACT shape. */
    public ExpenseView(UUID id, UUID groupId, String title, String splitType, long totalMinor,
                       LocalDate expenseDate, List<PayerView> payers, List<ShareView> shares,
                       Instant createdAt, int version) {
        this(id, groupId, title, splitType, totalMinor, expenseDate, payers, shares, createdAt, version, null, null);
    }

    public record PayerView(UUID memberId, long amountMinor) {
    }

    /**
     * What one member owes. The four breakdown fields are set for ITEMIZED expenses only
     * (owed = items + service + tax + adjustment) and are null for EQUAL/EXACT.
     */
    public record ShareView(UUID memberId, long owedMinor, Long itemsMinor, Long serviceMinor, Long taxMinor,
                            Long adjustmentMinor) {

        public ShareView(UUID memberId, long owedMinor) {
            this(memberId, owedMinor, null, null, null, null);
        }
    }

    public record ItemView(UUID id, String name, long amountMinor, List<UUID> assigneeMemberIds) {
    }

    /** ITEMIZED totals. {@code service}/{@code tax} are null when that charge was not applied. */
    public record Charges(long subtotalMinor, ServiceCharge service, TaxCharge tax, long adjustmentMinor) {
    }

    public record ServiceCharge(int bps, long amountMinor) {
    }

    public record TaxCharge(int bps, String base, long amountMinor) {
    }
}
