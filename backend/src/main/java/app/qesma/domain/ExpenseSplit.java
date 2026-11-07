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

/**
 * One resolved participant of an expense and what they owe: the explicit snapshot (an "All" selection is
 * stored as one row per member at creation time). Zero-owed participants are kept (Decision A13).
 */
@Entity
@Table(name = "expense_splits")
@IdClass(ExpenseSplit.Key.class)
public class ExpenseSplit implements Persistable<ExpenseSplit.Key> {

    @Id
    @Column(name = "expense_id", nullable = false, updatable = false)
    private UUID expenseId;

    @Id
    @Column(name = "member_id", nullable = false, updatable = false)
    private UUID memberId;

    @Column(name = "owed_minor", nullable = false, updatable = false)
    private long owedMinor;

    // itemized breakdown (NULL for EQUAL/EXACT): owed = items + service + tax + adjustment
    @Column(name = "items_minor", updatable = false)
    private Long itemsMinor;

    @Column(name = "service_minor", updatable = false)
    private Long serviceMinor;

    @Column(name = "tax_minor", updatable = false)
    private Long taxMinor;

    @Column(name = "adjustment_minor", updatable = false)
    private Long adjustmentMinor;

    @Transient
    private boolean isNew = true;

    protected ExpenseSplit() {
    }

    public ExpenseSplit(UUID expenseId, UUID memberId, long owedMinor) {
        this.expenseId = expenseId;
        this.memberId = memberId;
        this.owedMinor = owedMinor;
    }

    public ExpenseSplit(UUID expenseId, UUID memberId, long owedMinor, long itemsMinor, long serviceMinor,
                        long taxMinor, long adjustmentMinor) {
        this(expenseId, memberId, owedMinor);
        this.itemsMinor = itemsMinor;
        this.serviceMinor = serviceMinor;
        this.taxMinor = taxMinor;
        this.adjustmentMinor = adjustmentMinor;
    }

    @Override
    public Key getId() {
        return new Key(expenseId, memberId);
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

    public UUID getExpenseId() {
        return expenseId;
    }

    public UUID getMemberId() {
        return memberId;
    }

    public long getOwedMinor() {
        return owedMinor;
    }

    public Long getItemsMinor() {
        return itemsMinor;
    }

    public Long getServiceMinor() {
        return serviceMinor;
    }

    public Long getTaxMinor() {
        return taxMinor;
    }

    public Long getAdjustmentMinor() {
        return adjustmentMinor;
    }

    /** Composite primary key (expense_id, member_id). */
    public static class Key implements Serializable {
        private static final long serialVersionUID = 1L;

        private UUID expenseId;
        private UUID memberId;

        protected Key() {
        }

        public Key(UUID expenseId, UUID memberId) {
            this.expenseId = expenseId;
            this.memberId = memberId;
        }

        @Override
        public boolean equals(Object o) {
            return o instanceof Key k && Objects.equals(expenseId, k.expenseId) && Objects.equals(memberId, k.memberId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(expenseId, memberId);
        }
    }
}
