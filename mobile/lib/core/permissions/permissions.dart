import 'group_role.dart';

/// What a role may do in a group, mirroring the matrix of PHASE2_SPEC section 2.
///
/// This only decides what the UI **shows or enables**. The server is the authority: every call still handles
/// `403 FORBIDDEN` and `404 NOT_FOUND`, so a wrong or stale role can never grant anything.
///
/// Not decidable here: editing or deleting an expense or a payment ("own" for every member, "any" for admins),
/// because the API does not say who created it. Those buttons stay visible and a 403 is handled.
class Permissions {
  const Permissions(this.role);

  /// Nothing privileged is shown until the group (and so the role) is known.
  const Permissions.unknown() : role = GroupRole.member;

  final GroupRole role;

  bool get _isOwner => role == GroupRole.owner;
  bool get _isAdminOrOwner => role == GroupRole.owner || role == GroupRole.admin;

  /// Rename the group, change its type.
  bool get canEditGroup => _isAdminOrOwner;

  /// Delete the group (the server still refuses while it has expenses or payments).
  bool get canDeleteGroup => _isOwner;

  /// Add, rename and remove members.
  bool get canManageMembers => _isAdminOrOwner;

  /// Create, list and revoke invitations (FL11).
  bool get canManageInvites => _isAdminOrOwner;

  /// Read and decide join requests (FL12).
  bool get canApproveJoins => _isAdminOrOwner;

  /// Detach an account from a member (FL12).
  bool get canUnlinkMember => _isAdminOrOwner;

  /// Promote a member to admin and demote one (FL12).
  bool get canChangeRoles => _isOwner;

  /// Hand the group to another member (FL12).
  bool get canTransferOwnership => _isOwner;

  /// Leave the group: everybody except the owner, who must transfer ownership first (FL12).
  bool get canLeave => !_isOwner;

  /// Add expenses and record payments: every member (the same for all roles).
  bool get canAddExpense => true;

  @override
  bool operator ==(Object other) => other is Permissions && other.role == role;

  @override
  int get hashCode => role.hashCode;
}
