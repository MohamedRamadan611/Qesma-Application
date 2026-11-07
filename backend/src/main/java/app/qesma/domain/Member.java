package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/**
 * A person in a group's ledger. Members added by name are "ghosts" ({@code userId} null); the owner of the group is member #1 and linked to their account (B9).
 * {@code sortOrder} is assigned once from the group's counter and never changes or repeats (spec 7.10).
 */
@Entity
@Table(name = "members")
public class Member implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column(name = "group_id", nullable = false, updatable = false)
    private UUID groupId;

    @Column(name = "display_name", nullable = false)
    private String displayName;

    @Column(name = "user_id", updatable = false)
    private UUID userId;

    @Column(name = "sort_order", nullable = false, updatable = false)
    private int sortOrder;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Transient
    private boolean isNew = true;

    protected Member() {
    }

    public Member(UUID id, UUID groupId, String displayName, int sortOrder, Instant createdAt) {
        this.id = id;
        this.groupId = groupId;
        this.displayName = displayName;
        this.sortOrder = sortOrder;
        this.createdAt = createdAt;
    }

    /** The owner of a group as its first member, linked to their account (B9, Decision A53). */
    public static Member forOwner(UUID id, UUID groupId, String displayName, UUID ownerUserId, Instant createdAt) {
        Member m = new Member(id, groupId, displayName, 1, createdAt);
        m.userId = ownerUserId;
        return m;
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

    /** The linked account, or null for a ghost member. Never exposed by the API (only {@code isYou} is). */
    public UUID getUserId() {
        return userId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void rename(String newName) {
        this.displayName = newName;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
