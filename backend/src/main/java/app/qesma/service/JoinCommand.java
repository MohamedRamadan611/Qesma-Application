package app.qesma.service;

import java.util.UUID;

/** Body of "join": exactly one of {@code claimMemberId} (I am this existing member) or {@code newMemberName}. */
public record JoinCommand(UUID claimMemberId, String newMemberName) {
}
