package app.qesma.service;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Limits of the Remind action ({@code qesma.remind.*}, A108, A110).
 *
 * @param window            one reminder per (group, debtor) and at most {@code dailyCapPerUser} per sending account within
 *                          this rolling window; also the retention base of {@code remind_log}
 * @param dailyCapPerUser   soft abuse ceiling per sending account across all groups
 */
@ConfigurationProperties("qesma.remind")
public record RemindProperties(@DefaultValue("24h") Duration window,
                               @DefaultValue("20") int dailyCapPerUser) {
}
