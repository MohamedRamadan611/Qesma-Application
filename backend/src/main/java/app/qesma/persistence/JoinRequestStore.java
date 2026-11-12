package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/** Join requests (B11) in plain SQL, always inside the caller's transaction. */
@Repository
public class JoinRequestStore {

    public static final String PENDING = "PENDING";
    public static final String APPROVED = "APPROVED";
    public static final String REJECTED = "REJECTED";

    /** One request as stored. */
    public record Request(UUID id, UUID inviteId, UUID groupId, UUID userId, UUID claimMemberId, String newMemberName,
                          String status, Instant createdAt, Instant decidedAt) {
    }

    /** A pending request as an admin sees it: the requester by display name only (never ids of accounts). */
    public record Row(UUID id, String status, String requesterName, UUID claimMemberId, String claimMemberName,
                      String newMemberName, Instant createdAt, Instant decidedAt) {
    }

    private static final String COLUMNS = "id, invite_id, group_id, user_id, claim_member_id, new_member_name, status, "
            + "created_at, decided_at";

    private static final RowMapper<Request> MAPPER = (rs, i) -> new Request(rs.getObject(1, UUID.class),
            rs.getObject(2, UUID.class), rs.getObject(3, UUID.class), rs.getObject(4, UUID.class),
            rs.getObject(5, UUID.class), rs.getString(6), rs.getString(7), rs.getTimestamp(8).toInstant(),
            rs.getTimestamp(9) == null ? null : rs.getTimestamp(9).toInstant());

    private final JdbcTemplate jdbc;

    public JoinRequestStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void insert(Request r) {
        jdbc.update("insert into join_requests (" + COLUMNS + ") values (?, ?, ?, ?, ?, ?, ?, ?, ?)", r.id(),
                r.inviteId(), r.groupId(), r.userId(), r.claimMemberId(), r.newMemberName(), r.status(),
                Timestamp.from(r.createdAt()), null);
    }

    public Optional<Request> findPending(UUID inviteId, UUID userId) {
        return jdbc.query("select " + COLUMNS + " from join_requests where invite_id = ? and user_id = ? "
                + "and status = 'PENDING'", MAPPER, inviteId, userId).stream().findFirst();
    }

    public Optional<Request> findInGroupForUpdate(UUID requestId, UUID groupId) {
        return jdbc.query("select " + COLUMNS + " from join_requests where id = ? and group_id = ? for update", MAPPER,
                requestId, groupId).stream().findFirst();
    }

    public Optional<Request> findInGroup(UUID requestId, UUID groupId) {
        return jdbc.query("select " + COLUMNS + " from join_requests where id = ? and group_id = ?", MAPPER,
                requestId, groupId).stream().findFirst();
    }

    public void decide(UUID requestId, String status, Instant now, UUID decidedByMemberId) {
        jdbc.update("update join_requests set status = ?, decided_at = ?, decided_by_member_id = ? where id = ?",
                status, Timestamp.from(now), decidedByMemberId, requestId);
    }

    /** Requests of a group with the requester's display name and the claimed member's name, in one statement. */
    public List<Row> page(UUID groupId, String status, int limit, long offset) {
        return jdbc.query("""
                select r.id, r.status, u.display_name, r.claim_member_id, c.display_name, r.new_member_name,
                       r.created_at, r.decided_at
                from join_requests r
                join users u on u.id = r.user_id
                left join members c on c.id = r.claim_member_id
                where r.group_id = ? and r.status = ?
                order by r.created_at, r.id limit ? offset ?
                """, (rs, i) -> new Row(rs.getObject(1, UUID.class), rs.getString(2), rs.getString(3),
                rs.getObject(4, UUID.class), rs.getString(5), rs.getString(6), rs.getTimestamp(7).toInstant(),
                rs.getTimestamp(8) == null ? null : rs.getTimestamp(8).toInstant()), groupId, status, limit, offset);
    }

    public long count(UUID groupId, String status) {
        return jdbc.queryForObject("select count(*) from join_requests where group_id = ? and status = ?", Long.class,
                groupId, status);
    }

    public Optional<Row> row(UUID requestId) {
        return jdbc.query("""
                select r.id, r.status, u.display_name, r.claim_member_id, c.display_name, r.new_member_name,
                       r.created_at, r.decided_at
                from join_requests r join users u on u.id = r.user_id left join members c on c.id = r.claim_member_id
                where r.id = ?
                """, (rs, i) -> new Row(rs.getObject(1, UUID.class), rs.getString(2), rs.getString(3),
                rs.getObject(4, UUID.class), rs.getString(5), rs.getString(6), rs.getTimestamp(7).toInstant(),
                rs.getTimestamp(8) == null ? null : rs.getTimestamp(8).toInstant()), requestId).stream().findFirst();
    }
}
