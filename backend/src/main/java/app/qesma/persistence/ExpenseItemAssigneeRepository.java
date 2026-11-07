package app.qesma.persistence;

import app.qesma.domain.ExpenseItemAssignee;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExpenseItemAssigneeRepository extends JpaRepository<ExpenseItemAssignee, ExpenseItemAssignee.Key> {

    /** One statement for all items of a page of expenses (no N+1). */
    List<ExpenseItemAssignee> findByItemIdIn(Collection<UUID> itemIds);

    /** Delete-member rule (spec 7.10): the member is assigned to an item of any expense. */
    boolean existsByMemberId(UUID memberId);

    /** Edit: replaces the current-state rows (history lives in expense_revisions). Flushes pending changes first. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from ExpenseItemAssignee a where a.itemId in (select i.id from ExpenseItem i where i.expenseId = :id)")
    int deleteAllOf(@Param("id") UUID expenseId);
}
