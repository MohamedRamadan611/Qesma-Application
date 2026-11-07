package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Append-only storage of expense revisions (spec 7.9). Plain SQL on purpose: the snapshot is a {@code jsonb}
 * column, and every call runs inside the caller's transaction, so a revision commits or rolls back together with
 * the change it records.
 */
@Repository
public class ExpenseRevisionStore {

    /** A stored revision. Note jsonb normalizes the snapshot text (key order, spacing); the content is identical. */
    public record Revision(int version, String changeType, String snapshot, UUID changedByUserId, Instant changedAt) {
    }

    private final JdbcTemplate jdbc;

    public ExpenseRevisionStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void insert(UUID expenseId, int version, String changeType, String snapshotJson, UUID changedByUserId,
                       Instant changedAt) {
        jdbc.update("""
                insert into expense_revisions (id, expense_id, version, change_type, snapshot, changed_by_user_id,
                                               changed_at)
                values (?, ?, ?, ?, ?::jsonb, ?, ?)
                """, UUID.randomUUID(), expenseId, version, changeType, snapshotJson, changedByUserId,
                Timestamp.from(changedAt));
    }

    /** Chronological: oldest first. Bounded by the number of edits of one expense. */
    public List<Revision> findByExpense(UUID expenseId) {
        return jdbc.query("""
                select version, change_type, snapshot::text, changed_by_user_id, changed_at
                from expense_revisions where expense_id = ? order by version asc
                """,
                (rs, i) -> new Revision(rs.getInt(1), rs.getString(2), rs.getString(3),
                        rs.getObject(4, UUID.class), rs.getTimestamp(5).toInstant()),
                expenseId);
    }
}
