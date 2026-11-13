package app.qesma.persistence;

import app.qesma.domain.Settlement;
import java.time.Instant;
import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SettlementRepository extends JpaRepository<Settlement, UUID> {

    /** A settlement is only reachable through its own group (a settlement id of another group is a 404). */
    @Query("select s from Settlement s where s.id = :id and s.groupId = :groupId")
    Optional<Settlement> findInGroup(@Param("id") UUID id, @Param("groupId") UUID groupId);

    @Query(value = """
            select s from Settlement s where s.groupId = :groupId and s.status in :statuses
            order by s.settledOn desc, s.createdAt desc, s.id desc
            """,
            countQuery = "select count(s) from Settlement s where s.groupId = :groupId and s.status in :statuses")
    Page<Settlement> findPage(@Param("groupId") UUID groupId, @Param("statuses") Collection<String> statuses,
                              Pageable pageable);

    /**
     * Optimistic state change: succeeds only while the row is still in {@code fromStatus}. Returns the number of rows
     * changed (0 = somebody else moved it first; the caller reloads and applies the idempotency rule). The persistence
     * context is cleared so the reload sees the committed state.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = """
            update settlements set status = :toStatus,
                confirmed_at = case when :toStatus = 'CONFIRMED' then :now else confirmed_at end,
                disputed_at = case when :toStatus = 'DISPUTED' then :now else disputed_at end,
                cancelled_at = case when :toStatus = 'CANCELLED' then :now else cancelled_at end
            where id = :id and group_id = :groupId and status = :fromStatus
            """, nativeQuery = true)
    int transition(@Param("id") UUID id, @Param("groupId") UUID groupId, @Param("fromStatus") String fromStatus,
                   @Param("toStatus") String toStatus, @Param("now") Instant now);

    /** Any settlement at all, whatever its status: used by the delete-group rule. */
    boolean existsByGroupId(UUID groupId);

    /** Delete-member rule (spec 7.10): the member is on either side of any settlement, whatever its status. */
    boolean existsByFromMemberIdOrToMemberId(UUID fromMemberId, UUID toMemberId);
}
