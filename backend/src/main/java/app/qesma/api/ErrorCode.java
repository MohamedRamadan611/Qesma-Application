package app.qesma.api;

import java.net.URI;
import java.util.Locale;

/**
 * Stable machine-readable error codes (spec 8.5). Add codes here as milestones need them.
 * INTERNAL_ERROR, RATE_LIMITED, AUTH_PROVIDER_UNAVAILABLE and OWNER_MEMBER_PROTECTED are additions beyond spec 8.5
 * (see Decision Log A15); USERNAME_TAKEN comes with username + password sign-in (ADR-007, ADR-008).
 */
public enum ErrorCode {
    VALIDATION_ERROR,
    PAYERS_TOTAL_MISMATCH,
    SPLIT_TOTAL_MISMATCH,
    MEMBER_NOT_IN_GROUP,
    IDEMPOTENCY_KEY_REUSED,
    DUPLICATE_MEMBER_NAME,
    MEMBER_HAS_TRANSACTIONS,
    OWNER_MEMBER_PROTECTED,
    VERSION_CONFLICT,
    /** The invite is past its expiry or used up (410, Phase 2 B11). */
    INVITE_EXPIRED,
    /** The invite was revoked by an admin (410). */
    INVITE_REVOKED,
    /** The caller already has a member in the group (409). */
    ALREADY_MEMBER,
    /** The member was claimed by somebody else meanwhile (409). */
    MEMBER_ALREADY_CLAIMED,
    /** A LEFT member cannot be used in a new expense or settlement (422, Phase 2 B12). */
    MEMBER_INACTIVE,
    /** The owner cannot leave; ownership must be transferred first (409, B12). */
    OWNER_MUST_TRANSFER,
    GROUP_NOT_EMPTY,
    NOT_FOUND,
    /** A member of the group lacks the role permission for this action (Phase 2, Decision A65). */
    FORBIDDEN,
    /** A settlement action is not allowed from its current state (409, Phase 2 B13). */
    INVALID_STATE_TRANSITION,
    UNAUTHORIZED,
    INTERNAL_ERROR,
    RATE_LIMITED,
    AUTH_PROVIDER_UNAVAILABLE,
    USERNAME_TAKEN;

    /** RFC 7807 {@code type} URI for this code. */
    public URI type() {
        return URI.create("https://qesma.app/problems/" + name().toLowerCase(Locale.ROOT).replace('_', '-'));
    }
}
