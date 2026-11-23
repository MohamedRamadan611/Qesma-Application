package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
import app.qesma.engine.ItemizedCalculator.ChargeSpec;
import app.qesma.engine.ItemizedCalculator.Item;
import app.qesma.engine.ItemizedCalculator.ItemizedInput;
import app.qesma.engine.ItemizedCalculator.ItemizedResult;
import app.qesma.engine.ItemizedCalculator.MemberBreakdown;
import app.qesma.engine.ItemizedCalculator.TaxBase;
import app.qesma.engine.ItemizedCalculator.TaxSpec;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;

/**
 * Runs every shared vector in /fixtures/engine (spec section 10, V1-V8; STANDALONE_SPEC 18.6, V9-V16). Format:
 * { name, input: { members, expenses[], settlements[] }, expected: { expenses[], nets, transfers } }.
 * Only the keys present under "expected" are asserted, so a future Dart engine can reuse the files.
 */
class FixtureTest {

    private static final Path DIR = Path.of("..", "fixtures", "engine");
    private static final ObjectMapper JSON = new ObjectMapper();

    @Test
    void allSpecVectorsArePresent() throws IOException {
        List<String> names;
        try (Stream<Path> s = Files.list(DIR)) {
            names = s.map(p -> p.getFileName().toString()).filter(n -> n.endsWith(".json")).toList();
        }
        assertThat(names).hasSizeGreaterThanOrEqualTo(28);
        for (int v = 1; v <= 28; v++) {
            String prefix = "V" + v + "-";
            assertThat(names).as("vector %s", prefix).anyMatch(n -> n.startsWith(prefix));
        }
    }

    @TestFactory
    List<DynamicTest> everyFixtureProducesItsExpectedNumbers() throws IOException {
        List<Path> files;
        try (Stream<Path> s = Files.list(DIR)) {
            files = s.filter(p -> p.toString().endsWith(".json")).sorted().toList();
        }
        List<DynamicTest> tests = new ArrayList<>();
        for (Path file : files) {
            tests.add(DynamicTest.dynamicTest(file.getFileName().toString(), () -> run(JSON.readTree(file.toFile()))));
        }
        return tests;
    }

    private static void run(JsonNode fixture) {
        JsonNode input = fixture.get("input");
        JsonNode expected = fixture.get("expected");

        List<MemberRef> members = new ArrayList<>();
        for (JsonNode m : input.get("members")) {
            members.add(new MemberRef(m.get("id").asText(), m.get("sortOrder").asInt()));
        }

        List<ExpenseLedgerEntry> ledger = new ArrayList<>();
        JsonNode expenses = input.get("expenses");
        for (int i = 0; i < expenses.size(); i++) {
            JsonNode e = expenses.get(i);
            Map<String, Long> owed = new LinkedHashMap<>();
            long total;
            ItemizedResult itemized = null;
            switch (e.get("type").asText()) {
                case "EQUAL" -> {
                    total = e.get("totalMinor").asLong();
                    List<MemberRef> participants = new ArrayList<>();
                    for (JsonNode id : e.get("participantMemberIds")) {
                        participants.add(members.stream().filter(m -> m.id().equals(id.asText())).findFirst().orElseThrow());
                    }
                    owed.putAll(SplitCalculator.equal(total, participants));
                }
                case "EXACT" -> {
                    total = e.get("totalMinor").asLong();
                    List<Share> shares = new ArrayList<>();
                    for (JsonNode s : e.get("shares")) {
                        shares.add(new Share(s.get("memberId").asText(), s.get("amountMinor").asLong()));
                    }
                    owed.putAll(SplitCalculator.exact(total, shares));
                }
                case "ITEMIZED" -> {
                    JsonNode rejected = expected.path("expenses").path(i);
                    if (rejected.has("error")) {
                        // A rejected bill: the engine (input shape included) must refuse it with this code.
                        int index = i;
                        assertThatThrownBy(() -> ItemizedCalculator.calculate(itemizedInput(e, members)))
                                .as("expense %d", index).isInstanceOf(EngineException.class)
                                .extracting("code").isEqualTo(EngineErrorCode.valueOf(rejected.get("error").asText()));
                        continue;
                    }
                    itemized = ItemizedCalculator.calculate(itemizedInput(e, members));
                    total = itemized.totalMinor();
                    for (MemberBreakdown b : itemized.members()) {
                        owed.put(b.memberId(), b.owedMinor());
                    }
                }
                case "SHARES" -> {
                    total = e.get("totalMinor").asLong();
                    JsonNode rejected = expected.path("expenses").path(i);
                    if (rejected.has("error")) {
                        int index = i;
                        assertThatThrownBy(() -> SplitCalculator.shares(total, weightedShares(e, members), period(e)))
                                .as("expense %d", index).isInstanceOf(EngineException.class)
                                .extracting("code").isEqualTo(EngineErrorCode.valueOf(rejected.get("error").asText()));
                        continue;
                    }
                    owed.putAll(SplitCalculator.shares(total, weightedShares(e, members), period(e)));
                }
                default -> throw new IllegalArgumentException("unknown expense type " + e.get("type"));
            }

            List<Payer> payers = new ArrayList<>();
            for (JsonNode p : e.get("payers")) {
                payers.add(new Payer(p.get("memberId").asText(), p.get("amountMinor").asLong()));
            }
            PayerValidator.validate(total, payers);
            ledger.add(new ExpenseLedgerEntry(payers, owed));

            if (expected.has("expenses")) {
                JsonNode exp = expected.get("expenses").get(i);
                if (exp.has("owed")) {
                    assertThat(owed).as("expense %d owed", i).isEqualTo(longMap(exp.get("owed")));
                }
                if (exp.has("totalMinor")) {
                    assertThat(total).as("expense %d total", i).isEqualTo(exp.get("totalMinor").asLong());
                }
                if (itemized != null) {
                    assertField(exp, "subtotalMinor", itemized.subtotalMinor());
                    assertField(exp, "serviceMinor", itemized.serviceMinor());
                    assertField(exp, "taxMinor", itemized.taxMinor());
                    assertField(exp, "discountMinor", itemized.discountMinor());
                    assertField(exp, "deliveryMinor", itemized.deliveryMinor());
                    if (exp.has("deliveries")) {
                        Map<String, Long> deliveries = new LinkedHashMap<>();
                        itemized.members().forEach(b -> deliveries.put(b.memberId(), b.deliveryMinor()));
                        assertThat(deliveries).as("expense %d deliveries", i).isEqualTo(longMap(exp.get("deliveries")));
                    }
                    if (exp.has("discounts")) {
                        Map<String, Long> discounts = new LinkedHashMap<>();
                        itemized.members().forEach(b -> discounts.put(b.memberId(), b.discountMinor()));
                        assertThat(discounts).as("expense %d discounts", i).isEqualTo(longMap(exp.get("discounts")));
                    }
                }
            }
        }

        List<SettlementEntry> settlements = new ArrayList<>();
        if (input.has("settlements")) {
            for (JsonNode s : input.get("settlements")) {
                settlements.add(new SettlementEntry(s.get("fromMemberId").asText(), s.get("toMemberId").asText(),
                        s.get("amountMinor").asLong()));
            }
        }

        Map<String, Long> nets = BalanceCalculator.nets(members, ledger, settlements);
        if (expected.has("nets")) {
            assertThat(nets).as("nets").isEqualTo(longMap(expected.get("nets")));
        }
        if (expected.has("transfers")) {
            List<Transfer> exp = new ArrayList<>();
            for (JsonNode t : expected.get("transfers")) {
                exp.add(new Transfer(t.get("fromMemberId").asText(), t.get("toMemberId").asText(),
                        t.get("amountMinor").asLong()));
            }
            assertThat(Simplifier.simplify(nets, members)).as("transfers").containsExactlyElementsOf(exp);
        }
    }

    /**
     * Maps a fixture bill to the engine input through the engine's own shape rules ({@link Item#of},
     * {@link ChargeSpec#of}), so a rejected shape (V16) fails exactly as it does behind the API.
     * Legacy {@code serviceBps} is still read; {@code service}/{@code tax}/{@code discount} take bps or amountMinor.
     */
    private static ItemizedInput itemizedInput(JsonNode e, List<MemberRef> members) {
        List<Item> items = new ArrayList<>();
        for (JsonNode it : e.get("items")) {
            List<String> assignees = new ArrayList<>();
            it.get("assigneeMemberIds").forEach(a -> assignees.add(a.asText()));
            items.add(Item.of(it.get("name").asText(), longOrNull(it, "amountMinor"),
                    longOrNull(it, "unitAmountMinor"), intOrNull(it, "quantity"), assignees));
        }
        ChargeSpec service = null;
        if (e.hasNonNull("serviceBps")) {
            service = ChargeSpec.percent(e.get("serviceBps").asInt());
        } else if (e.hasNonNull("service")) {
            service = charge(e.get("service"));
        }
        TaxSpec tax = null;
        if (e.hasNonNull("tax")) {
            JsonNode t = e.get("tax");
            tax = new TaxSpec(charge(t), t.hasNonNull("base") ? TaxBase.valueOf(t.get("base").asText()) : null);
        }
        ChargeSpec discount = e.hasNonNull("discount") ? charge(e.get("discount")) : null;
        return new ItemizedInput(members, items, discount, service, tax, e.path("adjustmentMinor").asLong(0),
                e.path("deliveryMinor").asLong(0));
    }

    /** SHARES participants (STANDALONE_SPEC 19, V21-V28); the sortOrder comes from {@code members}. */
    private static List<WeightedShare> weightedShares(JsonNode e, List<MemberRef> members) {
        List<WeightedShare> shares = new ArrayList<>();
        for (JsonNode p : e.get("shareParticipants")) {
            String id = p.get("memberId").asText();
            int sortOrder = members.stream().filter(m -> m.id().equals(id)).findFirst().orElseThrow().sortOrder();
            shares.add(new WeightedShare(id, sortOrder, p.get("shareUnits").asInt(), dateOrNull(p, "presentFrom"),
                    dateOrNull(p, "presentTo")));
        }
        return shares;
    }

    /** Both bounds, one bound (rejected by the engine) or none. */
    private static SharePeriod period(JsonNode e) {
        LocalDate from = dateOrNull(e, "periodFrom");
        LocalDate to = dateOrNull(e, "periodTo");
        return from == null && to == null ? null : new SharePeriod(from, to);
    }

    private static LocalDate dateOrNull(JsonNode node, String field) {
        return node.hasNonNull(field) ? LocalDate.parse(node.get(field).asText()) : null;
    }

    private static ChargeSpec charge(JsonNode node) {
        return ChargeSpec.of(intOrNull(node, "bps"), longOrNull(node, "amountMinor"));
    }

    private static Long longOrNull(JsonNode node, String field) {
        return node.hasNonNull(field) ? node.get(field).asLong() : null;
    }

    private static Integer intOrNull(JsonNode node, String field) {
        return node.hasNonNull(field) ? node.get(field).asInt() : null;
    }

    private static void assertField(JsonNode exp, String field, long actual) {
        if (exp.has(field)) {
            assertThat(actual).as(field).isEqualTo(exp.get(field).asLong());
        }
    }

    private static Map<String, Long> longMap(JsonNode node) {
        Map<String, Long> map = new LinkedHashMap<>();
        node.fields().forEachRemaining(f -> map.put(f.getKey(), f.getValue().asLong()));
        return map;
    }
}
