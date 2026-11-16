package app.qesma.persistence;

import app.qesma.domain.RefreshToken;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    /**
     * The owner of a token, read without a lock and as a scalar on purpose: rotation locks the user row first and only
     * then the token, and an entity loaded here would be served stale by the locked read that follows.
     */
    @Query("select t.userId from RefreshToken t where t.tokenHash = :hash")
    Optional<UUID> findUserIdByTokenHash(@Param("hash") byte[] hash);

    /** Row lock (SELECT ... FOR UPDATE) so two simultaneous uses of one token are serialized. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from RefreshToken t where t.tokenHash = :hash")
    Optional<RefreshToken> findByTokenHashForUpdate(@Param("hash") byte[] hash);

    /** Ends every login session of a user (password changed or reset). */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update RefreshToken t set t.revokedAt = :now where t.userId = :userId and t.revokedAt is null")
    int revokeAllOfUser(@Param("userId") UUID userId, @Param("now") Instant now);

    /** Account deletion (B17): the rows go, not just the revocation (they only identify a session of the user). */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from RefreshToken t where t.userId = :userId")
    int deleteAllOfUser(@Param("userId") UUID userId);

    /** Revokes every still-active token of a login session. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update RefreshToken t set t.revokedAt = :now where t.familyId = :familyId and t.revokedAt is null")
    int revokeFamily(@Param("familyId") UUID familyId, @Param("now") Instant now);
}
