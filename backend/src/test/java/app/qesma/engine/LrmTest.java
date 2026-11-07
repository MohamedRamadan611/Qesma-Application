package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Arrays;
import org.junit.jupiter.api.Test;

/** Spec 7.1 Largest Remainder Method. */
class LrmTest {

    private static final int[] ORDER3 = {1, 2, 3};

    @Test
    void equalWeightsGiveExtraUnitToLowestSortOrder() { // V3
        assertThat(Lrm.allocate(10000, new long[] {1, 1, 1}, ORDER3)).containsExactly(3334, 3333, 3333);
    }

    @Test
    void tieBreakUsesSortOrderNotArrayPosition() {
        // sortOrder 1 sits at index 1, so it receives the single leftover unit.
        assertThat(Lrm.allocate(100, new long[] {1, 1, 1}, new int[] {3, 1, 2})).containsExactly(33, 34, 33);
    }

    @Test
    void largestFractionalRemainderWinsBeforeSortOrder() {
        // total 10, weights 1:2 -> exact 3.33 / 6.67 -> floors 3,6, leftover goes to the larger remainder (index 1).
        assertThat(Lrm.allocate(10, new long[] {1, 2}, new int[] {1, 2})).containsExactly(3, 7);
    }

    @Test
    void allZeroWeightsFallBackToEqualWeights() {
        assertThat(Lrm.allocate(100, new long[] {0, 0, 0}, ORDER3)).containsExactly(34, 33, 33);
    }

    @Test
    void zeroWeightMemberGetsNothingWhenOthersHavePositiveWeight() {
        assertThat(Lrm.allocate(3, new long[] {0, 1, 1}, ORDER3)).containsExactly(0, 2, 1);
    }

    @Test
    void singleMemberGetsEverything() {
        assertThat(Lrm.allocate(12345, new long[] {7}, new int[] {1})).containsExactly(12345);
    }

    @Test
    void oneUnitAmongSevenGoesToLowestSortOrder() {
        long[] ones = new long[7];
        Arrays.fill(ones, 1);
        assertThat(Lrm.allocate(1, ones, new int[] {1, 2, 3, 4, 5, 6, 7})).containsExactly(1, 0, 0, 0, 0, 0, 0);
    }

    @Test
    void zeroTotalAllocatesZeros() {
        assertThat(Lrm.allocate(0, new long[] {5, 9}, new int[] {1, 2})).containsExactly(0, 0);
    }

    @Test
    void negativeTotalAllocatesAbsoluteValueThenAppliesSign() {
        assertThat(Lrm.allocate(-100, new long[] {1, 1, 1}, ORDER3)).containsExactly(-34, -33, -33);
    }

    @Test
    void largeEgpAmountSplitsExactly() { // 1,250,000.50 EGP = 125,000,050 piasters
        assertThat(Lrm.allocate(125_000_050L, new long[] {1, 1, 1}, ORDER3))
                .containsExactly(41_666_684L, 41_666_683L, 41_666_683L);
    }

    @Test
    void extremeValuesDoNotOverflow() {
        long[] parts = Lrm.allocate(Long.MAX_VALUE, new long[] {Long.MAX_VALUE, Long.MAX_VALUE}, new int[] {1, 2});
        assertThat(parts[0] + parts[1]).isEqualTo(Long.MAX_VALUE);
        assertThat(parts[0] - parts[1]).isEqualTo(1);
    }

    @Test
    void rejectsInvalidInput() {
        assertThatThrownBy(() -> Lrm.allocate(10, new long[] {}, new int[] {}))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
        assertThatThrownBy(() -> Lrm.allocate(10, new long[] {1, -1}, new int[] {1, 2}))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
        assertThatThrownBy(() -> Lrm.allocate(10, new long[] {1, 1}, new int[] {1}))
                .isInstanceOf(EngineException.class);
        assertThatThrownBy(() -> Lrm.allocate(Long.MIN_VALUE, new long[] {1}, new int[] {1}))
                .isInstanceOf(EngineException.class);
    }
}
