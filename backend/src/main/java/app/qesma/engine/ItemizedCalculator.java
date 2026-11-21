package app.qesma.engine;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * ITEMIZED restaurant-bill split (spec 7.4, extended by STANDALONE_SPEC 18: bill discount, item quantity, service
 * and tax as amounts). A bill without the extensions computes exactly as spec 7.4.
 */
public final class ItemizedCalculator {

    /** Item quantity bounds (A172). */
    public static final int MIN_QUANTITY = 1;
    public static final int MAX_QUANTITY = 999;
    /** A discount percentage is 0.01% .. 99.99% (A171): 100% would make the bill free. */
    public static final int MAX_DISCOUNT_BPS = Bps.MAX_BPS - 1;

    private ItemizedCalculator() {
    }

    /** Which amount the tax rate applies to (spec 7.4, Decision A1); in the amount form it sets the weights only. */
    public enum TaxBase { SUBTOTAL, SUBTOTAL_PLUS_SERVICE }

    /**
     * A charge (discount, service or tax) given either as a percentage in basis points or as an amount in piasters,
     * never both and never neither (A171, A173). Ranges are checked by {@link #calculate}.
     */
    public record ChargeSpec(Integer bps, Long amountMinor) {

        public static ChargeSpec percent(int bps) {
            return new ChargeSpec(bps, null);
        }

        public static ChargeSpec amount(long amountMinor) {
            return new ChargeSpec(null, amountMinor);
        }

        /** The request shape rule: exactly one of {@code bps} and {@code amountMinor}. */
        public static ChargeSpec of(Integer bps, Long amountMinor) {
            if ((bps == null) == (amountMinor == null)) {
                throw EngineException.invalid("A charge needs either bps or amountMinor, not both");
            }
            return new ChargeSpec(bps, amountMinor);
        }

        public ChargeSpec {
            if ((bps == null) == (amountMinor == null)) {
                throw EngineException.invalid("A charge needs either bps or amountMinor, not both");
            }
        }

        boolean isPercent() {
            return bps != null;
        }

        /** The charge total on {@code base}: {@code round_half_up(base x bps / 10000)} or the stated amount. */
        long totalOn(long base) {
            return isPercent() ? Bps.percentOf(base, bps) : amountMinor;
        }
    }

    /** Tax as a rate or an amount; a null base defaults to {@link TaxBase#SUBTOTAL_PLUS_SERVICE}. */
    public record TaxSpec(ChargeSpec rate, TaxBase base) {
        public TaxSpec {
            if (rate == null) {
                throw EngineException.invalid("Tax needs either bps or amountMinor");
            }
            if (base == null) {
                base = TaxBase.SUBTOTAL_PLUS_SERVICE;
            }
        }

        /** Tax as a rate in basis points (spec 7.4). */
        public TaxSpec(int bps, TaxBase base) {
            this(ChargeSpec.percent(bps), base);
        }
    }

    /** One bill line: {@code quantity x unitAmountMinor}, split equally among its assignees (A172). */
    public record Item(String name, int quantity, long unitAmountMinor, List<String> assigneeMemberIds) {

        /** A legacy line given by its amount: quantity 1. */
        public Item(String name, long amountMinor, List<String> assigneeMemberIds) {
            this(name, 1, amountMinor, assigneeMemberIds);
        }

        /**
         * The request shape rule (A172): either a legacy {@code amountMinor} (quantity 1, no {@code quantity} field),
         * or {@code unitAmountMinor} with an optional {@code quantity} (default 1). Ranges are checked by
         * {@link #calculate}.
         */
        public static Item of(String name, Long amountMinor, Long unitAmountMinor, Integer quantity,
                              List<String> assigneeMemberIds) {
            if (amountMinor != null && unitAmountMinor != null) {
                throw EngineException.invalid("An item has either amountMinor or unitAmountMinor, not both");
            }
            if (amountMinor != null) {
                if (quantity != null) {
                    throw EngineException.invalid("quantity goes with unitAmountMinor, not with amountMinor");
                }
                return new Item(name, 1, amountMinor, assigneeMemberIds);
            }
            if (unitAmountMinor == null) {
                throw EngineException.invalid("An item needs amountMinor or unitAmountMinor");
            }
            return new Item(name, quantity == null ? 1 : quantity, unitAmountMinor, assigneeMemberIds);
        }

        /** The line amount, computed exactly; overflow is a {@code VALIDATION_ERROR} (A13). */
        public long amountMinor() {
            return Exact.multiply(quantity, unitAmountMinor);
        }
    }

    /**
     * @param members         the group roster (provides sortOrder for every id that may appear)
     * @param discount        null = no discount
     * @param service         null = service disabled
     * @param tax             null = tax disabled
     * @param adjustmentMinor signed rounding/tip adjustment, 0 = none
     * @param deliveryMinor   delivery amount, 0 = none (A180): outside discount, service and tax, split equally among
     *                        the members who have at least one item
     */
    public record ItemizedInput(List<MemberRef> members, List<Item> items, ChargeSpec discount, ChargeSpec service,
                                TaxSpec tax, long adjustmentMinor, long deliveryMinor) {

        /** Without delivery. */
        public ItemizedInput(List<MemberRef> members, List<Item> items, ChargeSpec discount, ChargeSpec service,
                             TaxSpec tax, long adjustmentMinor) {
            this(members, items, discount, service, tax, adjustmentMinor, 0);
        }

        /** Spec 7.4 input: service as a rate, no discount. */
        public ItemizedInput(List<MemberRef> members, List<Item> items, Integer serviceBps, TaxSpec tax,
                             long adjustmentMinor) {
            this(members, items, null, serviceBps == null ? null : ChargeSpec.percent(serviceBps), tax, adjustmentMinor,
                    0);
        }
    }

    /**
     * owed = items - discount + service + tax + delivery + adjustment. {@code deliveryMinor} comes last so the
     * pre-delivery constructors keep their shape (A180).
     */
    public record MemberBreakdown(String memberId, long itemsMinor, long discountMinor, long serviceMinor,
                                  long taxMinor, long adjustmentMinor, long owedMinor, long deliveryMinor) {

        /** Without delivery. */
        public MemberBreakdown(String memberId, long itemsMinor, long discountMinor, long serviceMinor,
                               long taxMinor, long adjustmentMinor, long owedMinor) {
            this(memberId, itemsMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor, 0);
        }

        /** Without a discount. */
        public MemberBreakdown(String memberId, long itemsMinor, long serviceMinor, long taxMinor, long adjustmentMinor,
                               long owedMinor) {
            this(memberId, itemsMinor, 0, serviceMinor, taxMinor, adjustmentMinor, owedMinor, 0);
        }
    }

    /**
     * Members are in sortOrder; those who owe 0 are omitted (spec 7.4 step 6). {@code subtotalMinor} is the sum of
     * the lines before the discount; total = subtotal - discount + service + tax + delivery + adjustment.
     */
    public record ItemizedResult(long subtotalMinor, long discountMinor, long serviceMinor, long taxMinor,
                                 long adjustmentMinor, long totalMinor, List<MemberBreakdown> members,
                                 long deliveryMinor) {

        /** Without delivery. */
        public ItemizedResult(long subtotalMinor, long discountMinor, long serviceMinor, long taxMinor,
                              long adjustmentMinor, long totalMinor, List<MemberBreakdown> members) {
            this(subtotalMinor, discountMinor, serviceMinor, taxMinor, adjustmentMinor, totalMinor, members, 0);
        }
    }

    /** Runs STANDALONE_SPEC 18.2 (spec 7.4 steps 1-6). Payers are checked separately by {@link PayerValidator}. */
    public static ItemizedResult calculate(ItemizedInput in) {
        List<MemberRef> roster = new ArrayList<>(in.members());
        roster.sort(Comparator.comparingInt(MemberRef::sortOrder)); // stable: ties keep input order
        int n = roster.size();
        if (n == 0) {
            throw EngineException.invalid("The member roster is empty");
        }
        Map<String, Integer> index = new HashMap<>();
        int[] sortOrders = new int[n];
        for (int i = 0; i < n; i++) {
            if (index.put(roster.get(i).id(), i) != null) {
                throw EngineException.invalid("Duplicate member in roster");
            }
            sortOrders[i] = roster.get(i).sortOrder();
        }
        if (in.items() == null || in.items().isEmpty()) {
            throw EngineException.invalid("At least one item is required");
        }
        if (in.discount() != null) {
            checkCharge(in.discount(), 1, MAX_DISCOUNT_BPS, "discount");
        }
        if (in.service() != null) {
            checkCharge(in.service(), 0, Bps.MAX_BPS, "service");
        }
        if (in.tax() != null) {
            checkCharge(in.tax().rate(), 0, Bps.MAX_BPS, "tax");
        }
        if (in.deliveryMinor() < 0 || !Limits.withinAmountLimit(in.deliveryMinor())) {
            throw EngineException.invalid("deliveryMinor must be between 0 and " + Limits.MAX_AMOUNT_MINOR);
        }

        // Step 1: item shares, equal LRM among each item's assignees.
        long[] itemsMinor = new long[n];
        boolean[] hasItem = new boolean[n];
        long subtotal = 0;
        for (Item item : in.items()) {
            long line = lineAmount(item);
            List<String> ids = item.assigneeMemberIds();
            if (ids == null || ids.isEmpty()) {
                throw EngineException.invalid("Every item needs at least one assignee");
            }
            Set<String> seen = new HashSet<>();
            List<Integer> idx = new ArrayList<>();
            for (String id : ids) {
                Integer i = index.get(id);
                if (i == null) {
                    throw new EngineException(EngineErrorCode.MEMBER_NOT_IN_GROUP, "Item assignee is not in the group");
                }
                if (!seen.add(id)) {
                    throw EngineException.invalid("Duplicate assignee on an item");
                }
                idx.add(i);
                hasItem[i] = true;
            }
            idx.sort(Integer::compare);
            long[] weights = new long[idx.size()];
            int[] order = new int[idx.size()];
            for (int k = 0; k < idx.size(); k++) {
                weights[k] = 1;
                order[k] = sortOrders[idx.get(k)];
            }
            long[] shares = Lrm.allocate(line, weights, order);
            for (int k = 0; k < idx.size(); k++) {
                itemsMinor[idx.get(k)] = Exact.add(itemsMinor[idx.get(k)], shares[k]);
            }
            subtotal = Exact.add(subtotal, line);
        }

        // Step 2: discount off the subtotal, allocated by each member's items (A171). Without one, net == items.
        long discountTotal = 0;
        long[] discountMinor = new long[n];
        if (in.discount() != null) {
            discountTotal = in.discount().totalOn(subtotal);
            if (discountTotal <= 0 || discountTotal >= subtotal) {
                throw EngineException.invalid("The discount must be greater than zero and less than the subtotal");
            }
            discountMinor = Lrm.allocate(discountTotal, itemsMinor, sortOrders);
        }
        long[] netMinor = new long[n];
        for (int i = 0; i < n; i++) {
            netMinor[i] = itemsMinor[i] - discountMinor[i];
            if (netMinor[i] < 0) {
                // Cannot happen: each LRM part of d < W is at most ceil(d * w / W) <= w.
                throw new IllegalStateException("Engine invariant violated: a discount part exceeds the member's items");
            }
        }
        long netSubtotal = subtotal - discountTotal;

        // Step 3: service, allocated by each member's net.
        long serviceTotal = 0;
        long[] serviceMinor = new long[n];
        if (in.service() != null) {
            serviceTotal = in.service().totalOn(netSubtotal);
            serviceMinor = Lrm.allocate(serviceTotal, netMinor, sortOrders);
        }

        // Step 4: tax, allocated by each member's own base (net, or net + service).
        long taxTotal = 0;
        long[] taxMinor = new long[n];
        if (in.tax() != null) {
            long[] baseWeights = netMinor.clone();
            long baseTotal = netSubtotal;
            if (in.tax().base() == TaxBase.SUBTOTAL_PLUS_SERVICE) {
                baseTotal = Exact.add(netSubtotal, serviceTotal);
                for (int i = 0; i < n; i++) {
                    baseWeights[i] = Exact.add(netMinor[i], serviceMinor[i]);
                }
            }
            taxTotal = in.tax().rate().totalOn(baseTotal);
            taxMinor = Lrm.allocate(taxTotal, baseWeights, sortOrders);
        }

        // Step 5: delivery (A180): outside discount, service and tax; equal parts among the members with an item,
        // leftover piasters by the usual largest-remainder order.
        long deliveryTotal = in.deliveryMinor();
        long[] deliveryMinor = new long[n];
        if (deliveryTotal != 0) {
            long[] ones = new long[n];
            for (int i = 0; i < n; i++) {
                ones[i] = hasItem[i] ? 1 : 0;
            }
            deliveryMinor = Lrm.allocate(deliveryTotal, ones, sortOrders);
        }

        // Step 6: signed adjustment, allocated by net shares (Lrm applies the sign afterwards).
        long adjustment = in.adjustmentMinor();
        long[] adjustmentMinor = new long[n];
        if (adjustment != 0) {
            adjustmentMinor = Lrm.allocate(adjustment, netMinor, sortOrders);
        }

        // Step 7: owed per member and total; total must be > 0.
        long total = Exact.add(Exact.add(Exact.add(netSubtotal, serviceTotal), Exact.add(taxTotal, adjustment)),
                deliveryTotal);
        if (total <= 0) {
            throw EngineException.invalid("The bill total must be greater than zero");
        }
        List<MemberBreakdown> breakdown = new ArrayList<>();
        long owedSum = 0;
        long discountSum = 0;
        for (int i = 0; i < n; i++) {
            long owed = Exact.add(Exact.add(Exact.add(netMinor[i], serviceMinor[i]), Exact.add(taxMinor[i], adjustmentMinor[i])),
                    deliveryMinor[i]);
            if (owed < 0) {
                // Decision A12: an adjustment must never make one member's share negative.
                throw EngineException.invalid("The adjustment makes a member's share negative");
            }
            owedSum = Exact.add(owedSum, owed);
            discountSum = Exact.add(discountSum, discountMinor[i]);
            if (owed != 0) { // members owing 0 are not participants.
                breakdown.add(new MemberBreakdown(roster.get(i).id(), itemsMinor[i], discountMinor[i], serviceMinor[i],
                        taxMinor[i], adjustmentMinor[i], owed, deliveryMinor[i]));
            }
        }
        if (owedSum != total || discountSum != discountTotal) {
            throw new IllegalStateException("Engine invariant violated: parts do not sum to their totals");
        }
        return new ItemizedResult(subtotal, discountTotal, serviceTotal, taxTotal, adjustment, total,
                List.copyOf(breakdown), deliveryTotal);
    }

    /** Quantity 1..999, unit price > 0, line within the A43 cap; overflow is a VALIDATION_ERROR (A13). */
    private static long lineAmount(Item item) {
        if (item.quantity() < MIN_QUANTITY || item.quantity() > MAX_QUANTITY) {
            throw EngineException.invalid("Item quantity must be between " + MIN_QUANTITY + " and " + MAX_QUANTITY);
        }
        if (item.unitAmountMinor() <= 0) {
            throw EngineException.invalid("Item amounts must be greater than zero");
        }
        long line = item.amountMinor();
        if (!Limits.withinAmountLimit(line)) {
            throw EngineException.invalid("An item line must be at most " + Limits.MAX_AMOUNT_MINOR);
        }
        return line;
    }

    /** Percent form within [minBps, maxBps]; amount form within 1..A43 cap. */
    private static void checkCharge(ChargeSpec charge, int minBps, int maxBps, String field) {
        if (charge.isPercent()) {
            if (charge.bps() < minBps || charge.bps() > maxBps) {
                throw EngineException.invalid(field + " basis points must be between " + minBps + " and " + maxBps);
            }
        } else if (charge.amountMinor() < 1 || !Limits.withinAmountLimit(charge.amountMinor())) {
            throw EngineException.invalid(field + " amountMinor must be between 1 and " + Limits.MAX_AMOUNT_MINOR);
        }
    }
}
