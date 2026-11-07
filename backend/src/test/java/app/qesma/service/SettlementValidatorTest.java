package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.engine.Limits;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SettlementValidatorTest {

    private static final UUID A = UUID.randomUUID();
    private static final UUID B = UUID.randomUUID();
    private static final LocalDate DAY = LocalDate.of(2026, 10, 20);

    private static void assertInvalid(SettlementCommand c) {
        assertThatThrownBy(() -> SettlementValidator.validate(c)).isInstanceOfSatisfying(ApiException.class, e -> {
            assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
            assertThat(e.status().value()).isEqualTo(422);
        });
    }

    @Test
    void aValidSettlementKeepsItsFieldsAndTrimsTheNote() {
        SettlementValidator.Valid v = SettlementValidator.validate(new SettlementCommand(A, B, 8000L, DAY, "  cash  "));
        assertThat(v.note()).isEqualTo("cash");
        assertThat(v.amountMinor()).isEqualTo(8000);
        assertThat(SettlementValidator.validate(new SettlementCommand(A, B, 1L, DAY, "   ")).note()).isNull();
        assertThat(SettlementValidator.validate(new SettlementCommand(A, B, 1L, DAY, null)).note()).isNull();
    }

    @Test
    void membersAmountAndDateAreRequiredAndSane() {
        assertInvalid(null);
        assertInvalid(new SettlementCommand(null, B, 1L, DAY, null));
        assertInvalid(new SettlementCommand(A, null, 1L, DAY, null));
        assertInvalid(new SettlementCommand(A, A, 1L, DAY, null));                       // from == to
        for (Long bad : new Long[] {null, 0L, -5L, Long.MIN_VALUE, Limits.MAX_AMOUNT_MINOR + 1, Long.MAX_VALUE}) {
            assertInvalid(new SettlementCommand(A, B, bad, DAY, null));
        }
        SettlementValidator.validate(new SettlementCommand(A, B, Limits.MAX_AMOUNT_MINOR, DAY, null)); // at the cap
        assertInvalid(new SettlementCommand(A, B, 1L, null, null));
        assertInvalid(new SettlementCommand(A, B, 1L, LocalDate.of(1999, 12, 31), null));
        assertInvalid(new SettlementCommand(A, B, 1L, LocalDate.of(2101, 1, 1), null));
    }

    @Test
    void theNoteIsLimitedTo200CharactersCountedAsCodePoints() {
        SettlementValidator.validate(new SettlementCommand(A, B, 1L, DAY, "x".repeat(200)));
        SettlementValidator.validate(new SettlementCommand(A, B, 1L, DAY, "😀".repeat(200)));
        assertInvalid(new SettlementCommand(A, B, 1L, DAY, "x".repeat(201)));
        assertInvalid(new SettlementCommand(A, B, 1L, DAY, "😀".repeat(201)));
    }
}
