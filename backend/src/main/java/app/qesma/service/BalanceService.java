package app.qesma.service;

import app.qesma.domain.Member;
import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.EngineException;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Simplifier;
import app.qesma.engine.Transfer;
import app.qesma.persistence.BalanceTotalsQuery;
import app.qesma.persistence.PendingPairsQuery;
import app.qesma.persistence.RemindLogStore;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Clock;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Net balances and suggested transfers, never stored (invariant 4). The database only adds up per-member sums in
 * one statement (CONFIRMED settlements only, A83); the rule and the zero-sum invariant are the engine's. A second
 * grouped statement adds the informational PENDING/DISPUTED data per transfer pair. If the invariant is ever violated
 * the call fails loudly (500) instead of returning wrong money.
 */
@Service
public class BalanceService {

    private static final Logger log = LoggerFactory.getLogger(BalanceService.class);

    private record Pair(UUID from, UUID to) {
    }

    private final GroupAccessService access;
    private final BalanceTotalsQuery totals;
    private final PendingPairsQuery pending;
    private final MeterRegistry metrics;
    private final PaymentHandleService paymentHandles;
    private final RemindLogStore remindLog;
    private final RemindProperties remindProps;
    private final Clock clock;

    public BalanceService(GroupAccessService access, BalanceTotalsQuery totals, PendingPairsQuery pending,
                          MeterRegistry metrics, PaymentHandleService paymentHandles, RemindLogStore remindLog,
                          RemindProperties remindProps, Clock clock) {
        this.remindLog = remindLog;
        this.remindProps = remindProps;
        this.clock = clock;
        this.access = access;
        this.totals = totals;
        this.pending = pending;
        this.paymentHandles = paymentHandles;
        this.metrics = metrics;
    }

    /** One snapshot for the roster and the sums, so concurrent writes cannot skew the result. */
    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public BalanceView balances(UUID userId, UUID groupId) {
        GroupContext ctx = access.requireMember(userId, groupId);
        return metrics.timer("qesma.balances.compute").record(() -> compute(ctx, groupId));
    }

    /** The members, the nets and the suggested transfers of one group, from one set of reads (shared with Remind, B16). */
    record Suggestion(List<Member> members, Map<String, Long> nets, List<Transfer> transfers) {
    }

    /**
     * Roster + one grouped totals statement + the engine (CONFIRMED settlements only, A83). The single place where the
     * suggested transfers are derived, so Remind sees exactly what GET balances shows. If the zero-sum invariant is
     * violated the call fails loudly (500).
     */
    Suggestion suggestion(GroupContext ctx) {
        UUID groupId = ctx.groupId();
        List<Member> members = access.listMembers(ctx);
        List<MemberRef> roster = members.stream()
                .map(m -> new MemberRef(m.getId().toString(), m.getSortOrder())).toList();
        Map<String, Long> nets;
        try {
            nets = BalanceCalculator.netsFromTotals(roster, totals.totals(groupId));
        } catch (EngineException e) {
            metrics.counter("qesma.balances.invariant_violations").increment();
            log.atError().addKeyValue("event", "balance.invariant_violated").addKeyValue("groupId", groupId)
                    .log("balance.invariant_violated groupId={} reason={}", groupId, e.getMessage());
            throw new IllegalStateException("Balance invariant violated for group " + groupId, e);
        }
        return new Suggestion(members, nets, Simplifier.simplify(nets, roster));
    }

    private BalanceView compute(GroupContext ctx, UUID groupId) {
        Suggestion s = suggestion(ctx);
        Map<String, Long> nets = s.nets();
        List<BalanceView.Net> netViews = nets.entrySet().stream()
                .map(e -> new BalanceView.Net(UUID.fromString(e.getKey()), e.getValue())).toList();
        Map<Pair, PendingPairsQuery.Pair> open = new HashMap<>();
        for (PendingPairsQuery.Pair p : pending.pairs(groupId)) {
            open.put(new Pair(p.fromMemberId(), p.toMemberId()), p);
        }
        List<Transfer> suggested = s.transfers();
        Map<UUID, PaymentHandlesView> handles = handlesOf(ctx, suggested);
        // B16 (A109): ONE grouped statement for the whole group, however many transfers
        Instant now = clock.instant();
        Map<UUID, Instant> lastReminded = remindLog.lastPerDebtor(groupId, now.minus(remindProps.window()));
        List<BalanceView.TransferView> transfers = suggested.stream().map(t -> {
            UUID from = UUID.fromString(t.fromMemberId());
            UUID to = UUID.fromString(t.toMemberId());
            PendingPairsQuery.Pair p = open.get(new Pair(from, to));
            PaymentHandlesView receiverHandles = handles.get(to);
            Instant last = lastReminded.get(from);
            Instant canRemindAt = last == null ? null : last.plus(remindProps.window());
            if (canRemindAt != null && !canRemindAt.isAfter(now)) {
                canRemindAt = null;
            }
            return p == null ? new BalanceView.TransferView(from, to, t.amountMinor(), 0L, false, List.of(),
                    receiverHandles, canRemindAt)
                    : new BalanceView.TransferView(from, to, t.amountMinor(), p.pendingMinor(), p.hasDispute(),
                            p.ids(), receiverHandles, canRemindAt);
        }).toList();
        return new BalanceView(netViews, transfers);
    }

    /**
     * Whose handles this viewer may see on these transfers (A91): the receivers of the transfers the viewer pays, or every
     * receiver for Owner/Admin. ONE batched statement for all of them (never one per transfer).
     */
    private Map<UUID, PaymentHandlesView> handlesOf(GroupContext ctx, List<Transfer> suggested) {
        boolean all = ctx.can(Permission.VIEW_ALL_PAYMENT_HANDLES);
        UUID me = ctx.me().getId();
        Set<UUID> receivers = new HashSet<>();
        for (Transfer t : suggested) {
            if (all || t.fromMemberId().equals(me.toString())) {
                receivers.add(UUID.fromString(t.toMemberId()));
            }
        }
        return paymentHandles.visibleForReceivers(ctx, receivers);
    }
}
