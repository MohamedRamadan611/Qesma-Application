package app.qesma.service;

import java.util.EnumSet;
import java.util.Set;

/** A member's role in a group and what it may do. The one place where roles meet permissions (PHASE2_SPEC section 2). */
public enum Role {
    OWNER(EnumSet.allOf(Permission.class)),
    ADMIN(EnumSet.of(Permission.READ_GROUP, Permission.EDIT_GROUP, Permission.MANAGE_MEMBERS,
            Permission.ADD_EXPENSE, Permission.ADD_SETTLEMENT, Permission.EDIT_OWN_EXPENSE,
            Permission.EDIT_ANY_EXPENSE, Permission.DELETE_OWN_SETTLEMENT, Permission.DELETE_ANY_SETTLEMENT,
            Permission.MANAGE_INVITES, Permission.APPROVE_JOINS, Permission.UNLINK_MEMBER,
            Permission.LEAVE_GROUP, Permission.MANAGE_MEMBER_STATUS)),
    MEMBER(EnumSet.of(Permission.READ_GROUP, Permission.ADD_EXPENSE, Permission.ADD_SETTLEMENT,
            Permission.EDIT_OWN_EXPENSE, Permission.DELETE_OWN_SETTLEMENT, Permission.LEAVE_GROUP));

    private final Set<Permission> permissions;

    Role(Set<Permission> permissions) {
        this.permissions = permissions;
    }

    public boolean allows(Permission permission) {
        return permissions.contains(permission);
    }
}
