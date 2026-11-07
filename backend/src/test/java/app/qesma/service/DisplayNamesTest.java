package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import org.junit.jupiter.api.Test;

class DisplayNamesTest {

    @Test
    void newUserPrefersGoogleNameThenEmailLocalPartThenPlaceholder() {
        assertThat(DisplayNames.forNewUser("  Ali Hassan ", "ali@example.com")).isEqualTo("Ali Hassan");
        assertThat(DisplayNames.forNewUser(null, "mohamed.ramadan61197@gmail.com")).isEqualTo("mohamed.ramadan61197");
        assertThat(DisplayNames.forNewUser("   ", "a@b.com")).isEqualTo("a");
        assertThat(DisplayNames.forNewUser(null, null)).isEqualTo(DisplayNames.FALLBACK);
        assertThat(DisplayNames.forNewUser("", "@weird.com")).isEqualTo("@weird.com");
    }

    @Test
    void newUserNamesAreCutToSixtyCodePointsNotUtf16Units() {
        String arabic = "م".repeat(80);
        assertThat(DisplayNames.forNewUser(arabic, null).codePointCount(0, 60)).isEqualTo(60);
        String emoji = "😀".repeat(70); // each is two UTF-16 units
        String cut = DisplayNames.forNewUser(emoji, null);
        assertThat(cut.codePointCount(0, cut.length())).isEqualTo(60);
        assertThat(cut).isEqualTo("😀".repeat(60)); // never splits a surrogate pair
    }

    @Test
    void validatedTrimsAndAcceptsBoundaryLengths() {
        assertThat(DisplayNames.validated("  Sara  ")).isEqualTo("Sara");
        assertThat(DisplayNames.validated("x")).isEqualTo("x");
        assertThat(DisplayNames.validated("ع".repeat(60))).hasSize(60);
        assertThat(DisplayNames.validated("😀".repeat(60))).isEqualTo("😀".repeat(60));
    }

    @Test
    void validatedRejectsBlankNullAndOverLong() {
        for (String bad : new String[] {null, "", "   ", "\t\n", "x".repeat(61), "😀".repeat(61)}) {
            assertThatThrownBy(() -> DisplayNames.validated(bad))
                    .isInstanceOfSatisfying(ApiException.class, e -> assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        }
    }
}
