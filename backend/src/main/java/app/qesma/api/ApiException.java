package app.qesma.api;

import org.springframework.http.HttpStatus;

/** A deliberate, client-visible failure carrying a stable {@link ErrorCode}. The message is safe to show. */
public class ApiException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final ErrorCode code;
    private final HttpStatus status;

    public ApiException(ErrorCode code, HttpStatus status, String message) {
        super(message);
        this.code = code;
        this.status = status;
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

    public static ApiException conflict(ErrorCode code, String message) {
        return new ApiException(code, HttpStatus.CONFLICT, message);
    }

    /** A required precondition header (If-Match) is missing. */
    public static ApiException preconditionRequired(String message) {
        return new ApiException(ErrorCode.VALIDATION_ERROR, HttpStatus.PRECONDITION_REQUIRED, message);
    }
}
