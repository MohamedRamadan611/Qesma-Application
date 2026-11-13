package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.ActivityService;
import io.swagger.v3.oas.annotations.Operation;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** The signed-in user's in-app notification center (B15). Every statement is scoped to the token's subject. */
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    /** Exactly one of the two: up to 100 notification ids, or {@code all: true}. */
    public record MarkReadRequest(List<UUID> ids, Boolean all) {
    }

    private final ActivityService activity;
    private final CurrentUser currentUser;

    public NotificationController(ActivityService activity, CurrentUser currentUser) {
        this.activity = activity;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "Your notifications, newest first (keyset pagination)",
            description = "limit: 1 to 50 (default 20). before: the opaque nextBefore of the previous page (422 if "
                    + "malformed). groupName is always present; actorName and subject only while you are still an "
                    + "ACTIVE member of that group. Notifications stay readable after you leave a group.")
    public ActivityService.NotificationPage list(@RequestParam(required = false) Integer limit,
                                                 @RequestParam(required = false) String before) {
        return activity.notifications(currentUser.id(), limit, before);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "How many of your notifications are unread")
    public ActivityService.UnreadCount unreadCount() {
        return activity.unreadCount(currentUser.id());
    }

    @PostMapping("/read")
    @Operation(summary = "Mark your notifications read",
            description = "Body: exactly one of ids (1 to 100 notification ids) or all: true (else 422). Ids that are "
                    + "unknown or belong to someone else are ignored (the answer is identical). marked counts the rows "
                    + "that changed now. Not a create: no Idempotency-Key, repeating it is harmless.")
    public ActivityService.MarkReadResult markRead(@RequestBody MarkReadRequest request) {
        return activity.markRead(currentUser.id(), request.ids(), request.all());
    }
}
