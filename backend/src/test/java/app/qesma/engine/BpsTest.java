package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

/** Spec 7.1 round_half_up(amount x bps / 10000). */
class BpsTest {

    @Test
    void roundsHalfUp() {
        assertThat(Bps.percentOf(49280, 1400)).isEqualTo(6899); // 6899.2
        assertThat(Bps.percentOf(44000, 1200)).isEqualTo(5280); // exact
        assertThat(Bps.percentOf(1, 5000)).isEqualTo(1);        // 0.5 -> 1
        assertThat(Bps.percentOf(1, 4999)).isEqualTo(0);        // 0.4999 -> 0
        assertThat(Bps.percentOf(3, 5000)).isEqualTo(2);        // 1.5 -> 2
    }

    @Test
    void zeroCases() {
        assertThat(Bps.percentOf(0, 1400)).isEqualTo(0);
        assertThat(Bps.percentOf(1000, 0)).isEqualTo(0);
    }

    @Test
    void largeAmountsDoNotOverflow() {
        assertThat(Bps.percentOf(Long.MAX_VALUE, 10000)).isEqualTo(Long.MAX_VALUE);
    }

    @Test
    void rejectsNegativeAmountAndOutOfRangeBps() {
        assertThatThrownBy(() -> Bps.percentOf(-1, 100)).isInstanceOf(EngineException.class);
        assertThatThrownBy(() -> Bps.percentOf(100, -1)).isInstanceOf(EngineException.class);
        assertThatThrownBy(() -> Bps.percentOf(100, 10001)).isInstanceOf(EngineException.class);
    }
}
