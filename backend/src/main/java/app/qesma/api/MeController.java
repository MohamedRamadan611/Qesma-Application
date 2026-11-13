package app.qesma.api;

import app.qesma.security.CurrentUser;
import app.qesma.service.NotificationPrefService;
import app.qesma.service.PasswordAuthService;
import app.qesma.service.PaymentHandleService;
import app.qesma.service.PaymentHandlesView;
import app.qesma.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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

    /**
     * Both fields are optional: null, absent or blank removes that handle (PUT replaces both). Personal data, so the
     * record never prints its values (A51 style, A92).
     */
    public record UpdatePaymentHandlesRequest(String instapay, String wallet) {
        @Override
        public String toString() {
            return "UpdatePaymentHandlesRequest[***]";
        }
    }

    private final UserService users;
    private final PasswordAuthService passwordAuth;
    private final PaymentHandleService paymentHandles;
    private final NotificationPrefService prefs;
    private final CurrentUser currentUser;

    public MeController(UserService users, PasswordAuthService passwordAuth, PaymentHandleService paymentHandles,
                        NotificationPrefService prefs, CurrentUser currentUser) {
        this.prefs = prefs;
        this.users = users;
        this.passwordAuth = passwordAuth;
        this.paymentHandles = paymentHandles;
        this.currentUser = currentUser;
    }

    @GetMapping("/payment-handles")
    @Operation(summary = "Your own InstaPay address and mobile-wallet number",
            description = "Personal data. Co-members see a receiver's handles only on the balances transfers they pay (or as Owner/Admin).")
    public PaymentHandlesView paymentHandles() {
        return paymentHandles.get(currentUser.id());
    }

    @PutMapping("/payment-handles")
    @Operation(summary = "Replace your payment handles",
            description = "A null, absent or blank field removes that handle. Wallet: Egyptian mobile (Arabic digits, spaces, "
                    + "dashes and +20 accepted), stored as 01XXXXXXXXX. InstaPay: name@bank, 3 to 60 ASCII characters, stored lower case.")
    public PaymentHandlesView updatePaymentHandles(@RequestBody UpdatePaymentHandlesRequest request) {
        return paymentHandles.replace(currentUser.id(), request.instapay(), request.wallet());
    }

    @GetMapping
    public UserDto me() {
        return UserDto.from(users.get(currentUser.id()), prefs.isEnabled(currentUser.id()));
    }

    @PatchMapping
    public UserDto update(@RequestBody UpdateMeRequest request) {
        return UserDto.from(users.updateDisplayName(currentUser.id(), request.displayName()), prefs.isEnabled(currentUser.id()));
    }

    /** Changes the password of a password account. Other sessions end; the answer carries this session's new tokens. */
    @PostMapping("/password")
    public AuthController.TokenResponse changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        PasswordAuthService.Session s = passwordAuth.changePassword(currentUser.id(), request.currentPassword(), request.newPassword());
        return new AuthController.TokenResponse(s.accessToken(), s.refreshToken());
    }
}
