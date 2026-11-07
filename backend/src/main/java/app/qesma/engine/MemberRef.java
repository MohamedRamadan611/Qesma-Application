package app.qesma.engine;

/** A member as the engine sees it: an id and the creation-order {@code sortOrder} used for tie-breaks (spec A9). */
public record MemberRef(String id, int sortOrder) {
}
