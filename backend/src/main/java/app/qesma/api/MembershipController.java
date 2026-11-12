package app.qesma.api;

import app.qesma.api.GroupDtos.TransferOwnershipRequest;
import app.qesma.security.CurrentUser;
import app.qesma.service.MemberService;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** The caller's own membership and the ownership of a group (B12, PHASE2_SPEC section 5). */
@RestController
@RequestMapping("/api/v1/groups/{gid}")
public class MembershipController {

    private final MemberService members;
    private final CurrentUser currentUser;

    public MembershipController(MemberService members, CurrentUser currentUser) {
        this.members = members;
        this.currentUser = currentUser;
    }

    @PostMapping("/leave")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @io.swagger.v3.oas.annotations.Operation(summary = "Leave the group",
            description = "The member row, its history and its balance stay; the group disappears from the caller's "
                    + "list and becomes 404 for them. The owner gets 409 OWNER_MUST_TRANSFER.")
    public void leave(@PathVariable UUID gid) {
        members.leave(currentUser.id(), gid);
    }

    @PostMapping("/transfer-ownership")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @io.swagger.v3.oas.annotations.Operation(summary = "Make another member the owner (the old owner becomes ADMIN)",
            description = "Owner only. The target must be an ACTIVE member with an account (a member who left is 422 "
                    + "MEMBER_INACTIVE). One transaction.")
    public void transferOwnership(@PathVariable UUID gid, @RequestBody TransferOwnershipRequest request) {
        members.transferOwnership(currentUser.id(), gid, request.toMemberId());
    }
}
