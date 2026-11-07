package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.UserService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** The signed-in user's own profile. No id in the path: it always acts on the token's subject. */
@RestController
@RequestMapping("/api/v1/me")
public class MeController {

    /** Validated and trimmed in the service (1 to 60 characters). */
    public record UpdateMeRequest(String displayName) {
    }

    private final UserService users;
    private final CurrentUser currentUser;

    public MeController(UserService users, CurrentUser currentUser) {
        this.users = users;
        this.currentUser = currentUser;
    }

    @GetMapping
    public UserDto me() {
        return UserDto.from(users.get(currentUser.id()));
    }

    @PatchMapping
    public UserDto update(@RequestBody UpdateMeRequest request) {
        return UserDto.from(users.updateDisplayName(currentUser.id(), request.displayName()));
    }
}
