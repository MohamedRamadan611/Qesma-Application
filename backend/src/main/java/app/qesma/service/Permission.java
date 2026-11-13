package app.qesma.service;

/** What a caller may do inside a group. Checked only through {@link GroupAccessService} (Decision A67). */
public enum Permission {
    /** Read the group, its members, expenses, balances, settlements; run an expense preview. */
    READ_GROUP,
    EDIT_GROUP,
    DELETE_GROUP,
    /** Add, rename and remove members. */
    MANAGE_MEMBERS,
    ADD_EXPENSE,
    ADD_SETTLEMENT,
    /** Edit or delete an expense the caller created. */
    EDIT_OWN_EXPENSE,
    /** Edit or delete an expense somebody else created. */
    EDIT_ANY_EXPENSE,
    /** Record a settlement on behalf of two other members, cancel or confirm one that is not yours (B13, Owner and Admin). */
    MANAGE_SETTLEMENTS,
    /** Create, list and revoke invitations (B11). */
    MANAGE_INVITES,
    /** Read and decide join requests (B11). */
    APPROVE_JOINS,
    /** Detach an account from a member, keeping the member and its history (B11). */
    UNLINK_MEMBER,
    /** Change a member's role between ADMIN and MEMBER (B12, Owner only). */
    CHANGE_ROLE,
    /** Make another member the owner (B12, Owner only). */
    TRANSFER_OWNERSHIP,
    /** Leave the group yourself (B12). The Owner holds it too, but gets 409 OWNER_MUST_TRANSFER. */
    LEAVE_GROUP,
    /** Remove a linked member from the group (status LEFT) or reactivate one (B12, Owner and Admin). */
    MANAGE_MEMBER_STATUS
}
