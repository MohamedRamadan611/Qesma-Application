package app.qesma.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.util.UUID;
import org.springframework.data.domain.Persistable;

/** One line of an itemized bill (spec 6). {@code sortOrder} is the order the client entered the items in. */
@Entity
@Table(name = "expense_items")
public class ExpenseItem implements Persistable<UUID> {

    @Id
    private UUID id;

    @Column(name = "expense_id", nullable = false, updatable = false)
    private UUID expenseId;

    @Column(name = "name", nullable = false, updatable = false)
    private String name;

    @Column(name = "amount_minor", nullable = false, updatable = false)
    private long amountMinor;

    @Column(name = "sort_order", nullable = false, updatable = false)
    private int sortOrder;

    // BSA2 (V21): amount_minor = quantity x unit_amount_minor (a CHECK in the database)
    @Column(name = "quantity", nullable = false, updatable = false)
    private int quantity;

    @Column(name = "unit_amount_minor", nullable = false, updatable = false)
    private long unitAmountMinor;

    @Transient
    private boolean isNew = true;

    protected ExpenseItem() {
    }

    /** {@code amountMinor} is the engine-computed line amount, quantity x unit. */
    public ExpenseItem(UUID id, UUID expenseId, String name, int quantity, long unitAmountMinor, long amountMinor,
                       int sortOrder) {
        this.id = id;
        this.expenseId = expenseId;
        this.name = name;
        this.quantity = quantity;
        this.unitAmountMinor = unitAmountMinor;
        this.amountMinor = amountMinor;
        this.sortOrder = sortOrder;
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

    public UUID getExpenseId() {
        return expenseId;
    }

    public String getName() {
        return name;
    }

    public long getAmountMinor() {
        return amountMinor;
    }

    public int getQuantity() {
        return quantity;
    }

    public long getUnitAmountMinor() {
        return unitAmountMinor;
    }

    public int getSortOrder() {
        return sortOrder;
    }
}
