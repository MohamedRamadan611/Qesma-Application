package app.qesma.service;

import java.util.UUID;

/**
 * Answers "has this member ever taken part in a transaction?" for the delete rule of spec 7.10: a member
 * that appears as payer, split participant or item assignee of any expense, or in any settlement
 * (including soft-deleted ones), cannot be removed.
 *
 * <p>Extension point: B2 ships no implementation (nothing can reference a member yet). B4 and B7 provide a
 * bean that queries expenses and settlements; {@link MemberService} then uses it automatically.
 */
public interface MemberUsageChecker {

    /** Used when no other bean exists: no ledger tables yet, so no member is ever in use. */
    MemberUsageChecker UNUSED = (groupId, memberId) -> false;

    boolean isUsed(UUID groupId, UUID memberId);
}
