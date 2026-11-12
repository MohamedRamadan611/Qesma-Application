package app.qesma.api;

import app.qesma.api.GroupDtos.CreateMemberRequest;
import app.qesma.api.GroupDtos.MemberDto;
import app.qesma.api.GroupDtos.UpdateMemberRequest;
import app.qesma.domain.Member;
import app.qesma.security.CurrentUser;
import app.qesma.service.MemberService;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Ghost members of a group (spec 8.2). The group is always addressed first, so ownership is always checked. */
@RestController
@RequestMapping("/api/v1/groups/{gid}/members")
public class MemberController {

    private final MemberService members;
    private final CurrentUser currentUser;

    public MemberController(MemberService members, CurrentUser currentUser) {
        this.members = members;
        this.currentUser = currentUser;
    }

    @PostMapping
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Created",
            headers = @io.swagger.v3.oas.annotations.headers.Header(name = "Location", description = "URL of the new member",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(type = "string")),
            content = @io.swagger.v3.oas.annotations.media.Content(mediaType = "application/json",
                    schema = @io.swagger.v3.oas.annotations.media.Schema(implementation = MemberDto.class)))
    public ResponseEntity<MemberDto> add(@PathVariable UUID gid, @RequestBody CreateMemberRequest request) {
        Member member = members.add(currentUser.id(), gid, request.displayName());
        return ResponseEntity.created(URI.create("/api/v1/groups/" + gid + "/members/" + member.getId()))
                .body(MemberDto.from(member, currentUser.id()));
    }

    @PatchMapping("/{mid}")
    @io.swagger.v3.oas.annotations.Operation(summary = "Rename a member, change its role, or remove/reactivate it",
            description = "Send at least one of displayName, role, status. displayName: Owner/Admin. role (ADMIN or "
                    + "MEMBER): Owner only. status (LEFT removes a linked member, ACTIVE reactivates): Owner, and Admin "
                    + "for members (not admins). The owner's member is protected (409 OWNER_MEMBER_PROTECTED). A member "
                    + "without an account has no role or status.")
    public MemberDto update(@PathVariable UUID gid, @PathVariable UUID mid,
                            @RequestBody UpdateMemberRequest request) {
        return MemberDto.from(members.update(currentUser.id(), gid, mid, new MemberService.MemberPatch(
                request.displayName(), request.role(), request.status())), currentUser.id());
    }

    /** Detaches the person's account from a member; the member and its history stay (Owner/Admin). */
    @PostMapping("/{mid}/unlink")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @io.swagger.v3.oas.annotations.Operation(summary = "Unlink the account from a member (the member, its history and balance stay)",
            description = "The person loses access to the group at once and the member can be claimed again. The "
                    + "owner's member cannot be unlinked (409 OWNER_MEMBER_PROTECTED); only the owner may unlink an admin.")
    public void unlink(@PathVariable UUID gid, @PathVariable UUID mid) {
        members.unlink(currentUser.id(), gid, mid);
    }

    @DeleteMapping("/{mid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID gid, @PathVariable UUID mid) {
        members.delete(currentUser.id(), gid, mid);
    }
}
