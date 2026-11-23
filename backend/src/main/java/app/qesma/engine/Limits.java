package app.qesma.engine;

/**
 * Bounds on stored money. Every amount (expense total, payer, share, item, settlement) is at most
 * {@link #MAX_AMOUNT_MINOR} piasters (10 billion EGP), so sums over a group's ledger cannot overflow a {@code long}
 * in any realistic group (it would take millions of maximal expenses). The same bound is a CHECK in the database.
 */
public final class Limits {

    public static final long MAX_AMOUNT_MINOR = 1_000_000_000_000L;

    /** SHARES units per participant (A185). */
    public static final int MIN_SHARE_UNITS = 1;
    public static final int MAX_SHARE_UNITS = 100;

    /** Longest SHARES period, inclusive (A186). */
    public static final int MAX_PERIOD_DAYS = 366;

    private Limits() {
    }

    public static boolean withinAmountLimit(long amountMinor) {
        return amountMinor <= MAX_AMOUNT_MINOR;
    }
}
