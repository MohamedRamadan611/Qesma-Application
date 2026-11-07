package app.qesma.persistence;

import java.util.UUID;

/** One row of the group list: the group plus its member count, computed in the same query (no N+1). */
public record GroupSummaryRow(UUID id, String name, String type, String currencyCode, Long memberCount) {
}
