package app.qesma.persistence;

import app.qesma.domain.User;
import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, UUID> {

    /** Row lock on the account (SELECT ... FOR UPDATE): account deletion, concurrent with sign-in and handle writes. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.id = :id")
    Optional<User> findByIdForUpdate(@Param("id") UUID id);

    /**
     * Shared row lock on a NOT deleted account (SELECT ... FOR SHARE), empty if it is deleted or unknown. Sign-in and
     * refresh take it before they issue a token, so they wait for a running account deletion (which holds the row
     * exclusively), then see it deleted and refuse: no session row can appear after the purge (B17, A119).
     */
    @Query(nativeQuery = true, value = "SELECT id FROM users WHERE id = :id AND deleted_at IS NULL FOR SHARE")
    java.util.List<UUID> lockActive(@Param("id") UUID id);

    /** Has this account been deleted (B17)? A primary-key probe, run once per authenticated request. */
    @Query("select count(u) > 0 from User u where u.id = :id and u.deletedAt is not null")
    boolean isDeleted(@Param("id") UUID id);

    /**
     * Anonymises the account in place (B17, A114): fixed display name, no email, a random tombstone as the subject (it
     * frees the original address/username/Google subject; it contains ':', so no sign-in can match it).
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(nativeQuery = true, value = """
            UPDATE users SET display_name = 'Deleted user', auth_subject = :tombstone, email = NULL,
                   email_verified_at = NULL, deleted_at = :now
            WHERE id = :id AND deleted_at IS NULL
            """)
    int anonymise(@Param("id") UUID id, @Param("tombstone") String tombstone, @Param("now") java.time.Instant now);

    Optional<User> findByAuthProviderAndAuthSubject(String authProvider, String authSubject);

    /** Password accounts that have this address on file (for the emailed links; none exist for username-only accounts). */
    java.util.List<User> findAllByAuthProviderAndEmailIgnoreCase(String authProvider, String email);

    /** Is this address already used by an account of that provider (case-insensitive)? */
    boolean existsByAuthProviderAndEmailIgnoreCase(String authProvider, String email);

    /** Records that the address was proven (keeps the first time). */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update User u set u.emailVerifiedAt = coalesce(u.emailVerifiedAt, :now) where u.id = :id")
    int markEmailVerified(@Param("id") UUID id, @Param("now") java.time.Instant now);

    /**
     * Race-safe create: the UNIQUE (auth_provider, auth_subject) constraint is the arbiter. A concurrent
     * second insert blocks until the first commits, then does nothing; the caller re-reads the row.
     */
    @Modifying
    @Query(nativeQuery = true, value = """
            INSERT INTO users (id, auth_provider, auth_subject, email, display_name)
            VALUES (:id, :provider, :subject, :email, :displayName)
            ON CONFLICT (auth_provider, auth_subject) DO NOTHING
            """)
    int insertIfAbsent(@Param("id") UUID id, @Param("provider") String provider, @Param("subject") String subject,
                       @Param("email") String email, @Param("displayName") String displayName);
}
