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

    Optional<ExpenseGroup> findByIdAndOwnerUserId(UUID id, UUID ownerUserId);

    /** Row lock on the group: serializes member creation/rename/delete and group deletion. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select g from ExpenseGroup g where g.id = :id and g.ownerUserId = :owner")
    Optional<ExpenseGroup> findOwnedForUpdate(@Param("id") UUID id, @Param("owner") UUID owner);

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

    /** The owner's groups, newest first, with member counts from a single statement. */
    @Query(value = """
            select new app.qesma.persistence.GroupSummaryRow(g.id, g.name, g.type, g.currencyCode,
                   (select count(m) from Member m where m.groupId = g.id),
                   (select coalesce(sum(x.totalMinor), 0L) from Expense x
                     where x.groupId = g.id and x.deletedAt is null),
                   (select max(x.createdAt) from Expense x where x.groupId = g.id and x.deletedAt is null))
            from ExpenseGroup g
            where g.ownerUserId = :owner
            order by g.createdAt desc, g.id desc
            """,
            countQuery = "select count(g) from ExpenseGroup g where g.ownerUserId = :owner")
    Page<GroupSummaryRow> findSummaries(@Param("owner") UUID owner, Pageable pageable);
}
