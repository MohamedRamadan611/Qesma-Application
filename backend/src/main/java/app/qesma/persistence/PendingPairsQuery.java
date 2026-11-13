package app.qesma.persistence;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * The informational side of the balance rule (A83): per exact (from, to) pair, the sum of PENDING settlements, whether a
 * DISPUTED one exists and the ids of the open ones (PENDING and DISPUTED, oldest first). ONE grouped statement for the
 * whole group, however many transfers are suggested; nothing here changes a net.
 */
@Repository
public class PendingPairsQuery {

    /** Public so a test can EXPLAIN exactly this statement. */
    public static final String SQL = """
            select from_member_id, to_member_id,
                   coalesce(sum(amount_minor) filter (where status = 'PENDING'), 0)::bigint,
                   coalesce(bool_or(status = 'DISPUTED'), false),
                   array_agg(id order by created_at, id)
            from settlements
            where group_id = ? and status in ('PENDING', 'DISPUTED')
            group by from_member_id, to_member_id
            """;

    public record Pair(UUID fromMemberId, UUID toMemberId, long pendingMinor, boolean hasDispute, List<UUID> ids) {
    }

    private final JdbcTemplate jdbc;

    public PendingPairsQuery(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Pair> pairs(UUID groupId) {
        return jdbc.query(SQL, (rs, i) -> new Pair(rs.getObject(1, UUID.class), rs.getObject(2, UUID.class),
                rs.getLong(3), rs.getBoolean(4), Arrays.asList((UUID[]) rs.getArray(5).getArray())), groupId);
    }
}
