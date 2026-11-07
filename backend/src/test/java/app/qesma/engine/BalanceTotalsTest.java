package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.MemberTotals;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import org.junit.jupiter.api.Test;

/** The per-member-totals form of the balance rule (what the database sums) against the row-based form and V1/V2. */
class BalanceTotalsTest {

    private static final List<MemberRef> ROSTER = List.of(new MemberRef("M", 1), new MemberRef("A", 2),
            new MemberRef("S", 3));

    @Test
    void v1FromTotalsGivesTheSpecNets() {
        // E1: M paid 100.00, A and S owe 50.00. E2: S paid 30.00, A owes 30.00.
        Map<String, Long> nets = BalanceCalculator.netsFromTotals(ROSTER, List.of(
                new MemberTotals("M", 10000, 0, 0, 0), new MemberTotals("A", 0, 8000, 0, 0),
                new MemberTotals("S", 3000, 5000, 0, 0)));
        assertThat(nets).containsExactly(Map.entry("M", 10000L), Map.entry("A", -8000L), Map.entry("S", -2000L));
    }

    @Test
    void v2SettlementMovesTheNetsByTheSentAndReceivedAmounts() {
        Map<String, Long> nets = BalanceCalculator.netsFromTotals(ROSTER, List.of(
                new MemberTotals("M", 10000, 0, 0, 8000), new MemberTotals("A", 0, 8000, 8000, 0),
                new MemberTotals("S", 3000, 5000, 0, 0)));
        assertThat(nets).containsExactly(Map.entry("M", 2000L), Map.entry("A", 0L), Map.entry("S", -2000L));
    }

    @Test
    void membersWithoutTotalsAreZeroAndListedInSortOrder() {
        Map<String, Long> nets = BalanceCalculator.netsFromTotals(ROSTER, List.of());
        assertThat(nets.keySet()).containsExactly("M", "A", "S");
        assertThat(nets.values()).containsOnly(0L);
    }

    @Test
    void anUnknownMemberOrABrokenLedgerIsRejected() {
        assertThatThrownBy(() -> BalanceCalculator.netsFromTotals(ROSTER,
                List.of(new MemberTotals("X", 5, 0, 0, 0), new MemberTotals("M", 0, 5, 0, 0))))
                .isInstanceOfSatisfying(EngineException.class,
                        e -> assertThat(e.code()).isEqualTo(EngineErrorCode.MEMBER_NOT_IN_GROUP));
        // paid more than owed overall: the invariant is violated and must never be shown as a balance
        assertThatThrownBy(() -> BalanceCalculator.netsFromTotals(ROSTER, List.of(new MemberTotals("M", 100, 0, 0, 0))))
                .isInstanceOf(EngineException.class).hasMessageContaining("sum to zero");
    }

    @Test
    void overflowIsATypedErrorNotAWrapAround() {
        assertThatThrownBy(() -> BalanceCalculator.netsFromTotals(ROSTER,
                List.of(new MemberTotals("M", Long.MAX_VALUE, 0, 0, 0), new MemberTotals("A", Long.MAX_VALUE, 0, 0, 0))))
                .isInstanceOf(EngineException.class);
    }

    @Test
    void theTotalsFormEqualsTheRowFormOnRandomLedgersWithSettlements() {
        Random rnd = new Random(7L);
        List<MemberRef> roster = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            roster.add(new MemberRef("m" + i, i + 1));
        }
        for (int round = 0; round < 300; round++) {
            List<ExpenseLedgerEntry> expenses = new ArrayList<>();
            Map<String, long[]> totals = new LinkedHashMap<>();   // paid, owed, sent, received
            for (int e = 0, n = rnd.nextInt(12); e < n; e++) {
                long amount = 1 + rnd.nextInt(100000);
                String payer = "m" + rnd.nextInt(8);
                Map<String, Long> owed = new LinkedHashMap<>();
                long left = amount;
                for (int k = 0; k < 3; k++) {
                    long part = k == 2 ? left : rnd.nextInt((int) left + 1);
                    owed.merge("m" + rnd.nextInt(8), part, Long::sum);
                    left -= part;
                }
                expenses.add(new ExpenseLedgerEntry(List.of(new Payer(payer, amount)), owed));
                totals.computeIfAbsent(payer, k -> new long[4])[0] += amount;
                owed.forEach((m, v) -> totals.computeIfAbsent(m, k -> new long[4])[1] += v);
            }
            List<SettlementEntry> settlements = new ArrayList<>();
            for (int s = 0, n = rnd.nextInt(6); s < n; s++) {
                int from = rnd.nextInt(8);
                int to = (from + 1 + rnd.nextInt(7)) % 8;
                long amount = 1 + rnd.nextInt(50000);
                settlements.add(new SettlementEntry("m" + from, "m" + to, amount));
                totals.computeIfAbsent("m" + from, k -> new long[4])[2] += amount;
                totals.computeIfAbsent("m" + to, k -> new long[4])[3] += amount;
            }
            List<MemberTotals> list = new ArrayList<>();
            totals.forEach((m, v) -> list.add(new MemberTotals(m, v[0], v[1], v[2], v[3])));

            Map<String, Long> fromRows = BalanceCalculator.nets(roster, expenses, settlements);
            Map<String, Long> fromTotals = BalanceCalculator.netsFromTotals(roster, list);

            assertThat(fromTotals).as("round " + round).isEqualTo(fromRows);
            assertThat(fromTotals.values().stream().mapToLong(Long::longValue).sum()).isZero();
            // applying the suggested transfers zeroes every net
            Map<String, Long> after = new LinkedHashMap<>(fromTotals);
            for (Transfer t : Simplifier.simplify(fromTotals, roster)) {
                after.merge(t.fromMemberId(), t.amountMinor(), Long::sum);
                after.merge(t.toMemberId(), -t.amountMinor(), Long::sum);
            }
            assertThat(after.values()).containsOnly(0L);
        }
    }

    @Test
    void theAmountCapIsTenBillionPounds() {
        assertThat(Limits.MAX_AMOUNT_MINOR).isEqualTo(1_000_000_000_000L);
        assertThat(Limits.withinAmountLimit(Limits.MAX_AMOUNT_MINOR)).isTrue();
        assertThat(Limits.withinAmountLimit(Limits.MAX_AMOUNT_MINOR + 1)).isFalse();
    }
}
