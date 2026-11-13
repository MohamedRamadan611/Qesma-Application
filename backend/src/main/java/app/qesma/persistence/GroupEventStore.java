package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/**
 * The append-only group event log (B15, A95-A103) in plain SQL. Every call runs inside the caller's transaction, so an
 * event commits or rolls back together with the business write it describes. Events are never updated; the only delete
 * is the retention purge. The payload is a jsonb string of ids and integers (never a name or a title).
 */
@Repository
public class GroupEventStore {

    /** One feed row: the event as stored plus the subject resolved in the same statement (null when none applies). */
    public record FeedRow(UUID id, String type, UUID actorMemberId, Instant createdAt, String payload, String subject) {
    }

    /** First-page cursor values: every real {@code (created_at, id)} sorts below them. */
    public static final String NO_CURSOR_TIME = "infinity";
    public static final String NO_CURSOR_ID = "ffffffff-ffff-ffff-ffff-ffffffffffff";

    /**
     * One page of a group's feed: keyset on {@code (created_at, id)} descending (index {@code ix_group_events_feed}).
     * {@code subject}: the expense title for EXPENSE_* events (the row's current title, soft-deleted included), the
     * member's display name for member events, else null. Parameters: group id, cursor time, cursor id, limit.
     */
    public static final String FEED_SQL = """
            select e.id, e.type, e.actor_member_id, e.created_at, e.payload::text,
                   case when starts_with(e.type, 'EXPENSE_') then x.title
                        when e.type in ('INVITE_ACCEPTED', 'JOIN_REQUESTED', 'MEMBER_JOINED', 'MEMBER_LEFT',
                                        'MEMBER_REACTIVATED', 'MEMBER_UNLINKED', 'ROLE_CHANGED',
                                        'OWNERSHIP_TRANSFERRED') then sm.display_name
                   end as subject
            from group_events e
            left join expenses x on x.id = (e.payload ->> 'expenseId')::uuid and x.group_id = e.group_id
            left join members sm on sm.id = (e.payload ->> 'memberId')::uuid and sm.group_id = e.group_id
            where e.group_id = ?
              and (e.created_at, e.id) < (?::timestamptz, ?::uuid)
            order by e.created_at desc, e.id desc
            limit ?
            """;

    private static final RowMapper<FeedRow> FEED_MAPPER = (rs, i) -> new FeedRow(rs.getObject(1, UUID.class),
            rs.getString(2), rs.getObject(3, UUID.class), rs.getTimestamp(4).toInstant(), rs.getString(5),
            rs.getString(6));

    private final JdbcTemplate jdbc;

    public GroupEventStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void insert(UUID id, UUID groupId, UUID actorMemberId, String type, String payloadJson, Instant createdAt) {
        jdbc.update("insert into group_events (id, group_id, actor_member_id, type, payload, created_at) "
                + "values (?, ?, ?, ?, ?::jsonb, ?)", id, groupId, actorMemberId, type, payloadJson,
                Timestamp.from(createdAt));
    }

    /**
     * One statement, at most {@code limit} rows. {@code beforeTime}/{@code beforeId} are {@link #NO_CURSOR_TIME} and
     * {@link #NO_CURSOR_ID} on the first page.
     */
    public List<FeedRow> feedPage(UUID groupId, String beforeTime, String beforeId, int limit) {
        return jdbc.query(FEED_SQL, FEED_MAPPER, groupId, beforeTime, beforeId, limit);
    }

    /** Deletes up to {@code chunk} events older than {@code cutoff} (their notifications cascade); returns how many. */
    public int deleteOlderThan(Instant cutoff, int chunk) {
        return jdbc.update("delete from group_events where id in "
                + "(select id from group_events where created_at < ? order by created_at limit ?)",
                Timestamp.from(cutoff), chunk);
    }
}
