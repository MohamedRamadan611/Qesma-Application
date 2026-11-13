package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.NotificationPrefService;
import io.swagger.v3.oas.annotations.Operation;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Notification preferences (B16, A104-A106): the global switch and a per-group mute. Both only ever act on the signed-in
 * user. PUT sets a value, so repeating it changes nothing (no Idempotency-Key). Reads come with {@code GET /me}
 * ({@code notificationsEnabled}) and {@code GET /groups/{gid}} ({@code muted}).
 */
@RestController
public class NotificationPrefsController {

    /** {@code enabled} is required (null is a 422). */
    public record UpdateNotificationPrefsRequest(Boolean enabled) {
    }

    public record NotificationPrefsView(boolean enabled) {
    }

    /** {@code muted} is required (null is a 422). */
    public record UpdateGroupNotificationPrefsRequest(Boolean muted) {
    }

    public record GroupNotificationPrefsView(boolean muted) {
    }

    private final NotificationPrefService prefs;
    private final CurrentUser currentUser;

    public NotificationPrefsController(NotificationPrefService prefs, CurrentUser currentUser) {
        this.prefs = prefs;
        this.currentUser = currentUser;
    }

    @PutMapping("/api/v1/me/notification-prefs")
    @Operation(summary = "Switch all your notifications on or off",
            description = "enabled=false: you get no new notification from any group, reminders and disputes included. "
                    + "Activity feeds still show everything. Notifications you already have are kept; switching back on "
                    + "does not backfill what you missed.")
    public NotificationPrefsView update(@RequestBody UpdateNotificationPrefsRequest request) {
        return new NotificationPrefsView(prefs.setEnabled(currentUser.id(), request.enabled()));
    }

    @PutMapping("/api/v1/groups/{gid}/notification-prefs")
    @Operation(summary = "Mute or unmute one group for yourself",
            description = "muted=true: you get no new notification from this group, reminders and disputes included. "
                    + "The group activity feed still shows everything. Any active member may do this for themselves.")
    public GroupNotificationPrefsView updateGroup(@PathVariable UUID gid,
                                                  @RequestBody UpdateGroupNotificationPrefsRequest request) {
        return new GroupNotificationPrefsView(prefs.setGroupMuted(currentUser.id(), gid, request.muted()));
    }
}
