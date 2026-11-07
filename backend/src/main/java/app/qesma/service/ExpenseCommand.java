package app.qesma.service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * The create/preview-expense request body (spec 8.4). Wrapper types so a missing field is detected and reported
 * as a validation error rather than silently becoming 0. Bound directly from JSON; it has no fields a client
 * could use to set ids, owner, version or derived amounts.
 *
 * @param splitType            EQUAL, EXACT or ITEMIZED
 * @param totalMinor           required for EQUAL/EXACT; for ITEMIZED optional (the engine computes it) and, when
 *                             given, must equal the computed total
 * @param participantMemberIds EQUAL only; null means "all current members" (resolved and stored explicitly)
 * @param shares               EXACT only
 * @param items                ITEMIZED only
 * @param service              ITEMIZED only; absent = no service charge
 * @param tax                  ITEMIZED only; absent = no tax
 * @param adjustmentMinor      ITEMIZED only; signed, absent = 0
 */
public record ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                             List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares,
                             List<ItemInput> items, ServiceInput service, TaxInput tax, Long adjustmentMinor) {

    /** EQUAL/EXACT shape (no itemized fields). */
    public ExpenseCommand(String title, LocalDate expenseDate, String splitType, Long totalMinor,
                          List<PayerInput> payers, List<UUID> participantMemberIds, List<ShareInput> shares) {
        this(title, expenseDate, splitType, totalMinor, payers, participantMemberIds, shares, null, null, null, null);
    }

    public record PayerInput(UUID memberId, Long amountMinor) {
    }

    public record ShareInput(UUID memberId, Long amountMinor) {
    }

    public record ItemInput(String name, Long amountMinor, List<UUID> assigneeMemberIds) {
    }

    public record ServiceInput(Integer bps) {
    }

    /** {@code base} is SUBTOTAL or SUBTOTAL_PLUS_SERVICE; null means SUBTOTAL_PLUS_SERVICE (Decision A1). */
    public record TaxInput(Integer bps, String base) {
    }
}
