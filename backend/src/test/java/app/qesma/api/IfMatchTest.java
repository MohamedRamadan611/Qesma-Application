package app.qesma.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class IfMatchTest {

    @Test
    void parsesQuotedWeakAndBareVersions() {
        assertThat(IfMatch.version("\"3\"")).isEqualTo(3);
        assertThat(IfMatch.version("W/\"12\"")).isEqualTo(12);
        assertThat(IfMatch.version("7")).isEqualTo(7);
        assertThat(IfMatch.version("  \"1\"  ")).isEqualTo(1);
    }

    @Test
    void missingHeaderIs428() {
        for (String missing : new String[] {null, "", "  "}) {
            assertThatThrownBy(() -> IfMatch.version(missing)).isInstanceOfSatisfying(ApiException.class, e ->
                    assertThat(e.status().value()).isEqualTo(428));
        }
    }

    @Test
    void anythingThatIsNotASingleVersionIs422() {
        for (String bad : new String[] {"*", "\"1\", \"2\"", "abc", "\"abc\"", "-1", "\"-1\"", "1.5", "\"1", "9999999999",
                "W/1"}) {
            assertThatThrownBy(() -> IfMatch.version(bad)).as(bad).isInstanceOfSatisfying(ApiException.class, e -> {
                assertThat(e.status().value()).isEqualTo(422);
                assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
            });
        }
    }
}
