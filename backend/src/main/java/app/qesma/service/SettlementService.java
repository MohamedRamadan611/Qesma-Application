package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.api.ErrorCode;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import app.qesma.domain.Settlement;
import app.qesma.persistence.SettlementRepository;
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
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Settlements of a group (spec 7.8, 8.2): recorded real-world payments that move balances. Creation is idempotent
 * through the same {@link IdempotencyService} as expenses; deletion is a soft delete. Ownership is decided only by
 * {@link GroupAccessService}.
 */
@Service
public class SettlementService {

    static final String CREATE_ENDPOINT = "POST /api/v1/groups/{gid}/settlements";

    private static final Logger log = LoggerFactory.getLogger(SettlementService.class);

    private final GroupAccessService access;
    private final SettlementRepository settlements;
    private final IdempotencyService idempotency;
    private final RequestHasher hasher;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final MeterRegistry metrics;

    public SettlementService(GroupAccessService access, SettlementRepository settlements,
                             IdempotencyService idempotency, RequestHasher hasher, ObjectMapper mapper, Clock clock,
                             MeterRegistry metrics) {
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
     * validation, membership check, insert, key row. Partial amounts and amounts larger than the suggested
     * transfer are fine (spec 7.8).
     */
    @Transactional
    public IdempotencyService.Outcome create(UUID userId, UUID groupId, UUID idempotencyKey,
                                             SettlementCommand command) {
        String key = idempotencyKey.toString();
        idempotency.lock(userId, key);
        ExpenseGroup group = access.requireOwnedForUpdate(userId, groupId);

        SettlementValidator.Valid request = SettlementValidator.validate(command);
        String requestHash = hasher.hash(CREATE_ENDPOINT, groupId, canonical(request));
        Optional<IdempotencyService.Outcome> replay = idempotency.findReplay(userId, key, CREATE_ENDPOINT, requestHash);
        if (replay.isPresent()) {
            log.atInfo().addKeyValue("event", "settlement.replayed").addKeyValue("userId", userId)
                    .addKeyValue("groupId", groupId).log("settlement.replayed userId={} groupId={}", userId, groupId);
            return replay.get();
        }

        List<Member> members = access.listMembers(group);
        requireMember(members, request.fromMemberId());
        requireMember(members, request.toMemberId());

        Instant now = clock.instant().truncatedTo(ChronoUnit.MICROS);
        UUID id = UUID.randomUUID();
        settlements.saveAndFlush(new Settlement(id, groupId, request.fromMemberId(), request.toMemberId(),
                request.amountMinor(), request.settledOn(), request.note(), userId, now));
        SettlementView view = new SettlementView(id, groupId, request.fromMemberId(), request.toMemberId(),
                request.amountMinor(), request.settledOn(), request.note(), now);
        String body = toJson(view);
        idempotency.store(userId, key, CREATE_ENDPOINT, requestHash, HttpStatus.CREATED.value(), body);
        metrics.counter("qesma.settlements", "op", "created").increment();
        log.atInfo().addKeyValue("event", "settlement.created").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("settlementId", id)
                .log("settlement.created userId={} groupId={} settlementId={}", userId, groupId, id);
        return new IdempotencyService.Outcome(HttpStatus.CREATED.value(), body, false);
    }

    @Transactional(readOnly = true)
    public Page<SettlementView> list(UUID userId, UUID groupId, int page, int size) {
        FieldRules.page(page, size);
        access.requireOwned(userId, groupId);
        return settlements.findPage(groupId, PageRequest.of(page, size)).map(SettlementService::view);
    }

    /** Soft delete: balances stop counting it. Deleting an already deleted settlement is a plain 404. */
    @Transactional
    public void delete(UUID userId, UUID groupId, UUID settlementId) {
        access.requireOwnedForUpdate(userId, groupId);
        Settlement settlement = settlements.findActive(settlementId, groupId).orElseThrow(ApiException::notFound);
        settlement.markDeleted(clock.instant().truncatedTo(ChronoUnit.MICROS));
        metrics.counter("qesma.settlements", "op", "deleted").increment();
        log.atInfo().addKeyValue("event", "settlement.deleted").addKeyValue("userId", userId)
                .addKeyValue("groupId", groupId).addKeyValue("settlementId", settlementId)
                .log("settlement.deleted userId={} groupId={} settlementId={}", userId, groupId, settlementId);
    }

    private static SettlementView view(Settlement s) {
        return new SettlementView(s.getId(), s.getGroupId(), s.getFromMemberId(), s.getToMemberId(),
                s.getAmountMinor(), s.getSettledOn(), s.getNote(), s.getCreatedAt());
    }

    /** Spec 6 notes: both members must belong to the settlement's group. */
    private static void requireMember(List<Member> members, UUID memberId) {
        if (members.stream().noneMatch(m -> m.getId().equals(memberId))) {
            throw new ApiException(ErrorCode.MEMBER_NOT_IN_GROUP, HttpStatus.UNPROCESSABLE_ENTITY,
                    "A referenced member is not part of this group");
        }
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
