package app.qesma;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

/** One real PostgreSQL container shared by all integration test classes in the JVM (never H2). */
public abstract class AbstractIntegrationTest {

    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16.6-alpine")
            .withCommand("postgres", "-c", "max_connections=400"); // many cached Spring contexts share this one database

    static {
        POSTGRES.start(); // stopped by Testcontainers' Ryuk when the JVM exits
    }

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }
}
