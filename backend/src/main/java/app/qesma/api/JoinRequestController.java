package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.JoinRequestView;
import app.qesma.service.JoinService;
import io.swagger.v3.oas.annotations.Operation;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Join requests of a group that needs approval (B11). Owner/Admin only. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/join-requests")
public class JoinRequestController {

    private final JoinService joins;
    private final CurrentUser currentUser;

    public JoinRequestController(JoinService joins, CurrentUser currentUser) {
        this.joins = joins;
        this.currentUser = currentUser;
    }

    @GetMapping
    @Operation(summary = "List the requests waiting for a decision, oldest first (the requester by display name only)")
    public PageResponse<JoinRequestView> list(@PathVariable UUID gid, @RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(joins.pendingRequests(currentUser.id(), gid, page, size), view -> view);
    }

    @PostMapping("/{rid}/approve")
    @Operation(summary = "Approve a join request: the person becomes a member (or claims the member they chose)",
            description = "Repeating the same decision returns the stored result. A member somebody else claimed in "
                    + "the meantime is 409 and the request stays pending so it can be rejected.")
    public JoinRequestView approve(@PathVariable UUID gid, @PathVariable UUID rid) {
        return joins.approve(currentUser.id(), gid, rid);
    }

    @PostMapping("/{rid}/reject")
    @Operation(summary = "Reject a join request")
    public JoinRequestView reject(@PathVariable UUID gid, @PathVariable UUID rid) {
        return joins.reject(currentUser.id(), gid, rid);
    }
}
