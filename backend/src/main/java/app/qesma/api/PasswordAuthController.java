package app.qesma.api;

import app.qesma.api.AuthController.AuthResponse;
import app.qesma.security.CurrentUser;
import app.qesma.service.NotificationPrefService;
import app.qesma.service.PasswordAuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Email + password sign-in (ADR-007). Everything except {@code /email/verify/resend} is public and, like every
 * {@code /auth/**} path, rate limited by AuthRateLimitFilter.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class PasswordAuthController {

    // Every record that carries a credential hides it in toString (invariant 10).
    public record RegisterRequest(@NotBlank @Size(max = 254) String username, @NotBlank @Size(max = 256) String password,
                                  @Size(max = 200) String displayName) {
        @Override
        public String toString() {
            return "RegisterRequest[***]";
        }
    }

    public record LoginRequest(@NotBlank @Size(max = 254) String username, @NotBlank @Size(max = 256) String password) {
        @Override
        public String toString() {
            return "LoginRequest[***]";
        }
    }

    public record ForgotPasswordRequest(@NotBlank @Size(max = 254) String email) {
        @Override
        public String toString() {
            return "ForgotPasswordRequest[***]";
        }
    }

    public record ResetPasswordRequest(@NotBlank @Size(max = 256) String token, @NotBlank @Size(max = 256) String newPassword) {
        @Override
        public String toString() {
            return "ResetPasswordRequest[***]";
        }
    }

    public record VerifyEmailRequest(@NotBlank @Size(max = 256) String token) {
        @Override
        public String toString() {
            return "VerifyEmailRequest[***]";
        }
    }

    private final PasswordAuthService passwordAuth;
    private final NotificationPrefService prefs;
    private final CurrentUser currentUser;

    public PasswordAuthController(PasswordAuthService passwordAuth, NotificationPrefService prefs, CurrentUser currentUser) {
        this.passwordAuth = passwordAuth;
        this.prefs = prefs;
        this.currentUser = currentUser;
    }

    /** 201 with the signed-in session. A retry with the same username and password (lost reply) answers the same way. */
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        PasswordAuthService.Session s = passwordAuth.register(request.username(), request.password(), request.displayName());
        return new AuthResponse(s.accessToken(), s.refreshToken(), UserDto.from(s.user(), prefs.isEnabled(s.user().getId())));
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        PasswordAuthService.Session s = passwordAuth.login(request.username(), request.password());
        return new AuthResponse(s.accessToken(), s.refreshToken(), UserDto.from(s.user(), prefs.isEnabled(s.user().getId())));
    }

    /** Always 204: it never says whether the address has an account. */
    @PostMapping("/password/forgot")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void forgot(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordAuth.forgotPassword(request.email());
    }

    @PostMapping("/password/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reset(@Valid @RequestBody ResetPasswordRequest request) {
        passwordAuth.resetPassword(request.token(), request.newPassword());
    }

    @PostMapping("/email/verify")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void verify(@Valid @RequestBody VerifyEmailRequest request) {
        passwordAuth.verifyEmail(request.token());
    }

    /** Needs an access token: sends a new verification link to the signed-in password account. */
    @PostMapping("/email/verify/resend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resend() {
        passwordAuth.resendVerification(currentUser.id());
    }
}
