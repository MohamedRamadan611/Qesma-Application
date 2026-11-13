package app.qesma.service;

/**
 * The event catalogue (PHASE2_SPEC section 8, B15 A98). The names are stored in {@code group_events.type} (CHECK
 * {@code ck_group_events_type}) and sent to clients, so they are stable. B16 adds REMINDER with a new constraint.
 */
public enum EventType {
    EXPENSE_ADDED,
    EXPENSE_EDITED,
    EXPENSE_DELETED,
    SETTLEMENT_PENDING,
    SETTLEMENT_CONFIRMED,
    SETTLEMENT_DISPUTED,
    SETTLEMENT_CANCELLED,
    INVITE_ACCEPTED,
    JOIN_REQUESTED,
    MEMBER_JOINED,
    MEMBER_LEFT,
    /** Added by B15 (rule 2.4: every role/status change is an event). */
    MEMBER_REACTIVATED,
    /** Added by B15: an account was detached from a member. Feed only, the account has no access any more. */
    MEMBER_UNLINKED,
    ROLE_CHANGED,
    OWNERSHIP_TRANSFERRED
}
