package app.qesma.service;

import java.util.UUID;

/**
 * Answers "does this group have any expenses or settlements?" (soft-deleted ones included) for the delete
 * rule of spec 3.1. Extension point: B4 and B7 provide a bean; until then no group holds ledger data.
 */
public interface GroupUsageChecker {

    GroupUsageChecker EMPTY = groupId -> false;

    boolean hasLedgerData(UUID groupId);
}
