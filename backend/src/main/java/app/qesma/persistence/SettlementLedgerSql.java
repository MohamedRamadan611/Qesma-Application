package app.qesma.persistence;

/**
 * The ONE place that says which settlements move balances (PHASE2_SPEC section 6, Decision A83): CONFIRMED only.
 * PENDING and DISPUTED are informational, CANCELLED never counts. Every statement that adds settlements into a net
 * ({@link BalanceTotalsQuery}, {@link YourNetQuery}) uses this predicate; a test pins that.
 */
public final class SettlementLedgerSql {

    /** SQL predicate on the settlements table (unaliased column name; valid for any alias). */
    public static final String COUNTS_IN_BALANCE = "status = 'CONFIRMED'";

    private SettlementLedgerSql() {
    }
}
