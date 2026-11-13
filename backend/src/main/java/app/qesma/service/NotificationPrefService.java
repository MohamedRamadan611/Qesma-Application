package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.persistence.NotificationPrefStore;
import java.time.Clock;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Notification preferences (B16, A104-A106): the global switch and the per-group mute. They are applied when a
 * notification would be written ({@code GroupEventRecorder}); the feed and existing notifications are never touched.
 * Setting a value is idempotent (an upsert), so these are PUTs without an Idempotency-Key.
 */
@Service
public class NotificationPrefService {

    private static final Logger log = LoggerFactory.getLogger(NotificationPrefService.class);

    private final NotificationPrefStore prefs;
    private final GroupAccessService access;
    private final Clock clock;

    public NotificationPrefService(NotificationPrefStore prefs, GroupAccessService access, Clock clock) {
        this.prefs = prefs;
        this.access = access;
        this.clock = clock;
    }

    @Transactional
    public boolean setEnabled(UUID userId, Boolean enabled) {
        if (enabled == null) {
            throw ApiException.validation("enabled is required");
        }
        prefs.upsertGlobal(userId, !enabled, clock.instant().truncatedTo(ChronoUnit.MICROS));
        log.atInfo().addKeyValue("event", "notification_prefs.updated").addKeyValue("userId", userId)
                .addKeyValue("scope", "global").addKeyValue("enabled", enabled)
                .log("notification_prefs.updated userId={} scope=global enabled={}", userId, enabled);
        return enabled;
    }

    /** Any ACTIVE member may mute or unmute the group for themselves; everybody else gets the usual 404. */
    @Transactional
    public boolean setGroupMuted(UUID userId, UUID groupId, Boolean muted) {
        access.requireMember(userId, groupId);
        if (muted == null) {
            throw ApiException.validation("muted is required");
        }
        prefs.upsertGroup(userId, groupId, muted, clock.instant().truncatedTo(ChronoUnit.MICROS));
        log.atInfo().addKeyValue("event", "notification_prefs.updated").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("muted", muted)
                .log("notification_prefs.updated userId={} groupId={} muted={}", userId, groupId, muted);
        return muted;
    }

    @Transactional(readOnly = true)
    public boolean isEnabled(UUID userId) {
        return prefs.isEnabled(userId);
    }
}
