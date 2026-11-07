package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.ExpenseCommand;
import app.qesma.service.ExpensePreview;
import app.qesma.service.ExpenseRevisionView;
import app.qesma.service.ExpenseService;
import app.qesma.service.ExpenseView;
import app.qesma.service.IdempotencyService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Expenses of a group (spec 8.2). Ownership is enforced inside the service via the central access component. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/expenses")
public class ExpenseController {

    static final String IDEMPOTENCY_HEADER = "Idempotency-Key";
    static final String REPLAYED_HEADER = "Idempotency-Replayed";

    private final ExpenseService expenses;
    private final CurrentUser currentUser;
    private final ObjectMapper mapper;

    public ExpenseController(ExpenseService expenses, CurrentUser currentUser, ObjectMapper mapper) {
        this.expenses = expenses;
        this.currentUser = currentUser;
        this.mapper = mapper;
    }

    /**
     * Creates an expense. {@code Idempotency-Key} (a client-generated UUID) is required. The first success
     * answers 201; the same key with the same request answers the stored response again (header
     * {@code Idempotency-Replayed: true}) and creates nothing; the same key with a different request is 422.
     */
    @PostMapping
    @Operation(summary = "Create an expense (EQUAL, EXACT or ITEMIZED)",
            description = "Idempotency-Key (UUID) is required. For ITEMIZED, totalMinor is optional: the server "
                    + "computes it and the payers must add up to it (PAYERS_TOTAL_MISMATCH otherwise).")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(examples = {
            @ExampleObject(name = "EQUAL", value = ApiExamples.EQUAL),
            @ExampleObject(name = "EXACT", value = ApiExamples.EXACT),
            @ExampleObject(name = "ITEMIZED", value = ApiExamples.ITEMIZED)}))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Created (or the stored answer of an identical earlier request: header Idempotency-Replayed: true)",
            headers = {@io.swagger.v3.oas.annotations.headers.Header(name = "ETag", description = "Version of the expense",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
                    @io.swagger.v3.oas.annotations.headers.Header(name = "Location", description = "URL of the expense",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
                    @io.swagger.v3.oas.annotations.headers.Header(name = "Idempotency-Replayed",
                    description = "true when this is the stored answer of an identical earlier request",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string"))},
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = ExpenseView.class)))
    public ResponseEntity<String> create(@PathVariable UUID gid,
                                         @RequestHeader(value = IDEMPOTENCY_HEADER, required = false) String key,
                                         @RequestBody ExpenseCommand command) {
        UUID idempotencyKey = parseKey(key);
        IdempotencyService.Outcome outcome = expenses.create(currentUser.id(), gid, idempotencyKey, command);
        ResponseEntity.BodyBuilder response = ResponseEntity.status(outcome.status())
                .contentType(MediaType.APPLICATION_JSON);
        if (outcome.replayed()) {
            response.header(REPLAYED_HEADER, "true");
        }
        com.fasterxml.jackson.databind.JsonNode stored = parse(outcome.body());
        return response.eTag(stored.get("version").asText())
                .location(URI.create("/api/v1/groups/" + gid + "/expenses/" + stored.get("id").asText()))
                .body(outcome.body());
    }

    /**
     * Computes the split for the same body as create and saves nothing. No Idempotency-Key; safe to call on every
     * edit. {@code payers} may be empty here, in which case {@code payersTotalMatches} is false.
     */
    @PostMapping("/preview")
    @Operation(summary = "Preview an expense split without saving it",
            description = "Same body as create. Returns the computed total, charges and per-member breakdown, and "
                    + "payersTotalMatches. Persists nothing. Itemized-only totals are null for EQUAL/EXACT.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(examples = {
            @ExampleObject(name = "EQUAL", value = ApiExamples.EQUAL),
            @ExampleObject(name = "EXACT", value = ApiExamples.EXACT),
            @ExampleObject(name = "ITEMIZED", value = ApiExamples.ITEMIZED)}))
    public ExpensePreview preview(@PathVariable UUID gid, @RequestBody ExpenseCommand command) {
        return expenses.preview(currentUser.id(), gid, command);
    }

    @GetMapping
    public PageResponse<ExpenseView> list(@PathVariable UUID gid,
                                          @RequestParam(defaultValue = "0") int page,
                                          @RequestParam(defaultValue = "20") int size,
                                          @RequestParam(required = false)
                                          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
                                          @RequestParam(required = false)
                                          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
                                          @RequestParam(required = false) UUID memberId) {
        return PageResponse.of(expenses.list(currentUser.id(), gid, page, size, fromDate, toDate, memberId),
                view -> view);
    }

    @GetMapping("/{eid}")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "The expense",
            headers = @io.swagger.v3.oas.annotations.headers.Header(name = "ETag", description = "Version of the expense",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = ExpenseView.class)))
    public ResponseEntity<ExpenseView> get(@PathVariable UUID gid, @PathVariable UUID eid) {
        ExpenseView view = expenses.get(currentUser.id(), gid, eid);
        return ResponseEntity.ok().eTag(Integer.toString(view.version())).body(view);
    }

    /**
     * Replaces the expense. {@code If-Match} carries the version the client last saw (428 if missing, 409
     * VERSION_CONFLICT if stale). Same body, same validation and same errors as create; no Idempotency-Key: the
     * version is what makes a retry safe (a repeated PUT with the old version is a 409).
     */
    @PutMapping("/{eid}")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "The updated expense",
            headers = @io.swagger.v3.oas.annotations.headers.Header(name = "ETag", description = "New version of the expense",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = ExpenseView.class)))
    @Operation(summary = "Edit an expense (replaces payers, shares and items)",
            description = "If-Match with the current version is required. Send the explicit participant list: "
                    + "members who joined later are never added silently. Writes a revision.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(examples = {
            @ExampleObject(name = "EQUAL", value = ApiExamples.EQUAL),
            @ExampleObject(name = "EXACT", value = ApiExamples.EXACT),
            @ExampleObject(name = "ITEMIZED", value = ApiExamples.ITEMIZED)}))
    public ResponseEntity<ExpenseView> update(@PathVariable UUID gid, @PathVariable UUID eid,
                                              @RequestHeader(value = "If-Match", required = false) String ifMatch,
                                              @RequestBody ExpenseCommand command) {
        int expected = IfMatch.version(ifMatch);
        ExpenseView view = expenses.update(currentUser.id(), gid, eid, expected, command);
        return ResponseEntity.ok().eTag(Integer.toString(view.version())).body(view);
    }

    /** Soft delete. The expense leaves lists and balances; its history stays. A second delete is a plain 404. */
    @DeleteMapping("/{eid}")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Deleted",
            headers = @io.swagger.v3.oas.annotations.headers.Header(name = "ETag", description = "Version after the delete",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")))
    @Operation(summary = "Delete an expense (soft delete, keeps the history)",
            description = "If-Match with the current version is required. Answers 204 with the new ETag.")
    public ResponseEntity<Void> delete(@PathVariable UUID gid, @PathVariable UUID eid,
                                       @RequestHeader(value = "If-Match", required = false) String ifMatch) {
        int expected = IfMatch.version(ifMatch);
        int version = expenses.delete(currentUser.id(), gid, eid, expected);
        return ResponseEntity.noContent().eTag(Integer.toString(version)).build();
    }

    @GetMapping("/{eid}/revisions")
    @Operation(summary = "History of an expense, oldest first",
            description = "Each entry carries the full expense as it was after that change. Still available after the "
                    + "expense was deleted.")
    public List<ExpenseRevisionView> revisions(@PathVariable UUID gid, @PathVariable UUID eid) {
        return expenses.revisions(currentUser.id(), gid, eid);
    }

    /** Spec 8.3: the key is a client-generated UUID. Normalized to lower case so equal keys compare equal. */
    static UUID parseKey(String raw) {
        if (raw == null || raw.isBlank()) {
            throw ApiException.validation(IDEMPOTENCY_HEADER + " header is required");
        }
        try {
            return UUID.fromString(raw.strip().toLowerCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw ApiException.validation(IDEMPOTENCY_HEADER + " must be a UUID");
        }
    }

    private com.fasterxml.jackson.databind.JsonNode parse(String body) {
        try {
            com.fasterxml.jackson.databind.JsonNode node = mapper.readTree(body);
            if (node.get("id") == null || node.get("version") == null) {
                throw new IllegalStateException("Stored expense response has no id or version");
            }
            return node;
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored expense response is not valid JSON", e);
        }
    }
}
