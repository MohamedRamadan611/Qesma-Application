package app.qesma.persistence;

import java.sql.Array;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/**
 * Per-user notifications (B15, A95-A103) in plain SQL. One row per (event, recipient account). Every statement that
 * reads or changes rows is filtered by {@code user_id} = the caller, never by a client-supplied user. The only state
 * that changes after insert is {@code read_at}.
 */
@Repository
public class NotificationStore {

    /** One notification as the center shows it; names are resolved only while the caller is still an ACTIVE member. */
    public record CenterRow(UUID id, UUID groupId, String groupName, String type, UUID actorMemberId, String actorName,
                            Instant createdAt, Instant readAt, String payload, String subject) {
    }

    /**
     * One page of the caller's notifications, keyset on {@code (created_at, id)} descending (index
     * {@code ix_notifications_user}). {@code groupName} is always resolved; {@code actorName} and {@code subject} only
     * while the caller has an ACTIVE member in that group (a user who left does not learn later renames).
     * Parameters: user id, cursor time, cursor id, limit.
     */
    public static final String CENTER_SQL = """
            select n.id, e.group_id, g.name, e.type, e.actor_member_id,
                   case when me.id is not null then actor.display_name end as actor_name,
                   n.created_at, n.read_at, e.payload::text,
                   case when me.id is null then null
                        when starts_with(e.type, 'EXPENSE_') then x.title
                        when e.type in ('INVITE_ACCEPTED', 'JOIN_REQUESTED', 'MEMBER_JOINED', 'MEMBER_LEFT',
                                        'MEMBER_REACTIVATED', 'MEMBER_UNLINKED', 'ROLE_CHANGED',
                                        'OWNERSHIP_TRANSFERRED') then sm.display_name
                   end as subject
            from notifications n
            join group_events e on e.id = n.event_id
            join expense_groups g on g.id = e.group_id
            left join members me on me.group_id = e.group_id and me.user_id = n.user_id and me.status = 'ACTIVE'
            left join members actor on actor.id = e.actor_member_id
            left join expenses x on x.id = (e.payload ->> 'expenseId')::uuid and x.group_id = e.group_id
            left join members sm on sm.id = (e.payload ->> 'memberId')::uuid and sm.group_id = e.group_id
            where n.user_id = ?
              and (n.created_at, n.id) < (?::timestamptz, ?::uuid)
            order by n.created_at desc, n.id desc
            limit ?
            """;

    public static final String UNREAD_COUNT_SQL =
            "select count(*) from notifications where user_id = ? and read_at is null";

    private static final RowMapper<CenterRow> CENTER_MAPPER = (rs, i) -> new CenterRow(rs.getObject(1, UUID.class),
            rs.getObject(2, UUID.class), rs.getString(3), rs.getString(4), rs.getObject(5, UUID.class),
            rs.getString(6), rs.getTimestamp(7).toInstant(),
            rs.getTimestamp(8) == null ? null : rs.getTimestamp(8).toInstant(), rs.getString(9), rs.getString(10));

    private final JdbcTemplate jdbc;

    public NotificationStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Writes every notification of one event with ONE statement: the recipients are resolved inside the INSERT ... SELECT
     * (ACTIVE, linked members of the group; the listed members, plus Owner/Admins when {@code includeManagers}; never the
     * actor's member), minus anybody who switched notifications off globally or for this group (B16, A104). The unique {@code (event_id, user_id)} guards against a duplicate. Returns the rows written.
     */
    public int insertFor(UUID eventId, UUID groupId, Collection<UUID> memberIds, boolean includeManagers,
                         UUID actorMemberId, Instant createdAt) {
        UUID[] ids = memberIds.toArray(new UUID[0]);
        return jdbc.update(con -> {
            var ps = con.prepareStatement("""
                    insert into notifications (id, user_id, event_id, created_at)
                    select gen_random_uuid(), m.user_id, ?, ?
                    from members m
                    where m.group_id = ? and m.status = 'ACTIVE' and m.user_id is not null
                      and (m.id = any(?) or (? and m.role in ('OWNER', 'ADMIN')))
                      and (?::uuid is null or m.id <> ?::uuid)
                      and not exists (select 1 from notification_prefs p where p.user_id = m.user_id and p.muted
                                      and (p.group_id is null or p.group_id = m.group_id))
                    """);
            ps.setObject(1, eventId);
            ps.setTimestamp(2, Timestamp.from(createdAt));
            ps.setObject(3, groupId);
            Array arr = con.createArrayOf("uuid", ids);
            ps.setArray(4, arr);
            ps.setBoolean(5, includeManagers);
            String actor = actorMemberId == null ? null : actorMemberId.toString();
            ps.setString(6, actor);
            ps.setString(7, actor);
            return ps;
        });
    }

    public List<CenterRow> centerPage(UUID userId, String beforeTime, String beforeId, int limit) {
        return jdbc.query(CENTER_SQL, CENTER_MAPPER, userId, beforeTime, beforeId, limit);
    }

    public long unreadCount(UUID userId) {
        Long n = jdbc.queryForObject(UNREAD_COUNT_SQL, Long.class, userId);
        return n == null ? 0 : n;
    }

    /** Marks the caller's own unread rows with these ids; foreign or unknown ids match nothing. Returns rows changed. */
    public int markRead(UUID userId, Collection<UUID> ids, Instant now) {
        UUID[] arr = ids.toArray(new UUID[0]);
        return jdbc.update(con -> {
            var ps = con.prepareStatement("update notifications set read_at = greatest(?, created_at) "
                    + "where user_id = ? and read_at is null and id = any(?)");
            ps.setTimestamp(1, Timestamp.from(now));
            ps.setObject(2, userId);
            ps.setArray(3, con.createArrayOf("uuid", arr));
            return ps;
        });
    }

    /** Marks every unread notification of the caller. Returns rows changed. */
    public int markAllRead(UUID userId, Instant now) {
        return jdbc.update("update notifications set read_at = greatest(?, created_at) "
                + "where user_id = ? and read_at is null", Timestamp.from(now), userId);
    }
}
