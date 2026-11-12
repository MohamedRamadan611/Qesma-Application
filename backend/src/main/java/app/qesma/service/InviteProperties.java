package app.qesma.service;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Invitation settings ({@code qesma.invites.*}, B11).
 *
 * @param linkBase       start of the shareable link; the invite code is appended (the Android App Link opens the app)
 * @param rateLimit      per-client-IP limit on {@code /api/v1/invites/**} (guessing a code needs many requests)
 * @param failedLookups  per-user cap on lookups that found no usable invite, so one account cannot scan for codes
 */
@ConfigurationProperties("qesma.invites")
public record InviteProperties(
        @DefaultValue("https://qesma.app/join/") String linkBase,
        @DefaultValue RateLimit rateLimit,
        @DefaultValue FailedLookups failedLookups) {

    public record RateLimit(@DefaultValue("30") int maxRequests, @DefaultValue("1m") Duration window) {
    }

    public record FailedLookups(@DefaultValue("10") int max, @DefaultValue("15m") Duration window) {
    }
}
