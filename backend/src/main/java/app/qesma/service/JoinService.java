package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Member;
import app.qesma.persistence.InviteStore;
import app.qesma.persistence.JoinRequestStore;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
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
 * Joining a group with an invite code and deciding join requests (B11, Decisions A70-A76).
 *
 * <p>Lock order is always: idempotency advisory lock, invite row, group row. The invite row lock serializes every
 * join and approval of one invite (so {@code max_uses} holds), the group row lock serializes member creation. The
 * "claim a ghost" step is one conditional UPDATE, so of two parallel claims exactly one wins; the unique indexes on
 * {@code (group_id, user_id)} and the member name are the last defense.
 */
@Service
public class JoinService {

    static final String JOIN_ENDPOINT = "POST /api/v1/invites/{code}/join";

    private static final Logger log = LoggerFactory.getLogger(JoinService.class);

    private final GroupAccessService access;
    private final MemberService members;
    private final InviteStore invites;
    private final JoinRequestStore requests;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final InviteAttemptLimiter limiter;
    private final InviteService inviteService;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public JoinService(GroupAccessService access, MemberService members, InviteStore invites,
                       JoinRequestStore requests, IdempotencyService idempotency, RequestHasher hasher,
                       InviteAttemptLimiter limiter, InviteService inviteService, ObjectMapper mapper, Clock clock,
                       MeterRegistry metrics) {
        this.access = access;
        this.members = members;
        this.invites = invites;
        this.requests = requests;
        this.idempotency = idempotency;
        this.hasher = hasher;
        this.limiter = limiter;
        this.inviteService = inviteService;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    /** What the person asked to be: an existing member, or a new one with this name. */
    private record Target(UUID claimMemberId, String newName) {
    }

    /**
     * Joins exactly once per Idempotency-Key: 201 JOINED, or 202 PENDING_APPROVAL when the invite needs an admin's
     * approval. A replay returns the stored answer (also after the invite expired).
     */
    @Transactional
    public IdempotencyService.Outcome join(UUID userId, UUID idempotencyKey, String rawCode, JoinCommand command) {
        limiter.check(userId);
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);
        Target target = target(command);

        String code = InviteCodes.normalize(rawCode);
        InviteStore.Invite invite = code == null ? null : invites.findByCodeForUpdate(code).orElse(null);
        if (invite == null) {
            inviteService.failed(userId, "unknown");
            throw ApiException.notFound();
        }
        String requestHash = hasher.hash(JOIN_ENDPOINT, invite.id(), canonical(target));
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, JOIN_ENDPOINT, requestHash);
        if (replay.isPresent()) {
            return replay.get();
        }
        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        String problem = InviteService.unusable(invite.revokedAt(), invite.expiresAt(), invite.maxUses(),
                invite.useCount(), now);
        if (problem != null) {
            inviteService.failed(userId, problem);
            throw InviteService.gone(problem);
        }
        if (members.isActiveMember(invite.groupId(), userId)) {
            throw ApiException.conflict(ErrorCode.ALREADY_MEMBER, "You are already a member of this group");
        }

        IdempotencyService.Outcome outcome;
        if (invite.requiresApproval()) {
            UUID requestId = openRequest(invite, userId, target, now);
            outcome = outcome(HttpStatus.ACCEPTED, new JoinView("PENDING_APPROVAL", invite.groupId(), null, requestId));
            metrics.counter("qesma.joins", "result", "pending").increment();
        } else {
            Member member = perform(invite.groupId(), userId, target, now);
            invites.incrementUse(invite.id());
            outcome = outcome(HttpStatus.CREATED, new JoinView("JOINED", invite.groupId(), joined(member), null));
            metrics.counter("qesma.joins", "result", "joined").increment();
            log.atInfo().addKeyValue("event", "join.joined").addKeyValue("userId", userId)
                    .addKeyValue("groupId", invite.groupId()).addKeyValue("memberId", member.getId())
                    .log("join.joined userId={} groupId={} memberId={}", userId, invite.groupId(), member.getId());
        }
        idempotency.store(userId, key, JOIN_ENDPOINT, requestHash, outcome.status(), outcome.body());
        return outcome;
    }

    // ---- requests an admin decides ----------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public Page<JoinRequestView> pendingRequests(UUID userId, UUID groupId, int page, int size) {
        FieldRules.page(page, size);
        access.require(userId, groupId, Permission.APPROVE_JOINS);
        var rows = requests.page(groupId, JoinRequestStore.PENDING, size, (long) page * size).stream()
                .map(JoinService::view).toList();
        return new PageImpl<>(rows, PageRequest.of(page, size), requests.count(groupId, JoinRequestStore.PENDING));
    }

    @Transactional
    public JoinRequestView approve(UUID userId, UUID groupId, UUID requestId) {
        return decide(userId, groupId, requestId, true);
    }

    @Transactional
    public JoinRequestView reject(UUID userId, UUID groupId, UUID requestId) {
        return decide(userId, groupId, requestId, false);
    }

    private JoinRequestView decide(UUID userId, UUID groupId, UUID requestId, boolean approve) {
        access.require(userId, groupId, Permission.APPROVE_JOINS);                   // 404 / 403 first, no lock taken
        JoinRequestStore.Request peek = requests.findInGroup(requestId, groupId).orElseThrow(ApiException::notFound);
        InviteStore.Invite invite = invites.findByIdForUpdate(peek.inviteId()).orElseThrow(ApiException::notFound);
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.APPROVE_JOINS); // invite, then group
        JoinRequestStore.Request request = requests.findInGroupForUpdate(requestId, groupId)
                .orElseThrow(ApiException::notFound);

        String wanted = approve ? JoinRequestStore.APPROVED : JoinRequestStore.REJECTED;
        if (!JoinRequestStore.PENDING.equals(request.status())) {
            if (request.status().equals(wanted)) {
                return view(requests.row(requestId).orElseThrow(ApiException::notFound));   // repeating a decision is fine
            }
            throw ApiException.conflict(ErrorCode.VERSION_CONFLICT, "This request was already decided");
        }
        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        if (approve) {
            if (invite.maxUses() != null && invite.useCount() >= invite.maxUses()) {
                throw ApiException.gone(ErrorCode.INVITE_EXPIRED, "This invitation has expired or was used up");
            }
            if (members.isActiveMember(groupId, request.userId())) {
                throw ApiException.conflict(ErrorCode.ALREADY_MEMBER, "This person is already a member");
            }
            Target target = new Target(request.claimMemberId(), request.newMemberName());
            perform(groupId, request.userId(), target, now);   // a ghost claimed meanwhile -> 409, request stays PENDING
            invites.incrementUse(invite.id());
        }
        requests.decide(requestId, wanted, now, ctx.me().getId());
        metrics.counter("qesma.joins", "result", approve ? "approved" : "rejected").increment();
        log.atInfo().addKeyValue("event", "join.decided").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("requestId", requestId)
                .addKeyValue("decision", wanted)
                .log("join.decided userId={} groupId={} requestId={} decision={}", userId, groupId, requestId, wanted);
        return view(requests.row(requestId).orElseThrow(ApiException::notFound));
    }

    // ---- helpers ------------------------------------------------------------------------------------------------

    private UUID openRequest(InviteStore.Invite invite, UUID userId, Target target, Instant now) {
        Optional<JoinRequestStore.Request> existing = requests.findPending(invite.id(), userId);
        if (existing.isPresent()) {
            return existing.get().id();                                  // asking twice is the same request
        }
        Optional<Member> left = members.findLeft(invite.groupId(), userId);
        if (left.isPresent()) {                                          // a returning member: the request points at their own row
            UUID id = UUID.randomUUID();
            requests.insert(new JoinRequestStore.Request(id, invite.id(), invite.groupId(), userId,
                    left.get().getId(), null, JoinRequestStore.PENDING, now, null));
            return id;
        }
        String name = target.claimMemberId() != null ? null : members.requireFreeName(invite.groupId(), target.newName());
        if (target.claimMemberId() != null) {
            members.requireUnclaimed(invite.groupId(), target.claimMemberId());
        }
        UUID id = UUID.randomUUID();
        requests.insert(new JoinRequestStore.Request(id, invite.id(), invite.groupId(), userId, target.claimMemberId(),
                name, JoinRequestStore.PENDING, now, null));
        return id;
    }

    private Member perform(UUID groupId, UUID accountId, Target target, Instant now) {
        Optional<Member> returning = members.reactivateIfLeft(groupId, accountId, now);   // B12: rejoin = own row back
        if (returning.isPresent()) {
            return returning.get();
        }
        return target.claimMemberId() != null
                ? members.claimGhost(groupId, target.claimMemberId(), accountId, now)
                : members.createJoined(groupId, target.newName(), accountId, now);
    }

    private static Target target(JoinCommand command) {
        boolean claim = command != null && command.claimMemberId() != null;
        boolean name = command != null && command.newMemberName() != null && !command.newMemberName().isBlank();
        if (claim == name) {
            throw ApiException.validation("Send exactly one of claimMemberId or newMemberName");
        }
        return claim ? new Target(command.claimMemberId(), null)
                : new Target(null, FieldRules.name(command.newMemberName(), FieldRules.MEMBER_NAME_MAX, "newMemberName"));
    }

    private static Map<String, Object> canonical(Target t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("claimMemberId", t.claimMemberId() == null ? null : t.claimMemberId().toString());
        m.put("newMemberName", t.newName());
        return m;
    }

    private static JoinView.JoinedMember joined(Member m) {
        return new JoinView.JoinedMember(m.getId(), m.getDisplayName(), m.getRole());
    }

    private static JoinRequestView view(JoinRequestStore.Row r) {
        return new JoinRequestView(r.id(), r.status(), r.requesterName(), r.claimMemberId(), r.claimMemberName(),
                r.newMemberName(), r.createdAt(), r.decidedAt());
    }

    private IdempotencyService.Outcome outcome(HttpStatus status, JoinView view) {
        try {
            return new IdempotencyService.Outcome(status.value(), mapper.writeValueAsString(view), false);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize join response", e);
        }
    }
}
