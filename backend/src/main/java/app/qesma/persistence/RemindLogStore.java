package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * The Remind log (B16, A108-A110): the source of truth of the rate limit. Rows are written in the transaction of the
 * REMINDER event and read by the same service after it locked the group row.
 */
@Repository
public class RemindLogStore {

    /** How many reminders an account sent in a window and when the oldest of them was sent. */
    public record UserWindow(long count, Instant oldest) {
    }

    private final JdbcTemplate jdbc;

    public RemindLogStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** When the debtor was last reminded in this group (by anybody), if ever. */
    public Optional<Instant> lastForDebtor(UUID groupId, UUID fromMemberId) {
        return jdbc.query("select max(created_at) from remind_log where group_id = ? and from_member_id = ?",
                rs -> rs.next() && rs.getTimestamp(1) != null ? Optional.of(rs.getTimestamp(1).toInstant())
                        : Optional.<Instant>empty(), groupId, fromMemberId);
    }

    /** Reminders sent by this account since {@code since} (all groups) and the oldest of them. */
    public UserWindow userWindow(UUID userId, Instant since) {
        return jdbc.query("select count(*), min(created_at) from remind_log where sent_by_user_id = ? and created_at > ?",
                rs -> {
                    rs.next();
                    Timestamp oldest = rs.getTimestamp(2);
                    return new UserWindow(rs.getLong(1), oldest == null ? null : oldest.toInstant());
                }, userId, Timestamp.from(since));
    }

    public void insert(UUID id, UUID groupId, UUID fromMemberId, UUID toMemberId, UUID sentByUserId, Instant now) {
        jdbc.update("insert into remind_log (id, group_id, from_member_id, to_member_id, sent_by_user_id, created_at) "
                + "values (?, ?, ?, ?, ?, ?)", id, groupId, fromMemberId, toMemberId, sentByUserId, Timestamp.from(now));
    }

    /** ONE grouped statement: per debtor of the group, the time of the last reminder at or after {@code since}. */
    public Map<UUID, Instant> lastPerDebtor(UUID groupId, Instant since) {
        Map<UUID, Instant> out = new HashMap<>();
        jdbc.query("select from_member_id, max(created_at) from remind_log "
                + "where group_id = ? and created_at > ? group by from_member_id", rs -> {
                    out.put(rs.getObject(1, UUID.class), rs.getTimestamp(2).toInstant());
                }, groupId, Timestamp.from(since));
        return out;
    }

    public int purgeOlderThan(Instant cutoff) {
        return jdbc.update("delete from remind_log where created_at < ?", Timestamp.from(cutoff));
    }
}
