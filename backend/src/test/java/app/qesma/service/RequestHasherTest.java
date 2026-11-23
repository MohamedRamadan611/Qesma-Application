package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.service.ExpenseCommand.PayerInput;
import app.qesma.service.ExpenseCommand.ShareInput;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The idempotency request hash: equal meaning => equal hash, any real difference => different hash. */
class RequestHasherTest {

    private static final String ENDPOINT = ExpenseService.CREATE_ENDPOINT;
    private static final UUID GROUP = UUID.randomUUID();
    private static final UUID A = UUID.fromString("00000000-0000-0000-0000-00000000000a");
    private static final UUID B = UUID.fromString("00000000-0000-0000-0000-00000000000b");
    private static final UUID C = UUID.fromString("00000000-0000-0000-0000-00000000000c");

    private final RequestHasher hasher = new RequestHasher(new ObjectMapper());

    private static ExpenseValidator.Valid equal(String title, long total, List<PayerInput> payers, List<UUID> parts) {
        return new ExpenseValidator.Valid(title, LocalDate.of(2026, 10, 18), "EQUAL", total, payers, parts, null);
    }

    private static ExpenseValidator.Valid exact(List<PayerInput> payers, List<ShareInput> shares) {
        return new ExpenseValidator.Valid("Taxi", LocalDate.of(2026, 10, 18), "EXACT", 10000, payers, null, shares);
    }

    private String h(ExpenseValidator.Valid v) {
        return hasher.hash(ENDPOINT, GROUP, v);
    }

    @Test
    void sameRequestHashesTheSameAndLooksLikeSha256Hex() {
        ExpenseValidator.Valid v = equal("Dinner", 10000, List.of(new PayerInput(A, 10000L)), List.of(A, B));
        assertThat(h(v)).isEqualTo(h(v)).matches("[0-9a-f]{64}");
    }

    @Test
    void orderOfPayersParticipantsAndSharesDoesNotMatter() {
        List<PayerInput> p1 = List.of(new PayerInput(A, 6000L), new PayerInput(B, 4000L));
        List<PayerInput> p2 = List.of(new PayerInput(B, 4000L), new PayerInput(A, 6000L));
        assertThat(h(equal("D", 10000, p1, List.of(A, B, C)))).isEqualTo(h(equal("D", 10000, p2, List.of(C, B, A))));

        List<ShareInput> s1 = List.of(new ShareInput(A, 4000L), new ShareInput(B, 6000L));
        List<ShareInput> s2 = List.of(new ShareInput(B, 6000L), new ShareInput(A, 4000L));
        assertThat(h(exact(p1, s1))).isEqualTo(h(exact(p2, s2)));
    }

    @Test
    void anyRealDifferenceChangesTheHash() {
        List<PayerInput> pay = List.of(new PayerInput(A, 10000L));
        String base = h(equal("Dinner", 10000, pay, List.of(A, B)));

        assertThat(h(equal("Dinner!", 10000, pay, List.of(A, B)))).isNotEqualTo(base);       // title
        assertThat(h(equal("Dinner", 10001, pay, List.of(A, B)))).isNotEqualTo(base);        // total
        assertThat(h(equal("Dinner", 10000, List.of(new PayerInput(B, 10000L)), List.of(A, B)))).isNotEqualTo(base);
        assertThat(h(equal("Dinner", 10000, List.of(new PayerInput(A, 9999L)), List.of(A, B)))).isNotEqualTo(base);
        assertThat(h(equal("Dinner", 10000, pay, List.of(A)))).isNotEqualTo(base);           // participants
        assertThat(h(new ExpenseValidator.Valid("Dinner", LocalDate.of(2026, 10, 19), "EQUAL", 10000, pay,
                List.of(A, B), null))).isNotEqualTo(base);                                    // date
    }

    @Test
    void anOmittedParticipantListIsADifferentRequestThanAnExplicitOne() {
        List<PayerInput> pay = List.of(new PayerInput(A, 10000L));
        assertThat(h(equal("D", 10000, pay, null))).isNotEqualTo(h(equal("D", 10000, pay, List.of(A, B))));
    }

    @Test
    void theGenericHashBindsEndpointGroupAndEveryField() {
        java.util.Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("amountMinor", 5L);
        String base = hasher.hash("POST /x", GROUP, body);
        assertThat(base).matches("[0-9a-f]{64}").isEqualTo(hasher.hash("POST /x", GROUP, body));
        assertThat(hasher.hash("POST /y", GROUP, body)).isNotEqualTo(base);
        assertThat(hasher.hash("POST /x", UUID.randomUUID(), body)).isNotEqualTo(base);
        body.put("amountMinor", 6L);
        assertThat(hasher.hash("POST /x", GROUP, body)).isNotEqualTo(base);
    }

    @Test
    void groupAndEndpointArePartOfTheHash() {
        ExpenseValidator.Valid v = equal("D", 100, List.of(new PayerInput(A, 100L)), null);
        assertThat(hasher.hash(ENDPOINT, GROUP, v)).isNotEqualTo(hasher.hash(ENDPOINT, UUID.randomUUID(), v));
        assertThat(hasher.hash(ENDPOINT, GROUP, v)).isNotEqualTo(hasher.hash("POST /something/else", GROUP, v));
    }

    // ---- ITEMIZED (B5) ------------------------------------------------------------------------------------

    private static ExpenseValidator.Valid itemized(List<ExpenseCommand.ItemInput> items, Integer service, Integer tax,
                                                   String base, long adjustment) {
        return new ExpenseValidator.Valid("Dinner", LocalDate.of(2026, 10, 18), "ITEMIZED", 0,
                List.of(new PayerInput(A, 100L)), null, null, items, service, tax, base, adjustment);
    }

    private static List<ExpenseCommand.ItemInput> twoItems() {
        return List.of(new ExpenseCommand.ItemInput("Pizza", 200L, List.of(A, B)),
                new ExpenseCommand.ItemInput("Pasta", 150L, List.of(C)));
    }

    @Test
    void assigneeOrderDoesNotMatterButItemOrderAndContentDo() {
        String base = h(itemized(twoItems(), 1200, 1400, "SUBTOTAL", 0));

        List<ExpenseCommand.ItemInput> swappedAssignees = List.of(
                new ExpenseCommand.ItemInput("Pizza", 200L, List.of(B, A)),
                new ExpenseCommand.ItemInput("Pasta", 150L, List.of(C)));
        assertThat(h(itemized(swappedAssignees, 1200, 1400, "SUBTOTAL", 0))).isEqualTo(base);

        List<ExpenseCommand.ItemInput> swappedItems = List.of(twoItems().get(1), twoItems().get(0));
        assertThat(h(itemized(swappedItems, 1200, 1400, "SUBTOTAL", 0))).isNotEqualTo(base);   // order is stored

        List<ExpenseCommand.ItemInput> otherAmount = List.of(
                new ExpenseCommand.ItemInput("Pizza", 201L, List.of(A, B)), twoItems().get(1));
        assertThat(h(itemized(otherAmount, 1200, 1400, "SUBTOTAL", 0))).isNotEqualTo(base);
        List<ExpenseCommand.ItemInput> otherName = List.of(
                new ExpenseCommand.ItemInput("Pizza!", 200L, List.of(A, B)), twoItems().get(1));
        assertThat(h(itemized(otherName, 1200, 1400, "SUBTOTAL", 0))).isNotEqualTo(base);
        List<ExpenseCommand.ItemInput> otherAssignees = List.of(
                new ExpenseCommand.ItemInput("Pizza", 200L, List.of(A)), twoItems().get(1));
        assertThat(h(itemized(otherAssignees, 1200, 1400, "SUBTOTAL", 0))).isNotEqualTo(base);
    }

    @Test
    void everyChargeParameterChangesTheHashAndServiceOffDiffersFromZeroPercent() {
        String base = h(itemized(twoItems(), 1200, 1400, "SUBTOTAL", 0));
        assertThat(h(itemized(twoItems(), 1300, 1400, "SUBTOTAL", 0))).isNotEqualTo(base);
        assertThat(h(itemized(twoItems(), 1200, 1500, "SUBTOTAL", 0))).isNotEqualTo(base);
        assertThat(h(itemized(twoItems(), 1200, 1400, "SUBTOTAL_PLUS_SERVICE", 0))).isNotEqualTo(base);
        assertThat(h(itemized(twoItems(), 1200, 1400, "SUBTOTAL", -1))).isNotEqualTo(base);
        assertThat(h(itemized(twoItems(), null, 1400, "SUBTOTAL", 0)))
                .isNotEqualTo(h(itemized(twoItems(), 0, 1400, "SUBTOTAL", 0)));
    }

    // ---- BSA2 (A175): new fields are hashed only when not default ------------------------------------------------

    private static ExpenseCommand legacyCommand(List<ExpenseCommand.ItemInput> items) {
        return new ExpenseCommand("Dinner", LocalDate.of(2026, 10, 18), "ITEMIZED", null,
                List.of(new PayerInput(A, 100L)), null, null, items, new ExpenseCommand.ServiceInput(1200),
                new ExpenseCommand.TaxInput(1400, "SUBTOTAL"), 0L);
    }

    /** The pre-BSA2 canonical form of an itemized request, copied from the hasher before BSA2. */
    private static String preBsa2Hash(ExpenseValidator.Valid v) throws Exception {
        java.util.Map<String, Object> canonical = new java.util.LinkedHashMap<>();
        canonical.put("endpoint", ENDPOINT);
        canonical.put("groupId", GROUP.toString());
        canonical.put("title", v.title());
        canonical.put("expenseDate", v.expenseDate().toString());
        canonical.put("splitType", v.splitType());
        canonical.put("totalMinor", v.totalMinor());
        canonical.put("payers", v.payers().stream().map(p -> {
            java.util.Map<String, Object> m = new java.util.LinkedHashMap<>();
            m.put("memberId", p.memberId().toString());
            m.put("amountMinor", p.amountMinor());
            return m;
        }).toList());
        canonical.put("participantMemberIds", null);
        canonical.put("shares", null);
        canonical.put("items", v.items().stream().map(i -> {
            java.util.Map<String, Object> m = new java.util.LinkedHashMap<>();
            m.put("name", i.name());
            m.put("amountMinor", i.amountMinor());
            m.put("assigneeMemberIds", i.assigneeMemberIds().stream().map(UUID::toString).sorted().toList());
            return m;
        }).toList());
        canonical.put("serviceBps", v.serviceBps());
        canonical.put("taxBps", v.taxBps());
        canonical.put("taxBase", v.taxBase());
        canonical.put("adjustmentMinor", v.adjustmentMinor());
        byte[] json = new ObjectMapper().writeValueAsString(canonical).getBytes(java.nio.charset.StandardCharsets.UTF_8);
        return java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(json));
    }

    @Test
    void aPreBsa2ItemizedRequestKeepsItsHash() throws Exception {
        ExpenseValidator.Valid v = ExpenseValidator.validate(legacyCommand(twoItems()));
        assertThat(h(v)).isEqualTo(preBsa2Hash(v));
    }

    @Test
    void aUnitPriceWithQuantityOneIsTheSameRequestAsTheLegacyAmount() {
        List<ExpenseCommand.ItemInput> unitShaped = List.of(
                new ExpenseCommand.ItemInput("Pizza", null, 200L, 1, List.of(A, B)),
                new ExpenseCommand.ItemInput("Pasta", null, 150L, null, List.of(C)));
        assertThat(h(ExpenseValidator.validate(legacyCommand(unitShaped))))
                .isEqualTo(h(ExpenseValidator.validate(legacyCommand(twoItems()))));
    }

    @Test
    void quantityDiscountAndAmountChargesChangeTheHash() {
        String base = h(ExpenseValidator.validate(legacyCommand(twoItems())));
        List<ExpenseCommand.ItemInput> twoPizzas = List.of(
                new ExpenseCommand.ItemInput("Pizza", null, 100L, 2, List.of(A, B)), twoItems().get(1));
        assertThat(h(ExpenseValidator.validate(legacyCommand(twoPizzas)))).isNotEqualTo(base);  // same line amount

        ExpenseCommand c = legacyCommand(twoItems());
        ExpenseCommand discounted = new ExpenseCommand(c.title(), c.expenseDate(), c.splitType(), null, c.payers(), null,
                null, c.items(), c.service(), c.tax(), 0L, null, null, new ExpenseCommand.DiscountInput(1000, null));
        ExpenseCommand discountAmount = new ExpenseCommand(c.title(), c.expenseDate(), c.splitType(), null, c.payers(),
                null, null, c.items(), c.service(), c.tax(), 0L, null, null, new ExpenseCommand.DiscountInput(null, 1000L));
        ExpenseCommand serviceAmount = new ExpenseCommand(c.title(), c.expenseDate(), c.splitType(), null, c.payers(),
                null, null, c.items(), new ExpenseCommand.ServiceInput(null, 1200L), c.tax(), 0L);
        ExpenseCommand taxAmount = new ExpenseCommand(c.title(), c.expenseDate(), c.splitType(), null, c.payers(),
                null, null, c.items(), c.service(), new ExpenseCommand.TaxInput(null, 1400L, "SUBTOTAL"), 0L);
        java.util.Set<String> hashes = new java.util.HashSet<>(List.of(base,
                h(ExpenseValidator.validate(discounted)), h(ExpenseValidator.validate(discountAmount)),
                h(ExpenseValidator.validate(serviceAmount)), h(ExpenseValidator.validate(taxAmount))));
        assertThat(hashes).hasSize(5);
    }

    @Test
    void amountsAreNotConfusedAcrossMembers() {
        // swapping which member holds which amount is a different request even though the multiset is equal
        List<PayerInput> one = List.of(new PayerInput(A, 1L), new PayerInput(B, 2L));
        List<PayerInput> two = List.of(new PayerInput(A, 2L), new PayerInput(B, 1L));
        assertThat(h(equal("D", 3, one, null))).isNotEqualTo(h(equal("D", 3, two, null)));
    }

    // ---- SHARES (BSA3, A189) ----

    private static ExpenseValidator.Valid sharesValid(LocalDate from, LocalDate to,
            ExpenseCommand.ShareParticipantInput... participants) {
        return ExpenseValidator.validate(new ExpenseCommand("Rent", LocalDate.of(2026, 12, 1), "SHARES", 900000L,
                List.of(new PayerInput(A, 900000L)), null, null, null, null, null, null, null, null, null, null,
                List.of(participants), from, to));
    }

    private static ExpenseCommand.ShareParticipantInput sp(UUID id, int units, LocalDate from, LocalDate to) {
        return new ExpenseCommand.ShareParticipantInput(id, units, from, to);
    }

    @Test
    void sharesParticipantOrderAndANormalizedPresenceDoNotChangeTheHash() {
        LocalDate nov1 = LocalDate.of(2026, 11, 1);
        LocalDate nov30 = LocalDate.of(2026, 11, 30);
        String base = h(sharesValid(nov1, nov30, sp(A, 2, null, null), sp(B, 1, LocalDate.of(2026, 11, 12), null)));
        assertThat(h(sharesValid(nov1, nov30, sp(B, 1, LocalDate.of(2026, 11, 12), nov30), sp(A, 2, nov1, nov30))))
                .isEqualTo(base);
    }

    @Test
    void sharesUnitsPresenceAndPeriodChangeTheHash() {
        LocalDate nov1 = LocalDate.of(2026, 11, 1);
        LocalDate nov30 = LocalDate.of(2026, 11, 30);
        String base = h(sharesValid(nov1, nov30, sp(A, 2, null, null), sp(B, 1, null, null)));
        assertThat(java.util.Set.of(base,
                h(sharesValid(nov1, nov30, sp(A, 3, null, null), sp(B, 1, null, null))),
                h(sharesValid(nov1, nov30, sp(A, 2, null, null), sp(B, 1, LocalDate.of(2026, 11, 2), null))),
                h(sharesValid(nov1, LocalDate.of(2026, 11, 29), sp(A, 2, null, null), sp(B, 1, null, null))),
                h(sharesValid(null, null, sp(A, 2, null, null), sp(B, 1, null, null))),
                h(sharesValid(nov1, nov30, sp(A, 2, null, null), sp(C, 1, null, null))))).hasSize(6);
    }
}
