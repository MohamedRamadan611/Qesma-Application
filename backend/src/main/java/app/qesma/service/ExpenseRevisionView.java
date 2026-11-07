package app.qesma.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Instant;
import java.util.UUID;

/**
 * One entry of an expense's history (spec 7.9). {@code snapshot} is the complete expense as it looked right after
 * the change: the same JSON the API returns for the expense itself (header, payers, shares, items, charges).
 */
public record ExpenseRevisionView(int version, String changeType, Instant changedAt, UUID changedByUserId,
                                  JsonNode snapshot) {
}
