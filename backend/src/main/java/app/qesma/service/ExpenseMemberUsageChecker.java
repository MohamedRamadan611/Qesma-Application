package app.qesma.service;

import app.qesma.persistence.ExpenseItemAssigneeRepository;
import app.qesma.persistence.ExpensePayerRepository;
import app.qesma.persistence.ExpenseSplitRepository;
import app.qesma.persistence.SettlementRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Spec 7.10: a member that is a payer, participant or item assignee of any expense, or on either side of any
 * settlement (soft-deleted ones included), cannot be removed. An assignee counts even when rounding left them
 * owing 0.
 */
@Component
public class ExpenseMemberUsageChecker implements MemberUsageChecker {

    private final ExpensePayerRepository payers;
    private final ExpenseSplitRepository splits;
    private final ExpenseItemAssigneeRepository assignees;
    private final SettlementRepository settlements;

    public ExpenseMemberUsageChecker(ExpensePayerRepository payers, ExpenseSplitRepository splits,
                                     ExpenseItemAssigneeRepository assignees, SettlementRepository settlements) {
        this.payers = payers;
        this.splits = splits;
        this.assignees = assignees;
        this.settlements = settlements;
    }

    @Override
    public boolean isUsed(UUID groupId, UUID memberId) {
        return payers.existsByMemberId(memberId) || splits.existsByMemberId(memberId)
                || assignees.existsByMemberId(memberId)
                || settlements.existsByFromMemberIdOrToMemberId(memberId, memberId);
    }
}
