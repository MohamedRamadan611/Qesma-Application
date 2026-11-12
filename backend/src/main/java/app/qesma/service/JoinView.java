package app.qesma.service;

import java.util.UUID;

/**
 * Answer of "join": status JOINED (with the member) or PENDING_APPROVAL (with the request id). The client refetches the
 * group afterwards; nothing else about the group is returned here.
 */
public record JoinView(String status, UUID groupId, JoinedMember member, UUID requestId) {

    /** The member the caller now is. */
    public record JoinedMember(UUID id, String displayName, String role) {
    }
}
