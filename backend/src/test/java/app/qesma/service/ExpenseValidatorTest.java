package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.service.ExpenseCommand.PayerInput;
import app.qesma.service.ExpenseCommand.ShareInput;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Shape validation of create-expense requests (no database, no money rules). */
class ExpenseValidatorTest {

    private static final UUID A = UUID.randomUUID();
    private static final UUID B = UUID.randomUUID();
    private static final LocalDate DAY = LocalDate.of(2026, 10, 18);

    private static ExpenseCommand equal() {
        return new ExpenseCommand("  Dinner  ", DAY, "equal", 10000L, List.of(new PayerInput(A, 10000L)), null, null);
    }

    private static ExpenseCommand exact() {
        return new ExpenseCommand("Taxi", DAY, "EXACT", 10000L, List.of(new PayerInput(A, 10000L)), null,
                List.of(new ShareInput(A, 4000L), new ShareInput(B, 6000L)));
    }

    private static void assertInvalid(ExpenseCommand c) {
        assertThatThrownBy(() -> ExpenseValidator.validate(c)).isInstanceOfSatisfying(ApiException.class, e -> {
            assertThat(e.code()).isEqualTo(ErrorCode.VALIDATION_ERROR);
            assertThat(e.status().value()).isEqualTo(422);
        });
    }

    private static ExpenseCommand with(ExpenseCommand c, String title, LocalDate date, String type, Long total,
                                       List<PayerInput> payers, List<UUID> participants, List<ShareInput> shares) {
        return new ExpenseCommand(title, date, type, total, payers, participants, shares);
    }

    @Test
    void validEqualRequestIsNormalized() {
        ExpenseValidator.Valid v = ExpenseValidator.validate(equal());
        assertThat(v.title()).isEqualTo("Dinner");
        assertThat(v.splitType()).isEqualTo("EQUAL");
        assertThat(v.participantMemberIds()).isNull(); // null = all members, resolved by the service
        assertThat(v.shares()).isNull();
    }

    @Test
    void validExactRequestKeepsShares() {
        ExpenseValidator.Valid v = ExpenseValidator.validate(exact());
        assertThat(v.shares()).hasSize(2);
        assertThat(v.participantMemberIds()).isNull();
    }

    @Test
    void titleRulesMatchTheDatabaseCheck() {
        ExpenseCommand ok = equal();
        for (String bad : new String[] {null, "", "   ", "x".repeat(101), "😀".repeat(101)}) {
            assertInvalid(with(ok, bad, DAY, "EQUAL", 100L, ok.payers(), null, null));
        }
        assertThat(ExpenseValidator.validate(with(ok, "x".repeat(100), DAY, "EQUAL", 100L, ok.payers(), null, null))
                .title()).hasSize(100);
    }

    @Test
    void dateIsRequiredAndWithinTheSaneRange() {
        ExpenseCommand ok = equal();
        assertInvalid(with(ok, "t", null, "EQUAL", 100L, ok.payers(), null, null));
        assertInvalid(with(ok, "t", LocalDate.of(1999, 12, 31), "EQUAL", 100L, ok.payers(), null, null));
        assertInvalid(with(ok, "t", LocalDate.of(2101, 1, 1), "EQUAL", 100L, ok.payers(), null, null));
        ExpenseValidator.validate(with(ok, "t", LocalDate.of(2000, 1, 1), "EQUAL", 100L, ok.payers(), null, null));
        ExpenseValidator.validate(with(ok, "t", LocalDate.of(2100, 12, 31), "EQUAL", 100L, ok.payers(), null, null));
    }

    @Test
    void splitTypeMustBeOneOfTheThreeKnownTypes() {
        ExpenseCommand ok = equal();
        for (String bad : new String[] {null, "", "PERCENT", "SHARES"}) {
            assertInvalid(with(ok, "t", DAY, bad, 100L, ok.payers(), null, null));
        }
    }

    // ---- ITEMIZED (B5) ------------------------------------------------------------------------------------

    private static ExpenseCommand.ItemInput item(String name, Long amount, UUID... assignees) {
        return new ExpenseCommand.ItemInput(name, amount, List.of(assignees));
    }

    private static ExpenseCommand itemized(List<ExpenseCommand.ItemInput> items, ExpenseCommand.ServiceInput service,
                                           ExpenseCommand.TaxInput tax, Long adjustment) {
        return new ExpenseCommand("Seafood", DAY, "itemized", null, List.of(new PayerInput(A, 100L)), null, null,
                items, service, tax, adjustment);
    }

    private static ExpenseCommand validItemized() {
        return itemized(List.of(item("Pizza", 20000L, A, B)), null, null, null);
    }

    @Test
    void validItemizedWithNothingOptionalHasNoChargesAndTotalIsNotStated() {
        ExpenseValidator.Valid v = ExpenseValidator.validate(validItemized());
        assertThat(v.splitType()).isEqualTo("ITEMIZED");
        assertThat(v.totalMinor()).isZero();                  // "not stated": the engine computes it
        assertThat(v.serviceBps()).isNull();
        assertThat(v.taxBps()).isNull();
        assertThat(v.taxBase()).isNull();
        assertThat(v.adjustmentMinor()).isZero();
        assertThat(v.items()).hasSize(1);
    }

    @Test
    void serviceAndTaxAreIndependentAndTaxBaseDefaultsToSubtotalPlusService() {
        ExpenseCommand it = validItemized();
        ExpenseValidator.Valid serviceOnly = ExpenseValidator.validate(itemized(it.items(),
                new ExpenseCommand.ServiceInput(1200), null, null));
        assertThat(serviceOnly.serviceBps()).isEqualTo(1200);
        assertThat(serviceOnly.taxBps()).isNull();

        ExpenseValidator.Valid taxOnly = ExpenseValidator.validate(itemized(it.items(), null,
                new ExpenseCommand.TaxInput(1400, null), -50L));
        assertThat(taxOnly.serviceBps()).isNull();
        assertThat(taxOnly.taxBps()).isEqualTo(1400);
        assertThat(taxOnly.taxBase()).isEqualTo("SUBTOTAL_PLUS_SERVICE");
        assertThat(taxOnly.adjustmentMinor()).isEqualTo(-50L);

        ExpenseValidator.Valid onSubtotal = ExpenseValidator.validate(itemized(it.items(), null,
                new ExpenseCommand.TaxInput(0, " subtotal "), null));
        assertThat(onSubtotal.taxBase()).isEqualTo("SUBTOTAL");
        assertThat(onSubtotal.taxBps()).isZero();            // 0 bps is a valid, enabled rate
    }

    @Test
    void itemizedRulesAreEnforced() {
        UUID[] ab = {A, B};
        assertInvalid(itemized(null, null, null, null));
        assertInvalid(itemized(List.of(), null, null, null));
        assertInvalid(itemized(List.of(item("P", 0L, ab)), null, null, null));
        assertInvalid(itemized(List.of(item("P", -5L, ab)), null, null, null));
        assertInvalid(itemized(List.of(item("P", null, ab)), null, null, null));
        assertInvalid(itemized(List.of(item(" ", 100L, ab)), null, null, null));
        assertInvalid(itemized(List.of(item("x".repeat(101), 100L, ab)), null, null, null));
        assertInvalid(itemized(List.of(item("P", 100L)), null, null, null));                  // no assignee
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", 100L, null)), null, null, null));
        List<UUID> withNull = new ArrayList<>();
        withNull.add(null);
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", 100L, withNull)), null, null, null));
    }

    @Test
    void itemizedBpsMustBeInRangeAndTaxBaseKnown() {
        List<ExpenseCommand.ItemInput> items = validItemized().items();
        for (Integer bad : new Integer[] {null, -1, 10001}) {
            assertInvalid(itemized(items, new ExpenseCommand.ServiceInput(bad), null, null));
            assertInvalid(itemized(items, null, new ExpenseCommand.TaxInput(bad, null), null));
        }
        ExpenseValidator.validate(itemized(items, new ExpenseCommand.ServiceInput(10000),
                new ExpenseCommand.TaxInput(10000, "SUBTOTAL"), null));
        assertInvalid(itemized(items, null, new ExpenseCommand.TaxInput(100, "TOTAL"), null));
    }

    // ---- BSA2: quantity, discount, charges as amounts --------------------------------------------------------

    private static ExpenseCommand withDiscount(ExpenseCommand.DiscountInput discount) {
        ExpenseCommand c = validItemized();
        return new ExpenseCommand(c.title(), c.expenseDate(), c.splitType(), null, c.payers(), null, null, c.items(),
                null, null, null, null, null, discount);
    }

    @Test
    void itemsAreNormalizedToQuantityUnitAndLineAmount() {
        ExpenseValidator.Valid legacy = ExpenseValidator.validate(validItemized());
        assertThat(legacy.items().get(0)).isEqualTo(new ExpenseCommand.ItemInput("Pizza", 20000L, 20000L, 1, List.of(A, B)));
        ExpenseValidator.Valid unit = ExpenseValidator.validate(itemized(List.of(
                new ExpenseCommand.ItemInput("Pepsi", null, 1525L, 3, List.of(A))), null, null, null));
        assertThat(unit.items().get(0)).isEqualTo(new ExpenseCommand.ItemInput("Pepsi", 4575L, 1525L, 3, List.of(A)));
        ExpenseValidator.Valid unitNoQuantity = ExpenseValidator.validate(itemized(List.of(
                new ExpenseCommand.ItemInput("Pepsi", null, 1525L, null, List.of(A))), null, null, null));
        assertThat(unitNoQuantity.items().get(0).quantity()).isEqualTo(1);
    }

    @Test
    void itemShapeAndQuantityRangeAreEnforced() {
        UUID[] a = {A};
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", 100L, 100L, null, List.of(a))), null, null, null));
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", 100L, null, 2, List.of(a))), null, null, null));
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, null, 2, List.of(a))), null, null, null));
        for (Integer bad : new Integer[] {0, -1, 1000}) {
            assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, 100L, bad, List.of(a))), null, null,
                    null));
        }
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, 0L, 1, List.of(a))), null, null, null));
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, 1_000_000_000_001L, 1, List.of(a))), null,
                null, null));
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, 1_000_000_000_000L, 2, List.of(a))), null,
                null, null));                                                   // line above the A43 cap
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", null, Long.MAX_VALUE, 999, List.of(a))), null,
                null, null));                                                   // overflow is a 422, not a 500
        ExpenseValidator.validate(itemized(List.of(new ExpenseCommand.ItemInput("P", null, 1L, 999, List.of(a))), null,
                null, null));
    }

    @Test
    void chargesTakeExactlyOneFormWithinRange() {
        List<ExpenseCommand.ItemInput> items = validItemized().items();
        ExpenseValidator.Valid amounts = ExpenseValidator.validate(itemized(items,
                new ExpenseCommand.ServiceInput(null, 500L), new ExpenseCommand.TaxInput(null, 700L, null), null));
        assertThat(amounts.serviceBps()).isNull();
        assertThat(amounts.serviceAmountMinor()).isEqualTo(500L);
        assertThat(amounts.taxAmountMinor()).isEqualTo(700L);
        assertThat(amounts.taxBase()).isEqualTo("SUBTOTAL_PLUS_SERVICE");

        assertInvalid(itemized(items, new ExpenseCommand.ServiceInput(1200, 500L), null, null));
        assertInvalid(itemized(items, new ExpenseCommand.ServiceInput(null, null), null, null));
        assertInvalid(itemized(items, new ExpenseCommand.ServiceInput(null, 0L), null, null));
        assertInvalid(itemized(items, null, new ExpenseCommand.TaxInput(1400, 700L, null), null));
        assertInvalid(itemized(items, null, new ExpenseCommand.TaxInput(null, null, "SUBTOTAL"), null));
        assertInvalid(itemized(items, null, new ExpenseCommand.TaxInput(null, 1_000_000_000_001L, null), null));
    }

    @Test
    void discountTakesExactlyOneFormWithinRangeAndOnlyOnItemized() {
        assertThat(ExpenseValidator.validate(withDiscount(new ExpenseCommand.DiscountInput(1000, null))).discountBps())
                .isEqualTo(1000);
        assertThat(ExpenseValidator.validate(withDiscount(new ExpenseCommand.DiscountInput(null, 500L)))
                .discountAmountMinor()).isEqualTo(500L);
        ExpenseValidator.validate(withDiscount(new ExpenseCommand.DiscountInput(9999, null)));
        for (ExpenseCommand.DiscountInput bad : List.of(new ExpenseCommand.DiscountInput(0, null),
                new ExpenseCommand.DiscountInput(10000, null), new ExpenseCommand.DiscountInput(null, 0L),
                new ExpenseCommand.DiscountInput(1000, 500L), new ExpenseCommand.DiscountInput(null, null))) {
            assertInvalid(withDiscount(bad));
        }
        ExpenseCommand e = equal();
        assertInvalid(new ExpenseCommand(e.title(), e.expenseDate(), e.splitType(), e.totalMinor(), e.payers(), null,
                null, null, null, null, null, null, null, new ExpenseCommand.DiscountInput(1000, null)));
    }

    @Test
    void itemsAndAssigneesAreCapped() {
        List<ExpenseCommand.ItemInput> many = new ArrayList<>();
        for (int i = 0; i < 101; i++) {
            many.add(item("i" + i, 100L, A));
        }
        assertInvalid(itemized(many, null, null, null));
        ExpenseValidator.validate(itemized(many.subList(0, 100), null, null, null));

        List<UUID> crowd = new ArrayList<>();
        for (int i = 0; i < 101; i++) {
            crowd.add(UUID.randomUUID());
        }
        assertInvalid(itemized(List.of(new ExpenseCommand.ItemInput("P", 100L, crowd)), null, null, null));
    }

    @Test
    void aStatedItemizedTotalMustBePositiveAndFieldsOfOtherTypesAreRejected() {
        ExpenseCommand base = validItemized();
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", 0L, base.payers(), null, null, base.items(), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", -1L, base.payers(), null, null, base.items(), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", null, base.payers(), List.of(A), null, base.items(), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", null, base.payers(), null,
                List.of(new ShareInput(A, 1L)), base.items(), null, null, null));
        ExpenseCommand ok = equal();
        assertInvalid(new ExpenseCommand("t", DAY, "EQUAL", 100L, ok.payers(), null, null, base.items(), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "EQUAL", 100L, ok.payers(), null, null, null,
                new ExpenseCommand.ServiceInput(100), null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "EXACT", 100L, exact().payers(), null, exact().shares(), null, null,
                new ExpenseCommand.TaxInput(100, null), null));
        assertInvalid(new ExpenseCommand("t", DAY, "EQUAL", 100L, ok.payers(), null, null, null, null, null, 5L));
    }

    @Test
    void previewMayOmitPayersButCreateMayNot() {
        ExpenseCommand noPayers = new ExpenseCommand("t", DAY, "EQUAL", 100L, null, null, null);
        assertInvalid(noPayers);
        assertThat(ExpenseValidator.validate(noPayers, false).payers()).isEmpty();
        // a half-filled payer row is still an error in preview
        assertThatThrownBy(() -> ExpenseValidator.validate(
                new ExpenseCommand("t", DAY, "EQUAL", 100L, List.of(new PayerInput(null, 1L)), null, null), false))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void totalMustBePresentAndPositive() {
        ExpenseCommand ok = equal();
        for (Long bad : new Long[] {null, 0L, -1L, Long.MIN_VALUE}) {
            assertInvalid(with(ok, "t", DAY, "EQUAL", bad, ok.payers(), null, null));
        }
    }

    @Test
    void everyAmountIsCappedAtTenBillionPounds() {
        long cap = app.qesma.engine.Limits.MAX_AMOUNT_MINOR;
        ExpenseCommand ok = equal();
        ExpenseValidator.validate(with(ok, "t", DAY, "EQUAL", cap, List.of(new PayerInput(A, cap)), null, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", cap + 1, ok.payers(), null, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, List.of(new PayerInput(A, cap + 1)), null, null));
        ExpenseCommand ex = exact();
        assertInvalid(with(ex, "t", DAY, "EXACT", 100L, ex.payers(), null, List.of(new ShareInput(A, cap + 1))));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", cap + 1, ok.payers(), null, null,
                List.of(new ExpenseCommand.ItemInput("p", 1L, List.of(A))), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", null, ok.payers(), null, null,
                List.of(new ExpenseCommand.ItemInput("p", cap + 1, List.of(A))), null, null, null));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", null, ok.payers(), null, null,
                List.of(new ExpenseCommand.ItemInput("p", 1L, List.of(A))), null, null, cap + 1));
        assertInvalid(new ExpenseCommand("t", DAY, "ITEMIZED", null, ok.payers(), null, null,
                List.of(new ExpenseCommand.ItemInput("p", 1L, List.of(A))), null, null, -cap - 1));
    }

    @Test
    void payersAreRequiredBoundedAndComplete() {
        ExpenseCommand ok = equal();
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, null, null, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, List.of(), null, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, List.of(new PayerInput(null, 100L)), null, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, List.of(new PayerInput(A, null)), null, null));
        List<PayerInput> many = new ArrayList<>();
        for (int i = 0; i < 101; i++) {
            many.add(new PayerInput(UUID.randomUUID(), 1L));
        }
        assertInvalid(with(ok, "t", DAY, "EQUAL", 101L, many, null, null));
    }

    @Test
    void equalRejectsSharesAndAnEmptyOrNullContainingParticipantList() {
        ExpenseCommand ok = equal();
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, ok.payers(), List.of(), null));
        List<UUID> withNull = new ArrayList<>();
        withNull.add(null);
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, ok.payers(), withNull, null));
        assertInvalid(with(ok, "t", DAY, "EQUAL", 100L, ok.payers(), null, List.of(new ShareInput(A, 100L))));
        ExpenseValidator.validate(with(ok, "t", DAY, "EQUAL", 100L, ok.payers(), List.of(A, B), null));
    }

    @Test
    void exactRequiresCompleteSharesAndRejectsParticipantList() {
        ExpenseCommand ok = exact();
        assertInvalid(with(ok, "t", DAY, "EXACT", 100L, ok.payers(), null, null));
        assertInvalid(with(ok, "t", DAY, "EXACT", 100L, ok.payers(), null, List.of()));
        assertInvalid(with(ok, "t", DAY, "EXACT", 100L, ok.payers(), null, List.of(new ShareInput(null, 1L))));
        assertInvalid(with(ok, "t", DAY, "EXACT", 100L, ok.payers(), null, List.of(new ShareInput(A, null))));
        assertInvalid(with(ok, "t", DAY, "EXACT", 100L, ok.payers(), List.of(A), ok.shares()));
    }

    @Test
    void nullRequestIsRejected() {
        assertInvalid(null);
    }

    @Test
    void validationMessagesNeverEchoTheTitle() {
        ExpenseCommand ok = equal();
        String secret = "secret-title-" + "x".repeat(120);
        assertThatThrownBy(() -> ExpenseValidator.validate(with(ok, secret, DAY, "EQUAL", 100L, ok.payers(), null, null)))
                .hasMessageNotContaining("secret-title");
    }
}
