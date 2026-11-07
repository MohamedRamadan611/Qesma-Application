package app.qesma.engine;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** ITEMIZED restaurant-bill split (spec 7.4). */
public final class ItemizedCalculator {

    private ItemizedCalculator() {
    }

    /** Which amount the tax rate applies to (spec 7.4, Decision A1). */
    public enum TaxBase { SUBTOTAL, SUBTOTAL_PLUS_SERVICE }

    /** Tax rate in basis points; a null base defaults to {@link TaxBase#SUBTOTAL_PLUS_SERVICE}. */
    public record TaxSpec(int bps, TaxBase base) {
        public TaxSpec {
            if (base == null) {
                base = TaxBase.SUBTOTAL_PLUS_SERVICE;
            }
        }
    }

    public record Item(String name, long amountMinor, List<String> assigneeMemberIds) {
    }

    /**
     * @param members       the group roster (provides sortOrder for every id that may appear)
     * @param serviceBps    null = service disabled
     * @param tax           null = tax disabled
     * @param adjustmentMinor signed rounding/tip adjustment, 0 = none
     */
    public record ItemizedInput(List<MemberRef> members, List<Item> items, Integer serviceBps, TaxSpec tax,
                                long adjustmentMinor) {
    }

    public record MemberBreakdown(String memberId, long itemsMinor, long serviceMinor, long taxMinor,
                                  long adjustmentMinor, long owedMinor) {
    }

    /** Members are in sortOrder; those who owe 0 are omitted (spec 7.4 step 6). */
    public record ItemizedResult(long subtotalMinor, long serviceMinor, long taxMinor, long adjustmentMinor,
                                 long totalMinor, List<MemberBreakdown> members) {
    }

    /** Runs spec 7.4 steps 1-6. Step 7 (payers) is checked separately by {@link PayerValidator}. */
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
        if (in.serviceBps() != null) {
            checkBps(in.serviceBps());
        }
        if (in.tax() != null) {
            checkBps(in.tax().bps());
        }

        // Step 1: item shares, equal LRM among each item's assignees.
        long[] itemsMinor = new long[n];
        long subtotal = 0;
        for (Item item : in.items()) {
            if (item.amountMinor() <= 0) {
                throw EngineException.invalid("Item amounts must be greater than zero");
            }
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
            }
            idx.sort(Integer::compare);
            long[] weights = new long[idx.size()];
            int[] order = new int[idx.size()];
            for (int k = 0; k < idx.size(); k++) {
                weights[k] = 1;
                order[k] = sortOrders[idx.get(k)];
            }
            long[] shares = Lrm.allocate(item.amountMinor(), weights, order);
            for (int k = 0; k < idx.size(); k++) {
                itemsMinor[idx.get(k)] = Exact.add(itemsMinor[idx.get(k)], shares[k]);
            }
            subtotal = Exact.add(subtotal, item.amountMinor());
        }

        // Step 2: service, allocated by each member's items.
        long serviceTotal = 0;
        long[] serviceMinor = new long[n];
        if (in.serviceBps() != null) {
            serviceTotal = Bps.percentOf(subtotal, in.serviceBps());
            serviceMinor = Lrm.allocate(serviceTotal, itemsMinor, sortOrders);
        }

        // Step 3: tax, allocated by each member's own base.
        long taxTotal = 0;
        long[] taxMinor = new long[n];
        if (in.tax() != null) {
            long[] baseWeights = itemsMinor.clone();
            long baseTotal = subtotal;
            if (in.tax().base() == TaxBase.SUBTOTAL_PLUS_SERVICE) {
                baseTotal = Exact.add(subtotal, serviceTotal);
                for (int i = 0; i < n; i++) {
                    baseWeights[i] = Exact.add(itemsMinor[i], serviceMinor[i]);
                }
            }
            taxTotal = Bps.percentOf(baseTotal, in.tax().bps());
            taxMinor = Lrm.allocate(taxTotal, baseWeights, sortOrders);
        }

        // Step 4: signed adjustment, allocated by item subtotals (Lrm applies the sign afterwards).
        long adjustment = in.adjustmentMinor();
        long[] adjustmentMinor = new long[n];
        if (adjustment != 0) {
            adjustmentMinor = Lrm.allocate(adjustment, itemsMinor, sortOrders);
        }

        // Step 5: owed per member and total; total must be > 0.
        long total = Exact.add(Exact.add(subtotal, serviceTotal), Exact.add(taxTotal, adjustment));
        if (total <= 0) {
            throw EngineException.invalid("The bill total must be greater than zero");
        }
        List<MemberBreakdown> breakdown = new ArrayList<>();
        long owedSum = 0;
        for (int i = 0; i < n; i++) {
            long owed = Exact.add(Exact.add(itemsMinor[i], serviceMinor[i]), Exact.add(taxMinor[i], adjustmentMinor[i]));
            if (owed < 0) {
                // Decision (B3 review): an adjustment must never make one member's share negative.
                throw EngineException.invalid("The adjustment makes a member's share negative");
            }
            owedSum = Exact.add(owedSum, owed);
            if (owed != 0) { // Step 6: members owing 0 are not participants.
                breakdown.add(new MemberBreakdown(roster.get(i).id(), itemsMinor[i], serviceMinor[i], taxMinor[i],
                        adjustmentMinor[i], owed));
            }
        }
        if (owedSum != total) {
            throw new IllegalStateException("Engine invariant violated: owed does not sum to total");
        }
        return new ItemizedResult(subtotal, serviceTotal, taxTotal, adjustment, total, List.copyOf(breakdown));
    }

    private static void checkBps(int bps) {
        if (bps < 0 || bps > Bps.MAX_BPS) {
            throw EngineException.invalid("Basis points must be between 0 and " + Bps.MAX_BPS);
        }
    }
}
