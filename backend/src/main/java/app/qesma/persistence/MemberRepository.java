package app.qesma.persistence;

import app.qesma.domain.Member;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MemberRepository extends JpaRepository<Member, UUID> {

    List<Member> findByGroupIdOrderBySortOrderAsc(UUID groupId);

    /** The caller's own ACTIVE member in a group (at most one: unique index on group_id, user_id). */
    @Query("select m from Member m where m.groupId = :groupId and m.userId = :userId and m.status = 'ACTIVE'")
    Optional<Member> findActiveLink(@Param("groupId") UUID groupId, @Param("userId") UUID userId);

    /** A member is only reachable through the group it belongs to. */
    Optional<Member> findByIdAndGroupId(UUID id, UUID groupId);

    /**
     * Case-insensitive name check, same {@code lower()} as the unique index. Pass a random/zero UUID as
     * {@code excludeId} when there is no member to exclude (a null parameter has no inferable SQL type).
     */
    @Query("select count(m) > 0 from Member m where m.groupId = :groupId "
            + "and lower(m.displayName) = lower(:name) and m.id <> :excludeId")
    boolean nameTaken(@Param("groupId") UUID groupId, @Param("name") String name, @Param("excludeId") UUID excludeId);

    /** Does this account already have an ACTIVE member in the group? */
    @Query("select count(m) > 0 from Member m where m.groupId = :groupId and m.userId = :userId and m.status = 'ACTIVE'")
    boolean hasActiveLink(@Param("groupId") UUID groupId, @Param("userId") UUID userId);

    /**
     * Links an account to a member nobody has claimed yet. The condition makes the claim atomic: of two parallel claims
     * exactly one updates a row. Zero rows means somebody else got there first (or the member is not in this group).
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(nativeQuery = true, value = "UPDATE members SET user_id = :userId, joined_at = :now "
            + "WHERE id = :memberId AND group_id = :groupId AND user_id IS NULL")
    int claim(@Param("memberId") UUID memberId, @Param("groupId") UUID groupId, @Param("userId") UUID userId,
              @Param("now") java.time.Instant now);

    /** Detaches the account (the member and its history stay). The owner's member is never unlinked. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(nativeQuery = true, value = "UPDATE members SET user_id = NULL, role = 'MEMBER' "
            + "WHERE id = :memberId AND group_id = :groupId AND user_id IS NOT NULL AND role <> 'OWNER'")
    int unlink(@Param("memberId") UUID memberId, @Param("groupId") UUID groupId);

    @Modifying
    @Query("delete from Member m where m.groupId = :groupId")
    int deleteAllByGroup(@Param("groupId") UUID groupId);
}
