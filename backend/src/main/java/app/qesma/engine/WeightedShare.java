package app.qesma.engine;

import java.time.LocalDate;

/**
 * One SHARES participant (STANDALONE_SPEC 19.1, A185-A186): integer {@code shareUnits} (1..100) and, only when the
 * expense has a period, an optional inclusive presence inside it (each bound defaults to the period bound).
 */
public record WeightedShare(String memberId, int sortOrder, int shareUnits, LocalDate presentFrom,
        LocalDate presentTo) {
}
