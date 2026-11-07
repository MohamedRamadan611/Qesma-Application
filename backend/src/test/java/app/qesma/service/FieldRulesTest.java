package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import org.junit.jupiter.api.Test;

class FieldRulesTest {

    private static void assertValidationError(Runnable r) {
        assertThatThrownBy(r::run).isInstanceOfSatisfying(ApiException.class, e -> {
            assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
            assertThat(e.status().value()).isEqualTo(422);
        });
    }

    @Test
    void namesAreTrimmedAndBoundedByCodePoints() {
        assertThat(FieldRules.name("  Trip to Dahab ", 60, "name")).isEqualTo("Trip to Dahab");
        assertThat(FieldRules.name("x", 60, "name")).isEqualTo("x");
        assertThat(FieldRules.name("ع".repeat(40), 40, "displayName")).hasSize(40);
        assertThat(FieldRules.name("😀".repeat(40), 40, "displayName")).isEqualTo("😀".repeat(40));
    }

    @Test
    void blankNullAndOverLongNamesAreRejected() {
        for (String bad : new String[] {null, "", "   ", "\n\t", "x".repeat(61), "😀".repeat(61)}) {
            assertValidationError(() -> FieldRules.name(bad, 60, "name"));
        }
        assertValidationError(() -> FieldRules.name("x".repeat(41), 40, "displayName"));
    }

    @Test
    void errorMessagesNameTheFieldButNeverEchoTheInput() {
        assertThatThrownBy(() -> FieldRules.name("secret-looking-value".repeat(10), 60, "name"))
                .hasMessageContaining("name").hasMessageNotContaining("secret-looking-value");
    }

    @Test
    void groupTypeAcceptsTheFourTypesCaseInsensitively() {
        assertThat(FieldRules.groupType("TRIP")).isEqualTo("TRIP");
        assertThat(FieldRules.groupType(" housing ")).isEqualTo("HOUSING");
        assertThat(FieldRules.groupType("Outing")).isEqualTo("OUTING");
        assertThat(FieldRules.groupType("other")).isEqualTo("OTHER");
    }

    @Test
    void groupTypeRejectsEverythingElse() {
        for (String bad : new String[] {null, "", "VACATION", "TRIP;DROP TABLE", "TRIPS"}) {
            assertValidationError(() -> FieldRules.groupType(bad));
        }
    }

    @Test
    void currencyDefaultsToEgpAndNormalizesCase() {
        assertThat(FieldRules.currency(null)).isEqualTo("EGP");
        assertThat(FieldRules.currency("")).isEqualTo("EGP");
        assertThat(FieldRules.currency("   ")).isEqualTo("EGP");
        assertThat(FieldRules.currency("usd")).isEqualTo("USD");
        assertThat(FieldRules.currency(" eur ")).isEqualTo("EUR");
    }

    @Test
    void currencyMustBeARealIso4217Code() {
        // wrong shape, unknown code, and pseudo-currencies (no minor unit) are all rejected
        for (String bad : new String[] {"EG", "EGPP", "E1P", "ZZZ", "ABC", "XXX", "XTS", "XAU", "12$"}) {
            assertValidationError(() -> FieldRules.currency(bad));
        }
    }

    @Test
    void pagingBoundsAreEnforced() {
        FieldRules.page(0, 1);
        FieldRules.page(5, 100);
        assertValidationError(() -> FieldRules.page(-1, 20));
        assertValidationError(() -> FieldRules.page(0, 0));
        assertValidationError(() -> FieldRules.page(0, 101));
        assertValidationError(() -> FieldRules.page(0, Integer.MAX_VALUE));
    }
}
