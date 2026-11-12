package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/**
 * Invitations (B11) in plain SQL: the join path needs {@code SELECT ... FOR UPDATE} on the invite row and
 * conditional updates, and every call runs inside the caller's transaction. The code is a secret: it is a bind
 * parameter only and never part of a log line, a metric tag or an error message.
 */
@Repository
public class InviteStore {

    /** One invitation as stored. */
    public record Invite(UUID id, UUID groupId, String code, UUID createdByMemberId, Instant createdAt,
                         Instant expiresAt, Integer maxUses, int useCount, boolean requiresApproval,
                         Instant revokedAt) {
    }

    /** What the join screen may know about an invite and its group (no balances, no accounts). */
    public record PreviewRow(UUID inviteId, UUID groupId, String groupName, String groupType, String inviterName,
                             long memberCount, Instant expiresAt, Integer maxUses, int useCount,
                             boolean requiresApproval, Instant revokedAt, boolean callerIsMember,
                             boolean callerHasPendingRequest) {
    }

    public record Ghost(UUID id, String name) {
    }

    private static final String COLUMNS = "id, group_id, code, created_by_member_id, created_at, expires_at, max_uses, "
            + "use_count, requires_approval, revoked_at";

    private static final RowMapper<Invite> MAPPER = (rs, i) -> new Invite(rs.getObject(1, UUID.class),
            rs.getObject(2, UUID.class), rs.getString(3), rs.getObject(4, UUID.class),
            rs.getTimestamp(5).toInstant(), rs.getTimestamp(6).toInstant(), (Integer) rs.getObject(7),
            rs.getInt(8), rs.getBoolean(9), rs.getTimestamp(10) == null ? null : rs.getTimestamp(10).toInstant());

    private final JdbcTemplate jdbc;

    public InviteStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public boolean codeExists(String code) {
        return Boolean.TRUE.equals(jdbc.queryForObject("select exists (select 1 from group_invites where code = ?)",
                Boolean.class, code));
    }

    public void insert(Invite i) {
        jdbc.update("insert into group_invites (" + COLUMNS + ") values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                i.id(), i.groupId(), i.code(), i.createdByMemberId(), Timestamp.from(i.createdAt()),
                Timestamp.from(i.expiresAt()), i.maxUses(), i.useCount(), i.requiresApproval(), null);
    }

    /** The row lock serializes every join and approval of one invite (use_count, max_uses). */
    public Optional<Invite> findByCodeForUpdate(String code) {
        return jdbc.query("select " + COLUMNS + " from group_invites where code = ? for update", MAPPER, code)
                .stream().findFirst();
    }

    public Optional<Invite> findByIdForUpdate(UUID id) {
        return jdbc.query("select " + COLUMNS + " from group_invites where id = ? for update", MAPPER, id)
                .stream().findFirst();
    }

    public Optional<Invite> findById(UUID id) {
        return jdbc.query("select " + COLUMNS + " from group_invites where id = ?", MAPPER, id).stream().findFirst();
    }

    public List<Invite> pageByGroup(UUID groupId, int limit, long offset) {
        return jdbc.query("select " + COLUMNS + " from group_invites where group_id = ? "
                + "order by created_at desc, id desc limit ? offset ?", MAPPER, groupId, limit, offset);
    }

    public long countByGroup(UUID groupId) {
        return jdbc.queryForObject("select count(*) from group_invites where group_id = ?", Long.class, groupId);
    }

    public void incrementUse(UUID inviteId) {
        jdbc.update("update group_invites set use_count = use_count + 1 where id = ?", inviteId);
    }

    /** Sets {@code revoked_at} once; revoking again keeps the first time. Zero rows: no such invite in that group. */
    public int revoke(UUID inviteId, UUID groupId, Instant now) {
        return jdbc.update("update group_invites set revoked_at = coalesce(revoked_at, ?) where id = ? and group_id = ?",
                Timestamp.from(now), inviteId, groupId);
    }

    /** The invite, its group and the inviter's member name, and the caller's state, in one statement. */
    public Optional<PreviewRow> preview(String code, UUID callerUserId) {
        return jdbc.query("""
                select i.id, g.id, g.name, g.type, inv.display_name,
                       (select count(*) from members m where m.group_id = g.id and m.status = 'ACTIVE'),
                       i.expires_at, i.max_uses, i.use_count, i.requires_approval, i.revoked_at,
                       exists (select 1 from members m where m.group_id = g.id and m.user_id = ? and m.status = 'ACTIVE'),
                       exists (select 1 from join_requests r where r.invite_id = i.id and r.user_id = ? and r.status = 'PENDING')
                from group_invites i
                join expense_groups g on g.id = i.group_id
                join members inv on inv.id = i.created_by_member_id
                where i.code = ?
                """,
                (rs, n) -> new PreviewRow(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class), rs.getString(3),
                        rs.getString(4), rs.getString(5), rs.getLong(6), rs.getTimestamp(7).toInstant(),
                        (Integer) rs.getObject(8), rs.getInt(9), rs.getBoolean(10),
                        rs.getTimestamp(11) == null ? null : rs.getTimestamp(11).toInstant(), rs.getBoolean(12),
                        rs.getBoolean(13)),
                callerUserId, callerUserId, code).stream().findFirst();
    }

    /** Members of the group that no account is linked to (the "who are you?" list), in sort order. */
    public List<Ghost> unclaimed(UUID groupId) {
        return jdbc.query("select id, display_name from members where group_id = ? and user_id is null "
                + "and status = 'ACTIVE' order by sort_order", (rs, i) -> new Ghost(rs.getObject(1, UUID.class),
                rs.getString(2)), groupId);
    }
}
