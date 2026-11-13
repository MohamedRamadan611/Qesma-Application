package app.qesma.service;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Retention of events and notifications ({@code qesma.activity.*}, A103).
 *
 * @param retention     events (and, by cascade, their notifications) older than this are purged
 * @param purgeInterval delay between runs of the purge job
 */
@ConfigurationProperties("qesma.activity")
public record ActivityProperties(@DefaultValue("180d") Duration retention,
                                 @DefaultValue("PT6H") Duration purgeInterval) {
}
