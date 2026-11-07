package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/** A member who shares an item of an itemized bill. */
@Entity
@Table(name = "expense_item_assignees")
@IdClass(ExpenseItemAssignee.Key.class)
public class ExpenseItemAssignee implements Persistable<ExpenseItemAssignee.Key> {

    @Id
    @Column(name = "item_id", nullable = false, updatable = false)
    private UUID itemId;

    @Id
    @Column(name = "member_id", nullable = false, updatable = false)
    private UUID memberId;

    @Transient
    private boolean isNew = true;

    protected ExpenseItemAssignee() {
    }

    public ExpenseItemAssignee(UUID itemId, UUID memberId) {
        this.itemId = itemId;
        this.memberId = memberId;
    }

    @Override
    public Key getId() {
        return new Key(itemId, memberId);
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

    public UUID getItemId() {
        return itemId;
    }

    public UUID getMemberId() {
        return memberId;
    }

    /** Composite primary key (item_id, member_id). */
    public static class Key implements Serializable {
        private static final long serialVersionUID = 1L;

        private UUID itemId;
        private UUID memberId;

        protected Key() {
        }

        public Key(UUID itemId, UUID memberId) {
            this.itemId = itemId;
            this.memberId = memberId;
        }

        @Override
        public boolean equals(Object o) {
            return o instanceof Key k && Objects.equals(itemId, k.itemId) && Objects.equals(memberId, k.memberId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(itemId, memberId);
        }
    }
}
