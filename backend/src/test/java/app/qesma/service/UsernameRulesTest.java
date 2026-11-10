package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import org.junit.jupiter.api.Test;

/** Sign-in names (ADR-008) as a table. */
class UsernameRulesTest {

    @Test
    void namesAreTrimmedAndLowerCased() {
        assertThat(UsernameRules.normalize("  Ali.Hassan-9_x ")).isEqualTo("ali.hassan-9_x");
        assertThat(UsernameRules.normalize("علي_حسن")).isEqualTo("علي_حسن");
        assertThat(UsernameRules.normalize("abc")).isEqualTo("abc");
        assertThat(UsernameRules.normalize("a".repeat(30))).hasSize(30);
    }

    @Test
    void unacceptableNamesAreRefused() {
        for (String bad : new String[] {null, "", "  ", "ab", "a".repeat(31), "has space", "a@b.com", ".leading", "-leading", "_leading",
                "trailing.", "emoji😀", "admin", "ROOT", "Qesma", "tab\tname"}) {
            assertThatThrownBy(() -> UsernameRules.normalize(bad)).as("[" + bad + "]").isInstanceOf(ApiException.class);
        }
    }

    @Test
    void theSignInLookupIsLenientSoOlderAccountsStillFindTheirName() {
        assertThat(UsernameRules.lookupKey("  Ali@Example.com ")).isEqualTo("ali@example.com");
        assertThat(UsernameRules.lookupKey("Ali")).isEqualTo("ali");
        assertThat(UsernameRules.lookupKey(null)).isNull();
        assertThat(UsernameRules.lookupKey("  ")).isNull();
        assertThat(UsernameRules.lookupKey("two words")).isNull();
        assertThat(UsernameRules.lookupKey("x".repeat(255))).isNull();
    }
}
