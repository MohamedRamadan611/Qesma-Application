package app.qesma.engine;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Net balances (spec 7.6). Balances are always computed from the ledger, never stored. */
public final class BalanceCalculator {

    private BalanceCalculator() {
    }

    /** A non-deleted expense reduced to what balances need: who paid what and who owes what. */
    public record ExpenseLedgerEntry(List<Payer> payers, Map<String, Long> owed) {
    }

    /** A recorded real-world payment {@code from -> to} (spec 7.8). Soft-deleted ones must not be passed in. */
    public record SettlementEntry(String fromMemberId, String toMemberId, long amountMinor) {
    }

    /**
     * {@code net = paid - owed + settlements sent - settlements received}. Positive = is owed.
     * Returns every roster member in {@code sortOrder} order (zeros included); the values always sum to 0.
     */
    public static Map<String, Long> nets(List<MemberRef> members, List<ExpenseLedgerEntry> expenses,
                                         List<SettlementEntry> settlements) {
        List<MemberRef> roster = new ArrayList<>(members);
        roster.sort(Comparator.comparingInt(MemberRef::sortOrder));
        Map<String, Long> nets = new LinkedHashMap<>();
        for (MemberRef m : roster) {
            if (nets.put(m.id(), 0L) != null) {
                throw EngineException.invalid("Duplicate member in roster");
            }
        }

        for (ExpenseLedgerEntry e : expenses) {
            long paid = 0;
            long owed = 0;
            for (Payer p : e.payers()) {
                add(nets, p.memberId(), p.amountMinor());
                paid = Exact.add(paid, p.amountMinor());
            }
            for (Map.Entry<String, Long> o : e.owed().entrySet()) {
                add(nets, o.getKey(), Exact.negate(o.getValue()));
                owed = Exact.add(owed, o.getValue());
            }
            if (paid != owed) {
                throw new EngineException(EngineErrorCode.PAYERS_TOTAL_MISMATCH,
                        "An expense's payers and shares do not add up to the same total");
            }
        }

        for (SettlementEntry s : settlements) {
            if (s.amountMinor() <= 0) {
                throw EngineException.invalid("Settlement amounts must be greater than zero");
            }
            if (s.fromMemberId().equals(s.toMemberId())) {
                throw EngineException.invalid("A settlement needs two different members");
            }
            add(nets, s.fromMemberId(), s.amountMinor());
            add(nets, s.toMemberId(), Exact.negate(s.amountMinor()));
        }
        return nets;
    }

    private static void add(Map<String, Long> nets, String memberId, long delta) {
        Long current = nets.get(memberId);
        if (current == null) {
            throw new EngineException(EngineErrorCode.MEMBER_NOT_IN_GROUP, "A member in the ledger is not in the group");
        }
        nets.put(memberId, Exact.add(current, delta));
    }
}
