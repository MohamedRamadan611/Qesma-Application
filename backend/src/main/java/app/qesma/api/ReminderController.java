package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.IdempotencyService;
import app.qesma.service.RemindCommand;
import app.qesma.service.RemindService;
import app.qesma.service.ReminderView;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Remind a debtor of a suggested transfer (B16). Access is decided inside the service by the central component. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/transfers/remind")
public class ReminderController {

    private final RemindService reminders;
    private final CurrentUser currentUser;

    public ReminderController(RemindService reminders, CurrentUser currentUser) {
        this.reminders = reminders;
        this.currentUser = currentUser;
    }

    @PostMapping
    @Operation(summary = "Remind a member of a suggested transfer they owe",
            description = "Idempotency-Key (UUID) is required. fromMemberId (the debtor) and toMemberId (the creditor) must "
                    + "be a transfer of the current balances. The creditor may remind their own debtor; Owner/Admin may "
                    + "remind for any transfer (403 otherwise). The debtor must be an active member with an account. The "
                    + "amount is the one of the suggested transfer, set by the server. One reminder per debtor per group "
                    + "per 24 hours (any creditor), and a daily cap per sender: 429 REMIND_RATE_LIMITED with nextAllowedAt. "
                    + "A debtor who muted notifications still gets 201 (the mute is never revealed).")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(content = @Content(examples = @ExampleObject(
            name = "Remind A about the transfer to M", value = """
                    {"fromMemberId":"22222222-2222-2222-2222-222222222222",
                     "toMemberId":"11111111-1111-1111-1111-111111111111"}""")))
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Sent (or the stored answer of an identical earlier request: header Idempotency-Replayed: true)",
            headers = {@io.swagger.v3.oas.annotations.headers.Header(name = "Idempotency-Replayed",
                    description = "true when this is the stored answer of an identical earlier request",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string"))},
            content = @Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = ReminderView.class)))
    public ResponseEntity<String> remind(@PathVariable UUID gid,
                                         @RequestHeader(value = ExpenseController.IDEMPOTENCY_HEADER, required = false)
                                         String key,
                                         @RequestBody RemindCommand command) {
        IdempotencyService.Outcome outcome =
                reminders.remind(currentUser.id(), gid, ExpenseController.parseKey(key), command);
        ResponseEntity.BodyBuilder response = ResponseEntity.status(outcome.status())
                .contentType(MediaType.APPLICATION_JSON);
        if (outcome.replayed()) {
            response.header(ExpenseController.REPLAYED_HEADER, "true");
        }
        return response.body(outcome.body());
    }
}
