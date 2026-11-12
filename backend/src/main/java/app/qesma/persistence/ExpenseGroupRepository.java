package app.qesma.persistence;

import app.qesma.domain.ExpenseGroup;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExpenseGroupRepository extends JpaRepository<ExpenseGroup, UUID> {

    /**
     * The group, only if {@code user} has an ACTIVE member in it (B10, Decision A65): anybody else, and a LEFT member,
     * gets an empty result, which the caller turns into the same 404 as for an unknown id.
     */
    @Query("""
            select g from ExpenseGroup g where g.id = :id and exists
              (select 1 from Member m where m.groupId = g.id and m.userId = :user and m.status = 'ACTIVE')
            """)
    Optional<ExpenseGroup> findReachable(@Param("id") UUID id, @Param("user") UUID user);

    /**
     * Row lock on a group by id with NO membership check: only for the invitation paths, where the invite code is the
     * capability and the caller is not a member yet. Always taken after the invite row (lock order: invite, group).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select g from ExpenseGroup g where g.id = :id")
    Optional<ExpenseGroup> findByIdForUpdate(@Param("id") UUID id);

    /**
     * Row lock on the group, taken only when the caller is an ACTIVE member (a stranger locks nothing): serializes
     * member creation/rename/delete, ledger writes and group deletion.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select g from ExpenseGroup g where g.id = :id and exists
              (select 1 from Member m where m.groupId = g.id and m.userId = :user and m.status = 'ACTIVE')
            """)
    Optional<ExpenseGroup> findReachableForUpdate(@Param("id") UUID id, @Param("user") UUID user);

    /** Database defaults supply version (1), timestamps and member_seq (0). */
    @Modifying
    @Query(nativeQuery = true, value = """
            INSERT INTO expense_groups (id, owner_user_id, name, type, currency_code)
            VALUES (:id, :owner, :name, :type, :currency)
            """)
    int insertGroup(@Param("id") UUID id, @Param("owner") UUID owner, @Param("name") String name,
                    @Param("type") String type, @Param("currency") String currency);

    /** Advances the member counter without touching version (the caller must hold the row lock). */
    @Modifying
    @Query(nativeQuery = true, value = "UPDATE expense_groups SET member_seq = :seq WHERE id = :id")
    int setMemberSeq(@Param("id") UUID id, @Param("seq") int seq);

    /**
     * The groups where {@code user} has an ACTIVE member, newest first, with member counts, totals and the caller's
     * role from a single statement: membership is a join predicate here, never a per-group check (no N+1).
     */
    @Query(value = """
            select new app.qesma.persistence.GroupSummaryRow(g.id, g.name, g.type, g.currencyCode,
                   (select count(m) from Member m where m.groupId = g.id and m.status = 'ACTIVE'),
                   (select coalesce(sum(x.totalMinor), 0L) from Expense x
                     where x.groupId = g.id and x.deletedAt is null),
                   (select max(x.createdAt) from Expense x where x.groupId = g.id and x.deletedAt is null),
                   me.role)
            from ExpenseGroup g join Member me on me.groupId = g.id and me.userId = :user and me.status = 'ACTIVE'
            order by g.createdAt desc, g.id desc
            """,
            countQuery = """
            select count(g) from ExpenseGroup g
            join Member me on me.groupId = g.id and me.userId = :user and me.status = 'ACTIVE'
            """)
    Page<GroupSummaryRow> findSummaries(@Param("user") UUID user, Pageable pageable);
}
