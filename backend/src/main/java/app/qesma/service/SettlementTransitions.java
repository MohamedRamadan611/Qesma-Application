package app.qesma.service;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * The settlement state machine of PHASE2_SPEC section 6 as ONE table: {@code (from, action) -> (to, allowed actors)}.
 * Pure: no Spring, no I/O. The service computes the caller's actor set and persists the result.
 *
 * <p>Evaluation order (authorization before state, so a stranger learns nothing about the state):
 * <ol>
 *   <li>the caller may never perform this action in any state -> {@link Kind#FORBIDDEN};</li>
 *   <li>the settlement is already in the action's target state -> {@link Kind#NOOP} (idempotent repeat);</li>
 *   <li>no table row for (state, action) -> {@link Kind#INVALID} (409 INVALID_STATE_TRANSITION);</li>
 *   <li>otherwise {@link Kind#TRANSITION}.</li>
 * </ol>
 */
public final class SettlementTransitions {

    public enum Status { PENDING, CONFIRMED, DISPUTED, CANCELLED }

    public enum Action { CONFIRM, DISPUTE, CANCEL }

    /** What the caller is on this settlement: the payer (from), the receiver (to), a manager (Owner/Admin). */
    public enum Actor { PAYER, RECEIVER, MANAGER }

    public enum Kind { TRANSITION, NOOP, FORBIDDEN, INVALID }

    public record Decision(Kind kind, Status to) {
    }

    private record Row(Status from, Action action, Status to, Set<Actor> who) {
    }

    private static final List<Row> TABLE = List.of(
            new Row(Status.PENDING, Action.CONFIRM, Status.CONFIRMED, EnumSet.of(Actor.RECEIVER, Actor.MANAGER)),
            new Row(Status.PENDING, Action.DISPUTE, Status.DISPUTED, EnumSet.of(Actor.RECEIVER)),
            new Row(Status.PENDING, Action.CANCEL, Status.CANCELLED, EnumSet.of(Actor.PAYER, Actor.MANAGER)),
            new Row(Status.DISPUTED, Action.CONFIRM, Status.CONFIRMED, EnumSet.of(Actor.RECEIVER, Actor.MANAGER)),
            new Row(Status.DISPUTED, Action.CANCEL, Status.CANCELLED, EnumSet.of(Actor.PAYER, Actor.MANAGER)));

    private SettlementTransitions() {
    }

    public static Status target(Action action) {
        return switch (action) {
            case CONFIRM -> Status.CONFIRMED;
            case DISPUTE -> Status.DISPUTED;
            case CANCEL -> Status.CANCELLED;
        };
    }

    public static Decision decide(Status current, Action action, Set<Actor> actors) {
        Set<Actor> effective = effective(action, actors);
        if (TABLE.stream().noneMatch(r -> r.action() == action && intersects(r.who(), effective))) {
            return new Decision(Kind.FORBIDDEN, null);
        }
        if (current == target(action)) {
            return new Decision(Kind.NOOP, null);
        }
        for (Row r : TABLE) {
            if (r.from() == current && r.action() == action) {
                return intersects(r.who(), effective) ? new Decision(Kind.TRANSITION, r.to())
                        : new Decision(Kind.FORBIDDEN, null);
            }
        }
        return new Decision(Kind.INVALID, null);
    }

    /** The payer never confirms their own payment, not even as an Admin/Owner. */
    private static Set<Actor> effective(Action action, Set<Actor> actors) {
        if (action == Action.CONFIRM && actors.contains(Actor.PAYER)) {
            Set<Actor> copy = EnumSet.noneOf(Actor.class);
            copy.addAll(actors);
            copy.remove(Actor.MANAGER);
            return copy;
        }
        return actors;
    }

    private static boolean intersects(Set<Actor> a, Set<Actor> b) {
        for (Actor x : a) {
            if (b.contains(x)) {
                return true;
            }
        }
        return false;
    }
}
