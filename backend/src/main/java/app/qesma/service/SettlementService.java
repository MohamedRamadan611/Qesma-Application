package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Member;
import app.qesma.domain.Settlement;
import app.qesma.persistence.SettlementRepository;
import app.qesma.service.SettlementTransitions.Action;
import app.qesma.service.SettlementTransitions.Actor;
import app.qesma.service.SettlementTransitions.Decision;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Two-sided settlements of a group (PHASE2_SPEC section 6, A83-A89). Creation is idempotent through the same
 * {@link IdempotencyService} as expenses; the initial status is decided here, never by the client (A85). Confirm,
 * dispute and cancel go through ONE method driven by {@link SettlementTransitions}; concurrent transitions are
 * serialized by a conditional UPDATE. A settlement is never deleted. Access and roles are decided only by
 * {@link GroupAccessService}.
 */
@Service
public class SettlementService {

    static final String CREATE_ENDPOINT = "POST /api/v1/groups/{gid}/settlements";

    private static final Logger log = LoggerFactory.getLogger(SettlementService.class);

    /** Transitions retry once after losing a race; the second pass always ends in the no-op or the 409. */
    private static final int MAX_ATTEMPTS = 3;

    private final GroupAccessService access;
    private final SettlementRepository settlements;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;
    private final GroupEventRecorder events;

    public SettlementService(GroupAccessService access, SettlementRepository settlements,
                             IdempotencyService idempotency, RequestHasher hasher, ObjectMapper mapper, Clock clock,
                             MeterRegistry metrics, GroupEventRecorder events) {
        this.events = events;
        this.access = access;
        this.settlements = settlements;
        this.idempotency = idempotency;
        this.hasher = hasher;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    /**
     * Records a settlement exactly once per Idempotency-Key. One transaction: key lock, group lock, replay check,
     * validation, membership check, status decision, insert, key row. Partial amounts and amounts larger than the
     * suggested transfer are fine (spec 7.8).
     *
     * <p>Initial status (A85): the payer declares (PENDING) a payment to a member with an account; the receiver
     * recording it is the confirmation (CONFIRMED); an Owner/Admin may record any payment on behalf (CONFIRMED,
     * {@code recorded_by_admin}), which is also the only way to record a payment to a member nobody can confirm for.
     */
    @Transactional
    public IdempotencyService.Outcome create(UUID userId, UUID groupId, UUID idempotencyKey,
                                             SettlementCommand command) {
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.ADD_SETTLEMENT);

        SettlementValidator.Valid request = SettlementValidator.validate(command);
        String requestHash = hasher.hash(CREATE_ENDPOINT, groupId, canonical(request));
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, CREATE_ENDPOINT, requestHash);
        if (replay.isPresent()) {
            log.atInfo().addKeyValue("event", "settlement.replayed").addKeyValue("userId", userId)
                    .addKeyValue("groupId", groupId).log("settlement.replayed userId={} groupId={}", userId, groupId);
            return replay.get();
        }

        List<Member> members = access.listMembers(ctx);
        requireMember(members, request.fromMemberId());
        Member receiver = requireMember(members, request.toMemberId());

        boolean manager = ctx.can(Permission.MANAGE_SETTLEMENTS);
        UUID me = ctx.me().getId();
        boolean confirmed;
        boolean onBehalf;
        if (me.equals(request.fromMemberId())) {
            if (receiver.getUserId() != null) {
                confirmed = false;
                onBehalf = false;
            } else if (manager) {                                   // nobody could ever confirm a ghost's receipt
                confirmed = true;
                onBehalf = true;
            } else {
                throw ApiException.forbidden();
            }
        } else if (me.equals(request.toMemberId())) {
            confirmed = true;                                       // the receiver's own record is the confirmation
            onBehalf = false;
        } else if (manager) {
            confirmed = true;
            onBehalf = true;
        } else {
            throw ApiException.forbidden();
        }

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        UUID id = UUID.randomUUID();
        Settlement saved = settlements.saveAndFlush(new Settlement(id, groupId, request.fromMemberId(),
                request.toMemberId(), request.amountMinor(), request.settledOn(), request.note(), userId, me, now,
                confirmed, onBehalf));
        String body = toJson(view(saved));
        // B15: the receiver learns of a declared payment; both parties learn of a recorded (confirmed) one
        events.record(groupId, me, confirmed ? EventType.SETTLEMENT_CONFIRMED : EventType.SETTLEMENT_PENDING,
                EventPayload.settlement(id, request.amountMinor(), request.fromMemberId(), request.toMemberId()),
                confirmed ? GroupEventRecorder.Recipients.members(Set.of(request.fromMemberId(), request.toMemberId()))
                        : GroupEventRecorder.Recipients.members(Set.of(request.toMemberId())));
        idempotency.store(userId, key, CREATE_ENDPOINT, requestHash, HttpStatus.CREATED.value(), body);
        String op = confirmed ? "recorded" : "declared";
        metrics.counter("qesma.settlements", "op", op).increment();
        log.atInfo().addKeyValue("event", "settlement." + op).addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("settlementId", id)
                .log("settlement.{} userId={} groupId={} settlementId={}", op, userId, groupId, id);
        return new IdempotencyService.Outcome(HttpStatus.CREATED.value(), body, false);
    }

    /** Statuses are validated against the known four; no filter means all of them (cancelled rows stay in history). */
    @Transactional(readOnly = true)
    public Page<SettlementView> list(UUID userId, UUID groupId, List<String> statuses, int page, int size) {
        FieldRules.page(page, size);
        access.requireMember(userId, groupId);
        return settlements.findPage(groupId, parseStatuses(statuses), PageRequest.of(page, size))
                .map(SettlementService::view);
    }

    @Transactional
    public SettlementView confirm(UUID userId, UUID groupId, UUID settlementId) {
        return transition(userId, groupId, settlementId, Action.CONFIRM);
    }

    @Transactional
    public SettlementView dispute(UUID userId, UUID groupId, UUID settlementId) {
        return transition(userId, groupId, settlementId, Action.DISPUTE);
    }

    @Transactional
    public SettlementView cancel(UUID userId, UUID groupId, UUID settlementId) {
        return transition(userId, groupId, settlementId, Action.CANCEL);
    }

    /**
     * One transition. No group lock: the conditional UPDATE {@code ... WHERE status = <seen state>} decides races. The
     * loser (0 rows) reloads and applies the same rule to the new state, so it gets either the idempotent view (same
     * outcome as the winner's) or 409 INVALID_STATE_TRANSITION; never a second event or timestamp.
     */
    private SettlementView transition(UUID userId, UUID groupId, UUID settlementId, Action action) {
        GroupContext ctx = access.requireMember(userId, groupId);
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            Settlement s = settlements.findInGroup(settlementId, groupId).orElseThrow(ApiException::notFound);
            Decision decision = SettlementTransitions.decide(SettlementTransitions.Status.valueOf(s.getStatus()),
                    action, actorsOf(ctx, s));
            switch (decision.kind()) {
                case FORBIDDEN -> {
                    metrics.counter("qesma.settlements", "op", "forbidden").increment();
                    throw ApiException.forbidden();
                }
                case INVALID -> {
                    metrics.counter("qesma.settlements", "op", "invalid").increment();
                    throw ApiException.conflict(ErrorCode.INVALID_STATE_TRANSITION,
                            "This settlement is " + s.getStatus() + " and cannot be " + verb(action));
                }
                case NOOP -> {
                    metrics.counter("qesma.settlements", "op", "noop").increment();
                    return view(s);
                }
                case TRANSITION -> {
                    Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
                    int rows = settlements.transition(settlementId, groupId, s.getStatus(), decision.to().name(), now);
                    if (rows == 1) {
                        recordTransition(groupId, ctx.me().getId(), s, decision.to());   // B15: only the winner writes
                        String op = decision.to().name().toLowerCase(java.util.Locale.ROOT);
                        metrics.counter("qesma.settlements", "op", op).increment();
                        log.atInfo().addKeyValue("event", "settlement." + op).addKeyValue("userId", userId)
                                .addKeyValue("groupId", groupId).addKeyValue("settlementId", settlementId)
                                .log("settlement.{} userId={} groupId={} settlementId={}", op, userId, groupId,
                                        settlementId);
                        return view(settlements.findInGroup(settlementId, groupId).orElseThrow(ApiException::notFound));
                    }
                    metrics.counter("qesma.settlements", "op", "conflict").increment();   // lost a race: re-decide
                }
            }
        }
        throw ApiException.conflict(ErrorCode.INVALID_STATE_TRANSITION, "The settlement was changed concurrently");
    }

    /** CONFIRMED / DISPUTED / CANCELLED: the two parties (the actor is excluded by the recorder); a dispute also reaches Owner/Admins. */
    private void recordTransition(UUID groupId, UUID actorMemberId, Settlement s, SettlementTransitions.Status to) {
        EventType type = switch (to) {
            case CONFIRMED -> EventType.SETTLEMENT_CONFIRMED;
            case DISPUTED -> EventType.SETTLEMENT_DISPUTED;
            case CANCELLED -> EventType.SETTLEMENT_CANCELLED;
            case PENDING -> throw new IllegalStateException("No transition leads to PENDING");
        };
        Set<UUID> parties = Set.of(s.getFromMemberId(), s.getToMemberId());
        events.record(groupId, actorMemberId, type,
                EventPayload.settlement(s.getId(), s.getAmountMinor(), s.getFromMemberId(), s.getToMemberId()),
                to == SettlementTransitions.Status.DISPUTED ? GroupEventRecorder.Recipients.membersAndManagers(parties)
                        : GroupEventRecorder.Recipients.members(parties));
    }

    private static Set<Actor> actorsOf(GroupContext ctx, Settlement s) {
        Set<Actor> actors = EnumSet.noneOf(Actor.class);
        UUID me = ctx.me().getId();
        if (me.equals(s.getFromMemberId())) {
            actors.add(Actor.PAYER);
        }
        if (me.equals(s.getToMemberId())) {
            actors.add(Actor.RECEIVER);
        }
        if (ctx.can(Permission.MANAGE_SETTLEMENTS)) {
            actors.add(Actor.MANAGER);
        }
        return actors;
    }

    private static String verb(Action action) {
        return switch (action) {
            case CONFIRM -> "confirmed";
            case DISPUTE -> "disputed";
            case CANCEL -> "cancelled";
        };
    }

    private static List<String> parseStatuses(List<String> requested) {
        List<String> all = Arrays.stream(SettlementTransitions.Status.values()).map(Enum::name).toList();
        if (requested == null || requested.isEmpty()) {
            return all;
        }
        for (String s : requested) {
            if (!all.contains(s)) {
                throw ApiException.validation("status must be one of PENDING, CONFIRMED, DISPUTED, CANCELLED");
            }
        }
        return requested.stream().distinct().toList();
    }

    static SettlementView view(Settlement s) {
        return new SettlementView(s.getId(), s.getGroupId(), s.getFromMemberId(), s.getToMemberId(),
                s.getAmountMinor(), s.getSettledOn(), s.getNote(), s.getCreatedAt(), s.getStatus(),
                s.isRecordedByAdmin(), s.getCreatedByMemberId(), s.getDeclaredAt(), s.getConfirmedAt(),
                s.getDisputedAt(), s.getCancelledAt());
    }

    /** Spec 6 notes: both members must belong to the settlement's group and still be in it. */
    private static Member requireMember(List<Member> members, UUID memberId) {
        Member found = members.stream().filter(m -> m.getId().equals(memberId)).findFirst().orElseThrow(
                () -> new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, HttpStatus.UNPROCESSABLE_ENTITY,
                        "A referenced member is not part of this group"));
        if (Member.STATUS_LEFT.equals(found.getStatus())) {
            throw MemberService.inactive();                       // B12: a member who left is no party of a new settlement
        }
        return found;
    }

    private static Map<String, Object> canonical(SettlementValidator.Valid v) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("fromMemberId", v.fromMemberId().toString());
        m.put("toMemberId", v.toMemberId().toString());
        m.put("amountMinor", v.amountMinor());
        m.put("settledOn", v.settledOn().toString());
        m.put("note", v.note());
        return m;
    }

    private String toJson(SettlementView view) {
        try {
            return mapper.writeValueAsString(view);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize settlement response", e);
        }
    }
}
