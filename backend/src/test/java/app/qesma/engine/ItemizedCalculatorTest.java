package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.ItemizedCalculator.ChargeSpec;
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

    // ---- BSA2: discount, quantity, charges as amounts (STANDALONE_SPEC 18, A171-A173) ----------------------

    private static final List<MemberRef> AB = List.of(new MemberRef("A", 1), new MemberRef("B", 2));

    private static ItemizedInput meal(ChargeSpec discount) {
        return new ItemizedInput(AB, List.of(new Item("Meal", 10000, List.of("A", "B"))), discount, null, null, 0);
    }

    @Test
    void discountMustBeAboveZeroAndBelowTheSubtotal() {
        assertValidation(meal(ChargeSpec.amount(0)));
        assertValidation(meal(ChargeSpec.amount(10000)));                  // equal to the subtotal (V15)
        assertValidation(meal(ChargeSpec.amount(10001)));
        assertValidation(meal(ChargeSpec.percent(0)));
        assertValidation(meal(ChargeSpec.percent(10000)));                 // 100% (V15)
        ItemizedResult r = ItemizedCalculator.calculate(meal(ChargeSpec.amount(9999)));   // subtotal - 1 piaster
        assertThat(r.discountMinor()).isEqualTo(9999);
        assertThat(r.totalMinor()).isEqualTo(1);
        assertThat(ItemizedCalculator.calculate(meal(ChargeSpec.percent(9999))).discountMinor()).isEqualTo(9999);
    }

    @Test
    void percentDiscountThatRoundsToZeroPiastersIsRejected() {
        // 1 bps of 10 piasters = 0.001 -> 0, which breaks 0 < discount (STANDALONE_SPEC 18.2 step 2).
        assertValidation(new ItemizedInput(AB, List.of(new Item("Gum", 10, List.of("A"))),
                ChargeSpec.percent(1), null, null, 0));
    }

    @Test
    void discountCanDropAMemberToZero() {
        ItemizedResult r = ItemizedCalculator.calculate(meal(ChargeSpec.amount(9999)));   // V14
        assertThat(r.members()).containsExactly(new MemberBreakdown("B", 5000, 4999, 0, 0, 0, 1));
    }

    @Test
    void discountPartNeverExceedsTheMembersItems() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(ABC, List.of(
                new Item("Big", 99999, List.of("A")), new Item("Tiny", 1, List.of("B")), new Item("Mid", 3, List.of("C"))),
                ChargeSpec.amount(100002), null, null, 0));
        assertThat(r.members()).allSatisfy(m -> assertThat(m.discountMinor()).isBetween(0L, m.itemsMinor()));
        assertThat(r.totalMinor()).isEqualTo(1);
    }

    @Test
    void quantityBoundaries() {
        ItemizedResult one = ItemizedCalculator.calculate(new ItemizedInput(AB,
                List.of(new Item("Pepsi", 1, 1525, List.of("A"))), null, null, null, 0));
        assertThat(one.subtotalMinor()).isEqualTo(1525);
        ItemizedResult max = ItemizedCalculator.calculate(new ItemizedInput(AB,
                List.of(new Item("Pepsi", 999, 1525, List.of("A", "B"))), null, null, null, 0));
        assertThat(max.subtotalMinor()).isEqualTo(999L * 1525);
        assertValidation(new ItemizedInput(AB, List.of(new Item("Pepsi", 0, 1525, List.of("A"))), null, null, null, 0));
        assertValidation(new ItemizedInput(AB, List.of(new Item("Pepsi", 1000, 1525, List.of("A"))), null, null, null, 0));
        assertValidation(new ItemizedInput(AB, List.of(new Item("Free", 2, 0, List.of("A"))), null, null, null, 0));
    }

    @Test
    void lineAmountIsCappedAndOverflowIsAValidationError() {
        assertValidation(new ItemizedInput(AB,
                List.of(new Item("Yacht", 999, Limits.MAX_AMOUNT_MINOR, List.of("A"))), null, null, null, 0));
        assertValidation(new ItemizedInput(AB,
                List.of(new Item("Overflow", 999, Long.MAX_VALUE, List.of("A"))), null, null, null, 0));
        ItemizedResult atCap = ItemizedCalculator.calculate(new ItemizedInput(AB,
                List.of(new Item("Cap", 1, Limits.MAX_AMOUNT_MINOR, List.of("A"))), null, null, null, 0));
        assertThat(atCap.totalMinor()).isEqualTo(Limits.MAX_AMOUNT_MINOR);
    }

    @Test
    void itemShapeIsEitherLegacyAmountOrUnitWithOptionalQuantity() {
        assertThat(Item.of("X", 500L, null, null, List.of("A"))).isEqualTo(new Item("X", 1, 500, List.of("A")));
        assertThat(Item.of("X", null, 500L, null, List.of("A"))).isEqualTo(new Item("X", 1, 500, List.of("A")));
        assertThat(Item.of("X", null, 500L, 3, List.of("A")).amountMinor()).isEqualTo(1500);
        assertShape(() -> Item.of("X", 500L, 500L, null, List.of("A")));   // both (V16)
        assertShape(() -> Item.of("X", null, null, null, List.of("A")));   // neither
        assertShape(() -> Item.of("X", 500L, null, 2, List.of("A")));      // quantity only goes with a unit price
    }

    @Test
    void chargeShapeIsEitherPercentOrAmount() {
        assertThat(ChargeSpec.of(1200, null)).isEqualTo(ChargeSpec.percent(1200));
        assertThat(ChargeSpec.of(null, 5000L)).isEqualTo(ChargeSpec.amount(5000));
        assertShape(() -> ChargeSpec.of(1200, 5000L));
        assertShape(() -> ChargeSpec.of(null, null));
    }

    @Test
    void chargeAmountsMustBePositive() {
        List<Item> items = List.of(new Item("X", 10000, List.of("A")));
        assertValidation(new ItemizedInput(AB, items, null, ChargeSpec.amount(0), null, 0));
        assertValidation(new ItemizedInput(AB, items, null, null, new TaxSpec(ChargeSpec.amount(0), TaxBase.SUBTOTAL), 0));
        assertValidation(new ItemizedInput(AB, items, null, ChargeSpec.amount(Limits.MAX_AMOUNT_MINOR + 1), null, 0));
    }

    @Test
    void taxAmountOnSubtotalIsWeightedByNetShares() {
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), ChargeSpec.amount(5000),
                ChargeSpec.percent(1200), new TaxSpec(ChargeSpec.amount(5000), TaxBase.SUBTOTAL), 0));
        // Net 11523 / 11523 / 15954: the tax amount follows the discount allocation exactly (same weights' ratio).
        assertThat(r.members()).extracting(MemberBreakdown::taxMinor).containsExactly(1477L, 1477L, 2046L);
        assertThat(r.totalMinor()).isEqualTo(44000 - 5000 + r.serviceMinor() + 5000);
    }

    @Test
    void adjustmentIsWeightedByNetShares() {
        // Net A 0, B 1 after the V14 discount: the whole adjustment goes to B.
        ItemizedResult r = ItemizedCalculator.calculate(new ItemizedInput(AB,
                List.of(new Item("Meal", 10000, List.of("A", "B"))), ChargeSpec.amount(9999), null, null, 100));
        assertThat(r.members()).containsExactly(new MemberBreakdown("B", 5000, 4999, 0, 0, 100, 101));
    }

    @Test
    void legacyInputIsTheSameAsPercentSpecs() {
        ItemizedResult legacy = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), 1200,
                new TaxSpec(1400, TaxBase.SUBTOTAL_PLUS_SERVICE), 0));
        ItemizedResult specs = ItemizedCalculator.calculate(new ItemizedInput(ABC, restaurant(), null,
                ChargeSpec.percent(1200), new TaxSpec(ChargeSpec.percent(1400), TaxBase.SUBTOTAL_PLUS_SERVICE), 0));
        assertThat(specs).isEqualTo(legacy);
        assertThat(legacy.discountMinor()).isZero();
        assertThat(legacy.members()).allSatisfy(m -> assertThat(m.discountMinor()).isZero());
    }

    private static void assertShape(org.assertj.core.api.ThrowableAssert.ThrowingCallable call) {
        assertThatThrownBy(call).isInstanceOf(EngineException.class)
                .extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }

    private static void assertValidation(ItemizedInput in) {
        assertThatThrownBy(() -> ItemizedCalculator.calculate(in))
                .isInstanceOf(EngineException.class).extracting("code").isEqualTo(EngineErrorCode.VALIDATION_ERROR);
    }
}
