package app.qesma.persistence;

import java.time.Instant;
import java.util.UUID;

/** One row of the group list: the group plus member count and expense totals, computed in the same query (no N+1). */
public record GroupSummaryRow(UUID id, String name, String type, String currencyCode, Long memberCount,
                              Long totalSpentMinor, Instant lastExpenseAt) {
}
