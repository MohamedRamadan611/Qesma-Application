package app.qesma.engine;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** EQUAL (spec 7.2) and EXACT (spec 7.3) splits. Results map memberId to owed minor units. */
public final class SplitCalculator {

    private SplitCalculator() {
    }

    /**
     * Spec 7.2: LRM with weight 1 each; extra minor units go to the lowest {@code sortOrder}.
     * Participants are returned in {@code sortOrder} order, including any that owe 0.
     */
    public static Map<String, Long> equal(long total, List<MemberRef> participants) {
        if (total <= 0) {
            throw EngineException.invalid("Total must be greater than zero");
        }
        if (participants.isEmpty()) {
            throw EngineException.invalid("At least one participant is required");
        }
        List<MemberRef> sorted = new ArrayList<>(participants);
        sorted.sort(java.util.Comparator.comparingInt(MemberRef::sortOrder));
        Set<String> seen = new HashSet<>();
        long[] weights = new long[sorted.size()];
        int[] order = new int[sorted.size()];
        for (int i = 0; i < sorted.size(); i++) {
            if (!seen.add(sorted.get(i).id())) {
                throw EngineException.invalid("Duplicate participant");
            }
            weights[i] = 1;
            order[i] = sorted.get(i).sortOrder();
        }
        long[] parts = Lrm.allocate(total, weights, order);
        Map<String, Long> owed = new LinkedHashMap<>();
        for (int i = 0; i < parts.length; i++) {
            owed.put(sorted.get(i).id(), parts[i]);
        }
        return owed;
    }

    /**
     * Spec 7.3: each amount &gt;= 0, at least one &gt; 0, sum must equal {@code total}, otherwise
     * {@link EngineErrorCode#SPLIT_TOTAL_MISMATCH}. Zero shares are kept as given.
     */
    public static Map<String, Long> exact(long total, List<Share> shares) {
        if (total <= 0) {
            throw EngineException.invalid("Total must be greater than zero");
        }
        if (shares.isEmpty()) {
            throw EngineException.invalid("At least one share is required");
        }
        Map<String, Long> owed = new LinkedHashMap<>();
        long sum = 0;
        boolean anyPositive = false;
        for (Share s : shares) {
            if (s.amountMinor() < 0) {
                throw EngineException.invalid("Share amounts must not be negative");
            }
            if (owed.put(s.memberId(), s.amountMinor()) != null) {
                throw EngineException.invalid("Duplicate member in shares");
            }
            anyPositive |= s.amountMinor() > 0;
            sum = Exact.add(sum, s.amountMinor());
        }
        if (!anyPositive) {
            throw EngineException.invalid("At least one share must be greater than zero");
        }
        if (sum != total) {
            throw new EngineException(EngineErrorCode.SPLIT_TOTAL_MISMATCH, "Shares do not add up to the total");
        }
        return owed;
    }
}
