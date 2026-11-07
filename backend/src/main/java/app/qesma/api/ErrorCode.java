package app.qesma.api;

import java.net.URI;
import java.util.Locale;

/**
 * Stable machine-readable error codes (spec 8.5). Add codes here as milestones need them.
 * INTERNAL_ERROR, RATE_LIMITED and AUTH_PROVIDER_UNAVAILABLE are additions beyond spec 8.5
 * (see Decision Log A15).
 */
public enum ErrorCode {
    VALIDATION_ERROR,
    PAYERS_TOTAL_MISMATCH,
    SPLIT_TOTAL_MISMATCH,
    MEMBER_NOT_IN_GROUP,
    IDEMPOTENCY_KEY_REUSED,
    DUPLICATE_MEMBER_NAME,
    MEMBER_HAS_TRANSACTIONS,
    VERSION_CONFLICT,
    GROUP_NOT_EMPTY,
    NOT_FOUND,
    UNAUTHORIZED,
    INTERNAL_ERROR,
    RATE_LIMITED,
    AUTH_PROVIDER_UNAVAILABLE;

    /** RFC 7807 {@code type} URI for this code. */
    public URI type() {
        return URI.create("https://qesma.app/problems/" + name().toLowerCase(Locale.ROOT).replace('_', '-'));
    }
}
