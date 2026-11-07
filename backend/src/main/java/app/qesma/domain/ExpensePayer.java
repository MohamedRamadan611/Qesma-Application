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

/** One payer of an expense and the amount they paid (spec 7.5). Payers need not be participants. */
@Entity
@Table(name = "expense_payers")
@IdClass(ExpensePayer.Key.class)
public class ExpensePayer implements Persistable<ExpensePayer.Key> {

    @Id
    @Column(name = "expense_id", nullable = false, updatable = false)
    private UUID expenseId;

    @Id
    @Column(name = "member_id", nullable = false, updatable = false)
    private UUID memberId;

    @Column(name = "amount_minor", nullable = false, updatable = false)
    private long amountMinor;

    @Transient
    private boolean isNew = true;

    protected ExpensePayer() {
    }

    public ExpensePayer(UUID expenseId, UUID memberId, long amountMinor) {
        this.expenseId = expenseId;
        this.memberId = memberId;
        this.amountMinor = amountMinor;
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

    public long getAmountMinor() {
        return amountMinor;
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
