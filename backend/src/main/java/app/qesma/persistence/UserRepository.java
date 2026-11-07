package app.qesma.persistence;

import app.qesma.domain.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByAuthProviderAndAuthSubject(String authProvider, String authSubject);

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
