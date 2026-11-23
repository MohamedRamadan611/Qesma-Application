package app.qesma.service;

import java.util.List;

/**
 * Result of {@code POST /groups/{gid}/expenses/preview} (spec 8.4): the computed split, nothing saved.
 * The itemized-only totals are null for EQUAL/EXACT. {@code payersTotalMatches} lets the UI show a live warning.
 * {@code subtotalMinor} is the item sum before the discount (BSA2); {@code deliveryMinor} is the delivery charge (A180).

 * {@code periodFrom}/{@code periodTo} echo the SHARES period (null otherwise; A186).
 */
public record ExpensePreview(long totalMinor, Long subtotalMinor, Long discountMinor, Long serviceMinor,
                             Long taxMinor, Long adjustmentMinor, List<ExpenseView.ShareView> members,
                             boolean payersTotalMatches, Long deliveryMinor, java.time.LocalDate periodFrom,
                             java.time.LocalDate periodTo) {

    /** Without the SHARES period. */
    public ExpensePreview(long totalMinor, Long subtotalMinor, Long discountMinor, Long serviceMinor, Long taxMinor,
                          Long adjustmentMinor, List<ExpenseView.ShareView> members, boolean payersTotalMatches,
                          Long deliveryMinor) {
        this(totalMinor, subtotalMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, members,
                payersTotalMatches, deliveryMinor, null, null);
    }

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
