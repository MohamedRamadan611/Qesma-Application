package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/**
 * A recorded real-world payment {@code from -> to} (spec 7.8). Never hard-deleted: {@link #markDeleted} sets
 * {@code deleted_at} and balances then ignore it.
 */
@Entity
@Table(name = "settlements")
public class Settlement implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column(name = "group_id", nullable = false, updatable = false)
    private UUID groupId;

    @Column(name = "from_member_id", nullable = false, updatable = false)
    private UUID fromMemberId;

    @Column(name = "to_member_id", nullable = false, updatable = false)
    private UUID toMemberId;

    @Column(name = "amount_minor", nullable = false, updatable = false)
    private long amountMinor;

    @Column(name = "settled_on", nullable = false, updatable = false)
    private LocalDate settledOn;

    @Column(name = "note", updatable = false)
    private String note;

    @Column(name = "created_by_user_id", nullable = false, updatable = false)
    private UUID createdByUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Transient
    private boolean isNew = true;

    protected Settlement() {
    }

    public Settlement(UUID id, UUID groupId, UUID fromMemberId, UUID toMemberId, long amountMinor,
                      LocalDate settledOn, String note, UUID createdByUserId, Instant createdAt) {
        this.id = id;
        this.groupId = groupId;
        this.fromMemberId = fromMemberId;
        this.toMemberId = toMemberId;
        this.amountMinor = amountMinor;
        this.settledOn = settledOn;
        this.note = note;
        this.createdByUserId = createdByUserId;
        this.createdAt = createdAt;
    }

    public void markDeleted(Instant now) {
        this.deletedAt = now;
    }

    @Override
    public UUID getId() {
        return id;
    }

    @Override
    public boolean isNew() {
        return isNew;
    }

    @PostLoad
    @PostPersist
    void markNotNew() {
        this.isNew = false;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public UUID getFromMemberId() {
        return fromMemberId;
    }

    public UUID getToMemberId() {
        return toMemberId;
    }

    public long getAmountMinor() {
        return amountMinor;
    }

    public LocalDate getSettledOn() {
        return settledOn;
    }

    public String getNote() {
        return note;
    }

    public UUID getCreatedByUserId() {
        return createdByUserId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }
}
