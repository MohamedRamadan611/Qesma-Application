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

    /** A member is only reachable through the group it belongs to. */
    Optional<Member> findByIdAndGroupId(UUID id, UUID groupId);

    /**
     * Case-insensitive name check, same {@code lower()} as the unique index. Pass a random/zero UUID as
     * {@code excludeId} when there is no member to exclude (a null parameter has no inferable SQL type).
     */
    @Query("select count(m) > 0 from Member m where m.groupId = :groupId "
            + "and lower(m.displayName) = lower(:name) and m.id <> :excludeId")
    boolean nameTaken(@Param("groupId") UUID groupId, @Param("name") String name, @Param("excludeId") UUID excludeId);

    @Modifying
    @Query("delete from Member m where m.groupId = :groupId")
    int deleteAllByGroup(@Param("groupId") UUID groupId);
}
