package app.qesma.service;

import java.util.UUID;

/** Remind request body (B16): remind {@code fromMemberId} (the debtor) of the suggested transfer to {@code toMemberId}. */
public record RemindCommand(UUID fromMemberId, UUID toMemberId) {
}
