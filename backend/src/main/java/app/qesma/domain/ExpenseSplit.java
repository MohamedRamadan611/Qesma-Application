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
import java.time.LocalDate;
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

    // itemized breakdown (NULL for EQUAL/EXACT): owed = items - discount + service + tax + adjustment
    @Column(name = "items_minor", updatable = false)
    private Long itemsMinor;

    @Column(name = "service_minor", updatable = false)
    private Long serviceMinor;

    @Column(name = "tax_minor", updatable = false)
    private Long taxMinor;

    @Column(name = "adjustment_minor", updatable = false)
    private Long adjustmentMinor;

    @Column(name = "discount_minor", updatable = false)
    private Long discountMinor;

    @Column(name = "delivery_minor", updatable = false)
    private Long deliveryMinor;

    // SHARES inputs (A185-A186, NULL on other types); presence is stored normalized: both bounds when the expense
    // has a period (defaulted to the period), NULL without one (A195)
    @Column(name = "share_units", updatable = false)
    private Integer shareUnits;

    @Column(name = "present_from", updatable = false)
    private LocalDate presentFrom;

    @Column(name = "present_to", updatable = false)
    private LocalDate presentTo;

    @Transient
    private boolean isNew = true;

    protected ExpenseSplit() {
    }

    public ExpenseSplit(UUID expenseId, UUID memberId, long owedMinor) {
        this.expenseId = expenseId;
        this.memberId = memberId;
        this.owedMinor = owedMinor;
    }

    /** ITEMIZED: owed = items - discount + service + tax + delivery + adjustment (BSA2, A180). */
    public ExpenseSplit(UUID expenseId, UUID memberId, long owedMinor, long itemsMinor, long discountMinor,
                        long serviceMinor, long taxMinor, long adjustmentMinor, long deliveryMinor) {
        this(expenseId, memberId, owedMinor);
        this.deliveryMinor = deliveryMinor;
        this.itemsMinor = itemsMinor;
        this.discountMinor = discountMinor;
        this.serviceMinor = serviceMinor;
        this.taxMinor = taxMinor;
        this.adjustmentMinor = adjustmentMinor;
    }

    /** SHARES: the units and the (normalized) presence next to the owed amount. */
    public static ExpenseSplit shares(UUID expenseId, UUID memberId, long owedMinor, int shareUnits,
                                      LocalDate presentFrom, LocalDate presentTo) {
        ExpenseSplit s = new ExpenseSplit(expenseId, memberId, owedMinor);
        s.shareUnits = shareUnits;
        s.presentFrom = presentFrom;
        s.presentTo = presentTo;
        return s;
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

    public Long getDiscountMinor() {
        return discountMinor;
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

    public Long getDeliveryMinor() {
        return deliveryMinor;
    }

    public Integer getShareUnits() {
        return shareUnits;
    }

    public LocalDate getPresentFrom() {
        return presentFrom;
    }

    public LocalDate getPresentTo() {
        return presentTo;
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
