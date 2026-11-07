package app.qesma.engine;

/** A payer of an expense, in minor units (spec 7.5). */
public record Payer(String memberId, long amountMinor) {
}
