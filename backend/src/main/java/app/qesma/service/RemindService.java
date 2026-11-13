package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.Member;
import app.qesma.engine.Transfer;
import app.qesma.persistence.RemindLogStore;
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
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The rate-limited Remind (B16, A107-A111). A creditor (or an Owner/Admin) reminds the debtor of a suggested transfer;
 * the debtor gets an in-app REMINDER notification. The amount comes only from the engine's suggested transfer, never
 * from the client, and nothing is moved or stored as money.
 *
 * <p>Same shape as {@code SettlementService.create}: key lock, group row lock, replay check, checks, write, event, key row,
 * all in ONE transaction. The group row lock serializes concurrent reminders of one group, so the window check on
 * {@code remind_log} is race-free per (group, debtor). A refused reminder (429) stores nothing, so the same key works
 * again after the window.
 */
@Service
public class RemindService {

    static final String ENDPOINT = "POST /api/v1/groups/{gid}/transfers/remind";

    private static final Logger log = LoggerFactory.getLogger(RemindService.class);

    private final GroupAccessService access;
    private final BalanceService balances;
    private final RemindLogStore remindLog;
    private final RemindProperties props;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final GroupEventRecorder events;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public RemindService(GroupAccessService access, BalanceService balances, RemindLogStore remindLog,
                         RemindProperties props, IdempotencyService idempotency, RequestHasher hasher,
                         GroupEventRecorder events, ObjectMapper mapper, Clock clock, MeterRegistry metrics) {
        this.access = access;
        this.balances = balances;
        this.remindLog = remindLog;
        this.props = props;
        this.idempotency = idempotency;
        this.hasher = hasher;
        this.events = events;
        this.mapper = mapper;
        this.clock = clock;
        this.metrics = metrics;
    }

    @Transactional
    public IdempotencyService.Outcome remind(UUID userId, UUID groupId, UUID idempotencyKey, RemindCommand command) {
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);
        GroupContext ctx = access.requireForUpdate(userId, groupId, Permission.READ_GROUP);       // 404 for non-members
        UUID me = ctx.me().getId();
        RemindCommand c = command == null ? new RemindCommand(null, null) : command;
        if (!me.equals(c.toMemberId())) {
            access.requireAlso(ctx, userId, Permission.REMIND_ANY);                                // 403: not your debtor
        }

        if (c.fromMemberId() == null || c.toMemberId() == null) {
            throw ApiException.validation("fromMemberId and toMemberId are required");
        }
        if (c.fromMemberId().equals(c.toMemberId())) {
            throw ApiException.validation("A reminder needs two different members");
        }
        if (me.equals(c.fromMemberId())) {
            throw ApiException.validation("You cannot remind yourself");
        }
        String requestHash = hasher.hash(ENDPOINT, groupId, canonical(c));
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, ENDPOINT, requestHash);
        if (replay.isPresent()) {
            metrics.counter("qesma.reminders", "result", "replayed").increment();
            log.atInfo().addKeyValue("event", "remind.replayed").addKeyValue("userId", userId)
                    .addKeyValue("groupId", groupId).log("remind.replayed userId={} groupId={}", userId, groupId);
            return replay.get();
        }

        BalanceService.Suggestion suggestion = balances.suggestion(ctx);
        Member debtor = find(suggestion.members(), c.fromMemberId());
        find(suggestion.members(), c.toMemberId());
        if (Member.STATUS_LEFT.equals(debtor.getStatus())) {
            throw MemberService.inactive();
        }
        if (debtor.getUserId() == null) {
            throw ApiException.validation("This member has no account to remind");
        }
        Transfer transfer = suggestion.transfers().stream()
                .filter(t -> t.fromMemberId().equals(c.fromMemberId().toString())
                        && t.toMemberId().equals(c.toMemberId().toString()))
                .findFirst()
                .orElseThrow(() -> ApiException.validation("There is no suggested transfer between these members"));

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        Optional<Instant> last = remindLog.lastForDebtor(groupId, c.fromMemberId());
        if (last.isPresent() && last.get().plus(props.window()).isAfter(now)) {
            throw limited("rate_limited_pair", last.get().plus(props.window()), userId, groupId);
        }
        RemindLogStore.UserWindow sent = remindLog.userWindow(userId, now.minus(props.window()));
        if (sent.count() >= props.dailyCapPerUser()) {
            throw limited("rate_limited_user", sent.oldest().plus(props.window()), userId, groupId);
        }

        remindLog.insert(UUID.randomUUID(), groupId, c.fromMemberId(), c.toMemberId(), userId, now);
        events.record(groupId, me, EventType.REMINDER,
                EventPayload.reminder(c.fromMemberId(), c.toMemberId(), transfer.amountMinor()),
                GroupEventRecorder.Recipients.members(Set.of(c.fromMemberId())));
        String body = toJson(new ReminderView(c.fromMemberId(), c.toMemberId(), transfer.amountMinor(), now,
                now.plus(props.window())));
        idempotency.store(userId, key, ENDPOINT, requestHash, HttpStatus.CREATED.value(), body);
        metrics.counter("qesma.reminders", "result", "sent").increment();
        log.atInfo().addKeyValue("event", "remind.sent").addKeyValue("groupId", groupId)
                .addKeyValue("fromMemberId", c.fromMemberId()).addKeyValue("toMemberId", c.toMemberId())
                .log("remind.sent groupId={} fromMemberId={} toMemberId={}", groupId, c.fromMemberId(), c.toMemberId());
        return new IdempotencyService.Outcome(HttpStatus.CREATED.value(), body, false);
    }

    private ApiException limited(String result, Instant nextAllowedAt, UUID userId, UUID groupId) {
        metrics.counter("qesma.reminders", "result", result).increment();
        log.atInfo().addKeyValue("event", "remind.rate_limited").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("reason", result)
                .log("remind.rate_limited userId={} groupId={} reason={}", userId, groupId, result);
        return ApiException.remindRateLimited(nextAllowedAt);
    }

    private static Member find(List<Member> members, UUID memberId) {
        return members.stream().filter(m -> m.getId().equals(memberId)).findFirst().orElseThrow(
                () -> new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, HttpStatus.UNPROCESSABLE_ENTITY,
                        "A referenced member is not part of this group"));
    }

    private static Map<String, Object> canonical(RemindCommand c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("fromMemberId", c.fromMemberId().toString());
        m.put("toMemberId", c.toMemberId().toString());
        return m;
    }

    private String toJson(ReminderView view) {
        try {
            return mapper.writeValueAsString(view);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialize reminder response", e);
        }
    }
}
