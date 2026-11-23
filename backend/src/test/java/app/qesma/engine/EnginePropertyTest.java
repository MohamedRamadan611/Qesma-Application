package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
import app.qesma.engine.ItemizedCalculator.ChargeSpec;
import app.qesma.engine.ItemizedCalculator.Item;
import app.qesma.engine.ItemizedCalculator.ItemizedInput;
import app.qesma.engine.ItemizedCalculator.ItemizedResult;
import app.qesma.engine.ItemizedCalculator.MemberBreakdown;
import app.qesma.engine.ItemizedCalculator.TaxBase;
import app.qesma.engine.ItemizedCalculator.TaxSpec;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.constraints.LongRange;
import net.jqwik.api.constraints.Size;

/**
 * Property tests (spec section 10). Scenario-style properties derive everything from a
 * jqwik-generated seed, so a failure is reproducible from the reported seed.
 */
class EnginePropertyTest {

    @Property(tries = 5000)
    void lrmPartsSumExactlyAndStayWithinOneUnitOfExactShare(
            @ForAll @LongRange(min = -1_000_000_000_000L, max = 1_000_000_000_000L) long total,
            @ForAll @Size(min = 1, max = 20) List<@LongRange(min = 0, max = 1_000_000_000L) Long> weights) {
        int n = weights.size();
        long[] w = weights.stream().mapToLong(Long::longValue).toArray();
        int[] order = new int[n];
        for (int i = 0; i < n; i++) {
            order[i] = i;
        }

        long[] parts = Lrm.allocate(total, w, order);

        BigInteger sum = BigInteger.ZERO;
        for (long x : w) {
            sum = sum.add(BigInteger.valueOf(x));
        }
        boolean equalFallback = sum.signum() == 0;
        if (equalFallback) {
            sum = BigInteger.valueOf(n);
        }
        long allocated = 0;
        for (int i = 0; i < n; i++) {
            allocated += parts[i];
            BigInteger weight = BigInteger.valueOf(equalFallback ? 1 : w[i]);
            BigInteger diff = BigInteger.valueOf(parts[i]).multiply(sum)
                    .subtract(BigInteger.valueOf(total).multiply(weight)).abs();
            assertThat(diff).as("part %d off by a full unit or more", i).isLessThan(sum);
        }
        assertThat(allocated).isEqualTo(total);
        assertThat(Lrm.allocate(total, w, order)).isEqualTo(parts);
    }

    @Property(tries = 3000)
    void itemizedOwedSumsToTotalForAnyServiceTaxAdjustmentCombination(@ForAll long seed) {
        Random rnd = new Random(seed);
        List<MemberRef> members = members(2 + rnd.nextInt(7));
        int adjustment = rnd.nextInt(20001) - 10000;
        ItemizedInput in = new ItemizedInput(members, randomItems(rnd, members),
                rnd.nextBoolean() ? null : rnd.nextInt(3001),
                rnd.nextBoolean() ? null : new TaxSpec(rnd.nextInt(3001),
                        rnd.nextBoolean() ? TaxBase.SUBTOTAL : TaxBase.SUBTOTAL_PLUS_SERVICE),
                adjustment);
        ItemizedResult r;
        try {
            r = ItemizedCalculator.calculate(in);
        } catch (EngineException e) {
            // Only a negative adjustment can legitimately push the total to <= 0.
            assertThat(e.code()).isEqualTo(EngineErrorCode.VALIDATION_ERROR);
            assertThat(adjustment).isNegative();
            return;
        }
        long owedSum = r.members().stream().mapToLong(MemberBreakdown::owedMinor).sum();
        assertThat(owedSum).isEqualTo(r.totalMinor());
        assertThat(r.totalMinor()).isEqualTo(r.subtotalMinor() + r.serviceMinor() + r.taxMinor() + adjustment);
        assertThat(r.members()).allSatisfy(m -> assertThat(m.owedMinor()).isPositive());
        assertThat(ItemizedCalculator.calculate(in)).isEqualTo(r);
    }

    /** BSA2 (STANDALONE_SPEC 18.2): discount, quantity and charges as amounts keep every sum exact. */
    @Property(tries = 3000)
    void itemizedV2SumsStayExactWithDiscountQuantityAndAmountCharges(@ForAll long seed) {
        Random rnd = new Random(seed);
        List<MemberRef> members = members(2 + rnd.nextInt(7));
        List<Item> items = new ArrayList<>();
        for (Item legacy : randomItems(rnd, members)) {
            items.add(new Item(legacy.name(), 1 + rnd.nextInt(999), 1 + rnd.nextInt(50_000), legacy.assigneeMemberIds()));
        }
        long subtotal = items.stream().mapToLong(Item::amountMinor).sum();
        ChargeSpec discount = switch (rnd.nextInt(3)) {
            case 0 -> null;
            case 1 -> ChargeSpec.percent(1 + rnd.nextInt(9_999));
            default -> ChargeSpec.amount(1 + (long) (rnd.nextDouble() * (subtotal - 1)));
        };
        ChargeSpec service = switch (rnd.nextInt(3)) {
            case 0 -> null;
            case 1 -> ChargeSpec.percent(rnd.nextInt(3001));
            default -> ChargeSpec.amount(1 + rnd.nextInt(100_000));
        };
        TaxSpec tax = switch (rnd.nextInt(3)) {
            case 0 -> null;
            case 1 -> new TaxSpec(ChargeSpec.percent(rnd.nextInt(3001)),
                    rnd.nextBoolean() ? TaxBase.SUBTOTAL : TaxBase.SUBTOTAL_PLUS_SERVICE);
            default -> new TaxSpec(ChargeSpec.amount(1 + rnd.nextInt(100_000)),
                    rnd.nextBoolean() ? TaxBase.SUBTOTAL : TaxBase.SUBTOTAL_PLUS_SERVICE);
        };
        int adjustment = rnd.nextInt(20001) - 10000;
        ItemizedInput in = new ItemizedInput(members, items, discount, service, tax, adjustment);
        ItemizedResult r;
        try {
            r = ItemizedCalculator.calculate(in);
        } catch (EngineException e) {
            // A discount that rounds to 0 / reaches a 1-piaster subtotal, or a negative adjustment, are the only
            // legitimate rejections.
            assertThat(e.code()).isEqualTo(EngineErrorCode.VALIDATION_ERROR);
            assertThat(adjustment < 0 || discount != null).isTrue();
            return;
        }
        assertThat(r.subtotalMinor()).isEqualTo(subtotal);
        assertThat(r.discountMinor()).isBetween(discount == null ? 0L : 1L, subtotal - (discount == null ? 0 : 1));
        long owedSum = r.members().stream().mapToLong(MemberBreakdown::owedMinor).sum();
        assertThat(owedSum).isEqualTo(r.totalMinor());
        assertThat(r.totalMinor())
                .isEqualTo(subtotal - r.discountMinor() + r.serviceMinor() + r.taxMinor() + adjustment);
        assertThat(r.members()).allSatisfy(m -> {
            assertThat(m.discountMinor()).isBetween(0L, m.itemsMinor());
            assertThat(m.owedMinor()).isEqualTo(m.itemsMinor() - m.discountMinor() + m.serviceMinor() + m.taxMinor()
                    + m.adjustmentMinor());
            assertThat(m.owedMinor()).isPositive();
        });
        if (adjustment == 0) {
            // Without an adjustment a member is dropped only when the discount took all their items (net 0, so no
            // service/tax weight either): the discount parts then sum to the discount total.
            long keptDiscount = r.members().stream().mapToLong(MemberBreakdown::discountMinor).sum();
            long droppedItems = subtotal - r.members().stream().mapToLong(MemberBreakdown::itemsMinor).sum();
            assertThat(keptDiscount + droppedItems).isEqualTo(r.discountMinor());
        }
        if (service != null && service.amountMinor() != null) {
            assertThat(r.serviceMinor()).isEqualTo(service.amountMinor());
        }
        if (tax != null && tax.rate().amountMinor() != null) {
            assertThat(r.taxMinor()).isEqualTo(tax.rate().amountMinor());
        }
        assertThat(ItemizedCalculator.calculate(in)).isEqualTo(r);
    }

    /** Bills without the BSA2 fields compute exactly as the pre-BSA2 algorithm (spec 7.4, reproduced below). */
    @Property(tries = 3000)
    void billsWithoutTheNewFieldsMatchTheOriginalAlgorithm(@ForAll long seed) {
        Random rnd = new Random(seed);
        List<MemberRef> members = members(2 + rnd.nextInt(7));
        List<Item> items = randomItems(rnd, members);
        Integer serviceBps = rnd.nextBoolean() ? null : rnd.nextInt(3001);
        TaxSpec tax = rnd.nextBoolean() ? null : new TaxSpec(rnd.nextInt(3001),
                rnd.nextBoolean() ? TaxBase.SUBTOTAL : TaxBase.SUBTOTAL_PLUS_SERVICE);
        long adjustment = rnd.nextInt(20001) - 10000;
        long[][] reference;
        try {
            reference = originalAlgorithm(members, items, serviceBps, tax, adjustment);
        } catch (EngineException e) {
            assertThatCode(e, () -> ItemizedCalculator.calculate(new ItemizedInput(members, items, serviceBps, tax,
                    adjustment)));
            return;
        }
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(members, items, serviceBps, tax, adjustment));
        assertThat(r.discountMinor()).isZero();
        Map<String, long[]> byId = new LinkedHashMap<>();
        r.members().forEach(m -> byId.put(m.memberId(), new long[] {m.itemsMinor(), m.serviceMinor(), m.taxMinor(),
                m.adjustmentMinor(), m.owedMinor(), m.discountMinor()}));
        for (int i = 0; i < members.size(); i++) {
            long[] ref = reference[i];
            if (ref[4] == 0) {
                assertThat(byId).doesNotContainKey(members.get(i).id());
            } else {
                assertThat(byId.get(members.get(i).id())).containsExactly(ref[0], ref[1], ref[2], ref[3], ref[4], 0L);
            }
        }
    }

    private static void assertThatCode(EngineException expected, Runnable call) {
        org.assertj.core.api.Assertions.assertThatThrownBy(call::run).isInstanceOf(EngineException.class)
                .extracting("code").isEqualTo(expected.code());
    }

    /** Spec 7.4 steps 1-5 as they were before BSA2; rows are {items, service, tax, adjustment, owed} per member. */
    private static long[][] originalAlgorithm(List<MemberRef> members, List<Item> items, Integer serviceBps,
                                              TaxSpec tax, long adjustment) {
        int n = members.size();
        int[] order = new int[n];
        Map<String, Integer> index = new LinkedHashMap<>();
        for (int i = 0; i < n; i++) {
            order[i] = members.get(i).sortOrder();
            index.put(members.get(i).id(), i);
        }
        long[] it = new long[n];
        long subtotal = 0;
        for (Item item : items) {
            List<Integer> idx = item.assigneeMemberIds().stream().map(index::get).sorted().toList();
            long[] w = new long[idx.size()];
            int[] o = new int[idx.size()];
            for (int k = 0; k < idx.size(); k++) {
                w[k] = 1;
                o[k] = order[idx.get(k)];
            }
            long[] parts = Lrm.allocate(item.amountMinor(), w, o);
            for (int k = 0; k < idx.size(); k++) {
                it[idx.get(k)] += parts[k];
            }
            subtotal += item.amountMinor();
        }
        long serviceTotal = serviceBps == null ? 0 : Bps.percentOf(subtotal, serviceBps);
        long[] sv = serviceBps == null ? new long[n] : Lrm.allocate(serviceTotal, it, order);
        long[] tx = new long[n];
        long taxTotal = 0;
        if (tax != null) {
            long[] base = it.clone();
            long baseTotal = subtotal;
            if (tax.base() == TaxBase.SUBTOTAL_PLUS_SERVICE) {
                baseTotal += serviceTotal;
                for (int i = 0; i < n; i++) {
                    base[i] += sv[i];
                }
            }
            taxTotal = Bps.percentOf(baseTotal, tax.rate().bps());
            tx = Lrm.allocate(taxTotal, base, order);
        }
        long[] adj = adjustment == 0 ? new long[n] : Lrm.allocate(adjustment, it, order);
        if (subtotal + serviceTotal + taxTotal + adjustment <= 0) {
            throw EngineException.invalid("total");
        }
        long[][] rows = new long[n][];
        for (int i = 0; i < n; i++) {
            long owed = it[i] + sv[i] + tx[i] + adj[i];
            if (owed < 0) {
                throw EngineException.invalid("negative");
            }
            rows[i] = new long[] {it[i], sv[i], tx[i], adj[i], owed};
        }
        return rows;
    }

    @Property(tries = 3000)
    void netsSumToZeroAndSimplifiedTransfersSettleEverything(@ForAll long seed) {
        Random rnd = new Random(seed);
        List<MemberRef> members = members(2 + rnd.nextInt(7));
        List<ExpenseLedgerEntry> expenses = new ArrayList<>();
        int expenseCount = 1 + rnd.nextInt(10);
        for (int i = 0; i < expenseCount; i++) {
            expenses.add(randomExpense(rnd, members));
        }
        List<SettlementEntry> settlements = new ArrayList<>();
        int settlementCount = rnd.nextInt(6);
        for (int i = 0; i < settlementCount; i++) {
            int from = rnd.nextInt(members.size());
            int to = (from + 1 + rnd.nextInt(members.size() - 1)) % members.size();
            settlements.add(new SettlementEntry(members.get(from).id(), members.get(to).id(), 1 + rnd.nextInt(1_000_000)));
        }

        Map<String, Long> nets = BalanceCalculator.nets(members, expenses, settlements);
        assertThat(nets.values().stream().mapToLong(Long::longValue).sum()).isZero();

        List<Transfer> transfers = Simplifier.simplify(nets, members);
        assertThat(transfers).hasSizeLessThanOrEqualTo(members.size() - 1);
        Map<String, Long> after = new LinkedHashMap<>(nets);
        for (Transfer t : transfers) {
            assertThat(t.amountMinor()).isPositive();
            after.merge(t.fromMemberId(), t.amountMinor(), Long::sum);
            after.merge(t.toMemberId(), -t.amountMinor(), Long::sum);
        }
        assertThat(after.values()).allMatch(v -> v == 0L);
        assertThat(Simplifier.simplify(nets, members)).isEqualTo(transfers);
    }

    // ---- generators -------------------------------------------------------------------------

    private static List<MemberRef> members(int n) {
        List<MemberRef> list = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            list.add(new MemberRef("m" + i, i + 1));
        }
        return list;
    }

    private static List<Item> randomItems(Random rnd, List<MemberRef> members) {
        List<Item> items = new ArrayList<>();
        int count = 1 + rnd.nextInt(6);
        for (int i = 0; i < count; i++) {
            List<String> assignees = new ArrayList<>();
            for (MemberRef m : members) {
                if (rnd.nextInt(3) == 0) {
                    assignees.add(m.id());
                }
            }
            if (assignees.isEmpty()) {
                assignees.add(members.get(rnd.nextInt(members.size())).id());
            }
            items.add(new Item("item" + i, 1 + rnd.nextInt(500_000), assignees));
        }
        return items;
    }

    private static ExpenseLedgerEntry randomExpense(Random rnd, List<MemberRef> members) {
        long total;
        Map<String, Long> owed = new LinkedHashMap<>();
        switch (rnd.nextInt(3)) {
            case 0 -> { // EQUAL among a random non-empty subset
                total = 1 + rnd.nextInt(5_000_000);
                owed.putAll(SplitCalculator.equal(total, nonEmptySubset(rnd, members)));
            }
            case 1 -> { // EXACT: split a total into random positive shares
                List<MemberRef> subset = nonEmptySubset(rnd, members);
                List<Share> shares = new ArrayList<>();
                total = 0;
                for (MemberRef m : subset) {
                    long amount = 1 + rnd.nextInt(1_000_000);
                    shares.add(new Share(m.id(), amount));
                    total += amount;
                }
                owed.putAll(SplitCalculator.exact(total, shares));
            }
            default -> { // ITEMIZED with optional service/tax
                ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(members, randomItems(rnd, members),
                        rnd.nextBoolean() ? null : 1200,
                        rnd.nextBoolean() ? null : new TaxSpec(1400, TaxBase.SUBTOTAL_PLUS_SERVICE), 0));
                total = r.totalMinor();
                for (MemberBreakdown m : r.members()) {
                    owed.put(m.memberId(), m.owedMinor());
                }
            }
        }
        return new ExpenseLedgerEntry(randomPayers(rnd, members, total), owed);
    }

    private static List<MemberRef> nonEmptySubset(Random rnd, List<MemberRef> members) {
        List<MemberRef> subset = new ArrayList<>();
        for (MemberRef m : members) {
            if (rnd.nextBoolean()) {
                subset.add(m);
            }
        }
        if (subset.isEmpty()) {
            subset.add(members.get(rnd.nextInt(members.size())));
        }
        return subset;
    }

    /** Payers need not be participants (spec 7.5); amounts are positive and sum to total. */
    private static List<Payer> randomPayers(Random rnd, List<MemberRef> members, long total) {
        List<MemberRef> chosen = nonEmptySubset(rnd, members);
        long[] weights = new long[chosen.size()];
        int[] order = new int[chosen.size()];
        for (int i = 0; i < weights.length; i++) {
            weights[i] = 1 + rnd.nextInt(100);
            order[i] = chosen.get(i).sortOrder();
        }
        long[] parts = Lrm.allocate(total, weights, order);
        List<Payer> payers = new ArrayList<>();
        for (int i = 0; i < parts.length; i++) {
            if (parts[i] > 0) {
                payers.add(new Payer(chosen.get(i).id(), parts[i]));
            }
        }
        PayerValidator.validate(total, payers);
        return payers;
    }

    // ---- SHARES (BSA3, STANDALONE_SPEC 19, A185-A187) ----

    @Property(tries = 3000)
    void sharesOwedSumsToTotalWithAndWithoutAPeriod(@ForAll long seed) {
        Random rnd = new Random(seed);
        long total = 1 + rnd.nextLong(Limits.MAX_AMOUNT_MINOR);
        SharePeriod period = rnd.nextBoolean() ? null : randomPeriod(rnd);
        List<WeightedShare> shares = randomShares(rnd, members(1 + rnd.nextInt(20)), period, 1);
        Map<String, Long> owed = SplitCalculator.shares(total, shares, period);
        assertThat(owed.values().stream().mapToLong(Long::longValue).sum()).isEqualTo(total);
        assertThat(owed.values()).allSatisfy(v -> assertThat(v).isNotNegative());
        assertThat(owed).hasSize(shares.size());
    }

    @Property(tries = 2000)
    void sharesWithUnitOneAndNoPeriodEqualsEqual(
            @ForAll @LongRange(min = 1, max = 1_000_000_000_000L) long total, @ForAll long seed) {
        List<MemberRef> members = members(1 + new Random(seed).nextInt(30));
        List<WeightedShare> shares = new ArrayList<>();
        members.forEach(m -> shares.add(new WeightedShare(m.id(), m.sortOrder(), 1, null, null)));
        assertThat(SplitCalculator.shares(total, shares, null)).isEqualTo(SplitCalculator.equal(total, members));
    }

    @Property(tries = 2000)
    void scalingEveryUnitByTheSameFactorChangesNothing(@ForAll long seed) {
        Random rnd = new Random(seed);
        long total = 1 + rnd.nextInt(10_000_000);
        SharePeriod period = rnd.nextBoolean() ? null : randomPeriod(rnd);
        List<WeightedShare> base = randomShares(rnd, members(1 + rnd.nextInt(10)), period, 10);
        int k = 2 + rnd.nextInt(9); // base units 1..10, so k x units stays within 1..100
        List<WeightedShare> scaled = base.stream()
                .map(s -> new WeightedShare(s.memberId(), s.sortOrder(), s.shareUnits() * k, s.presentFrom(), s.presentTo()))
                .toList();
        assertThat(SplitCalculator.shares(total, scaled, period)).isEqualTo(SplitCalculator.shares(total, base, period));
    }

    private static SharePeriod randomPeriod(Random rnd) {
        java.time.LocalDate from = java.time.LocalDate.of(2026, 1, 1).plusDays(rnd.nextInt(700));
        return new SharePeriod(from, from.plusDays(rnd.nextInt(Limits.MAX_PERIOD_DAYS)));
    }

    /** Units 1..maxUnits; with a period, a random presence inside it (or the whole period when absent). */
    private static List<WeightedShare> randomShares(Random rnd, List<MemberRef> members, SharePeriod period,
            int maxUnits) {
        List<WeightedShare> shares = new ArrayList<>();
        for (MemberRef m : members) {
            java.time.LocalDate from = null;
            java.time.LocalDate to = null;
            if (period != null && rnd.nextBoolean()) {
                long span = java.time.temporal.ChronoUnit.DAYS.between(period.from(), period.to());
                from = period.from().plusDays(rnd.nextLong(span + 1));
                to = from.plusDays(rnd.nextLong(java.time.temporal.ChronoUnit.DAYS.between(from, period.to()) + 1));
            }
            shares.add(new WeightedShare(m.id(), m.sortOrder(), 1 + rnd.nextInt(maxUnits), from, to));
        }
        return shares;
    }
}
