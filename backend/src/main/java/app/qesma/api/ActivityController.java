package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.ActivityService;
import io.swagger.v3.oas.annotations.Operation;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** The activity feed of a group (B15). Any ACTIVE member reads it; the service authorizes through GroupAccessService. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/activity")
public class ActivityController {

    private final ActivityService activity;
    private final CurrentUser currentUser;

    public ActivityController(ActivityService activity, CurrentUser currentUser) {
        this.activity = activity;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "The group's activity feed, newest first (keyset pagination)",
            description = "Every ACTIVE member reads the whole history. limit: 1 to 50 (default 20). before: the opaque "
                    + "nextBefore of the previous page (422 if malformed). nextBefore is null on the last page. payload "
                    + "holds ids, a version and integer amounts only; subject is the expense title (EXPENSE_* events, "
                    + "also after the expense was deleted) or the member's name (member events), resolved at read time.")
    public ActivityService.ActivityPage list(@PathVariable UUID gid,
                                             @RequestParam(required = false) Integer limit,
                                             @RequestParam(required = false) String before) {
        return activity.feed(currentUser.id(), gid, limit, before);
    }
}
