package app.qesma.service;

import java.time.Instant;
import java.util.UUID;

/**
 * A sent reminder as returned by the API. {@code amountMinor} is the suggested transfer's amount at that moment, computed
 * by the server. {@code canRemindAt} is when the same debtor may be reminded again in this group.
 */
public record ReminderView(UUID fromMemberId, UUID toMemberId, long amountMinor, Instant remindedAt,
                           Instant canRemindAt) {
}
