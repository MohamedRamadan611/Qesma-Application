package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Spec 7.2 EQUAL, 7.3 EXACT, 7.5 payers. */
class SplitCalculatorTest {

    private static final MemberRef M1 = new MemberRef("M1", 1);
    private static final MemberRef M2 = new MemberRef("M2", 2);
    private static final MemberRef M3 = new MemberRef("M3", 3);

    private static void assertCode(Runnable r, EngineErrorCode code) {
        assertThatThrownBy(r::run).isInstanceOf(EngineException.class).extracting("code").isEqualTo(code);
    }

    @Test
    void equalGivesExtraPiasterToLowestSortOrderRegardlessOfInputOrder() {
        Map<String, Long> owed = SplitCalculator.equal(10000, List.of(M3, M1, M2));
        assertThat(owed).containsEntry("M1", 3334L).containsEntry("M2", 3333L).containsEntry("M3", 3333L);
        assertThat(owed.values().stream().mapToLong(Long::longValue).sum()).isEqualTo(10000);
    }

    @Test
    void equalKeepsParticipantsThatOweZero() {
        Map<String, Long> owed = SplitCalculator.equal(2, List.of(M1, M2, M3));
        assertThat(owed).containsEntry("M1", 1L).containsEntry("M2", 1L).containsEntry("M3", 0L);
    }

    @Test
    void equalRejectsBadInput() {
        assertCode(() -> SplitCalculator.equal(100, List.of()), EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.equal(0, List.of(M1)), EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.equal(-5, List.of(M1)), EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.equal(100, List.of(M1, M1)), EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void exactAcceptsMatchingSumAndAllowsZeroShares() {
        Map<String, Long> owed = SplitCalculator.exact(10000,
                List.of(new Share("A", 5000), new Share("S", 5000), new Share("M", 0)));
        assertThat(owed).containsEntry("A", 5000L).containsEntry("S", 5000L).containsEntry("M", 0L);
    }

    @Test
    void exactRejectsSumMismatch() {
        assertCode(() -> SplitCalculator.exact(10000, List.of(new Share("A", 5000), new Share("S", 4999))),
                EngineErrorCode.SPLIT_TOTAL_MISMATCH);
        assertCode(() -> SplitCalculator.exact(10000, List.of(new Share("A", 10001))),
                EngineErrorCode.SPLIT_TOTAL_MISMATCH);
    }

    @Test
    void exactRejectsInvalidShares() {
        assertCode(() -> SplitCalculator.exact(100, List.of()), EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.exact(100, List.of(new Share("A", -10), new Share("B", 110))),
                EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.exact(100, List.of(new Share("A", 50), new Share("A", 50))),
                EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> SplitCalculator.exact(0, List.of(new Share("A", 0))), EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void payersMustSumToTotal() {
        PayerValidator.validate(50000, List.of(new Payer("X", 30000), new Payer("Y", 20000)));
        assertCode(() -> PayerValidator.validate(50000, List.of(new Payer("X", 30000), new Payer("Y", 19999))),
                EngineErrorCode.PAYERS_TOTAL_MISMATCH);
    }

    @Test
    void payersRejectEmptyZeroNegativeAndDuplicates() {
        assertCode(() -> PayerValidator.validate(100, List.of()), EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> PayerValidator.validate(100, List.of(new Payer("X", 0), new Payer("Y", 100))),
                EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> PayerValidator.validate(100, List.of(new Payer("X", -5), new Payer("Y", 105))),
                EngineErrorCode.VALIDATION_ERROR);
        assertCode(() -> PayerValidator.validate(100, List.of(new Payer("X", 50), new Payer("X", 50))),
                EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void payerAmountOverflowIsATypedError() {
        assertCode(() -> PayerValidator.validate(100,
                List.of(new Payer("X", Long.MAX_VALUE), new Payer("Y", Long.MAX_VALUE))),
                EngineErrorCode.VALIDATION_ERROR);
    }
}
