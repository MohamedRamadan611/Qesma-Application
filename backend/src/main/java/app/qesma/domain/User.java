package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * A signed-in person (spec 6). Rows are created by an atomic upsert in the repository, never by
 * {@code persist}, so concurrent first logins cannot create two users for one provider subject.
 */
@Entity
@Table(name = "users")
public class User {

    public static final String PROVIDER_GOOGLE = "GOOGLE";

    @Id
    private UUID id;

    @Column(name = "auth_provider", nullable = false, updatable = false)
    private String authProvider;

    @Column(name = "auth_subject", nullable = false, updatable = false)
    private String authSubject;

    @Column(name = "email")
    private String email;

    @Column(name = "display_name", nullable = false)
    private String displayName;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private Instant createdAt;

    protected User() {
    }

    public UUID getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
