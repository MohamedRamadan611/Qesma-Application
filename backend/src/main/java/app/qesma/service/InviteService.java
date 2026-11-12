package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.persistence.InviteStore;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Invitations of a group (B11, Decisions A70-A76): create, list, revoke (Owner/Admin through
 * {@link GroupAccessService}) and the preview a signed-in person sees before joining. The invite code is a secret: it
 * is never logged, never a metric tag, never part of an error message or of a request hash.
 */
@Service
public class InviteService {

    static final String CREATE_ENDPOINT = "POST /api/v1/groups/{gid}/invites";
    static final int DEFAULT_EXPIRY_DAYS = 7;
    static final int MAX_EXPIRY_DAYS = 30;
    static final int MAX_USES_LIMIT = 1000;

    private static final Logger log = LoggerFactory.getLogger(InviteService.class);

    private final GroupAccessService access;
    private final InviteStore invites;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final InviteAttemptLimiter limiter;
    private final InviteProperties props;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public InviteService(GroupAccessService access, InviteStore invites, IdempotencyService idempotency,
                         RequestHasher hasher, InviteAttemptLimiter limiter, InviteProperties props,
                         ObjectMapper mapper, Clock clock, MeterRegistry metrics) {
        this.access = access;
        this.invites = invites;
        this.idempotency = idempotency;
        this.hasher = hasher;
        this.limiter = limiter;
        this.props = props;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    /** Creates an invitation exactly once per Idempotency-Key (Owner/Admin). */
    @Transactional
    public IdempotencyService.Outcome create(UUID userId, UUID groupId, UUID idempotencyKey, InviteCommand command) {
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.MANAGE_INVITES);

        int days = command == null || command.expiresInDays() == null ? DEFAULT_EXPIRY_DAYS : command.expiresInDays();
        if (days < 1 || days > MAX_EXPIRY_DAYS) {
            throw ApiException.validation("expiresInDays must be between 1 and " + MAX_EXPIRY_DAYS);
        }
        Integer maxUses = command == null ? null : command.maxUses();
        if (maxUses != null && (maxUses < 1 || maxUses > MAX_USES_LIMIT)) {
            throw ApiException.validation("maxUses must be between 1 and " + MAX_USES_LIMIT);
        }
        boolean approval = command != null && Boolean.TRUE.equals(command.requiresApproval());

        Map<String, Object> canonical = new LinkedHashMap<>();
        canonical.put("expiresInDays", days);
        canonical.put("maxUses", maxUses);
        canonical.put("requiresApproval", approval);
        String requestHash = hasher.hash(CREATE_ENDPOINT, groupId, canonical);
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, CREATE_ENDPOINT, requestHash);
        if (replay.isPresent()) {
            return replay.get();
        }

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        String code = newCode();
        InviteStore.Invite invite = new InviteStore.Invite(UUID.randomUUID(), groupId, code, ctx.me().getId(), now,
                now.plus(days, ChronoUnit.DAYS), maxUses, 0, approval, null);
        invites.insert(invite);
        String body = toJson(view(invite, now));
        idempotency.store(userId, key, CREATE_ENDPOINT, requestHash, HttpStatus.CREATED.value(), body);
        metrics.counter("qesma.invites", "op", "created").increment();
        log.atInfo().addKeyValue("event", "invite.created").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("inviteId", invite.id())
                .log("invite.created userId={} groupId={} inviteId={}", userId, groupId, invite.id());
        return new IdempotencyService.Outcome(HttpStatus.CREATED.value(), body, false);
    }

    @Transactional(readOnly = true)
    public Page<InviteView> list(UUID userId, UUID groupId, int page, int size) {
        FieldRules.page(page, size);
        access.require(userId, groupId, Permission.MANAGE_INVITES);
        Instant now = clock.instant();
        List<InviteView> items = invites.pageByGroup(groupId, size, (long) page * size).stream()
                .map(i -> view(i, now)).toList();
        return new PageImpl<>(items, PageRequest.of(page, size), invites.countByGroup(groupId));
    }

    /** Revokes (never deletes): the code stops working at once. Revoking again is not an error. */
    @Transactional
    public void revoke(UUID userId, UUID groupId, UUID inviteId) {
        access.require(userId, groupId, Permission.MANAGE_INVITES);
        if (invites.revoke(inviteId, groupId, clock.instant().truncatedTo(ChronoUnit.MICROS)) == 0) {
            throw ApiException.notFound();
        }
        metrics.counter("qesma.invites", "op", "revoked").increment();
        log.atInfo().addKeyValue("event", "invite.revoked").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("inviteId", inviteId)
                .log("invite.revoked userId={} groupId={} inviteId={}", userId, groupId, inviteId);
    }

    /**
     * What a signed-in person may see about the group behind a code. 404 for an unknown code, 410 for an expired,
     * used-up or revoked one; every such answer counts against the user's failed-lookup budget.
     */
    @Transactional(readOnly = true)
    public InvitePreview preview(UUID userId, String rawCode) {
        limiter.check(userId);
        String code = InviteCodes.normalize(rawCode);
        InviteStore.PreviewRow row = code == null ? null : invites.preview(code, userId).orElse(null);
        if (row == null) {
            failed(userId, "unknown");
            throw ApiException.notFound();
        }
        Instant now = clock.instant();
        String problem = unusable(row.revokedAt(), row.expiresAt(), row.maxUses(), row.useCount(), now);
        if (problem != null) {
            failed(userId, problem);
            throw gone(problem);
        }
        List<InvitePreview.Unclaimed> ghosts = invites.unclaimed(row.groupId()).stream()
                .map(g -> new InvitePreview.Unclaimed(g.id(), g.name())).toList();
        String state = row.callerIsMember() ? "ALREADY_MEMBER" : row.callerHasPendingRequest() ? "PENDING_APPROVAL" : "NONE";
        return new InvitePreview(row.groupName(), row.groupType(), row.inviterName(), row.memberCount(), ghosts,
                row.requiresApproval(), row.expiresAt(), state);
    }

    // ---- shared with JoinService ----------------------------------------------------------------------------------

    /** null when usable, else "revoked" or "expired" (revoked wins; used up counts as expired). */
    static String unusable(Instant revokedAt, Instant expiresAt, Integer maxUses, int useCount, Instant now) {
        if (revokedAt != null) {
            return "revoked";
        }
        if (!now.isBefore(expiresAt) || maxUses != null && useCount >= maxUses) {
            return "expired";
        }
        return null;
    }

    static ApiException gone(String problem) {
        return "revoked".equals(problem)
                ? ApiException.gone(ErrorCode.INVITE_REVOKED, "This invitation was revoked")
                : ApiException.gone(ErrorCode.INVITE_EXPIRED, "This invitation has expired or was used up");
    }

    void failed(UUID userId, String reason) {
        limiter.recordFailure(userId);
        metrics.counter("qesma.invite.lookup_failed", "reason", reason).increment();
        log.atInfo().addKeyValue("event", "invite.lookup_failed").addKeyValue("userId", userId)
                .log("invite.lookup_failed userId={} reason={}", userId, reason);
    }

    private String newCode() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String code = InviteCodes.generate();
            if (!invites.codeExists(code)) {
                return code;
            }
        }
        throw new IllegalStateException("Could not find a free invite code");
    }

    private InviteView view(InviteStore.Invite i, Instant now) {
        String status = i.revokedAt() != null ? "REVOKED" : !now.isBefore(i.expiresAt()) ? "EXPIRED"
                : i.maxUses() != null && i.useCount() >= i.maxUses() ? "EXHAUSTED" : "ACTIVE";
        return new InviteView(i.id(), i.groupId(), i.code(), props.linkBase() + i.code(), i.createdAt(), i.expiresAt(),
                i.maxUses(), i.useCount(), i.requiresApproval(), i.revokedAt(), status);
    }

    private String toJson(InviteView view) {
        try {
            return mapper.writeValueAsString(view);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize invite response", e);
        }
    }
}
