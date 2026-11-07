package app.qesma.service;

import app.qesma.persistence.ExpenseRepository;
import app.qesma.persistence.SettlementRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * Spec 3.1: a group that has any expense or settlement (soft-deleted ones included, the ledger is never erased)
 * cannot be deleted.
 */
@Component
public class ExpenseGroupUsageChecker implements GroupUsageChecker {

    private final ExpenseRepository expenses;
    private final SettlementRepository settlements;

    public ExpenseGroupUsageChecker(ExpenseRepository expenses, SettlementRepository settlements) {
        this.expenses = expenses;
        this.settlements = settlements;
    }

    @Override
    public boolean hasLedgerData(UUID groupId) {
        return expenses.existsByGroupId(groupId) || settlements.existsByGroupId(groupId);
    }
}
