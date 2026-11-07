package app.qesma.service;

import app.qesma.api.ApiException;
import java.time.LocalDate;
import java.util.UUID;

/** Shape validation of a create-settlement request (no database). Membership of the group is checked by the service. */
final class SettlementValidator {

    static final int MAX_NOTE = 200;

    /** A request that passed validation; the note is trimmed and blank becomes null. */
    record Valid(UUID fromMemberId, UUID toMemberId, long amountMinor, LocalDate settledOn, String note) {
    }

    private SettlementValidator() {
    }

    static Valid validate(SettlementCommand c) {
        if (c == null) {
            throw ApiException.validation("Request body is required");
        }
        if (c.fromMemberId() == null || c.toMemberId() == null) {
            throw ApiException.validation("fromMemberId and toMemberId are required");
        }
        if (c.fromMemberId().equals(c.toMemberId())) {
            throw ApiException.validation("A settlement needs two different members");
        }
        if (c.amountMinor() == null || c.amountMinor() <= 0) {
            throw ApiException.validation("amountMinor must be greater than zero");
        }
        ExpenseValidator.capped(c.amountMinor(), "amountMinor");
        LocalDate date = c.settledOn();
        if (date == null) {
            throw ApiException.validation("settledOn is required");
        }
        if (date.isBefore(ExpenseValidator.MIN_DATE) || date.isAfter(ExpenseValidator.MAX_DATE)) {
            throw ApiException.validation("settledOn must be between " + ExpenseValidator.MIN_DATE + " and "
                    + ExpenseValidator.MAX_DATE);
        }
        String note = c.note() == null || c.note().isBlank() ? null : FieldRules.name(c.note(), MAX_NOTE, "note");
        return new Valid(c.fromMemberId(), c.toMemberId(), c.amountMinor(), date, note);
    }
}
