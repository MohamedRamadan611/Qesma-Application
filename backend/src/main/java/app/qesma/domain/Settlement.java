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
 * A payment {@code from -> to} between two members (spec 7.8, PHASE2_SPEC section 6). Never deleted: it ends as
 * CANCELLED and stays in the history. Only CONFIRMED settlements move balances. Every column is insert-only here: a
 * status change is a conditional {@code UPDATE ... WHERE status = ?} in {@code SettlementRepository.transition}, so two
 * concurrent transitions cannot both succeed. (The legacy {@code deleted_at} column is no longer mapped or written.)
 */
@Entity
@Table(name = "settlements")
public class Settlement implements Persistable<UUID> {

    public static final String PENDING = "PENDING";
    public static final String CONFIRMED = "CONFIRMED";
    public static final String DISPUTED = "DISPUTED";
    public static final String CANCELLED = "CANCELLED";

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

    @Column(name = "created_by_member_id", updatable = false)
    private UUID createdByMemberId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "status", nullable = false, updatable = false)
    private String status;

    @Column(name = "declared_at", nullable = false, updatable = false)
    private Instant declaredAt;

    @Column(name = "confirmed_at", updatable = false)
    private Instant confirmedAt;

    @Column(name = "disputed_at", updatable = false)
    private Instant disputedAt;

    @Column(name = "cancelled_at", updatable = false)
    private Instant cancelledAt;

    @Column(name = "recorded_by_admin", nullable = false, updatable = false)
    private boolean recordedByAdmin;

    @Transient
    private boolean isNew = true;

    protected Settlement() {
    }

    /** A new settlement: PENDING (a declaration) or CONFIRMED (recorded by the receiver or on behalf by a manager). */
    public Settlement(UUID id, UUID groupId, UUID fromMemberId, UUID toMemberId, long amountMinor,
                      LocalDate settledOn, String note, UUID createdByUserId, UUID createdByMemberId,
                      Instant createdAt, boolean confirmed, boolean recordedByAdmin) {
        this.id = id;
        this.groupId = groupId;
        this.fromMemberId = fromMemberId;
        this.toMemberId = toMemberId;
        this.amountMinor = amountMinor;
        this.settledOn = settledOn;
        this.note = note;
        this.createdByUserId = createdByUserId;
        this.createdByMemberId = createdByMemberId;
        this.createdAt = createdAt;
        this.declaredAt = createdAt;
        this.status = confirmed ? CONFIRMED : PENDING;
        this.confirmedAt = confirmed ? createdAt : null;
        this.recordedByAdmin = recordedByAdmin;
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

    public UUID getCreatedByMemberId() {
        return createdByMemberId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public String getStatus() {
        return status;
    }

    public Instant getDeclaredAt() {
        return declaredAt;
    }

    public Instant getConfirmedAt() {
        return confirmedAt;
    }

    public Instant getDisputedAt() {
        return disputedAt;
    }

    public Instant getCancelledAt() {
        return cancelledAt;
    }

    public boolean isRecordedByAdmin() {
        return recordedByAdmin;
    }
}
