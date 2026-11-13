package app.qesma.api;

import java.util.Map;
import org.springframework.http.HttpStatus;

/** A deliberate, client-visible failure carrying a stable {@link ErrorCode}. The message is safe to show. */
public class ApiException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final ErrorCode code;
    private final HttpStatus status;
    private final Map<String, Object> properties;

    public ApiException(ErrorCode code, HttpStatus status, String message) {
        this(code, status, message, Map.of());
    }

    /** {@code properties}: extra problem+json members (RFC 7807 extension members), e.g. nextAllowedAt. Never personal data. */
    public ApiException(ErrorCode code, HttpStatus status, String message, Map<String, Object> properties) {
        super(message);
        this.code = code;
        this.status = status;
        this.properties = Map.copyOf(properties);
    }

    public Map<String, Object> properties() {
        return properties;
    }

    /** 429 REMIND_RATE_LIMITED; {@code nextAllowedAt} is an ISO-8601 UTC instant (B16, A108, A112). */
    public static ApiException remindRateLimited(java.time.Instant nextAllowedAt) {
        return new ApiException(ErrorCode.REMIND_RATE_LIMITED, HttpStatus.TOO_MANY_REQUESTS,
                "A reminder was sent recently; try again later", Map.of("nextAllowedAt", nextAllowedAt.toString()));
    }

    public ErrorCode code() {
        return code;
    }

    public HttpStatus status() {
        return status;
    }

    /** One generic answer for every authentication failure: never reveals which part failed. */
    public static ApiException unauthorized() {
        return new ApiException(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, "Authentication failed");
    }

    public static ApiException validation(String message) {
        return new ApiException(ErrorCode.VALIDATION_ERROR, HttpStatus.UNPROCESSABLE_ENTITY, message);
    }

    /**
     * Same answer whether the resource does not exist or belongs to someone else (IDOR defense): never 403.
     */
    public static ApiException notFound() {
        return new ApiException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, "Resource not found");
    }

    /**
     * The caller IS a member of the group (so nothing is revealed) but their role lacks the permission (Decision A65).
     * Never used for non-members: those get {@link #notFound()}.
     */
    public static ApiException forbidden() {
        return new ApiException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, "Your role does not allow this action");
    }

    /** 410: the thing existed but is no longer usable (an invite that expired, was used up or revoked). */
    public static ApiException gone(ErrorCode code, String message) {
        return new ApiException(code, HttpStatus.GONE, message);
    }

    public static ApiException tooManyRequests(String message) {
        return new ApiException(ErrorCode.RATE_LIMITED, HttpStatus.TOO_MANY_REQUESTS, message);
    }

    public static ApiException conflict(ErrorCode code, String message) {
        return new ApiException(code, HttpStatus.CONFLICT, message);
    }

    /** A required precondition header (If-Match) is missing. */
    public static ApiException preconditionRequired(String message) {
        return new ApiException(ErrorCode.VALIDATION_ERROR, HttpStatus.PRECONDITION_REQUIRED, message);
    }
}
