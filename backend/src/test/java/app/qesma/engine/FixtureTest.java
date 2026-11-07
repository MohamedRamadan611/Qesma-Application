package app.qesma.engine;

import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.engine.BalanceCalculator.ExpenseLedgerEntry;
import app.qesma.engine.BalanceCalculator.SettlementEntry;
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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;

/**
 * Runs every shared vector in /fixtures/engine (spec section 10, V1-V8). Format:
 * { name, input: { members, expenses[], settlements[] }, expected: { expenses[], nets, transfers } }.
 * Only the keys present under "expected" are asserted, so a future Dart engine can reuse the files.
 */
class FixtureTest {

    private static final Path DIR = Path.of("..", "fixtures", "engine");
    private static final ObjectMapper JSON = new ObjectMapper();

    @Test
    void allEightSpecVectorsArePresent() throws IOException {
        try (Stream<Path> s = Files.list(DIR)) {
            assertThat(s.map(p -> p.getFileName().toString()).filter(n -> n.endsWith(".json")).toList())
                    .hasSizeGreaterThanOrEqualTo(8)
                    .anyMatch(n -> n.startsWith("V1-")).anyMatch(n -> n.startsWith("V2-"))
                    .anyMatch(n -> n.startsWith("V3-")).anyMatch(n -> n.startsWith("V4-"))
                    .anyMatch(n -> n.startsWith("V5-")).anyMatch(n -> n.startsWith("V6-"))
                    .anyMatch(n -> n.startsWith("V7-")).anyMatch(n -> n.startsWith("V8-"));
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
                    List<Item> items = new ArrayList<>();
                    for (JsonNode it : e.get("items")) {
                        List<String> assignees = new ArrayList<>();
                        it.get("assigneeMemberIds").forEach(a -> assignees.add(a.asText()));
                        items.add(new Item(it.get("name").asText(), it.get("amountMinor").asLong(), assignees));
                    }
                    Integer serviceBps = e.hasNonNull("serviceBps") ? e.get("serviceBps").asInt() : null;
                    TaxSpec tax = null;
                    if (e.hasNonNull("tax")) {
                        JsonNode t = e.get("tax");
                        tax = new TaxSpec(t.get("bps").asInt(),
                                t.hasNonNull("base") ? TaxBase.valueOf(t.get("base").asText()) : null);
                    }
                    itemized = ItemizedCalculator.calculate(new ItemizedInput(members, items, serviceBps, tax,
                            e.path("adjustmentMinor").asLong(0)));
                    total = itemized.totalMinor();
                    for (MemberBreakdown b : itemized.members()) {
                        owed.put(b.memberId(), b.owedMinor());
                    }
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
