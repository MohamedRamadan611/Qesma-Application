package app.qesma.persistence;

import app.qesma.domain.Expense;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExpenseRepository extends JpaRepository<Expense, UUID> {

    /** An expense is only reachable through its own group; soft-deleted ones are invisible. */
    @Query("select e from Expense e where e.id = :id and e.groupId = :groupId and e.deletedAt is null")
    Optional<Expense> findActive(@Param("id") UUID id, @Param("groupId") UUID groupId);

    /** Any expense at all, soft-deleted included: used by the delete-group rule (spec 3.1). */
    boolean existsByGroupId(UUID groupId);

    /** Any expense of the group, soft-deleted included: history stays readable after a delete. */
    boolean existsByIdAndGroupId(UUID id, UUID groupId);

    /**
     * One page of a group's expenses. The date filters are always present: the caller passes wide bounds when the
     * client gave none (a null parameter has no inferable SQL type).
     */
    @Query(value = """
            select e from Expense e
            where e.groupId = :groupId and e.deletedAt is null
              and e.expenseDate >= :from and e.expenseDate <= :to
            order by e.expenseDate desc, e.createdAt desc, e.id desc
            """,
            countQuery = """
            select count(e) from Expense e
            where e.groupId = :groupId and e.deletedAt is null
              and e.expenseDate >= :from and e.expenseDate <= :to
            """)
    Page<Expense> findPage(@Param("groupId") UUID groupId, @Param("from") LocalDate from,
                           @Param("to") LocalDate to, Pageable pageable);

    /** Same, restricted to expenses where the member is a payer or a participant. */
    @Query(value = """
            select e from Expense e
            where e.groupId = :groupId and e.deletedAt is null
              and e.expenseDate >= :from and e.expenseDate <= :to
              and (exists (select 1 from ExpensePayer p where p.expenseId = e.id and p.memberId = :memberId)
                   or exists (select 1 from ExpenseSplit s where s.expenseId = e.id and s.memberId = :memberId))
            order by e.expenseDate desc, e.createdAt desc, e.id desc
            """,
            countQuery = """
            select count(e) from Expense e
            where e.groupId = :groupId and e.deletedAt is null
              and e.expenseDate >= :from and e.expenseDate <= :to
              and (exists (select 1 from ExpensePayer p where p.expenseId = e.id and p.memberId = :memberId)
                   or exists (select 1 from ExpenseSplit s where s.expenseId = e.id and s.memberId = :memberId))
            """)
    Page<Expense> findPageForMember(@Param("groupId") UUID groupId, @Param("from") LocalDate from,
                                    @Param("to") LocalDate to, @Param("memberId") UUID memberId, Pageable pageable);

    @Query("""
            select new app.qesma.persistence.GroupTotals(coalesce(sum(e.totalMinor), 0L), max(e.createdAt))
            from Expense e where e.groupId = :groupId and e.deletedAt is null
            """)
    GroupTotals totals(@Param("groupId") UUID groupId);
}
