package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.User;
import app.qesma.persistence.JoinRequestStore;
import app.qesma.persistence.NotificationPrefStore;
import app.qesma.persistence.RemindLogStore;
import app.qesma.persistence.UserRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Deletes the signed-in account (B17, Phase 2 spec section 9; Decision Log A114-A120). The {@code users} row is
 * anonymised, not removed (the ledger tables reference it); everything that identifies the person or lets someone act
 * as them is purged; members linked to the account keep their row, name and history and become ordinary unclaimed
 * members, so no other member's balance and no ledger row changes.
 *
 * <p>The password check commits its own failure counter (like change-password), so it runs before, not inside, the
 * deletion transaction; the slow hash never holds the deletion's row locks. The purge is one transaction: all or
 * nothing. Nothing here logs an email, a username or a name; only ids.
 */
@Service
public class AccountDeletionService {

    /** The literal the client must send. */
    public static final String CONFIRM_WORD = "DELETE";

    private static final Logger log = LoggerFactory.getLogger(AccountDeletionService.class);

    private final UserRepository users;
    private final PasswordAuthService passwordAuth;
    private final GroupService groups;
    private final ActivityService activity;
    private final PaymentHandleService handles;
    private final IdempotencyService idempotency;
    private final RefreshTokenService refreshTokens;
    private final JoinRequestStore joinRequests;
    private final NotificationPrefStore prefs;
    private final RemindLogStore remindLog;
    private final Clock clock;
    private final MeterRegistry metrics;
    private final TransactionTemplate tx;

    public AccountDeletionService(UserRepository users, PasswordAuthService passwordAuth, GroupService groups,
                                  ActivityService activity, PaymentHandleService handles, IdempotencyService idempotency,
                                  RefreshTokenService refreshTokens, JoinRequestStore joinRequests,
                                  NotificationPrefStore prefs, RemindLogStore remindLog, Clock clock,
                                  MeterRegistry metrics, PlatformTransactionManager txManager) {
        this.users = users;
        this.passwordAuth = passwordAuth;
        this.groups = groups;
        this.activity = activity;
        this.handles = handles;
        this.idempotency = idempotency;
        this.refreshTokens = refreshTokens;
        this.joinRequests = joinRequests;
        this.prefs = prefs;
        this.remindLog = remindLog;
        this.clock = clock;
        this.metrics = metrics;
        this.tx = new TransactionTemplate(txManager);
    }

    /**
     * @param confirm  must be exactly {@value #CONFIRM_WORD}
     * @param password the current password; required for a password account, ignored for a Google account
     * @throws ApiException 401 for a deleted/unknown account (a repeated call), 422 for a wrong confirm word or password,
     *                      409 OWNER_MUST_TRANSFER (with the groups) when the account still owns groups that depend on it
     */
    public void delete(UUID userId, String confirm, String password) {
        User user = users.findById(userId).filter(u -> !u.isDeleted()).orElseThrow(ApiException::unauthorized);
        if (!CONFIRM_WORD.equals(confirm)) {
            throw ApiException.validation("confirm must be \"" + CONFIRM_WORD + "\"");
        }
        if (user.hasPassword()) {
            if (password == null || password.isBlank()) {
                throw ApiException.validation("the current password is required to delete this account");
            }
            passwordAuth.requireCurrentPassword(userId, password);
        }
        try {
            tx.executeWithoutResult(status -> purge(userId));
        } catch (ApiException e) {
            if (e.code() == ErrorCode.OWNER_MUST_TRANSFER) {
                metrics.counter("qesma.account.delete", "result", "owner_must_transfer").increment();
            }
            throw e;
        }
        metrics.counter("qesma.account.delete", "result", "success").increment();
        log.atInfo().addKeyValue("event", "account.deleted").addKeyValue("userId", userId)
                .log("account.deleted userId={}", userId);
    }

    /**
     * Lock order: credential row, user row, then groups in id order (the same credential-then-user order as sign-in, and
     * group locks last like every group writer). A repeated or parallel deletion finds the row already deleted: 401.
     */
    private void purge(UUID userId) {
        passwordAuth.purgeCredentialsOf(userId);          // password hash + emailed-link tokens (locks the credential first)
        User user = users.findByIdForUpdate(userId).orElseThrow(ApiException::unauthorized);
        if (user.isDeleted()) {
            throw ApiException.unauthorized();
        }
        groups.releaseUser(userId);                       // 409 OWNER_MUST_TRANSFER, empty owned groups removed, members detached
        joinRequests.deleteAllOfUser(userId);
        activity.deleteNotificationsOf(userId);
        prefs.deleteAllOfUser(userId);
        remindLog.deleteAllBySender(userId);
        handles.deleteAllFor(userId);
        idempotency.deleteAllOf(userId);
        refreshTokens.deleteAllOf(userId);                // every session ends in the same transaction
        users.anonymise(userId, "deleted:" + UUID.randomUUID(), clock.instant().truncatedTo(ChronoUnit.MICROS));
    }
}
