package app.qesma.service;

import java.util.List;

/**
 * Result of {@code POST /groups/{gid}/expenses/preview} (spec 8.4): the computed split, nothing saved.
 * The itemized-only totals are null for EQUAL/EXACT. {@code payersTotalMatches} lets the UI show a live warning.
 */
public record ExpensePreview(long totalMinor, Long subtotalMinor, Long serviceMinor, Long taxMinor,
                             Long adjustmentMinor, List<ExpenseView.ShareView> members, boolean payersTotalMatches) {
}
