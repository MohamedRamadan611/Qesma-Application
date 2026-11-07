package app.qesma.engine;

/** One explicit share of an EXACT split, in minor units (spec 7.3). */
public record Share(String memberId, long amountMinor) {
}
