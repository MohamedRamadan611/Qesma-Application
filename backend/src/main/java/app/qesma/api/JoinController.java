package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.IdempotencyService;
import app.qesma.service.InvitePreview;
import app.qesma.service.InviteService;
import app.qesma.service.JoinCommand;
import app.qesma.service.JoinService;
import app.qesma.service.JoinView;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Looking at and using an invitation code (B11). Any signed-in person may call these: the code is the capability, so
 * there is no group authorization here, and what they reveal is limited to what the join screen needs.
 */
@RestController
@RequestMapping("/api/v1/invites/{code}")
public class JoinController {

    private final InviteService invites;
    private final JoinService joins;
    private final CurrentUser currentUser;

    public JoinController(InviteService invites, JoinService joins, CurrentUser currentUser) {
        this.invites = invites;
        this.joins = joins;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "Look at an invitation before joining",
            description = "Group name, who invited you, member count and the members nobody has claimed yet. No "
                    + "balances and no accounts. 404 for an unknown code, 410 when expired, used up or revoked.")
    public InvitePreview preview(@PathVariable String code) {
        return invites.preview(currentUser.id(), code);
    }

    @PostMapping("/join")
    @Operation(summary = "Join the group: claim an existing member or become a new one",
            description = "Idempotency-Key (UUID) is required. Send exactly one of claimMemberId or newMemberName. "
                    + "201 JOINED, or 202 PENDING_APPROVAL when an admin must approve first.")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Joined (or the stored answer of an identical earlier request: header Idempotency-Replayed: true)",
            headers = @io.swagger.v3.oas.annotations.headers.Header(name = "Idempotency-Replayed",
                    description = "true when this is the stored answer of an identical earlier request",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = JoinView.class)))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "202", description = "Waiting for an admin's approval",
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = JoinView.class)))
    public ResponseEntity<String> join(@PathVariable String code,
                                       @RequestHeader(value = ExpenseController.IDEMPOTENCY_HEADER, required = false)
                                       String key,
                                       @RequestBody JoinCommand command) {
        IdempotencyService.Outcome outcome =
                joins.join(currentUser.id(), ExpenseController.parseKey(key), code, command);
        ResponseEntity.BodyBuilder response = ResponseEntity.status(outcome.status())
                .contentType(MediaType.APPLICATION_JSON);
        if (outcome.replayed()) {
            response.header(ExpenseController.REPLAYED_HEADER, "true");
        }
        return response.body(outcome.body());
    }
}
