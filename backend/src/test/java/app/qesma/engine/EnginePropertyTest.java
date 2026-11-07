package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
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
}
