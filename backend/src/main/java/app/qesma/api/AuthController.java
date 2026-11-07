package app.qesma.api;

import app.qesma.service.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Public sign-in endpoints (spec 8.2). Rate limited by AuthRateLimitFilter. */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    public record GoogleLoginRequest(@NotBlank @Size(max = 4096) String idToken) {
    }

    public record RefreshRequest(@NotBlank @Size(max = 256) String refreshToken) {
    }

    public record AuthResponse(String accessToken, String refreshToken, UserDto user) {
    }

    public record TokenResponse(String accessToken, String refreshToken) {
    }

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/google")
    public AuthResponse google(@Valid @RequestBody GoogleLoginRequest request) {
        AuthService.Login login = auth.loginWithGoogle(request.idToken());
        return new AuthResponse(login.accessToken(), login.refreshToken(), UserDto.from(login.user()));
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest request) {
        AuthService.Refreshed refreshed = auth.refresh(request.refreshToken());
        return new TokenResponse(refreshed.accessToken(), refreshed.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest request) {
        auth.logout(request.refreshToken());
    }
}
