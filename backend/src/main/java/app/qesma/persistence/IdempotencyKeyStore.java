package app.qesma.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Storage for spec 8.3 idempotency keys. Plain SQL on purpose: the response is a {@code jsonb} column, and
 * all calls run inside the caller's transaction (same connection as the business write).
 */
@Repository
public class IdempotencyKeyStore {

    /** A previously stored response. Note jsonb normalizes the body (key order, spacing), content is identical. */
    public record StoredKey(String endpoint, String requestHash, int responseStatus, String responseBody,
                            Instant createdAt) {
    }

    private final JdbcTemplate jdbc;

    public IdempotencyKeyStore(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Transaction-scoped advisory lock on (user, key): concurrent requests carrying the same key run one after
     * the other, even when they target different groups. Released automatically at commit or rollback.
     */
    public void lock(UUID userId, String key) {
        jdbc.query("select pg_advisory_xact_lock(hashtextextended(?, 0))", rs -> { }, userId + ":" + key);
    }

    public Optional<StoredKey> find(UUID userId, String key) {
        List<StoredKey> rows = jdbc.query("""
                select endpoint, request_hash, response_status, response_body::text, created_at
                from idempotency_keys where user_id = ? and key = ?
                """,
                (rs, i) -> new StoredKey(rs.getString(1), rs.getString(2), rs.getInt(3), rs.getString(4),
                        rs.getTimestamp(5).toInstant()),
                userId, key);
        return rows.stream().findFirst();
    }

    /** Removes this key's row if it is older than the cutoff (expired keys are treated as absent). */
    public int deleteIfOlderThan(UUID userId, String key, Instant cutoff) {
        return jdbc.update("delete from idempotency_keys where user_id = ? and key = ? and created_at < ?",
                userId, key, Timestamp.from(cutoff));
    }

    public void insert(UUID userId, String key, String endpoint, String requestHash, int status, String body,
                       Instant createdAt) {
        jdbc.update("""
                insert into idempotency_keys (user_id, key, endpoint, request_hash, response_status, response_body,
                                              created_at)
                values (?, ?, ?, ?, ?, ?::jsonb, ?)
                """, userId, key, endpoint, requestHash, status, body, Timestamp.from(createdAt));
    }

    /** Cleanup job: removes every key older than the cutoff. */
    public int deleteOlderThan(Instant cutoff) {
        return jdbc.update("delete from idempotency_keys where created_at < ?", Timestamp.from(cutoff));
    }
}
