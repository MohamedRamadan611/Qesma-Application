package app.qesma.engine;

/** A suggested real-world payment {@code from -> to} produced by simplification (spec 7.7). */
public record Transfer(String fromMemberId, String toMemberId, long amountMinor) {
}
