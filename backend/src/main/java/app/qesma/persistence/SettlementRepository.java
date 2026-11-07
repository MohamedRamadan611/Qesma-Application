package app.qesma.persistence;

import app.qesma.domain.Settlement;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SettlementRepository extends JpaRepository<Settlement, UUID> {

    /** A settlement is only reachable through its own group; soft-deleted ones are invisible. */
    @Query("select s from Settlement s where s.id = :id and s.groupId = :groupId and s.deletedAt is null")
    Optional<Settlement> findActive(@Param("id") UUID id, @Param("groupId") UUID groupId);

    @Query(value = """
            select s from Settlement s where s.groupId = :groupId and s.deletedAt is null
            order by s.settledOn desc, s.createdAt desc, s.id desc
            """,
            countQuery = "select count(s) from Settlement s where s.groupId = :groupId and s.deletedAt is null")
    Page<Settlement> findPage(@Param("groupId") UUID groupId, Pageable pageable);

    /** Any settlement at all, soft-deleted included: used by the delete-group rule. */
    boolean existsByGroupId(UUID groupId);

    /** Delete-member rule (spec 7.10): the member is on either side of any settlement, soft-deleted ones included. */
    boolean existsByFromMemberIdOrToMemberId(UUID fromMemberId, UUID toMemberId);
}
