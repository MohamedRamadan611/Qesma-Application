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

    /** OWNER, ADMIN or MEMBER (V12). Authorization reads it through {@code GroupAccessService} only. */
    @Column(name = "role", nullable = false)
    private String role = ROLE_MEMBER;

    /** ACTIVE or LEFT (V12). A LEFT member has no access to the group but stays in its history. */
    @Column(name = "status", nullable = false)
    private String status = STATUS_ACTIVE;

    @Column(name = "joined_at")
    private Instant joinedAt;

    @Column(name = "left_at")
    private Instant leftAt;

    public static final String ROLE_OWNER = "OWNER";
    public static final String ROLE_ADMIN = "ADMIN";
    public static final String ROLE_MEMBER = "MEMBER";
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_LEFT = "LEFT";

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
        this.joinedAt = createdAt;
    }

    /** The owner of a group as its first member, linked to their account and holding the OWNER role (A53, A66). */
    public static Member forOwner(UUID id, UUID groupId, String displayName, UUID ownerUserId, Instant createdAt) {
        Member m = new Member(id, groupId, displayName, 1, createdAt);
        m.userId = ownerUserId;
        m.role = ROLE_OWNER;
        return m;
    }

    /** A person who joined through an invitation: linked to their account from the start, role MEMBER (B11). */
    public static Member forJoined(UUID id, UUID groupId, String displayName, int sortOrder, UUID userId,
                                   Instant now) {
        Member m = new Member(id, groupId, displayName, sortOrder, now);
        m.userId = userId;
        return m;
    }

    public String getRole() {
        return role;
    }

    public String getStatus() {
        return status;
    }

    public Instant getJoinedAt() {
        return joinedAt;
    }

    public Instant getLeftAt() {
        return leftAt;
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

    /** Leaves the group: the row, its link and its history stay; the role drops to MEMBER (least privilege on return). */
    public void markLeft(Instant now) {
        this.status = STATUS_LEFT;
        this.leftAt = now;
        this.role = ROLE_MEMBER;
    }

    /** Back to ACTIVE (an admin reactivated the member). */
    public void reactivate() {
        this.status = STATUS_ACTIVE;
        this.leftAt = null;
    }

    /** Back to ACTIVE through a new invite: counts as a new join. */
    public void rejoin(Instant now) {
        reactivate();
        this.joinedAt = now;
    }

    /** ADMIN or MEMBER only; ownership moves through the transfer queries, never through this method. */
    public void changeRole(String newRole) {
        if (!ROLE_ADMIN.equals(newRole) && !ROLE_MEMBER.equals(newRole)) {
            throw new IllegalArgumentException("Role must be ADMIN or MEMBER");
        }
        this.role = newRole;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
