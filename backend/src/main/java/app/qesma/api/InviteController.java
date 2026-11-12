package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.IdempotencyService;
import app.qesma.service.InviteCommand;
import app.qesma.service.InviteService;
import app.qesma.service.InviteView;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Invitations of a group (B11). Owner/Admin only; the role check is inside the service via the central component. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/invites")
public class InviteController {

    private final InviteService invites;
    private final CurrentUser currentUser;
    private final ObjectMapper mapper;

    public InviteController(InviteService invites, CurrentUser currentUser, ObjectMapper mapper) {
        this.invites = invites;
        this.currentUser = currentUser;
        this.mapper = mapper;
    }

    @PostMapping
    @Operation(summary = "Create an invitation (code and link)",
            description = "Idempotency-Key (UUID) is required. Defaults: expires in 7 days (1 to 30), unlimited uses "
                    + "(or 1 to 1000), no approval. The code (8 characters, shown XXXX-XXXX) is typed by hand and is "
                    + "also the end of the link.")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Created (or the stored answer of an identical earlier request: header Idempotency-Replayed: true)",
            headers = {@io.swagger.v3.oas.annotations.headers.Header(name = "Location", description = "URL of the invitation",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
                    @io.swagger.v3.oas.annotations.headers.Header(name = "Idempotency-Replayed",
                    description = "true when this is the stored answer of an identical earlier request",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string"))},
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = InviteView.class)))
    public ResponseEntity<String> create(@PathVariable UUID gid,
                                         @RequestHeader(value = ExpenseController.IDEMPOTENCY_HEADER, required = false)
                                         String key,
                                         @RequestBody(required = false) InviteCommand command) {
        IdempotencyService.Outcome outcome =
                invites.create(currentUser.id(), gid, ExpenseController.parseKey(key), command);
        ResponseEntity.BodyBuilder response = ResponseEntity.status(outcome.status())
                .contentType(MediaType.APPLICATION_JSON);
        if (outcome.replayed()) {
            response.header(ExpenseController.REPLAYED_HEADER, "true");
        }
        return response.location(URI.create("/api/v1/groups/" + gid + "/invites/" + idOf(outcome.body())))
                .body(outcome.body());
    }

    @GetMapping
    @Operation(summary = "List the group's invitations, newest first (with their codes)")
    public PageResponse<InviteView> list(@PathVariable UUID gid, @RequestParam(defaultValue = "0") int page,
                                         @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(invites.list(currentUser.id(), gid, page, size), view -> view);
    }

    @DeleteMapping("/{iid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Revoke an invitation (the code stops working; revoking again is not an error)")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "204", description = "Revoked")
    public void revoke(@PathVariable UUID gid, @PathVariable UUID iid) {
        invites.revoke(currentUser.id(), gid, iid);
    }

    private String idOf(String body) {
        try {
            return mapper.readTree(body).get("id").asText();
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored invite response is not valid JSON", e);
        }
    }
}
