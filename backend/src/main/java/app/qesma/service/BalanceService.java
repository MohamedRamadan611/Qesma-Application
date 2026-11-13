package app.qesma.service;

import app.qesma.domain.Member;
import app.qesma.engine.BalanceCalculator;
import app.qesma.engine.EngineException;
import app.qesma.engine.MemberRef;
import app.qesma.engine.Simplifier;
import app.qesma.persistence.BalanceTotalsQuery;
import app.qesma.persistence.PendingPairsQuery;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

    public BalanceService(GroupAccessService access, BalanceTotalsQuery totals, PendingPairsQuery pending,
                          MeterRegistry metrics) {
        this.access = access;
        this.totals = totals;
        this.pending = pending;
        this.metrics = metrics;
    }

    /** One snapshot for the roster and the sums, so concurrent writes cannot skew the result. */
    @Transactional(readOnly = true, isolation = Isolation.REPEATABLE_READ)
    public BalanceView balances(UUID userId, UUID groupId) {
        GroupContext ctx = access.requireMember(userId, groupId);
        return metrics.timer("qesma.balances.compute").record(() -> compute(ctx, groupId));
    }

    private BalanceView compute(GroupContext ctx, UUID groupId) {
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
        List<BalanceView.Net> netViews = nets.entrySet().stream()
                .map(e -> new BalanceView.Net(UUID.fromString(e.getKey()), e.getValue())).toList();
        Map<Pair, PendingPairsQuery.Pair> open = new HashMap<>();
        for (PendingPairsQuery.Pair p : pending.pairs(groupId)) {
            open.put(new Pair(p.fromMemberId(), p.toMemberId()), p);
        }
        List<BalanceView.TransferView> transfers = Simplifier.simplify(nets, roster).stream().map(t -> {
            UUID from = UUID.fromString(t.fromMemberId());
            UUID to = UUID.fromString(t.toMemberId());
            PendingPairsQuery.Pair p = open.get(new Pair(from, to));
            return p == null ? new BalanceView.TransferView(from, to, t.amountMinor(), 0L, false, List.of())
                    : new BalanceView.TransferView(from, to, t.amountMinor(), p.pendingMinor(), p.hasDispute(),
                            p.ids());
        }).toList();
        return new BalanceView(netViews, transfers);
    }
}
