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
    public static final String SHARES = "SHARES";

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

    // A180 (V22): the delivery charge; NULL for EQUAL/EXACT, 0 or more for ITEMIZED
    @Column(name = "delivery_minor")
    private Long deliveryMinor;

    // BSA2 (V21): which form each charge took, and the computed discount total; NULL for EQUAL/EXACT
    @Column(name = "discount_bps")
    private Integer discountBps;

    @Column(name = "discount_amount_minor")
    private Long discountAmountMinor;

    @Column(name = "discount_minor")
    private Long discountMinor;

    @Column(name = "service_amount_minor")
    private Long serviceAmountMinor;

    @Column(name = "tax_amount_minor")
    private Long taxAmountMinor;

    // SHARES only (A186): the optional inclusive period; NULL otherwise
    @Column(name = "period_from")
    private LocalDate periodFrom;

    @Column(name = "period_to")
    private LocalDate periodTo;

    @Column(name = "category", nullable = false)
    private String category = "OTHER";

    @Column(name = "paid_from_pool", nullable = false)
    private boolean paidFromPool;

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

    /**
     * The charges of an ITEMIZED expense. Each charge is off (both form fields null, amount 0), a percentage
     * ({@code *Bps}) or an amount ({@code *AmountMinor}); {@code *Minor} are the computed totals.
     */
    public record ItemizedCharges(long subtotalMinor, Integer discountBps, Long discountAmountMinor, long discountMinor,
                                  Integer serviceBps, Long serviceAmountMinor, long serviceMinor, Integer taxBps,
                                  Long taxAmountMinor, String taxBase, long taxMinor, long adjustmentMinor,
                                  long deliveryMinor) {

        /** Without delivery (0). */
        public ItemizedCharges(long subtotalMinor, Integer discountBps, Long discountAmountMinor, long discountMinor,
                               Integer serviceBps, Long serviceAmountMinor, long serviceMinor, Integer taxBps,
                               Long taxAmountMinor, String taxBase, long taxMinor, long adjustmentMinor) {
            this(subtotalMinor, discountBps, discountAmountMinor, discountMinor, serviceBps, serviceAmountMinor,
                    serviceMinor, taxBps, taxAmountMinor, taxBase, taxMinor, adjustmentMinor, 0);
        }
    }

    /** An ITEMIZED expense with its computed charges. */
    public static Expense itemized(UUID id, UUID groupId, String title, long totalMinor, LocalDate expenseDate,
                                   UUID createdByUserId, Instant createdAt, ItemizedCharges c) {
        Expense e = new Expense(id, groupId, title, ITEMIZED, totalMinor, expenseDate, createdByUserId, createdAt);
        e.subtotalMinor = c.subtotalMinor();
        e.discountBps = c.discountBps();
        e.discountAmountMinor = c.discountAmountMinor();
        e.discountMinor = c.discountMinor();
        e.serviceBps = c.serviceBps();
        e.serviceAmountMinor = c.serviceAmountMinor();
        e.serviceMinor = c.serviceMinor();
        e.taxBps = c.taxBps();
        e.taxAmountMinor = c.taxAmountMinor();
        e.taxMinor = c.taxMinor();
        e.taxBase = c.taxBase();
        e.adjustmentMinor = c.adjustmentMinor();
        e.deliveryMinor = c.deliveryMinor();
        return e;
    }

    /** A SHARES expense (A185-A186); the period is both bounds or null. */
    public static Expense shares(UUID id, UUID groupId, String title, long totalMinor, LocalDate expenseDate,
                                 UUID createdByUserId, Instant createdAt, LocalDate periodFrom, LocalDate periodTo) {
        Expense e = new Expense(id, groupId, title, SHARES, totalMinor, expenseDate, createdByUserId, createdAt);
        e.periodFrom = periodFrom;
        e.periodTo = periodTo;
        return e;
    }

    /** BSA1: category and pool flag (validated by the service). */
    public Expense withPool(String category, boolean paidFromPool) {
        this.category = category;
        this.paidFromPool = paidFromPool;
        return this;
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
        this.deliveryMinor = next.deliveryMinor;
        this.discountBps = next.discountBps;
        this.discountAmountMinor = next.discountAmountMinor;
        this.discountMinor = next.discountMinor;
        this.serviceAmountMinor = next.serviceAmountMinor;
        this.taxAmountMinor = next.taxAmountMinor;
        this.periodFrom = next.periodFrom;
        this.periodTo = next.periodTo;
        this.category = next.category;
        this.paidFromPool = next.paidFromPool;
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

    public Long getDeliveryMinor() {
        return deliveryMinor;
    }

    public Integer getDiscountBps() {
        return discountBps;
    }

    public Long getDiscountAmountMinor() {
        return discountAmountMinor;
    }

    public Long getDiscountMinor() {
        return discountMinor;
    }

    public Long getServiceAmountMinor() {
        return serviceAmountMinor;
    }

    public Long getTaxAmountMinor() {
        return taxAmountMinor;
    }

    public LocalDate getPeriodFrom() {
        return periodFrom;
    }

    public LocalDate getPeriodTo() {
        return periodTo;
    }

    public String getCategory() {
        return category;
    }

    public boolean isPaidFromPool() {
        return paidFromPool;
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
