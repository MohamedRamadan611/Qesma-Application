package app.qesma.service;

import java.time.Instant;
import java.util.UUID;

/**
 * A join request as an admin sees it. The requester is shown by display name only (never an account id); exactly one
 * of {@code claimMemberId}/{@code newMemberName} is set.
 */
public record JoinRequestView(UUID id, String status, String requesterName, UUID claimMemberId,
                              String claimMemberName, String newMemberName, Instant createdAt, Instant decidedAt) {
}
