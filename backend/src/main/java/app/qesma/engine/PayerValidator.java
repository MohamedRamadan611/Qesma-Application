package app.qesma.engine;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Payer rules (spec 7.5). Payers need not be participants. */
public final class PayerValidator {

    private PayerValidator() {
    }

    /** At least one payer, each amount &gt; 0, no duplicate member, sum equals total or {@code PAYERS_TOTAL_MISMATCH}. */
    public static void validate(long total, List<Payer> payers) {
        if (payers.isEmpty()) {
            throw EngineException.invalid("At least one payer is required");
        }
        Set<String> seen = new HashSet<>();
        long sum = 0;
        for (Payer p : payers) {
            if (p.amountMinor() <= 0) {
                throw EngineException.invalid("Payer amounts must be greater than zero");
            }
            if (!seen.add(p.memberId())) {
                throw EngineException.invalid("Duplicate payer");
            }
            sum = Exact.add(sum, p.amountMinor());
        }
        if (sum != total) {
            throw new EngineException(EngineErrorCode.PAYERS_TOTAL_MISMATCH, "Payers do not add up to the total");
        }
    }
}
