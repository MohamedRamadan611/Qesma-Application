package app.qesma.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * What someone who holds an invite code may see before joining. Deliberately small: no balances, no expense counts,
 * no accounts and no ids of other users (a person who is not a member yet must not learn the group's money).
 * {@code callerState} is NONE, PENDING_APPROVAL or ALREADY_MEMBER.
 */
public record InvitePreview(String groupName, String groupType, String inviterName, long memberCount,
                            List<Unclaimed> unclaimedMembers, boolean requiresApproval, Instant expiresAt,
                            String callerState) {

    /** A member nobody has claimed yet: the "who are you?" list. */
    public record Unclaimed(UUID id, String name) {
    }
}
