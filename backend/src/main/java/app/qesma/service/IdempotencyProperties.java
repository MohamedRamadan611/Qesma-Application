package app.qesma.service;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Idempotency settings ({@code qesma.idempotency.*}). Spec 8.3: keys expire after 24 hours.
 *
 * @param ttl             how long a stored response can be replayed
 * @param cleanupInterval delay between runs of the cleanup job
 */
@ConfigurationProperties("qesma.idempotency")
public record IdempotencyProperties(@DefaultValue("24h") Duration ttl,
                                    @DefaultValue("1h") Duration cleanupInterval) {
}
