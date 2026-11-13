package app.qesma.service;

import static app.qesma.service.SettlementTransitions.Action.CANCEL;
import static app.qesma.service.SettlementTransitions.Action.CONFIRM;
import static app.qesma.service.SettlementTransitions.Action.DISPUTE;
import static app.qesma.service.SettlementTransitions.Actor.MANAGER;
import static app.qesma.service.SettlementTransitions.Actor.PAYER;
import static app.qesma.service.SettlementTransitions.Actor.RECEIVER;
import static app.qesma.service.SettlementTransitions.Kind.FORBIDDEN;
import static app.qesma.service.SettlementTransitions.Kind.INVALID;
import static app.qesma.service.SettlementTransitions.Kind.NOOP;
import static app.qesma.service.SettlementTransitions.Kind.TRANSITION;
import static app.qesma.service.SettlementTransitions.Status.CANCELLED;
import static app.qesma.service.SettlementTransitions.Status.CONFIRMED;
import static app.qesma.service.SettlementTransitions.Status.DISPUTED;
import static app.qesma.service.SettlementTransitions.Status.PENDING;
import static org.assertj.core.api.Assertions.assertThat;

import app.qesma.service.SettlementTransitions.Action;
import app.qesma.service.SettlementTransitions.Actor;
import app.qesma.service.SettlementTransitions.Decision;
import app.qesma.service.SettlementTransitions.Kind;
import app.qesma.service.SettlementTransitions.Status;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** PHASE2_SPEC section 6, every cell: 4 statuses x 3 actions x 5 kinds of caller. */
class SettlementTransitionsTest {

    private static final Set<Actor> PAYER_ONLY = EnumSet.of(PAYER);
    private static final Set<Actor> RECEIVER_ONLY = EnumSet.of(RECEIVER);
    private static final Set<Actor> MANAGER_ONLY = EnumSet.of(MANAGER);
    private static final Set<Actor> MANAGER_WHO_PAYS = EnumSet.of(PAYER, MANAGER);
    private static final Set<Actor> STRANGER = EnumSet.noneOf(Actor.class);

    private static void expect(Status from, Action action, Set<Actor> who, Kind kind, Status to) {
        Decision d = SettlementTransitions.decide(from, action, who);
        assertThat(d.kind()).as("%s %s by %s", from, action, who).isEqualTo(kind);
        if (kind == TRANSITION) {
            assertThat(d.to()).as("target of %s %s", from, action).isEqualTo(to);
        }
    }

    @Test
    void pendingConfirm() {
        expect(PENDING, CONFIRM, RECEIVER_ONLY, TRANSITION, CONFIRMED);
        expect(PENDING, CONFIRM, MANAGER_ONLY, TRANSITION, CONFIRMED);
        expect(PENDING, CONFIRM, PAYER_ONLY, FORBIDDEN, null);
        expect(PENDING, CONFIRM, MANAGER_WHO_PAYS, FORBIDDEN, null);   // the payer never confirms their own payment
        expect(PENDING, CONFIRM, STRANGER, FORBIDDEN, null);
    }

    @Test
    void pendingDispute() {
        expect(PENDING, DISPUTE, RECEIVER_ONLY, TRANSITION, DISPUTED);
        expect(PENDING, DISPUTE, MANAGER_ONLY, FORBIDDEN, null);       // only the receiver says "not received"
        expect(PENDING, DISPUTE, PAYER_ONLY, FORBIDDEN, null);
        expect(PENDING, DISPUTE, MANAGER_WHO_PAYS, FORBIDDEN, null);
        expect(PENDING, DISPUTE, STRANGER, FORBIDDEN, null);
    }

    @Test
    void pendingCancel() {
        expect(PENDING, CANCEL, PAYER_ONLY, TRANSITION, CANCELLED);
        expect(PENDING, CANCEL, MANAGER_ONLY, TRANSITION, CANCELLED);
        expect(PENDING, CANCEL, MANAGER_WHO_PAYS, TRANSITION, CANCELLED);
        expect(PENDING, CANCEL, RECEIVER_ONLY, FORBIDDEN, null);
        expect(PENDING, CANCEL, STRANGER, FORBIDDEN, null);
    }

    @Test
    void disputedConfirm() {
        expect(DISPUTED, CONFIRM, RECEIVER_ONLY, TRANSITION, CONFIRMED);
        expect(DISPUTED, CONFIRM, MANAGER_ONLY, TRANSITION, CONFIRMED);
        expect(DISPUTED, CONFIRM, PAYER_ONLY, FORBIDDEN, null);
        expect(DISPUTED, CONFIRM, MANAGER_WHO_PAYS, FORBIDDEN, null);
        expect(DISPUTED, CONFIRM, STRANGER, FORBIDDEN, null);
    }

    @Test
    void disputedDisputeIsNoopForTheReceiverElseForbidden() {
        expect(DISPUTED, DISPUTE, RECEIVER_ONLY, NOOP, null);
        expect(DISPUTED, DISPUTE, MANAGER_ONLY, FORBIDDEN, null);
        expect(DISPUTED, DISPUTE, PAYER_ONLY, FORBIDDEN, null);
        expect(DISPUTED, DISPUTE, STRANGER, FORBIDDEN, null);
    }

    @Test
    void disputedCancel() {
        expect(DISPUTED, CANCEL, PAYER_ONLY, TRANSITION, CANCELLED);
        expect(DISPUTED, CANCEL, MANAGER_ONLY, TRANSITION, CANCELLED);
        expect(DISPUTED, CANCEL, RECEIVER_ONLY, FORBIDDEN, null);
        expect(DISPUTED, CANCEL, STRANGER, FORBIDDEN, null);
    }

    @Test
    void confirmedIsFinalRepeatingConfirmIsANoop() {
        expect(CONFIRMED, CONFIRM, RECEIVER_ONLY, NOOP, null);
        expect(CONFIRMED, CONFIRM, MANAGER_ONLY, NOOP, null);
        expect(CONFIRMED, CONFIRM, PAYER_ONLY, FORBIDDEN, null);
        expect(CONFIRMED, DISPUTE, RECEIVER_ONLY, INVALID, null);
        expect(CONFIRMED, CANCEL, PAYER_ONLY, INVALID, null);
        expect(CONFIRMED, CANCEL, MANAGER_ONLY, INVALID, null);
        expect(CONFIRMED, DISPUTE, STRANGER, FORBIDDEN, null);          // authorization before state
        expect(CONFIRMED, CANCEL, RECEIVER_ONLY, FORBIDDEN, null);
    }

    @Test
    void cancelledIsFinalRepeatingCancelIsANoop() {
        expect(CANCELLED, CANCEL, PAYER_ONLY, NOOP, null);
        expect(CANCELLED, CANCEL, MANAGER_ONLY, NOOP, null);
        expect(CANCELLED, CONFIRM, RECEIVER_ONLY, INVALID, null);
        expect(CANCELLED, CONFIRM, MANAGER_ONLY, INVALID, null);
        expect(CANCELLED, DISPUTE, RECEIVER_ONLY, INVALID, null);
        expect(CANCELLED, CANCEL, RECEIVER_ONLY, FORBIDDEN, null);
        expect(CANCELLED, CONFIRM, STRANGER, FORBIDDEN, null);
    }

    @Test
    void noActorEverLeavesAFinalState() {
        List<Set<Actor>> callers = List.of(PAYER_ONLY, RECEIVER_ONLY, MANAGER_ONLY, MANAGER_WHO_PAYS, STRANGER);
        for (Action a : Action.values()) {
            for (Set<Actor> who : callers) {
                assertThat(SettlementTransitions.decide(CONFIRMED, a, who).kind()).isNotEqualTo(TRANSITION);
                assertThat(SettlementTransitions.decide(CANCELLED, a, who).kind()).isNotEqualTo(TRANSITION);
            }
        }
    }
}
