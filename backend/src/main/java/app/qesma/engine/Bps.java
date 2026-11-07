package app.qesma.engine;

import java.math.BigInteger;

/** Percentage-of-amount computation with integer basis points (spec 7.1, last bullet). */
public final class Bps {

    /** 100.00%. Service and tax rates above this are rejected as input errors. */
    public static final int MAX_BPS = 10_000;

    private static final BigInteger TEN_THOUSAND = BigInteger.valueOf(10_000);
    private static final BigInteger HALF = BigInteger.valueOf(5_000);

    private Bps() {
    }

    /** {@code round_half_up(amount x bps / 10000)} in minor units. Amount must be non-negative. */
    public static long percentOf(long amount, int bps) {
        if (amount < 0) {
            throw EngineException.invalid("Amount must not be negative");
        }
        if (bps < 0 || bps > MAX_BPS) {
            throw EngineException.invalid("Basis points must be between 0 and " + MAX_BPS);
        }
        return BigInteger.valueOf(amount).multiply(BigInteger.valueOf(bps)).add(HALF).divide(TEN_THOUSAND)
                .longValueExact(); // result <= amount, so it always fits
    }
}
