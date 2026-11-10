package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.PasswordAuthService;
import app.qesma.service.UserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
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

    /** Both passwords are checked by the password policy in the service; the sizes only bound the request. */
    public record ChangePasswordRequest(@NotBlank @Size(max = 256) String currentPassword,
                                        @NotBlank @Size(max = 256) String newPassword) {
        @Override
        public String toString() {
            return "ChangePasswordRequest[***]";
        }
    }

    private final UserService users;
    private final PasswordAuthService passwordAuth;
    private final CurrentUser currentUser;

    public MeController(UserService users, PasswordAuthService passwordAuth, CurrentUser currentUser) {
        this.users = users;
        this.passwordAuth = passwordAuth;
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

    /** Changes the password of a password account. Other sessions end; the answer carries this session's new tokens. */
    @PostMapping("/password")
    public AuthController.TokenResponse changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        PasswordAuthService.Session s = passwordAuth.changePassword(currentUser.id(), request.currentPassword(), request.newPassword());
        return new AuthController.TokenResponse(s.accessToken(), s.refreshToken());
    }
}
