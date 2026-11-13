package app.qesma.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/**
 * A83: which settlements move balances is decided in ONE place ({@link SettlementLedgerSql#COUNTS_IN_BALANCE}). Both
 * statements that add settlements into a net must use it for the sent and the received side, and neither may keep the
 * Phase 1 "deleted_at is null" test, so net, suggested transfers, yourNet and the group summary cannot disagree.
 */
class BalanceRuleFilterTest {

    private static int occurrences(String text, String part) {
        int n = 0;
        for (int i = text.indexOf(part); i >= 0; i = text.indexOf(part, i + part.length())) {
            n++;
        }
        return n;
    }

    @Test
    void theBalanceTotalsAndYourNetBothFilterSettlementsWithTheSamePredicate() {
        assertThat(SettlementLedgerSql.COUNTS_IN_BALANCE).isEqualTo("status = 'CONFIRMED'");
        for (String sql : new String[] {BalanceTotalsQuery.SQL, YourNetQuery.SQL}) {
            assertThat(occurrences(sql, SettlementLedgerSql.COUNTS_IN_BALANCE)).as(sql).isEqualTo(2);   // sent + received
            assertThat(occurrences(sql, "from settlements")).isEqualTo(2);
            assertThat(sql).doesNotContain("t.deleted_at");
        }
    }

    @Test
    void thePendingPairsStatementOnlyReadsOpenSettlementsAndNeverFeedsANet() {
        assertThat(PendingPairsQuery.SQL).contains("status in ('PENDING', 'DISPUTED')");
        assertThat(PendingPairsQuery.SQL).doesNotContain("CONFIRMED");
    }
}
