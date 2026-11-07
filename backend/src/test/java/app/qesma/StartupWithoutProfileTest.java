package app.qesma;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;

/**
 * SEC-001 / COR-001: with no profile the application must refuse to start (there is no default profile, so no
 * publicly known dev signing key can be picked up by accident). Needs no database: it fails during configuration.
 */
class StartupWithoutProfileTest {

    @Test
    void anUnconfiguredStartIsRefusedAndNamesWhatIsMissing() {
        assertThat(System.getenv("SPRING_PROFILES_ACTIVE")).as("this test needs a clean environment").isNull();

        assertThatThrownBy(() -> new SpringApplicationBuilder(QesmaApplication.class)
                .web(WebApplicationType.NONE).run("--spring.main.banner-mode=off", "--logging.level.root=OFF"))
                .hasStackTraceContaining("No Spring profile is active");
    }
}
