package app.qesma.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import org.junit.jupiter.api.Test;

/** The password rules (ADR-007) as a table: lengths at the edges, bytes versus characters, email, common passwords. */
class PasswordPolicyTest {

    private static void rejected(String password, String email, String messagePart) {
        assertThatThrownBy(() -> PasswordPolicy.check(password, email))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).code()).isEqualTo(ErrorCode.VALIDATION_ERROR))
                .hasMessageContaining(messagePart)
                .satisfies(e -> assertThat(e.getMessage()).as("never echoes the password").doesNotContain(password.isBlank() ? "\u0000" : password));
    }

    @Test
    void lengthIsCountedInCharactersAtTheLowEndAndBytesAtTheHighEnd() {
        rejected("1234567", null, "at least 8");
        assertThatCode(() -> PasswordPolicy.check("abcdefgh", null)).doesNotThrowAnyException();
        assertThatCode(() -> PasswordPolicy.check("a".repeat(72), null)).doesNotThrowAnyException();
        rejected("a".repeat(73), null, "at most 72 bytes");
        assertThatCode(() -> PasswordPolicy.check("ك".repeat(36), null)).as("36 Arabic letters = 72 bytes").doesNotThrowAnyException();
        rejected("ك".repeat(37), null, "at most 72 bytes");
        assertThatCode(() -> PasswordPolicy.check("كلمةسر12", null)).as("8 characters").doesNotThrowAnyException();
    }

    @Test
    void blankEmailAndCommonPasswordsAreRefused() {
        rejected("        ", null, "blank");
        rejected("", null, "blank");
        rejected("Ali@Example.com", "ali@example.com", "email");
        rejected("Password1", null, "too common");
        rejected("12345678", null, "too common");
        assertThatCode(() -> PasswordPolicy.check("correct horse battery", "ali@example.com")).doesNotThrowAnyException();
    }
}
