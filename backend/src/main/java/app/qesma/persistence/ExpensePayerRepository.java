package app.qesma.persistence;

import app.qesma.domain.ExpensePayer;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExpensePayerRepository extends JpaRepository<ExpensePayer, ExpensePayer.Key> {

    /** One statement for a whole page of expenses (no N+1). */
    List<ExpensePayer> findByExpenseIdIn(Collection<UUID> expenseIds);

    /** Delete-member rule (spec 7.10): the member paid on any expense, soft-deleted ones included. */
    boolean existsByMemberId(UUID memberId);

    /** Edit: replaces the current-state rows (history lives in expense_revisions). Flushes pending changes first. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from ExpensePayer p where p.expenseId = :id")
    int deleteAllOf(@Param("id") UUID expenseId);
}
