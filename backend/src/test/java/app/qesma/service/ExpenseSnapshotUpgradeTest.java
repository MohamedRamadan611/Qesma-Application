package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

/** A180: a revision stored before V22 has no delivery and reads back as delivery 0 (history is never rewritten). */
class ExpenseSnapshotUpgradeTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Test
    void anItemizedSnapshotWithoutDeliveryReadsBackAsZero() throws Exception {
        JsonNode old = MAPPER.readTree("""
                {"shares":[{"memberId":"a","owedMinor":100,"itemsMinor":100,"discountMinor":0,"serviceMinor":0,
                            "taxMinor":0,"adjustmentMinor":0}],
                 "charges":{"subtotalMinor":100,"discount":null,"service":null,"tax":null,"adjustmentMinor":0}}""");

        JsonNode upgraded = ExpenseService.upgradeSnapshot(old);

        assertThat(upgraded.get("shares").get(0).get("deliveryMinor").asLong()).isZero();
        assertThat(upgraded.get("charges").get("deliveryMinor").asLong()).isZero();
    }

    @Test
    void anEqualSnapshotKeepsNullDeliveryAndANewSnapshotIsUntouched() throws Exception {
        JsonNode equal = ExpenseService.upgradeSnapshot(MAPPER.readTree("""
                {"shares":[{"memberId":"a","owedMinor":100}],"charges":null}"""));
        assertThat(equal.get("shares").get(0).get("deliveryMinor").isNull()).isTrue();

        JsonNode current = ExpenseService.upgradeSnapshot(MAPPER.readTree("""
                {"shares":[{"memberId":"a","owedMinor":150,"itemsMinor":100,"discountMinor":0,"serviceMinor":0,
                            "taxMinor":0,"adjustmentMinor":0,"deliveryMinor":50}],
                 "charges":{"subtotalMinor":100,"discount":null,"adjustmentMinor":0,"deliveryMinor":50}}"""));
        assertThat(current.get("shares").get(0).get("deliveryMinor").asLong()).isEqualTo(50);
        assertThat(current.get("charges").get("deliveryMinor").asLong()).isEqualTo(50);
    }

    @Test
    void aPreBsa3SnapshotReadsBackWithNullSharesFieldsAndASharesSnapshotIsUntouched() throws Exception {
        JsonNode old = ExpenseService.upgradeSnapshot(MAPPER.readTree("""
                {"splitType":"EQUAL","shares":[{"memberId":"a","owedMinor":100}],"charges":null}"""));
        assertThat(old.get("periodFrom").isNull()).isTrue();
        assertThat(old.get("periodTo").isNull()).isTrue();
        JsonNode share = old.get("shares").get(0);
        assertThat(share.get("shareUnits").isNull()).isTrue();
        assertThat(share.get("presentFrom").isNull()).isTrue();
        assertThat(share.get("presentTo").isNull()).isTrue();

        JsonNode current = ExpenseService.upgradeSnapshot(MAPPER.readTree("""
                {"splitType":"SHARES","periodFrom":"2026-11-01","periodTo":"2026-11-30",
                 "shares":[{"memberId":"a","owedMinor":100,"shareUnits":2,"presentFrom":"2026-11-12",
                            "presentTo":"2026-11-30"}],"charges":null}"""));
        assertThat(current.get("periodFrom").asText()).isEqualTo("2026-11-01");
        assertThat(current.get("shares").get(0).get("shareUnits").asInt()).isEqualTo(2);
        assertThat(current.get("shares").get(0).get("presentFrom").asText()).isEqualTo("2026-11-12");
    }
}
