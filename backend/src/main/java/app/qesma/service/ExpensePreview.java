package app.qesma.service;

import java.util.List;

/**
 * Result of {@code POST /groups/{gid}/expenses/preview} (spec 8.4): the computed split, nothing saved.
 * The itemized-only totals are null for EQUAL/EXACT. {@code payersTotalMatches} lets the UI show a live warning.
 * {@code subtotalMinor} is the item sum before the discount (BSA2); {@code deliveryMinor} is the delivery charge (A180).
 */
public record ExpensePreview(long totalMinor, Long subtotalMinor, Long discountMinor, Long serviceMinor,
                             Long taxMinor, Long adjustmentMinor, List<ExpenseView.ShareView> members,
                             boolean payersTotalMatches, Long deliveryMinor) {

    /** Without delivery. */
    public ExpensePreview(long totalMinor, Long subtotalMinor, Long discountMinor, Long serviceMinor, Long taxMinor,
                          Long adjustmentMinor, List<ExpenseView.ShareView> members, boolean payersTotalMatches) {
        this(totalMinor, subtotalMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, members,
                payersTotalMatches, subtotalMinor == null ? null : 0L);
    }

    /** Without a discount. */
    public ExpensePreview(long totalMinor, Long subtotalMinor, Long serviceMinor, Long taxMinor, Long adjustmentMinor,
                          List<ExpenseView.ShareView> members, boolean payersTotalMatches) {
        this(totalMinor, subtotalMinor, subtotalMinor == null ? null : 0L, serviceMinor, taxMinor, adjustmentMinor,
                members, payersTotalMatches);
    }
}
