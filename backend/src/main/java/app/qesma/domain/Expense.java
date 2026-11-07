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
 * A recorded shared expense (spec 6). EQUAL and EXACT rows leave the itemized-only columns NULL; ITEMIZED rows
 * (B5) fill all of them through {@link #itemized}. Never hard-deleted: {@code deleted_at} is used from B6.
 */
@Entity
@Table(name = "expenses")
public class Expense implements Persistable<UUID> {

    public static final String EQUAL = "EQUAL";
    public static final String EXACT = "EXACT";
    public static final String ITEMIZED = "ITEMIZED";

    @Id
    private UUID id;

    @Column(name = "group_id", nullable = false, updatable = false)
    private UUID groupId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "split_type", nullable = false)
    private String splitType;

    @Column(name = "total_minor", nullable = false)
    private long totalMinor;

    @Column(name = "expense_date", nullable = false)
    private LocalDate expenseDate;

    // itemized-only columns (NULL for EQUAL/EXACT)
    @Column(name = "subtotal_minor")
    private Long subtotalMinor;

    @Column(name = "service_bps")
    private Integer serviceBps;

    @Column(name = "service_minor")
    private Long serviceMinor;

    @Column(name = "tax_bps")
    private Integer taxBps;

    @Column(name = "tax_minor")
    private Long taxMinor;

    @Column(name = "tax_base")
    private String taxBase;

    @Column(name = "adjustment_minor")
    private Long adjustmentMinor;

    @Column(name = "created_by_user_id", nullable = false, updatable = false)
    private UUID createdByUserId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "version", nullable = false)
    private int version;

    @Transient
    private boolean isNew = true;

    protected Expense() {
    }

    public Expense(UUID id, UUID groupId, String title, String splitType, long totalMinor, LocalDate expenseDate,
                   UUID createdByUserId, Instant createdAt) {
        this.id = id;
        this.groupId = groupId;
        this.title = title;
        this.splitType = splitType;
        this.totalMinor = totalMinor;
        this.expenseDate = expenseDate;
        this.createdByUserId = createdByUserId;
        this.createdAt = createdAt;
        this.updatedAt = createdAt;
        this.version = 1;
    }

    /** An ITEMIZED expense with its computed charges ({@code serviceBps}/{@code taxBps} null = that charge is off). */
    public static Expense itemized(UUID id, UUID groupId, String title, long totalMinor, LocalDate expenseDate,
                                   UUID createdByUserId, Instant createdAt, long subtotalMinor, Integer serviceBps,
                                   long serviceMinor, Integer taxBps, long taxMinor, String taxBase,
                                   long adjustmentMinor) {
        Expense e = new Expense(id, groupId, title, ITEMIZED, totalMinor, expenseDate, createdByUserId, createdAt);
        e.subtotalMinor = subtotalMinor;
        e.serviceBps = serviceBps;
        e.serviceMinor = serviceMinor;
        e.taxBps = taxBps;
        e.taxMinor = taxMinor;
        e.taxBase = taxBase;
        e.adjustmentMinor = adjustmentMinor;
        return e;
    }

    /**
     * Edit (spec 7.9): takes over everything the user can change from {@code next} (a freshly computed expense
     * for the same group), bumps the version by one and stamps {@code updated_at}. Identity, group, creator and
     * creation time never change.
     */
    public void replaceWith(Expense next, Instant now) {
        this.title = next.title;
        this.splitType = next.splitType;
        this.totalMinor = next.totalMinor;
        this.expenseDate = next.expenseDate;
        this.subtotalMinor = next.subtotalMinor;
        this.serviceBps = next.serviceBps;
        this.serviceMinor = next.serviceMinor;
        this.taxBps = next.taxBps;
        this.taxMinor = next.taxMinor;
        this.taxBase = next.taxBase;
        this.adjustmentMinor = next.adjustmentMinor;
        this.updatedAt = now;
        this.version++;
    }

    /** Soft delete (spec 7.9): the row stays, {@code deleted_at} is set and the version is bumped. */
    public void markDeleted(Instant now) {
        this.deletedAt = now;
        this.updatedAt = now;
        this.version++;
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

    public String getTitle() {
        return title;
    }

    public String getSplitType() {
        return splitType;
    }

    public long getTotalMinor() {
        return totalMinor;
    }

    public LocalDate getExpenseDate() {
        return expenseDate;
    }

    public Long getSubtotalMinor() {
        return subtotalMinor;
    }

    public Integer getServiceBps() {
        return serviceBps;
    }

    public Long getServiceMinor() {
        return serviceMinor;
    }

    public Integer getTaxBps() {
        return taxBps;
    }

    public Long getTaxMinor() {
        return taxMinor;
    }

    public String getTaxBase() {
        return taxBase;
    }

    public Long getAdjustmentMinor() {
        return adjustmentMinor;
    }

    public UUID getCreatedByUserId() {
        return createdByUserId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public int getVersion() {
        return version;
    }
}
