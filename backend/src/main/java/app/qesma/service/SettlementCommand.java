package app.qesma.service;

import java.time.LocalDate;
import java.util.UUID;

/** Create-settlement request body (spec 8.2). Wrapper types so a missing field is a validation error, not 0. */
public record SettlementCommand(UUID fromMemberId, UUID toMemberId, Long amountMinor, LocalDate settledOn,
                                String note, String kind) {

    /** A plain payment (kind PAYMENT). */
    public SettlementCommand(UUID fromMemberId, UUID toMemberId, Long amountMinor, LocalDate settledOn, String note) {
        this(fromMemberId, toMemberId, amountMinor, settledOn, note, null);
    }
}
