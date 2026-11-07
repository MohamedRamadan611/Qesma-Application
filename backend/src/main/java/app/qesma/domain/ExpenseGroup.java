package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * A group of people sharing expenses (spec 6). Rows are inserted by a native statement (so the database
 * defaults decide version/timestamps) and read/updated through JPA. {@code member_seq} is read-only here:
 * it is advanced by a dedicated statement so that adding a member never bumps {@code version} (the ETag).
 */
@Entity
@Table(name = "expense_groups")
public class ExpenseGroup {

    @Id
    private UUID id;

    @Column(name = "owner_user_id", nullable = false, updatable = false)
    private UUID ownerUserId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "type", nullable = false)
    private String type;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "currency_code", nullable = false, updatable = false, length = 3)
    private String currencyCode;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false, insertable = false)
    private Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    private int version;

    @Column(name = "member_seq", nullable = false, insertable = false, updatable = false)
    private int memberSeq;

    protected ExpenseGroup() {
    }

    public UUID getId() {
        return id;
    }

    public UUID getOwnerUserId() {
        return ownerUserId;
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public String getCurrencyCode() {
        return currencyCode;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public int getVersion() {
        return version;
    }

    public int getMemberSeq() {
        return memberSeq;
    }

    /** Applies an edit; the caller decides whether anything actually changed (to avoid a pointless version bump). */
    public void edit(String newName, String newType, Instant now) {
        this.name = newName;
        this.type = newType;
        this.updatedAt = now;
    }
}
