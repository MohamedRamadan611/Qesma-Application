package app.qesma.persistence;

import app.qesma.engine.BalanceCalculator.MemberTotals;
import java.sql.Array;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * Per-group sums for the member that represents the caller ("you") in each of the given groups, in ONE statement
 * however many groups are asked for (no N+1). SQL only adds; the balance rule is the engine's
 * ({@code BalanceCalculator.memberNet}). A group in which the caller has no linked member is simply absent from the
 * result; a linked member without any activity yields zeros.
 */
@Repository
public class YourNetQuery {

    /** The caller's member in a group together with their ledger sums. */
    public record YourTotals(UUID memberId, MemberTotals totals) {
    }

    private static final String SQL = """
            with mine as (
              select m.id as member_id, m.group_id from members m where m.user_id = ? and m.group_id = any(?)
            )
            select mine.group_id, mine.member_id,
                   coalesce(sum(l.paid), 0)::bigint, coalesce(sum(l.owed), 0)::bigint,
                   coalesce(sum(l.sent), 0)::bigint, coalesce(sum(l.received), 0)::bigint
            from mine
            left join (
              select p.member_id, p.amount_minor as paid, 0::bigint as owed, 0::bigint as sent, 0::bigint as received
              from expense_payers p join expenses e on e.id = p.expense_id
              where e.deleted_at is null and e.group_id = any(?)
              union all
              select s.member_id, 0, s.owed_minor, 0, 0
              from expense_splits s join expenses e on e.id = s.expense_id
              where e.deleted_at is null and e.group_id = any(?)
              union all
              select t.from_member_id, 0, 0, t.amount_minor, 0
              from settlements t where t.deleted_at is null and t.group_id = any(?)
              union all
              select t.to_member_id, 0, 0, 0, t.amount_minor
              from settlements t where t.deleted_at is null and t.group_id = any(?)
            ) l on l.member_id = mine.member_id
            group by mine.group_id, mine.member_id
            """;

    private final JdbcTemplate jdbc;

    public YourNetQuery(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** group id -> the caller's member and sums, for the groups where the caller has a linked member. */
    public Map<UUID, YourTotals> forGroups(UUID userId, Collection<UUID> groupIds) {
        Map<UUID, YourTotals> out = new HashMap<>();
        if (groupIds.isEmpty()) {
            return out;
        }
        return jdbc.execute((java.sql.Connection con) -> {
            Array ids = con.createArrayOf("uuid", groupIds.toArray());
            try (java.sql.PreparedStatement ps = con.prepareStatement(SQL)) {
                ps.setObject(1, userId);
                for (int i = 2; i <= 6; i++) {
                    ps.setArray(i, ids);
                }
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        UUID member = rs.getObject(2, UUID.class);
                        out.put(rs.getObject(1, UUID.class), new YourTotals(member,
                                new MemberTotals(member.toString(), rs.getLong(3), rs.getLong(4), rs.getLong(5),
                                        rs.getLong(6))));
                    }
                }
            } finally {
                ids.free();
            }
            return out;
        });
    }
}
