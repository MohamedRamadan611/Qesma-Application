package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.IdempotencyService;
import app.qesma.service.SettlementCommand;
import app.qesma.service.SettlementService;
import app.qesma.service.SettlementView;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Settlements of a group (spec 8.2). Ownership is enforced inside the service via the central access component. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/settlements")
public class SettlementController {

    private final SettlementService settlements;
    private final CurrentUser currentUser;
    private final ObjectMapper mapper;

    public SettlementController(SettlementService settlements, CurrentUser currentUser, ObjectMapper mapper) {
        this.settlements = settlements;
        this.currentUser = currentUser;
        this.mapper = mapper;
    }

    /**
     * Records a payment {@code fromMemberId -> toMemberId}. {@code Idempotency-Key} (UUID) is required; the same
     * key with the same request answers the stored response again ({@code Idempotency-Replayed: true}), the same
     * key with a different request is 422. Partial and larger-than-suggested amounts are allowed.
     */
    @PostMapping
    @Operation(summary = "Declare or record a settlement (a real-world payment between two members)",
            description = "Idempotency-Key (UUID) is required. amountMinor is in piasters, 1 to 10^12. The status is "
                    + "decided by the server: the payer declares (PENDING, to a member with an account); the receiver "
                    + "or an Owner/Admin recording it makes it CONFIRMED (Owner/Admin on behalf: recordedByAdmin). "
                    + "403 for a member recording a payment between two others or to a member without an account.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(examples = @ExampleObject(
            name = "A pays M 80.00", value = """
                    {"fromMemberId":"22222222-2222-2222-2222-222222222222",
                     "toMemberId":"11111111-1111-1111-1111-111111111111",
                     "amountMinor":8000,"settledOn":"2026-10-20","note":"Cash at the hotel"}""")))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Created (or the stored answer of an identical earlier request: header Idempotency-Replayed: true)",
            headers = {@io.swagger.v3.oas.annotations.headers.Header(name = "Location", description = "URL of the settlement",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
                    @io.swagger.v3.oas.annotations.headers.Header(name = "Idempotency-Replayed",
                    description = "true when this is the stored answer of an identical earlier request",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string"))},
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = SettlementView.class)))
    public ResponseEntity<String> create(@PathVariable UUID gid,
                                         @RequestHeader(value = ExpenseController.IDEMPOTENCY_HEADER, required = false)
                                         String key,
                                         @RequestBody SettlementCommand command) {
        IdempotencyService.Outcome outcome =
                settlements.create(currentUser.id(), gid, ExpenseController.parseKey(key), command);
        ResponseEntity.BodyBuilder response = ResponseEntity.status(outcome.status())
                .contentType(MediaType.APPLICATION_JSON);
        if (outcome.replayed()) {
            response.header(ExpenseController.REPLAYED_HEADER, "true");
        }
        return response.location(URI.create("/api/v1/groups/" + gid + "/settlements/" + idOf(outcome.body())))
                .body(outcome.body());
    }

    @GetMapping
    @Operation(summary = "List settlements, newest first (cancelled ones included)",
            description = "Optional repeatable filter status=PENDING|CONFIRMED|DISPUTED|CANCELLED; without it every status "
                    + "is listed. Only CONFIRMED settlements move balances.")
    public PageResponse<SettlementView> list(@PathVariable UUID gid,
                                             @RequestParam(required = false) List<String> status,
                                             @RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(settlements.list(currentUser.id(), gid, status, page, size), view -> view);
    }

    @PostMapping("/{sid}/confirm")
    @Operation(summary = "Confirm \"received\" (the receiver, or an Owner/Admin who is not the payer)",
            description = "PENDING or DISPUTED -> CONFIRMED. Repeating it returns the current settlement unchanged. "
                    + "409 INVALID_STATE_TRANSITION from CANCELLED.")
    public SettlementView confirm(@PathVariable UUID gid, @PathVariable UUID sid) {
        return settlements.confirm(currentUser.id(), gid, sid);
    }

    @PostMapping("/{sid}/dispute")
    @Operation(summary = "Dispute \"not received\" (the receiver only)",
            description = "PENDING -> DISPUTED. Repeating it returns the current settlement unchanged. "
                    + "409 INVALID_STATE_TRANSITION from CONFIRMED or CANCELLED.")
    public SettlementView dispute(@PathVariable UUID gid, @PathVariable UUID sid) {
        return settlements.dispute(currentUser.id(), gid, sid);
    }

    @PostMapping("/{sid}/cancel")
    @Operation(summary = "Cancel (the payer, or an Owner/Admin); replaces the Phase 1 delete",
            description = "PENDING or DISPUTED -> CANCELLED; the row stays in the history. Repeating it returns the "
                    + "current settlement unchanged. 409 INVALID_STATE_TRANSITION from CONFIRMED.")
    public SettlementView cancel(@PathVariable UUID gid, @PathVariable UUID sid) {
        return settlements.cancel(currentUser.id(), gid, sid);
    }


    private String idOf(String body) {
        try {
            return mapper.readTree(body).get("id").asText();
        } catch (JsonProcessingException | NullPointerException e) {
            throw new IllegalStateException("Stored settlement response has no id", e);
        }
    }
}
