package app.qesma.persistence;

import app.qesma.domain.UserPassword;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserPasswordRepository extends JpaRepository<UserPassword, UUID> {

    /** Row lock (SELECT ... FOR UPDATE): concurrent sign-in attempts on one account update the failure counter in turn. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from UserPassword p where p.userId = :userId")
    Optional<UserPassword> findByUserIdForUpdate(@Param("userId") UUID userId);
}
