package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Member;
import app.qesma.service.ExpenseCommand.ItemInput;
import app.qesma.service.ExpenseCommand.PayerInput;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * The shared create/preview pipeline against the spec section 10 vectors V5-V8 and the B5 edge cases. No database:
 * this is the exact code both endpoints call, so one set of numbers covers both.
 */
class ExpenseCalculatorTest {

    private static final UUID GROUP = UUID.randomUUID();
    private static final UUID A = UUID.fromString("00000000-0000-0000-0000-00000000000a");
    private static final UUID B = UUID.fromString("00000000-0000-0000-0000-00000000000b");
    private static final UUID C = UUID.fromString("00000000-0000-0000-0000-00000000000c");
    private static final LocalDate DAY = LocalDate.of(2026, 10, 18);

    private static final List<Member> ROSTER = List.of(member(A, "A", 1), member(B, "B", 2), member(C, "C", 3));

    private static Member member(UUID id, String name, int order) {
        return new Member(id, GROUP, name, order, Instant.parse("2026-10-18T10:00:00Z"));
    }

    /** Pizza 200.00 (A,B), Pasta 150.00 (C), Drinks 90.00 (A,B,C): the items shared by V5-V8. */
    private static List<ItemInput> restaurantItems() {
        return List.of(new ItemInput("Pizza", 20000L, List.of(A, B)), new ItemInput("Pasta", 15000L, List.of(C)),
                new ItemInput("Drinks", 9000L, List.of(A, B, C)));
    }

    private static ExpenseCommand bill(List<ItemInput> items, Integer serviceBps, Integer taxBps, String taxBase,
                                       Long adjustment, Long statedTotal, long paidByA) {
        return new ExpenseCommand("Dinner", DAY, "ITEMIZED", statedTotal, List.of(new PayerInput(A, paidByA)), null,
                null, items, serviceBps == null ? null : new ExpenseCommand.ServiceInput(serviceBps),
                taxBps == null ? null : new ExpenseCommand.TaxInput(taxBps, taxBase), adjustment);
    }

    private static ExpenseCalculator.Computation compute(ExpenseCommand command) {
        return ExpenseCalculator.compute(ExpenseValidator.validate(command, false), ROSTER);
    }

    private static List<Long> owed(ExpenseCalculator.Computation c) {
        return c.shares().stream().map(ExpenseView.ShareView::owedMinor).toList();
    }

    private static void assertError(ExpenseCommand command, ErrorCode code) {
        assertThatThrownBy(() -> compute(command)).isInstanceOfSatisfying(ApiException.class,
                e -> assertThat(e.code()).isEqualTo(code));
    }

    @Test
    void v5ServiceAndTaxOnSubtotalPlusServiceKeepsTheTieBreakToTheLowerSortOrder() {
        ExpenseCalculator.Computation c = compute(
                bill(restaurantItems(), 1200, 1400, "SUBTOTAL_PLUS_SERVICE", 0L, null, 56179));

        assertThat(owed(c)).containsExactly(16599L, 16598L, 22982L);      // A 165.99, B 165.98, C 229.82
        assertThat(c.totalMinor()).isEqualTo(56179);
        assertThat(c.subtotalMinor()).isEqualTo(44000);
        assertThat(c.serviceMinor()).isEqualTo(5280);
        assertThat(c.taxMinor()).isEqualTo(6899);
        assertThat(ExpenseCalculator.payersMatch(c)).isTrue();
        ExpenseCalculator.requirePayersMatch(c);
    }

    @Test
    void v5BreakdownExplainsEveryOwedAmount() {
        ExpenseCalculator.Computation c = compute(
                bill(restaurantItems(), 1200, 1400, "SUBTOTAL_PLUS_SERVICE", 0L, null, 56179));
        for (ExpenseView.ShareView s : c.shares()) {
            assertThat(s.itemsMinor() + s.serviceMinor() + s.taxMinor() + s.adjustmentMinor())
                    .isEqualTo(s.owedMinor());
        }
        assertThat(c.shares().get(0).itemsMinor()).isEqualTo(13000);      // A: half of pizza + third of drinks
        assertThat(c.shares().get(0).serviceMinor()).isEqualTo(1560);
    }

    @Test
    void v6ServiceOnly() {
        ExpenseCalculator.Computation c = compute(bill(restaurantItems(), 1200, null, null, null, null, 49280));
        assertThat(owed(c)).containsExactly(14560L, 14560L, 20160L);
        assertThat(c.totalMinor()).isEqualTo(49280);
        assertThat(c.taxBps()).isNull();
        assertThat(c.taxMinor()).isZero();
    }

    @Test
    void v7TaxOnlyOnSubtotal() {
        ExpenseCalculator.Computation c = compute(bill(restaurantItems(), null, 1400, "SUBTOTAL", null, null, 50160));
        assertThat(owed(c)).containsExactly(14820L, 14820L, 20520L);
        assertThat(c.totalMinor()).isEqualTo(50160);
        assertThat(c.serviceBps()).isNull();
        assertThat(c.serviceMinor()).isZero();
        assertThat(c.taxBase()).isEqualTo("SUBTOTAL");
    }

    @Test
    void v8Neither() {
        ExpenseCalculator.Computation c = compute(bill(restaurantItems(), null, null, null, null, null, 44000));
        assertThat(owed(c)).containsExactly(13000L, 13000L, 18000L);
        assertThat(c.totalMinor()).isEqualTo(44000);
        assertThat(c.subtotalMinor()).isEqualTo(44000);
        assertThat(c.serviceBps()).isNull();
        assertThat(c.taxBps()).isNull();
    }

    @Test
    void taxOnlyWithoutABaseUsesSubtotalPlusServiceWhichEqualsSubtotalWhenServiceIsOff() {
        ExpenseCalculator.Computation defaulted = compute(bill(restaurantItems(), null, 1400, null, null, null, 1));
        ExpenseCalculator.Computation explicit = compute(bill(restaurantItems(), null, 1400, "SUBTOTAL", null, null, 1));
        assertThat(defaulted.taxBase()).isEqualTo("SUBTOTAL_PLUS_SERVICE");
        assertThat(owed(defaulted)).isEqualTo(owed(explicit));
    }

    @Test
    void aMemberWithNoItemsIsDroppedFromTheShares() {
        List<ItemInput> items = List.of(new ItemInput("Pizza", 20000L, List.of(A, B)));
        ExpenseCalculator.Computation c = compute(bill(items, null, null, null, null, null, 20000));
        assertThat(c.shares()).extracting(ExpenseView.ShareView::memberId).containsExactly(A, B);
    }

    @Test
    void aPayerWhoIsNotAParticipantIsFine() {
        List<ItemInput> items = List.of(new ItemInput("Pizza", 20000L, List.of(A, B)));
        ExpenseCommand paidByC = new ExpenseCommand("Dinner", DAY, "ITEMIZED", null,
                List.of(new PayerInput(C, 20000L)), null, null, items, null, null, null);
        ExpenseCalculator.Computation c = compute(paidByC);
        ExpenseCalculator.requirePayersMatch(c);
        assertThat(c.shares()).extracting(ExpenseView.ShareView::memberId).doesNotContain(C);
    }

    @Test
    void aNegativeAdjustmentLowersTheTotalAndStillSumsExactly() {
        ExpenseCalculator.Computation c = compute(bill(restaurantItems(), null, null, null, -100L, null, 43900));
        assertThat(c.totalMinor()).isEqualTo(43900);
        assertThat(c.adjustmentMinor()).isEqualTo(-100);
        assertThat(owed(c).stream().mapToLong(Long::longValue).sum()).isEqualTo(43900);
    }

    @Test
    void anAdjustmentThatEmptiesTheBillOrMakesAShareNegativeIsRejected() {
        List<ItemInput> items = List.of(new ItemInput("Pizza", 100L, List.of(A)));
        assertError(bill(items, null, null, null, -100L, null, 1), ErrorCode.VALIDATION_ERROR);
        assertError(bill(items, null, null, null, -500L, null, 1), ErrorCode.VALIDATION_ERROR);
    }

    @Test
    void aStatedTotalMustMatchTheComputedOne() {
        assertThat(compute(bill(restaurantItems(), 1200, 1400, null, null, 56179L, 56179)).totalMinor())
                .isEqualTo(56179);
        assertError(bill(restaurantItems(), 1200, 1400, null, null, 56180L, 56179), ErrorCode.SPLIT_TOTAL_MISMATCH);
    }

    @Test
    void anAssigneeOutsideTheGroupIsRejectedBeforeTheEngineRuns() {
        List<ItemInput> items = List.of(new ItemInput("Pizza", 100L, List.of(A, UUID.randomUUID())));
        assertError(bill(items, null, null, null, null, null, 100), ErrorCode.MEMBER_NOT_IN_GROUP);
    }

    @Test
    void aPayerOutsideTheGroupIsRejected() {
        ExpenseCommand stranger = new ExpenseCommand("Dinner", DAY, "ITEMIZED", null,
                List.of(new PayerInput(UUID.randomUUID(), 100L)), null, null,
                List.of(new ItemInput("Pizza", 100L, List.of(A))), null, null, null);
        assertError(stranger, ErrorCode.MEMBER_NOT_IN_GROUP);
    }

    @Test
    void aDuplicateAssigneeIsAValidationError() {
        List<ItemInput> items = List.of(new ItemInput("Pizza", 100L, List.of(A, A)));
        assertError(bill(items, null, null, null, null, null, 100), ErrorCode.VALIDATION_ERROR);
    }

    @Test
    void payersThatDoNotAddUpAreAnErrorOnCreateButOnlyAFlagOnPreview() {
        ExpenseCalculator.Computation c = compute(bill(restaurantItems(), null, null, null, null, null, 43999));
        assertThat(ExpenseCalculator.payersMatch(c)).isFalse();
        assertThatThrownBy(() -> ExpenseCalculator.requirePayersMatch(c)).isInstanceOfSatisfying(ApiException.class,
                e -> assertThat(e.code()).isEqualTo(ErrorCode.PAYERS_TOTAL_MISMATCH));
    }

    @Test
    void noPayersYetMeansDoNotMatchRatherThanAnError() {
        ExpenseCommand noPayers = new ExpenseCommand("Dinner", DAY, "ITEMIZED", null, null, null, null,
                restaurantItems(), null, null, null);
        ExpenseCalculator.Computation c = compute(noPayers);
        assertThat(ExpenseCalculator.payersMatch(c)).isFalse();
        assertThat(owed(c)).containsExactly(13000L, 13000L, 18000L);
    }

    @Test
    void duplicatePayersStayAnErrorEvenInPreview() {
        ExpenseCommand twice = new ExpenseCommand("Dinner", DAY, "ITEMIZED", null,
                List.of(new PayerInput(A, 100L), new PayerInput(A, 100L)), null, null, restaurantItems(), null, null,
                null);
        ExpenseCalculator.Computation c = compute(twice);
        assertThatThrownBy(() -> ExpenseCalculator.payersMatch(c)).isInstanceOfSatisfying(ApiException.class,
                e -> assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR));
    }

    @Test
    void equalAndExactStillResolveThroughTheSamePipelineWithNoItemizedNumbers() {
        ExpenseCommand equal = new ExpenseCommand("Taxi", DAY, "EQUAL", 10000L, List.of(new PayerInput(A, 10000L)),
                null, null);
        ExpenseCalculator.Computation e = compute(equal);
        assertThat(owed(e)).containsExactly(3334L, 3333L, 3333L);          // spec V3: extra piaster to sort order 1
        assertThat(e.itemized()).isFalse();
        assertThat(e.subtotalMinor()).isNull();
        assertThat(e.shares()).allSatisfy(s -> assertThat(s.itemsMinor()).isNull());

        List<ExpenseCommand.ShareInput> shares = new ArrayList<>(List.of(
                new ExpenseCommand.ShareInput(C, 6000L), new ExpenseCommand.ShareInput(B, 4000L)));
        ExpenseCommand exact = new ExpenseCommand("Taxi", DAY, "EXACT", 10000L, List.of(new PayerInput(A, 10000L)),
                null, shares);
        ExpenseCalculator.Computation x = compute(exact);
        assertThat(x.shares()).extracting(ExpenseView.ShareView::memberId).containsExactly(B, C); // sort order
    }
}
