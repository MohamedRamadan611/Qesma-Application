package app.qesma.persistence;

import app.qesma.domain.ExpenseItem;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExpenseItemRepository extends JpaRepository<ExpenseItem, UUID> {

    /** One statement for a whole page of expenses (no N+1). */
    List<ExpenseItem> findByExpenseIdIn(Collection<UUID> expenseIds);

    /** Edit: replaces the current-state rows (history lives in expense_revisions). Flushes pending changes first. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from ExpenseItem i where i.expenseId = :id")
    int deleteAllOf(@Param("id") UUID expenseId);
}
