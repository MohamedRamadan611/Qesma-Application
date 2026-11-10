package app.qesma.persistence;

import app.qesma.domain.EmailToken;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EmailTokenRepository extends JpaRepository<EmailToken, UUID> {

    /**
     * Uses a token exactly once: one statement marks it used and returns its user only if it was unused, of this
     * purpose and not expired, so two parallel uses give one success. Empty = unknown, used, expired or wrong purpose.
     */
    @Query(nativeQuery = true, value = """
            UPDATE email_tokens SET used_at = :now
            WHERE token_hash = :hash AND purpose = :purpose AND used_at IS NULL AND expires_at > :now
            RETURNING user_id
            """)
    List<UUID> consume(@Param("hash") byte[] hash, @Param("purpose") String purpose, @Param("now") Instant now);

    /** A new link replaces older unused ones of the same kind. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update EmailToken t set t.usedAt = :now where t.userId = :userId and t.purpose = :purpose and t.usedAt is null")
    int invalidateOpen(@Param("userId") UUID userId, @Param("purpose") String purpose, @Param("now") Instant now);
}
