package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.ItemizedCalculator.Item;
import app.qesma.engine.ItemizedCalculator.ItemizedInput;
import app.qesma.engine.ItemizedCalculator.ItemizedResult;
import app.qesma.engine.ItemizedCalculator.MemberBreakdown;
import app.qesma.engine.ItemizedCalculator.TaxBase;
import app.qesma.engine.ItemizedCalculator.TaxSpec;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Spec 7.4 ITEMIZED. Vectors V5-V8 are also covered by fixtures; these are the edge cases. */
class ItemizedCalculatorTest {

    private static final List<MemberRef> ABC = List.of(new MemberRef("A", 1), new MemberRef("B", 2), new MemberRef("C", 3));

    private static List<Item> restaurant() {
        return List.of(
                new Item("Pizza", 20000, List.of("A", "B")),
                new Item("Pasta", 15000, List.of("C")),
                new Item("Drinks", 9000, List.of("A", "B", "C")));
    }

    private static long owed(ItemizedResult r, String id) {
        return r.members().stream().filter(m -> m.memberId().equals(id)).mapToLong(MemberBreakdown::owedMinor).sum();
    }

    @Test
    void serviceAndTaxMatchVectorV5WithBreakdown() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), 1200,
                new TaxSpec(1400, TaxBase.SUBTOTAL_PLUS_SERVICE), 0));
        assertThat(r.subtotalMinor()).isEqualTo(44000);
        assertThat(r.serviceMinor()).isEqualTo(5280);
        assertThat(r.taxMinor()).isEqualTo(6899);
        assertThat(r.totalMinor()).isEqualTo(56179);
        MemberBreakdown a = r.members().get(0);
        assertThat(a).isEqualTo(new MemberBreakdown("A", 13000, 1560, 2039, 0, 16599));
    }

    @Test
    void taxWithoutServiceIsTheSameForBothBases() {
        ItemizedResult plusService = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), null,
                new TaxSpec(1400, TaxBase.SUBTOTAL_PLUS_SERVICE), 0));
        ItemizedResult subtotal = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), null,
                new TaxSpec(1400, TaxBase.SUBTOTAL), 0));
        assertThat(plusService).isEqualTo(subtotal);
    }

    @Test
    void taxBaseDefaultsToSubtotalPlusService() {
        assertThat(new TaxSpec(1400, null).base()).isEqualTo(TaxBase.SUBTOTAL_PLUS_SERVICE);
    }

    @Test
    void itemSharedBySevenSplitsExactly() {
        List<MemberRef> seven = List.of(
                new MemberRef("1", 1), new MemberRef("2", 2), new MemberRef("3", 3), new MemberRef("4", 4),
                new MemberRef("5", 5), new MemberRef("6", 6), new MemberRef("7", 7));
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(seven,
                List.of(new Item("Feast", 10000, List.of("1", "2", "3", "4", "5", "6", "7"))), null, null, 0));
        // 10000 / 7 = 1428.57 -> floors 1428 (sum 9996), 4 leftover units to sortOrder 1..4
        assertThat(r.members()).extracting(MemberBreakdown::owedMinor)
                .containsExactly(1429L, 1429L, 1429L, 1429L, 1428L, 1428L, 1428L);
        assertThat(r.totalMinor()).isEqualTo(10000);
    }

    @Test
    void negativeAdjustmentIsAllocatedByItemSubtotalsAndSignApplied() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(
                List.of(new MemberRef("A", 1), new MemberRef("B", 2)),
                List.of(new Item("X", 10000, List.of("A")), new Item("Y", 10000, List.of("B"))), null, null, -1001));
        assertThat(r.totalMinor()).isEqualTo(18999);
        assertThat(r.adjustmentMinor()).isEqualTo(-1001);
        assertThat(owed(r, "A")).isEqualTo(9499); // -501 (tie -> lowest sortOrder)
        assertThat(owed(r, "B")).isEqualTo(9500); // -500
    }

    @Test
    void positiveAdjustmentIsAllocatedProportionally() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(
                List.of(new MemberRef("A", 1), new MemberRef("B", 2)),
                List.of(new Item("X", 10000, List.of("A")), new Item("Y", 30000, List.of("B"))), null, null, 400));
        assertThat(owed(r, "A")).isEqualTo(10100);
        assertThat(owed(r, "B")).isEqualTo(30300);
    }

    @Test
    void membersWithZeroOwedAreDropped() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(ABC,
                List.of(new Item("Solo", 5000, List.of("B"))), null, null, 0));
        assertThat(r.members()).extracting(MemberBreakdown::memberId).containsExactly("B");
    }

    @Test
    void totalMustBePositive() {
        assertThatThrownBy(() -> ItemizedCalculator.calculate(new ItemizedInput(ABC,
                List.of(new Item("Solo", 5000, List.of("A"))), null, null, -5000)))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }

    @Test
    void rejectsInvalidInput() {
        assertValidation(new ItemizedInput(ABC, List.of(), null, null, 0));
        assertValidation(new ItemizedInput(ABC, List.of(new Item("Zero", 0, List.of("A"))), null, null, 0));
        assertValidation(new ItemizedInput(ABC, List.of(new Item("Nobody", 100, List.of())), null, null, 0));
        assertValidation(new ItemizedInput(ABC, List.of(new Item("Dup", 100, List.of("A", "A"))), null, null, 0));
        assertValidation(new ItemizedInput(ABC, List.of(new Item("Ok", 100, List.of("A"))), 10001, null, 0));
        assertValidation(new ItemizedInput(ABC, List.of(new Item("Ok", 100, List.of("A"))), null,
                new TaxSpec(-1, TaxBase.SUBTOTAL), 0));
        assertValidation(new ItemizedInput(List.of(new MemberRef("A", 1), new MemberRef("A", 2)),
                List.of(new Item("Ok", 100, List.of("A"))), null, null, 0));
    }

    @Test
    void unknownAssigneeIsMemberNotInGroup() {
        assertThatThrownBy(() -> ItemizedCalculator.calculate(new ItemizedInput(ABC,
                List.of(new Item("Ghost", 100, List.of("Z"))), null, null, 0)))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.MEMBER_NOT_IN_GROUP);
    }

    @Test
    void hugeItemAmountsFailWithTypedErrorNotRawArithmeticException() {
        assertThatThrownBy(() -> ItemizedCalculator.calculate(new ItemizedInput(ABC,
                List.of(new Item("A", Long.MAX_VALUE, List.of("A")), new Item("B", Long.MAX_VALUE, List.of("B"))),
                null, null, 0)))
                .isInstanceOf(EngineException.class);
    }

    private static void assertValidation(ItemizedInput in) {
        assertThatThrownBy(() -> ItemizedCalculator.calculate(in))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }
}
