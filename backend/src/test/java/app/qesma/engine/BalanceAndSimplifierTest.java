package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Spec 7.6 balances, 7.7 simplification, 7.8 settlements. V1/V2/V4 are covered by fixtures. */
class BalanceAndSimplifierTest {

    private static final List<MemberRef> MEMBERS = List.of(new MemberRef("A", 1), new MemberRef("B", 2), new MemberRef("C", 3));

    private static ExpenseLedgerEntry expense(String payer, long total, Map<String, Long> owed) {
        return new ExpenseLedgerEntry(List.of(new Payer(payer, total)), owed);
    }

    @Test
    void netsSumToZeroAndIncludeAllMembers() {
        Map<String, Long> nets = BalanceCalculator.nets(MEMBERS,
                List.of(expense("A", 300, Map.of("B", 100L, "C", 200L))), List.of());
        assertThat(nets).containsExactly(Map.entry("A", 300L), Map.entry("B", -100L), Map.entry("C", -200L));
    }

    @Test
    void settlementExceedingDebtFlipsTheBalance() {
        Map<String, Long> nets = BalanceCalculator.nets(MEMBERS,
                List.of(expense("A", 100, Map.of("B", 100L))),
                List.of(new SettlementEntry("B", "A", 150)));
        assertThat(nets.get("B")).isEqualTo(50L);
        assertThat(nets.get("A")).isEqualTo(-50L);
    }

    @Test
    void rejectsExpenseWherePayersAndOwedDiffer() {
        assertThatThrownBy(() -> BalanceCalculator.nets(MEMBERS,
                List.of(expense("A", 100, Map.of("B", 99L))), List.of()))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.PAYERS_TOTAL_MISMATCH);
    }

    @Test
    void rejectsUnknownMembersAndBadSettlements() {
        assertThatThrownBy(() -> BalanceCalculator.nets(MEMBERS,
                List.of(expense("Z", 100, Map.of("B", 100L))), List.of()))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.MEMBER_NOT_IN_GROUP);
        assertThatThrownBy(() -> BalanceCalculator.nets(MEMBERS, List.of(), List.of(new SettlementEntry("A", "Z", 5))))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.MEMBER_NOT_IN_GROUP);
        assertThatThrownBy(() -> BalanceCalculator.nets(MEMBERS, List.of(), List.of(new SettlementEntry("A", "A", 5))))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
        assertThatThrownBy(() -> BalanceCalculator.nets(MEMBERS, List.of(), List.of(new SettlementEntry("A", "B", 0))))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void simplifierTieBreaksOnLowestSortOrder() {
        Map<String, Long> nets = new LinkedHashMap<>();
        nets.put("A", 100L);
        nets.put("B", -50L);
        nets.put("C", -50L);
        assertThat(Simplifier.simplify(nets, MEMBERS)).containsExactly(
                new Transfer("B", "A", 50), new Transfer("C", "A", 50));
    }

    @Test
    void simplifierPicksLargestCreditorThenMostNegativeDebtor() {
        List<MemberRef> four = List.of(new MemberRef("X", 1), new MemberRef("Y", 2), new MemberRef("Z", 3), new MemberRef("W", 4));
        Map<String, Long> nets = new LinkedHashMap<>();
        nets.put("X", 17500L);
        nets.put("Y", 7500L);
        nets.put("Z", -12500L);
        nets.put("W", -12500L);
        assertThat(Simplifier.simplify(nets, four)).containsExactly(
                new Transfer("Z", "X", 12500), new Transfer("W", "Y", 7500), new Transfer("W", "X", 5000));
    }

    @Test
    void allZeroNetsNeedNoTransfers() {
        Map<String, Long> nets = new LinkedHashMap<>();
        nets.put("A", 0L);
        nets.put("B", 0L);
        assertThat(Simplifier.simplify(nets, MEMBERS)).isEmpty();
    }

    @Test
    void simplifierRejectsNetsThatDoNotSumToZeroOrUnknownMembers() {
        assertThatThrownBy(() -> Simplifier.simplify(Map.of("A", 10L, "B", -9L), MEMBERS))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
        assertThatThrownBy(() -> Simplifier.simplify(Map.of("A", 10L, "Z", -10L), MEMBERS))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.MEMBER_NOT_IN_GROUP);
    }
}
