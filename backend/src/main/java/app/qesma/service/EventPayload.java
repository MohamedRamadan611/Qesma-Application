package app.qesma.service;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.UUID;

/**
 * What an event stores and what the API returns as {@code payload} (A97): ids, a version, integer amounts (minor units)
 * and roles. There is deliberately no free-text field, so a name or a title cannot be stored by construction. Absent
 * fields are omitted; which ones are set depends on the event type.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record EventPayload(UUID expenseId, UUID settlementId, UUID memberId, UUID requestId, UUID inviteId,
                           UUID fromMemberId, UUID toMemberId, Integer version, Long totalMinor, Long amountMinor,
                           Role role, Role previousRole) {

    public static EventPayload expense(UUID expenseId, int version, Long totalMinor) {
        return new EventPayload(expenseId, null, null, null, null, null, null, version, totalMinor, null, null, null);
    }

    public static EventPayload settlement(UUID settlementId, long amountMinor, UUID fromMemberId, UUID toMemberId) {
        return new EventPayload(null, settlementId, null, null, null, fromMemberId, toMemberId, null, null,
                amountMinor, null, null);
    }

    public static EventPayload member(UUID memberId) {
        return new EventPayload(null, null, memberId, null, null, null, null, null, null, null, null, null);
    }

    public EventPayload withRequestId(UUID id) {
        return new EventPayload(expenseId, settlementId, memberId, id, inviteId, fromMemberId, toMemberId, version,
                totalMinor, amountMinor, role, previousRole);
    }

    public EventPayload withInviteId(UUID id) {
        return new EventPayload(expenseId, settlementId, memberId, requestId, id, fromMemberId, toMemberId, version,
                totalMinor, amountMinor, role, previousRole);
    }

    public EventPayload withRoles(Role newRole, Role oldRole) {
        return new EventPayload(expenseId, settlementId, memberId, requestId, inviteId, fromMemberId, toMemberId,
                version, totalMinor, amountMinor, newRole, oldRole);
    }
}
