package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.EmailToken;
import app.qesma.domain.User;
import app.qesma.domain.UserPassword;
import app.qesma.persistence.EmailTokenRepository;
import app.qesma.persistence.RefreshTokenRepository;
import app.qesma.persistence.UserPasswordRepository;
import app.qesma.persistence.UserRepository;
import app.qesma.security.AccessTokenService;
import app.qesma.security.AuthProperties;
import app.qesma.security.PasswordHasher;
import app.qesma.security.PasswordPolicy;
import app.qesma.security.RefreshTokens;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Email + password accounts (ADR-007): register, sign in, change and reset the password, verify the address.
 *
 * <p>Accounts are identified by a username; email is not collected (ADR-008), so the emailed-link flows below only reach
 * accounts that have an address on file.
 *
 * <p>Failure outcomes that must still be saved (a failed attempt raises the counter) are returned from inside the
 * transaction and turned into exceptions afterwards, so the counter commits instead of rolling back with the exception.
 * Slow hashing happens outside transactions where it can. Emails are sent after the transaction committed and a failure
 * to send never changes the answer. Nothing here logs an email address, a password, a token or a link.
 */
@Service
public class PasswordAuthService {

    private static final Logger log = LoggerFactory.getLogger(PasswordAuthService.class);

    /** A signed-in session: the access and refresh tokens and the user; {@code created} is true for a new account. */
    public record Session(String accessToken, String refreshToken, User user, boolean created) {
    }

    private record PendingMail(String email, String rawToken) {
    }

    private final UserRepository users;
    private final UserPasswordRepository passwords;
    private final EmailTokenRepository emailTokens;
    private final RefreshTokenRepository refreshTokenRows;
    private final RefreshTokenService refreshTokens;
    private final AccessTokenService accessTokens;
    private final PasswordHasher hasher;
    private final MailSender mail;
    private final AuthProperties props;
    private final Clock clock;
    private final MeterRegistry metrics;
    private final TransactionTemplate tx;

    public PasswordAuthService(UserRepository users, UserPasswordRepository passwords, EmailTokenRepository emailTokens,
                               RefreshTokenRepository refreshTokenRows, RefreshTokenService refreshTokens,
                               AccessTokenService accessTokens, PasswordHasher hasher, MailSender mail,
                               AuthProperties props, Clock clock, MeterRegistry metrics,
                               PlatformTransactionManager txManager) {
        this.users = users;
        this.passwords = passwords;
        this.emailTokens = emailTokens;
        this.refreshTokenRows = refreshTokenRows;
        this.refreshTokens = refreshTokens;
        this.accessTokens = accessTokens;
        this.hasher = hasher;
        this.mail = mail;
        this.props = props;
        this.clock = clock;
        this.metrics = metrics;
        this.tx = new TransactionTemplate(txManager);
    }

    // ---- register -----------------------------------------------------------------------------------------

    /** What the insert found: a new account's session, or the id of the account that already has the name. */
    private record Registration(Session created, UUID existingId) {
    }

    /**
     * Creates a password account and signs it in. If the username already belongs to a password account and the password
     * given is its password (a retry after a lost reply), that account is signed in instead. That retry is a password
     * check like any other: it respects the lockout and a wrong password counts as a failure (review finding 1). Any
     * other clash is USERNAME_TAKEN. No email address is involved (ADR-008).
     */
    public Session register(String rawUsername, String password, String rawDisplayName) {
        String username = UsernameRules.normalize(rawUsername);
        PasswordPolicy.check(password, username);
        String name = rawDisplayName == null || rawDisplayName.isBlank() ? username : DisplayNames.validated(rawDisplayName);
        String hash = hasher.hash(password);

        Registration registration = tx.execute(status -> {
            UUID id = UUID.randomUUID();
            int inserted = users.insertIfAbsent(id, User.PROVIDER_PASSWORD, username, null, name);
            User user = users.findByAuthProviderAndAuthSubject(User.PROVIDER_PASSWORD, username)
                    .orElseThrow(() -> new IllegalStateException("User missing right after insert"));
            if (inserted == 0) {
                return new Registration(null, user.getId());
            }
            passwords.save(new UserPassword(user.getId(), hash, clock.instant()));
            return new Registration(openSession(user, true), null);
        });
        Session session = registration.created();
        if (session == null) {
            // The name exists: only its owner (same password, not locked out) is signed in again.
            session = checkPasswordAndOpenSession(registration.existingId(), password);
            if (session == null) {
                throw usernameTaken();
            }
        }
        metrics.counter("qesma.auth.register", "result", session.created() ? "created" : "existing").increment();
        log.atInfo().addKeyValue("event", "auth.register").addKeyValue("userId", session.user().getId())
                .addKeyValue("created", session.created())
                .log("auth.register userId={} created={}", session.user().getId(), session.created());
        return session;
    }

    // ---- sign in ------------------------------------------------------------------------------------------

    /** Signs in, or throws the same generic 401 whatever went wrong (unknown name, wrong password, locked, Google account). */
    public Session login(String rawUsername, String password) {
        String key = UsernameRules.lookupKey(rawUsername);
        Optional<User> found = key == null ? Optional.empty()
                : tx.execute(status -> users.findByAuthProviderAndAuthSubject(User.PROVIDER_PASSWORD, key));
        Session session = null;
        if (found.isPresent()) {
            session = checkPasswordAndOpenSession(found.get().getId(), password);
        } else {
            hasher.spendTime(password);
            loginFailed("unknown");
        }
        if (session == null) {
            throw ApiException.unauthorized();
        }
        metrics.counter("qesma.auth.login", "method", "password", "result", "success").increment();
        log.atInfo().addKeyValue("event", "auth.login").addKeyValue("method", "password")
                .addKeyValue("userId", session.user().getId())
                .log("auth.login method=password userId={}", session.user().getId());
        return session;
    }

    private record Credential(String hash, boolean locked) {
    }

    /**
     * The one place a typed password is checked for sign-in (login and the register retry). The slow BCrypt comparison
     * runs outside any transaction, so it never holds a pooled connection or a row lock (review finding 5); only the
     * counter update takes the row lock. A locked account is refused without checking, a wrong password counts as a
     * failure (five in a row lock the account), a right one resets the counter and opens a session. Returns null on any
     * refusal so the counter commits before the caller throws.
     */
    private Session checkPasswordAndOpenSession(UUID userId, String password) {
        Credential credential = tx.execute(status -> passwords.findById(userId)
                .map(p -> new Credential(p.getPasswordHash(), p.isLocked(clock.instant()))).orElse(null));
        if (credential == null) {
            throw new IllegalStateException("Password account without credential");
        }
        if (credential.locked()) {
            hasher.spendTime(password);
            loginFailed("locked");
            return null;
        }
        boolean matches = hasher.matches(password, credential.hash());
        return tx.execute(status -> {
            UserPassword locked = passwords.findByUserIdForUpdate(userId)
                    .orElseThrow(() -> new IllegalStateException("Password account without credential"));
            Instant now = clock.instant();
            if (!matches) {
                boolean wasLocked = locked.isLocked(now);
                locked.recordFailure(now, props.password().lockoutThreshold(), now.plus(props.password().lockoutDuration()));
                if (!wasLocked && locked.isLocked(now)) {
                    metrics.counter("qesma.auth.lockout").increment();
                    log.atWarn().addKeyValue("event", "auth.lockout").addKeyValue("userId", userId)
                            .log("auth.lockout userId={}", userId);
                }
                loginFailed("bad_credentials");
                return null;
            }
            locked.recordSuccess();
            User user = users.findById(userId).orElseThrow(() -> new IllegalStateException("User missing"));
            return openSession(user, false);
        });
    }

    private void loginFailed(String reason) {
        metrics.counter("qesma.auth.login", "method", "password", "result", reason).increment();
        log.atInfo().addKeyValue("event", "auth.login.failed").addKeyValue("method", "password")
                .addKeyValue("reason", reason).log("auth.login.failed method=password reason={}", reason);
    }

    // ---- change password (signed in) ----------------------------------------------------------------------

    /**
     * Changes the password of the signed-in user. Every other login session ends; this one continues with fresh tokens.
     * A wrong current password is a validation error (not a 401), so the app does not think the session ended.
     */
    public Session changePassword(UUID userId, String currentPassword, String newPassword) {
        User user = users.findById(userId).orElseThrow(ApiException::unauthorized);
        if (!user.hasPassword()) {
            throw ApiException.validation("this account signs in with Google and has no password");
        }
        PasswordPolicy.check(newPassword, user.getEmail());
        String newHash = hasher.hash(newPassword);

        Session session = tx.execute(status -> {
            UserPassword credential = passwords.findByUserIdForUpdate(userId)
                    .orElseThrow(() -> new IllegalStateException("Password account without credential"));
            Instant now = clock.instant();
            if (credential.isLocked(now)) {
                hasher.spendTime(currentPassword);
                return null;
            }
            if (!hasher.matches(currentPassword, credential.getPasswordHash())) {
                credential.recordFailure(now, props.password().lockoutThreshold(), now.plus(props.password().lockoutDuration()));
                return null;
            }
            credential.changePassword(newHash, now);
            refreshTokenRows.revokeAllOfUser(userId, now);
            return openSession(user, false);
        });
        if (session == null) {
            metrics.counter("qesma.auth.password_change", "result", "wrong_current").increment();
            throw ApiException.validation("current password is wrong");
        }
        metrics.counter("qesma.auth.password_change", "result", "success").increment();
        log.atInfo().addKeyValue("event", "auth.password.changed").addKeyValue("userId", userId)
                .log("auth.password.changed userId={}", userId);
        return session;
    }

    // ---- forgot / reset -----------------------------------------------------------------------------------

    /** Emails a reset link if the address belongs to a password account. Always looks the same to the caller. */
    public void forgotPassword(String rawEmail) {
        String email = EmailRules.normalizeOrNull(rawEmail);
        if (email == null) {
            return;
        }
        // Only accounts that have an email address on file (none are created today: recovery by email is on hold, ADR-008).
        List<PendingMail> pending = tx.execute(status -> users.findAllByAuthProviderAndEmailIgnoreCase(User.PROVIDER_PASSWORD, email).stream()
                .map(user -> new PendingMail(user.getEmail(),
                        newEmailToken(user.getId(), EmailToken.RESET_PASSWORD, props.password().resetTokenTtl())))
                .toList());
        metrics.counter("qesma.auth.password_reset", "result", pending.isEmpty() ? "requested_unknown" : "requested").increment();
        for (PendingMail mailToSend : pending) {
            send(() -> mail.sendPasswordReset(mailToSend.email(), link("reset-password", mailToSend.rawToken())), "password_reset");
        }
    }

    /** Sets a new password with a reset link (once). Ends every login session of the account. */
    public void resetPassword(String rawToken, String newPassword) {
        PasswordPolicy.check(newPassword, null);
        String newHash = hasher.hash(newPassword);
        tx.executeWithoutResult(status -> {
            List<UUID> consumed = emailTokens.consume(RefreshTokens.hash(rawToken), EmailToken.RESET_PASSWORD, clock.instant());
            if (consumed.isEmpty()) {
                metrics.counter("qesma.auth.password_reset", "result", "invalid_token").increment();
                throw invalidLink();
            }
            UUID userId = consumed.get(0);
            User user = users.findById(userId).orElseThrow(PasswordAuthService::invalidLink);
            // Checked after the link was used, inside the transaction: a refusal rolls the use back, so the link stays valid.
            PasswordPolicy.check(newPassword, user.getEmail());
            PasswordPolicy.check(newPassword, user.getUsername());   // also not the sign-in name (review finding 7)
            Instant now = clock.instant();
            UserPassword credential = passwords.findByUserIdForUpdate(userId).orElseThrow(PasswordAuthService::invalidLink);
            credential.changePassword(newHash, now);
            refreshTokenRows.revokeAllOfUser(userId, now);
            users.markEmailVerified(userId, now); // the link reached the inbox of this address
            log.atInfo().addKeyValue("event", "auth.password.reset").addKeyValue("userId", userId)
                    .log("auth.password.reset userId={}", userId);
        });
        metrics.counter("qesma.auth.password_reset", "result", "success").increment();
    }

    // ---- verify the address -------------------------------------------------------------------------------

    public void verifyEmail(String rawToken) {
        tx.executeWithoutResult(status -> {
            List<UUID> consumed = emailTokens.consume(RefreshTokens.hash(rawToken), EmailToken.VERIFY_EMAIL, clock.instant());
            if (consumed.isEmpty()) {
                metrics.counter("qesma.auth.email_verify", "result", "invalid_token").increment();
                throw invalidLink();
            }
            users.markEmailVerified(consumed.get(0), clock.instant());
            log.atInfo().addKeyValue("event", "auth.email.verified").addKeyValue("userId", consumed.get(0))
                    .log("auth.email.verified userId={}", consumed.get(0));
        });
        metrics.counter("qesma.auth.email_verify", "result", "success").increment();
    }

    /** Sends a fresh verification link to the signed-in password account (nothing to do if already verified). */
    public void resendVerification(UUID userId) {
        PendingMail pending = tx.execute(status -> {
            User user = users.findById(userId).orElseThrow(ApiException::unauthorized);
            if (!user.hasPassword() || user.getEmail() == null || user.isEmailVerified()) {
                return null;
            }
            return new PendingMail(user.getEmail(),
                    newEmailToken(userId, EmailToken.VERIFY_EMAIL, props.password().verifyTokenTtl()));
        });
        if (pending != null) {
            sendVerification(pending.email(), pending.rawToken());
        }
    }

    // ---- helpers ------------------------------------------------------------------------------------------

    private Session openSession(User user, boolean created) {
        String refresh = refreshTokens.issueNewFamily(user.getId());
        String access = accessTokens.issue(user.getId());
        return new Session(access, refresh, user, created);
    }

    /** Stores a fresh one-time token (older unused ones of the same kind stop working) and returns the raw value. */
    private String newEmailToken(UUID userId, String purpose, java.time.Duration ttl) {
        Instant now = clock.instant();
        emailTokens.invalidateOpen(userId, purpose, now);
        String raw = RefreshTokens.generate();
        emailTokens.save(new EmailToken(UUID.randomUUID(), userId, purpose, RefreshTokens.hash(raw), now, now.plus(ttl)));
        return raw;
    }

    private String link(String path, String rawToken) {
        String base = props.password().publicBaseUrl();
        return (base.endsWith("/") ? base.substring(0, base.length() - 1) : base) + "/" + path + "?token=" + rawToken;
    }

    private void sendVerification(String email, String rawToken) {
        send(() -> mail.sendVerification(email, link("verify-email", rawToken)), "verification");
    }

    /** A mail problem is logged (kind only, no address, no link) and never changes the answer to the caller. */
    private void send(Runnable sender, String kind) {
        try {
            sender.run();
        } catch (RuntimeException e) {
            metrics.counter("qesma.mail.failed", "kind", kind).increment();
            log.atError().addKeyValue("event", "mail.failed").addKeyValue("kind", kind)
                    .log("mail.failed kind={} cause={}", kind, e.getClass().getSimpleName());
        }
    }

    private static ApiException usernameTaken() {
        return new ApiException(ErrorCode.USERNAME_TAKEN, HttpStatus.CONFLICT,
                "This username is taken. Choose another one or sign in.");
    }

    private static ApiException invalidLink() {
        return ApiException.validation("this link is invalid or has expired");
    }
}
