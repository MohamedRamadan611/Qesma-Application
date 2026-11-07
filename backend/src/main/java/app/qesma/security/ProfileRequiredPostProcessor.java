package app.qesma.security;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;

/**
 * Review SEC-001/COR-001: there is deliberately no default profile, because the {@code local} profile carries a
 * development-only signing key that is public in git. Starting without any profile fails immediately with an
 * instruction, instead of silently running with the wrong configuration or dying later on a missing datasource.
 */
public class ProfileRequiredPostProcessor implements EnvironmentPostProcessor, Ordered {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        if (environment.getActiveProfiles().length == 0) {
            throw new IllegalStateException("No Spring profile is active. Start with SPRING_PROFILES_ACTIVE=prod "
                    + "(production: all secrets from the environment) or --spring.profiles.active=local,fake-auth "
                    + "(development). There is deliberately no default profile.");
        }
    }

    /** After the configuration files were read, so profiles set there or in the environment are known. */
    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }
}
