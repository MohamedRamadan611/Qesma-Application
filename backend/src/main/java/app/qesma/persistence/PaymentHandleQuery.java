package app.qesma.persistence;

import java.sql.Array;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * THE visibility rule for payment handles (A91): the handles of the given members of one group, for one viewer, in ONE
 * statement however many members are asked for. A row comes back only if the viewer is an ACTIVE member of the group
 * and the handle owner is an ACTIVE, linked member of the same group. (The service has already required the viewer to
 * be a member; the rule is repeated here so the query alone can never over-share.)
 */
@Repository
public class PaymentHandleQuery {

    /** Public so a test can EXPLAIN exactly this statement. */
    public static final String SQL = """
            select m.id, ph.type, ph.value
            from members m
            join payment_handles ph on ph.user_id = m.user_id
            where m.group_id = ? and m.id = any(?) and m.status = 'ACTIVE' and m.user_id is not null
              and exists (select 1 from members v
                          where v.group_id = m.group_id and v.user_id = ? and v.status = 'ACTIVE')
            """;

    public record Row(UUID memberId, String type, String value) {
    }

    private final JdbcTemplate jdbc;

    public PaymentHandleQuery(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Row> visibleTo(UUID viewerUserId, UUID groupId, Collection<UUID> memberIds) {
        if (memberIds.isEmpty()) {
            return List.of();
        }
        UUID[] ids = memberIds.toArray(new UUID[0]);
        return jdbc.query(con -> {
            var ps = con.prepareStatement(SQL);
            ps.setObject(1, groupId);
            Array arr = con.createArrayOf("uuid", ids);
            ps.setArray(2, arr);
            ps.setObject(3, viewerUserId);
            return ps;
        }, (rs, i) -> new Row(rs.getObject(1, UUID.class), rs.getString(2), rs.getString(3)));
    }
}
