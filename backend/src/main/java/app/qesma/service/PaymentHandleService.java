package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.persistence.PaymentHandleQuery;
import app.qesma.persistence.PaymentHandleStore;
import io.micrometer.core.instrument.MeterRegistry;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Payment handles (B14, A90-A94). A user manages only their own through {@code /me}; co-members see a receiver's
 * handles only through {@link #visibleForReceivers}. The values are never logged: log lines carry ids and the types
 * that changed.
 */
@Service
public class PaymentHandleService {

    private static final Logger log = LoggerFactory.getLogger(PaymentHandleService.class);

    private final PaymentHandleStore store;
    private final PaymentHandleQuery query;
    private final MeterRegistry metrics;

    public PaymentHandleService(PaymentHandleStore store, PaymentHandleQuery query, MeterRegistry metrics) {
        this.store = store;
        this.query = query;
        this.metrics = metrics;
    }

    @Transactional(readOnly = true)
    public PaymentHandlesView get(UUID userId) {
        return view(store.findByUser(userId));
    }

    /** Replaces both handles: a null or blank value removes that one. Validation first, so a bad request changes nothing. */
    @Transactional
    public PaymentHandlesView replace(UUID userId, String rawInstapay, String rawWallet) {
        String instapay = PaymentHandleRules.instapay(rawInstapay);
        String wallet = PaymentHandleRules.wallet(rawWallet);
        if (!store.lockUser(userId)) {
            throw ApiException.unauthorized();
        }
        Map<String, String> before = store.findByUser(userId);
        apply(userId, PaymentHandleStore.INSTAPAY, instapay, before);
        apply(userId, PaymentHandleStore.WALLET, wallet, before);
        return new PaymentHandlesView(instapay, wallet);
    }

    private void apply(UUID userId, String type, String value, Map<String, String> before) {
        boolean had = before.containsKey(type);
        if (value == null) {
            if (had) {
                store.delete(userId, type);
                changed(userId, type, "removed");
            }
        } else if (!value.equals(before.get(type))) {
            store.upsert(userId, type, value);
            changed(userId, type, "set");
        }
    }

    private void changed(UUID userId, String type, String change) {
        metrics.counter("qesma.payment_handles.updated", "change", change).increment();
        log.atInfo().addKeyValue("event", "payment_handles.updated").addKeyValue("userId", userId)
                .log("payment_handles.updated userId={} type={} change={}", userId, type, change);
    }

    /** Deletes every handle of a user (account deletion, B17). */
    @Transactional
    public void deleteAllFor(UUID userId) {
        store.deleteAll(userId);
    }

    /**
     * The handles of the given receiver members, for the viewer of {@code ctx}: ONE statement. Members without a
     * visible handle are absent from the map.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public Map<UUID, PaymentHandlesView> visibleForReceivers(GroupContext ctx, Collection<UUID> receiverMemberIds) {
        UUID viewer = ctx.me().getUserId();
        if (viewer == null || receiverMemberIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, Map<String, String>> byMember = new HashMap<>();
        for (PaymentHandleQuery.Row r : query.visibleTo(viewer, ctx.groupId(), receiverMemberIds)) {
            byMember.computeIfAbsent(r.memberId(), k -> new HashMap<>()).put(r.type(), r.value());
        }
        Map<UUID, PaymentHandlesView> out = new HashMap<>();
        byMember.forEach((member, handles) -> out.put(member, view(handles)));
        return out;
    }

    private static PaymentHandlesView view(Map<String, String> byType) {
        return new PaymentHandlesView(byType.get(PaymentHandleStore.INSTAPAY), byType.get(PaymentHandleStore.WALLET));
    }
}
