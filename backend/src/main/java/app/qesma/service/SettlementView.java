package app.qesma.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A settlement as returned by the API. {@code fromMemberId} paid {@code toMemberId}. {@code status} is PENDING,
 * CONFIRMED, DISPUTED or CANCELLED; only CONFIRMED moves balances. {@code recordedByAdmin} is true when an Owner/Admin
 * recorded it on behalf of the two members (and for every Phase 1 payment). Timestamps of states not reached are null.
 */
public record SettlementView(UUID id, UUID groupId, UUID fromMemberId, UUID toMemberId, long amountMinor,
                             LocalDate settledOn, String note, Instant createdAt, String status,
                             boolean recordedByAdmin, UUID createdByMemberId, Instant declaredAt,
                             Instant confirmedAt, Instant disputedAt, Instant cancelledAt) {
}
