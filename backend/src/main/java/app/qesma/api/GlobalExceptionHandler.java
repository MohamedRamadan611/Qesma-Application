package app.qesma.api;

import app.qesma.security.RequestSizeLimitFilter;
import jakarta.persistence.OptimisticLockException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.NestedExceptionUtils;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * Turns every failure into RFC 7807 problem+json with a stable {@code code}.
 * Never leaks stack traces or exception messages of unexpected errors.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        ProblemDetail body = problem(HttpStatus.UNPROCESSABLE_ENTITY, ErrorCode.VALIDATION_ERROR,
                "Validation failed");
        return handleExceptionInternal(ex, body, headers, HttpStatus.UNPROCESSABLE_ENTITY, request);
    }

    /** A body that outgrew the size limit while being read (no declared length) is 413, not a generic 400. */
    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        for (Throwable t = ex; t != null; t = t.getCause() == t ? null : t.getCause()) {
            if (t instanceof RequestSizeLimitFilter.RequestTooLargeException) {
                ProblemDetail body = problem(HttpStatus.PAYLOAD_TOO_LARGE, ErrorCode.VALIDATION_ERROR,
                        "Request body is too large");
                return handleExceptionInternal(ex, body, headers, HttpStatus.PAYLOAD_TOO_LARGE, request);
            }
        }
        return super.handleHttpMessageNotReadable(ex, headers, status, request);
    }

    @Override
    protected ResponseEntity<Object> handleNoResourceFoundException(NoResourceFoundException ex,
            HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        ProblemDetail body = problem(HttpStatus.NOT_FOUND, ErrorCode.NOT_FOUND, "Resource not found");
        return handleExceptionInternal(ex, body, headers, HttpStatus.NOT_FOUND, request);
    }

    /** Fallback for other framework exceptions: keep the status, add a code and request id. */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(Exception ex, Object body,
            HttpHeaders headers, HttpStatusCode statusCode, WebRequest request) {
        if (body instanceof ProblemDetail pd) {
            if (pd.getProperties() == null || !pd.getProperties().containsKey("code")) {
                pd.setProperty("code", statusCode.value() == 404
                        ? ErrorCode.NOT_FOUND.name() : ErrorCode.VALIDATION_ERROR.name());
            }
            if (pd.getProperties() == null || !pd.getProperties().containsKey("requestId")) {
                pd.setProperty("requestId", MDC.get(RequestIdFilter.MDC_KEY));
            }
        }
        return super.handleExceptionInternal(ex, body, headers, statusCode, request);
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ProblemDetail> handleApi(ApiException ex) {
        return respond(problem(ex.status(), ex.code(), ex.getMessage()));
    }

    /** Lost an optimistic-locking race (JPA @Version): the same answer as a stale If-Match. */
    @ExceptionHandler({ObjectOptimisticLockingFailureException.class, OptimisticLockException.class})
    public ResponseEntity<ProblemDetail> handleOptimisticLock(Exception ex) {
        return respond(problem(HttpStatus.CONFLICT, ErrorCode.VERSION_CONFLICT,
                "The resource was modified by someone else"));
    }

    /**
     * Database constraints are the last line of defense. Only violations we can name safely are translated;
     * anything else is an unexpected server error and is logged without being echoed to the client.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ProblemDetail> handleIntegrity(DataIntegrityViolationException ex) {
        String detail = String.valueOf(NestedExceptionUtils.getMostSpecificCause(ex).getMessage());
        if (detail.contains("ux_members_group_name")) {
            return respond(problem(HttpStatus.CONFLICT, ErrorCode.DUPLICATE_MEMBER_NAME,
                    "A member with this name already exists in the group"));
        }
        return handleUnexpected(ex);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ProblemDetail> handleUnexpected(Exception ex) {
        // Full detail goes to the server log only (requestId is in the MDC).
        log.error("Unhandled exception", ex);
        return respond(problem(HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_ERROR,
                "An unexpected error occurred"));
    }

    private static ResponseEntity<ProblemDetail> respond(ProblemDetail pd) {
        return ResponseEntity.status(pd.getStatus()).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(pd);
    }

    static ProblemDetail problem(HttpStatus status, ErrorCode code, String title) {
        ProblemDetail pd = ProblemDetail.forStatus(status);
        pd.setTitle(title);
        pd.setType(code.type());
        pd.setProperty("code", code.name());
        pd.setProperty("requestId", MDC.get(RequestIdFilter.MDC_KEY));
        return pd;
    }
}
