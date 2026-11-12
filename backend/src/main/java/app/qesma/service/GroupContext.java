package app.qesma.service;

import app.qesma.api.ApiException;
import app.qesma.domain.ExpenseGroup;
import app.qesma.domain.Member;
import java.util.UUID;

/** The group a caller may reach, the caller's own member in it and the role that decides what they may do. */
public record GroupContext(ExpenseGroup group, Member me, Role role) {

    public UUID groupId() {
        return group.getId();
    }

    public boolean can(Permission permission) {
        return role.allows(permission);
    }

    /**
     * Own-versus-any rule for a record somebody created: the creator needs the "own" permission, anybody else needs the
     * "any" permission. Throws 403 (the caller is a member, so nothing is revealed).
     */
    public void requireModify(UUID createdByUserId, Permission own, Permission any) {
        boolean mine = me.getUserId() != null && me.getUserId().equals(createdByUserId);
        if (!(mine ? role.allows(own) || role.allows(any) : role.allows(any))) {
            throw ApiException.forbidden();
        }
    }
}
