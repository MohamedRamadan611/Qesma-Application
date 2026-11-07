package app.qesma.engine;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.Comparator;

/**
 * Largest Remainder Method (spec 7.1): the single allocation primitive of the engine.
 *
 * <p>Allocates an integer total across recipients proportionally to integer weights so that the
 * parts sum exactly to the total. All products use {@link BigInteger}; no floating point.
 */
public final class Lrm {

    private Lrm() {
    }

    /**
     * Spec 7.1 steps 1-6.
     *
     * @param total      amount in minor units; may be negative (its absolute value is allocated, then the sign applied)
     * @param weights    non-negative weights, one per recipient; if all are zero every weight is treated as 1
     * @param sortOrders tie-break keys aligned with {@code weights}; the lower value wins a tied remainder
     * @return parts aligned with the input arrays; they sum exactly to {@code total}
     */
    public static long[] allocate(long total, long[] weights, int[] sortOrders) {
        int n = weights.length;
        if (n == 0) {
            throw EngineException.invalid("At least one recipient is required");
        }
        if (sortOrders.length != n) {
            throw EngineException.invalid("Weights and sort orders must have the same length");
        }
        if (total == Long.MIN_VALUE) {
            throw EngineException.invalid("Amount too large");
        }

        BigInteger sum = BigInteger.ZERO;
        for (long w : weights) {
            if (w < 0) {
                throw EngineException.invalid("Weights must not be negative");
            }
            sum = sum.add(BigInteger.valueOf(w));
        }
        long[] effective = weights;
        if (sum.signum() == 0) { // spec 7.1 step 5
            effective = new long[n];
            Arrays.fill(effective, 1L);
            sum = BigInteger.valueOf(n);
        }

        long abs = Math.abs(total);
        BigInteger absBig = BigInteger.valueOf(abs);
        long[] parts = new long[n];
        BigInteger[] remainders = new BigInteger[n];
        long allocated = 0;
        for (int i = 0; i < n; i++) { // steps 1-2: exact share, floor
            BigInteger[] qr = absBig.multiply(BigInteger.valueOf(effective[i])).divideAndRemainder(sum);
            parts[i] = qr[0].longValueExact();
            remainders[i] = qr[1];
            allocated += parts[i]; // each part <= abs, and the parts sum to <= abs: cannot overflow
        }

        long leftover = abs - allocated; // always < n
        Integer[] order = new Integer[n];
        for (int i = 0; i < n; i++) {
            order[i] = i;
        }
        // step 3-4: largest fractional remainder first, tie -> lower sortOrder, then lower index (determinism)
        Arrays.sort(order, Comparator
                .<Integer, BigInteger>comparing(i -> remainders[i], Comparator.reverseOrder())
                .thenComparingInt(i -> sortOrders[i])
                .thenComparingInt(i -> i));
        for (int k = 0; k < leftover; k++) {
            parts[order[k]]++;
        }

        if (total < 0) { // step 6
            for (int i = 0; i < n; i++) {
                parts[i] = -parts[i];
            }
        }
        return parts;
    }
}
