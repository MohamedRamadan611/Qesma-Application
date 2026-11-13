package app.qesma.service;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/** Turns on {@code @Scheduled} jobs (the idempotency-key cleanup and the activity purge, B15). */
@Configuration
@EnableScheduling
public class SchedulingConfig {
}
