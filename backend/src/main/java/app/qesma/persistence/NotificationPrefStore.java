package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Notification preferences (B16, A104-A105) in plain SQL. A row exists only once a user changed something; no row means
 * the default (enabled, not muted). The global switch is the row with {@code group_id} NULL ({@code muted = true} means
 * notifications off). Every statement is scoped by the caller's own user id.
 */
@Repository
public class NotificationPrefStore {

    private final JdbcTemplate jdbc;

    public NotificationPrefStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Idempotent upsert of the global switch ({@code ux_notification_prefs_global}). */
    public void upsertGlobal(UUID userId, boolean muted, Instant now) {
        jdbc.update("""
                insert into notification_prefs (id, user_id, group_id, muted, updated_at)
                values (?, ?, null, ?, ?)
                on conflict (user_id) where group_id is null
                do update set muted = excluded.muted, updated_at = excluded.updated_at
                """, UUID.randomUUID(), userId, muted, Timestamp.from(now));
    }

    /** Idempotent upsert of one group's mute ({@code ux_notification_prefs_group}). */
    public void upsertGroup(UUID userId, UUID groupId, boolean muted, Instant now) {
        jdbc.update("""
                insert into notification_prefs (id, user_id, group_id, muted, updated_at)
                values (?, ?, ?, ?, ?)
                on conflict (user_id, group_id) where group_id is not null
                do update set muted = excluded.muted, updated_at = excluded.updated_at
                """, UUID.randomUUID(), userId, groupId, muted, Timestamp.from(now));
    }

    public boolean isEnabled(UUID userId) {
        List<Boolean> rows = jdbc.queryForList(
                "select muted from notification_prefs where user_id = ? and group_id is null", Boolean.class, userId);
        return rows.isEmpty() || !rows.get(0);
    }

    public boolean isGroupMuted(UUID userId, UUID groupId) {
        List<Boolean> rows = jdbc.queryForList(
                "select muted from notification_prefs where user_id = ? and group_id = ?", Boolean.class, userId, groupId);
        return !rows.isEmpty() && rows.get(0);
    }
}
