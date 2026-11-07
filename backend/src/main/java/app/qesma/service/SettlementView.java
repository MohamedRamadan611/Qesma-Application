package app.qesma.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** A settlement as returned by the API. {@code fromMemberId} paid {@code toMemberId}. */
public record SettlementView(UUID id, UUID groupId, UUID fromMemberId, UUID toMemberId, long amountMinor,
                             LocalDate settledOn, String note, Instant createdAt) {
}
