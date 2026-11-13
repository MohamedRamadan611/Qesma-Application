package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

/** B14 / A90: the validation matrix of the two handle types. Pure rules, no Spring. */
class PaymentHandleRulesTest {

    // ---- wallet ---------------------------------------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(strings = {
            "01012345678", "01112345678", "01212345678", "01512345678",
            "010 1234 5678", "010-1234-5678", " 010 12345678 ",
            "٠١٠١٢٣٤٥٦٧٨",                       // Arabic-Indic digits
            "۰۱۰۱۲۳۴۵۶۷۸",                       // Extended Arabic-Indic digits
            "٠١٠ ١٢٣٤-٥٦٧٨",                    // Arabic digits with a space and a dash
            "+201012345678", "+20 10 1234 5678", "00201012345678"})
    void goodWalletsAreNormalisedToElevenDigits(String raw) {
        assertThat(PaymentHandleRules.wallet(raw)).isIn("01012345678", "01112345678", "01212345678", "01512345678");
    }

    @Test
    void walletNormalisationGivesTheExactStoredForm() {
        assertThat(PaymentHandleRules.wallet("٠١٠١٢٣٤٥٦٧٨")).isEqualTo("01012345678");
        assertThat(PaymentHandleRules.wallet("+20 10 1234 5678")).isEqualTo("01012345678");
        assertThat(PaymentHandleRules.wallet("010-1234-5678")).isEqualTo("01012345678");
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "01312345678",                // 013 is not an Egyptian mobile prefix
            "0101234567", "010123456789", // 10 and 12 digits
            "1012345678", "21012345678",  // no leading 0
            "010123456ab", "abc",
            "010.1234.5678", "010/1234/5678", "(010) 12345678",
            "+211012345678", "+2001012345678", "++201012345678",
            "---", "٠١٠١٢٣٤٥٦٧",         // only separators; ten Arabic digits
            "0101234567٨٩", "01012345678\n01012345678"})
    void badWalletsAreRejectedNamingTheFieldAndNeverEchoingTheValue(String raw) {
        assertThatThrownBy(() -> PaymentHandleRules.wallet(raw))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).contains("wallet").as("the same text for every bad value: nothing is echoed")
                            .isEqualTo(messageOf(() -> PaymentHandleRules.wallet("x")));
                });
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "   ", "\t"})
    void aBlankWalletMeansRemove(String raw) {
        assertThat(PaymentHandleRules.wallet(raw)).isNull();
    }

    // ---- instapay -------------------------------------------------------------------------------------------------

    @ParameterizedTest
    @ValueSource(strings = {"ali@instapay", "Ali@InstaPay", "  ali@instapay  ", "a.b-c_d@bank.eg", "x@y", "ali99@cib"})
    void goodInstapayAddressesAreTrimmedAndLowerCased(String raw) {
        String stored = PaymentHandleRules.instapay(raw);
        assertThat(stored).isEqualTo(raw.strip().toLowerCase());
    }

    @Test
    void instapayLengthBoundsAreInclusive() {
        assertThat(PaymentHandleRules.instapay("a@b")).isEqualTo("a@b");                               // 3
        String sixty = "a".repeat(40) + "@" + "b".repeat(19);                                          // 60
        assertThat(PaymentHandleRules.instapay(sixty)).isEqualTo(sixty);
        assertThatThrownBy(() -> PaymentHandleRules.instapay("a".repeat(41) + "@" + "b".repeat(19)))    // 61
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> PaymentHandleRules.instapay("ab")).isInstanceOf(ApiException.class);   // 2
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "noatsign", "a@@b", "a@b@c", "@bank", "ali@", "al i@bank", "ali@ba nk", "ali\t@bank",
            "ali@bank\nx", "علي@instapay", "ali@بنك",
            "ali‮@bank",       // right-to-left override
            "ali​@bank",       // zero-width space
            "K@bank",          // Kelvin sign: lower-cases to an ASCII k, so ASCII is checked first
            "ali@bank!", "ali+tag@bank", "ali@bank/x", "<script>@x"})
    void badInstapayAddressesAreRejectedNamingTheFieldAndNeverEchoingTheValue(String raw) {
        assertThatThrownBy(() -> PaymentHandleRules.instapay(raw))
                .isInstanceOfSatisfying(ApiException.class, e -> {
                    assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
                    assertThat(e.getMessage()).contains("instapay").as("the same text for every bad value: nothing is echoed")
                            .isEqualTo(messageOf(() -> PaymentHandleRules.instapay("x")));
                });
    }

    @ParameterizedTest
    @NullAndEmptySource
    @ValueSource(strings = {" ", "\t"})
    void aBlankInstapayMeansRemove(String raw) {
        assertThat(PaymentHandleRules.instapay(raw)).isNull();
    }

    private static String messageOf(Runnable call) {
        try {
            call.run();
        } catch (ApiException e) {
            return e.getMessage();
        }
        throw new AssertionError("expected a validation error");
    }
}
