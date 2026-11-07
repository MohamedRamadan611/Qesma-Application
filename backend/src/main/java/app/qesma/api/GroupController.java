package app.qesma.api;

import app.qesma.api.GroupDtos.CreateGroupRequest;
import app.qesma.api.GroupDtos.GroupDto;
import app.qesma.api.GroupDtos.GroupSummaryDto;
import app.qesma.api.GroupDtos.UpdateGroupRequest;
import app.qesma.domain.ExpenseGroup;
import app.qesma.security.CurrentUser;
import app.qesma.service.GroupService;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Groups (spec 8.2). Controllers only translate HTTP; ownership is enforced inside the services. */
@RestController
@RequestMapping("/api/v1/groups")
public class GroupController {

    private final GroupService groups;
    private final CurrentUser currentUser;

    public GroupController(GroupService groups, CurrentUser currentUser) {
        this.groups = groups;
        this.currentUser = currentUser;
    }

    @PostMapping
    public ResponseEntity<GroupDto> create(@RequestBody CreateGroupRequest request) {
        ExpenseGroup created = groups.create(currentUser.id(), request.name(), request.type(), request.currencyCode());
        return ResponseEntity.created(URI.create("/api/v1/groups/" + created.getId()))
                .eTag(Integer.toString(created.getVersion()))
                .body(GroupDto.from(created, List.of()));
    }

    @GetMapping
    public PageResponse<GroupSummaryDto> list(@RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "20") int size) {
        return PageResponse.of(groups.list(currentUser.id(), page, size), GroupSummaryDto::from);
    }

    @GetMapping("/{gid}")
    public ResponseEntity<GroupDto> get(@PathVariable UUID gid) {
        GroupDto dto = GroupDto.from(groups.get(currentUser.id(), gid));
        return ResponseEntity.ok().eTag(Integer.toString(dto.version())).body(dto);
    }

    @PatchMapping("/{gid}")
    public ResponseEntity<GroupDto> update(@PathVariable UUID gid,
                                           @RequestHeader(value = "If-Match", required = false) String ifMatch,
                                           @RequestBody UpdateGroupRequest request) {
        int expected = IfMatch.version(ifMatch);
        ExpenseGroup updated = groups.update(currentUser.id(), gid, expected, request.name(), request.type());
        // The response carries the group without members (they are unchanged); the new ETag is what clients need.
        return ResponseEntity.ok().eTag(Integer.toString(updated.getVersion()))
                .body(GroupDto.from(updated, List.of()));
    }

    @DeleteMapping("/{gid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID gid) {
        groups.delete(currentUser.id(), gid);
    }
}
