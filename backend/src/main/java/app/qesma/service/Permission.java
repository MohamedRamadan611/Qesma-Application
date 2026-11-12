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
    DELETE_OWN_SETTLEMENT,
    DELETE_ANY_SETTLEMENT,
    /** Create, list and revoke invitations (B11). */
    MANAGE_INVITES,
    /** Read and decide join requests (B11). */
    APPROVE_JOINS,
    /** Detach an account from a member, keeping the member and its history (B11). */
    UNLINK_MEMBER
}
