package app.qesma.persistence;

import java.time.Instant;

/** Sum of non-deleted expense totals and the creation time of the newest one (null when there are none). */
public record GroupTotals(Long totalSpentMinor, Instant lastExpenseAt) {
}
