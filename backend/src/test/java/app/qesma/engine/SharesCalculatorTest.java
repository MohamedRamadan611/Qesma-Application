package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** SHARES boundaries (STANDALONE_SPEC 19.1, A185-A187). The spec vectors V21-V28 run in {@link FixtureTest}. */
class SharesCalculatorTest {

    private static final LocalDate NOV_1 = LocalDate.of(2026, 11, 1);
    private static final LocalDate NOV_30 = LocalDate.of(2026, 11, 30);
    private static final SharePeriod NOVEMBER = new SharePeriod(NOV_1, NOV_30);

    private static WeightedShare a(int units) {
        return new WeightedShare("A", 1, units, null, null);
    }

    private static WeightedShare b(int units, LocalDate from, LocalDate to) {
        return new WeightedShare("B", 2, units, from, to);
    }

    private static void assertRejected(long total, List<WeightedShare> shares, SharePeriod period) {
        assertThatThrownBy(() -> SplitCalculator.shares(total, shares, period))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void unitsOneAndOneHundredAreAcceptedZeroAndOneHundredOneAreNot() {
        assertThat(SplitCalculator.shares(10_100, List.of(a(1), b(100, null, null)), null))
                .containsExactly(Map.entry("A", 100L), Map.entry("B", 10_000L));
        assertRejected(1000, List.of(a(0), b(1, null, null)), null);
        assertRejected(1000, List.of(a(101), b(1, null, null)), null);
        assertRejected(1000, List.of(a(-1)), null);
    }

    @Test
    void oneDayPresenceWeighsOneDay() {
        Map<String, Long> owed = SplitCalculator.shares(3100, List.of(a(1), b(1, NOV_30, NOV_30)), NOVEMBER);
        assertThat(owed).containsExactly(Map.entry("A", 3000L), Map.entry("B", 100L));
    }

    @Test
    void presenceEqualToThePeriodIsTheSameAsNoPresence() {
        Map<String, Long> explicit = SplitCalculator.shares(10_000, List.of(a(2), b(1, NOV_1, NOV_30)), NOVEMBER);
        Map<String, Long> defaulted = SplitCalculator.shares(10_000, List.of(a(2), b(1, null, null)), NOVEMBER);
        assertThat(explicit).isEqualTo(defaulted).containsExactly(Map.entry("A", 6667L), Map.entry("B", 3333L));
    }

    @Test
    void aPeriodOf366DaysIsAcceptedAnd367IsNot() {
        LocalDate from = LocalDate.of(2026, 1, 1);
        SharePeriod days366 = new SharePeriod(from, from.plusDays(365));
        SharePeriod days367 = new SharePeriod(from, from.plusDays(366));
        assertThat(SplitCalculator.shares(36_600, List.of(a(100)), days366)).containsExactly(Map.entry("A", 36_600L));
        assertRejected(36_600, List.of(a(100)), days367);
    }

    @Test
    void largestWeightCombinationStaysExact() {
        // 100 units x 366 days for every one of 100 participants: Σweight 3,660,000, total at the A43 cap.
        LocalDate from = LocalDate.of(2026, 1, 1);
        SharePeriod year = new SharePeriod(from, from.plusDays(365));
        List<WeightedShare> shares = new java.util.ArrayList<>();
        for (int i = 0; i < 100; i++) {
            shares.add(new WeightedShare("m" + i, i + 1, 100, null, null));
        }
        Map<String, Long> owed = SplitCalculator.shares(Limits.MAX_AMOUNT_MINOR, shares, year);
        assertThat(owed.values().stream().mapToLong(Long::longValue).sum()).isEqualTo(Limits.MAX_AMOUNT_MINOR);
    }

    @Test
    void shapeRulesAreRejected() {
        assertRejected(1000, List.of(), null); // no participant
        assertRejected(1000, List.of(a(1), new WeightedShare("A", 1, 2, null, null)), null); // duplicate
        assertRejected(1000, List.of(a(1), b(1, NOV_1, null)), null); // presence without a period
        assertRejected(1000, List.of(a(1), b(1, NOV_1.minusDays(1), null)), NOVEMBER); // before the period
        assertRejected(1000, List.of(a(1), b(1, null, NOV_30.plusDays(1))), NOVEMBER); // after the period
        assertRejected(1000, List.of(a(1), b(1, NOV_30, NOV_1)), NOVEMBER); // reversed presence
        assertRejected(1000, List.of(a(1)), new SharePeriod(NOV_1, null)); // one bound
        assertRejected(1000, List.of(a(1)), new SharePeriod(null, NOV_30)); // one bound
        assertRejected(1000, List.of(a(1)), new SharePeriod(NOV_30, NOV_1)); // reversed period
        assertRejected(0, List.of(a(1)), null); // total
    }

    @Test
    void aShareThatRoundsToZeroIsKept() {
        assertThat(SplitCalculator.shares(1, List.of(a(1), b(1, null, null)), null))
                .containsExactly(Map.entry("A", 1L), Map.entry("B", 0L));
    }

    @Test
    void resultIsInSortOrderWhateverTheInputOrder() {
        assertThat(SplitCalculator.shares(1000, List.of(b(1, null, null), a(1)), null).keySet())
                .containsExactly("A", "B");
    }
}
