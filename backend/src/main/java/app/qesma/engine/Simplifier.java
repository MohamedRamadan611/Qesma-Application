package app.qesma.engine;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Debt simplification (spec 7.7, Decision A5): deterministic greedy, not a guaranteed minimum. */
public final class Simplifier {

    private Simplifier() {
    }

    /**
     * Repeatedly pairs the creditor with the largest net and the debtor with the most negative net
     * (ties: lower {@code sortOrder}) and transfers {@code min(credit, debt)}, until all nets are 0.
     * Nets must sum to 0; roster members missing from {@code nets} count as 0.
     */
    public static List<Transfer> simplify(Map<String, Long> nets, List<MemberRef> members) {
        List<MemberRef> roster = new ArrayList<>(members);
        roster.sort(Comparator.comparingInt(MemberRef::sortOrder)); // index order == tie-break order
        int n = roster.size();
        Map<String, Integer> index = new HashMap<>();
        for (int i = 0; i < n; i++) {
            index.put(roster.get(i).id(), i);
        }
        long[] net = new long[n];
        long sum = 0;
        for (Map.Entry<String, Long> e : nets.entrySet()) {
            Integer i = index.get(e.getKey());
            if (i == null) {
                throw new EngineException(EngineErrorCode.MEMBER_NOT_IN_GROUP, "A member in the balances is not in the group");
            }
            net[i] = e.getValue();
            sum = Exact.add(sum, e.getValue());
        }
        if (sum != 0) {
            throw EngineException.invalid("Net balances must sum to zero");
        }

        List<Transfer> transfers = new ArrayList<>();
        while (true) {
            int creditor = -1;
            int debtor = -1;
            for (int i = 0; i < n; i++) { // strict comparisons keep the lowest index (lowest sortOrder) on ties
                if (net[i] > 0 && (creditor < 0 || net[i] > net[creditor])) {
                    creditor = i;
                }
                if (net[i] < 0 && (debtor < 0 || net[i] < net[debtor])) {
                    debtor = i;
                }
            }
            if (creditor < 0 || debtor < 0) {
                return transfers; // sum is 0, so both are absent together
            }
            long amount = Math.min(net[creditor], -net[debtor]); // net[debtor] > Long.MIN_VALUE: sum check bounds it
            transfers.add(new Transfer(roster.get(debtor).id(), roster.get(creditor).id(), amount));
            net[creditor] -= amount;
            net[debtor] += amount;
        }
    }
}
