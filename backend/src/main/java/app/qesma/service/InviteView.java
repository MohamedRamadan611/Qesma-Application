package app.qesma.service;

import java.time.Instant;
import java.util.UUID;

/**
 * An invitation as an admin sees it. {@code code} is the secret (8 characters, shown XXXX-XXXX by clients) and
 * {@code link} carries the same code. {@code status} is ACTIVE, EXPIRED, EXHAUSTED or REVOKED, computed on read.
 */
public record InviteView(UUID id, UUID groupId, String code, String link, Instant createdAt, Instant expiresAt,
                         Integer maxUses, int useCount, boolean requiresApproval, Instant revokedAt, String status) {
}
