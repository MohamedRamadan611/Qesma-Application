package app.qesma.persistence;

import app.qesma.engine.BalanceCalculator.MemberTotals;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * The one statement behind {@code GET /balances}: per member, the sums of what they paid and owe on live
 * (non-deleted) expenses and what they sent and received in live settlements. SQL only adds; the balance rule and
 * the zero-sum invariant live in the engine. A single statement reads one consistent snapshot, so concurrent
 * writes can never make the sums disagree with each other.
 */
@Repository
public class BalanceTotalsQuery {

    /** Public so the performance test can EXPLAIN exactly this statement. */
    public static final String SQL = """
            select member_id, sum(paid)::bigint, sum(owed)::bigint, sum(sent)::bigint, sum(received)::bigint
            from (
              select p.member_id, p.amount_minor as paid, 0::bigint as owed, 0::bigint as sent, 0::bigint as received
              from expense_payers p join expenses e on e.id = p.expense_id
              where e.group_id = ? and e.deleted_at is null
              union all
              select s.member_id, 0, s.owed_minor, 0, 0
              from expense_splits s join expenses e on e.id = s.expense_id
              where e.group_id = ? and e.deleted_at is null
              union all
              select t.from_member_id, 0, 0, t.amount_minor, 0
              from settlements t where t.group_id = ? and t.deleted_at is null
              union all
              select t.to_member_id, 0, 0, 0, t.amount_minor
              from settlements t where t.group_id = ? and t.deleted_at is null
            ) ledger
            group by member_id
            """;

    private final JdbcTemplate jdbc;

    public BalanceTotalsQuery(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<MemberTotals> totals(UUID groupId) {
        return jdbc.query(SQL, (rs, i) -> new MemberTotals(rs.getObject(1, UUID.class).toString(),
                        rs.getLong(2), rs.getLong(3),
                        rs.getLong(4), rs.getLong(5)),
                groupId, groupId, groupId, groupId);
    }
}
