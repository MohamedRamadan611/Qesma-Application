import 'package:qesma_api/qesma_api.dart';

import '../../../core/permissions/group_role.dart';
import '../../../core/permissions/permissions.dart';

/// What the options sheet of one member can offer (FL12). Only a UI decision: the server is the authority and
/// every action still handles `403 FORBIDDEN`, `404` and `409`/`422`.
enum MemberAction { rename, delete, promote, demote, unlink, markLeft, reactivate, transferOwnership }

/// The actions the [viewer] may be offered for [target], from the viewer's role and the target's state.
/// Pure: no I/O, no state. The matrix is in `.claude/mobile/SCREEN_MAP.md` and the FL12 plan.
Set<MemberAction> memberActionsFor({required Permissions viewer, required MemberDto target}) {
  if (!viewer.canManageMembers) return const {};

  final role = GroupRole.parse(target.role);
  final left = target.status == 'LEFT';
  final linked = target.hasAccount;
  final self = target.isYou;
  final targetIsOwner = role == GroupRole.owner;
  // Only the Owner acts on an Admin (B11: unlinking an admin needs the owner).
  final mayActOnTarget = role != GroupRole.admin || viewer.canChangeRoles;

  return {
    MemberAction.rename,
    // Ghosts only: a person with an account leaves, or is unlinked first.
    if (!self && !linked && role == GroupRole.member) MemberAction.delete,
    if (viewer.canChangeRoles && !left && !self && linked && role == GroupRole.member) MemberAction.promote,
    if (viewer.canChangeRoles && !left && !self && role == GroupRole.admin) MemberAction.demote,
    if (viewer.canUnlinkMember && !left && !self && linked && !targetIsOwner && mayActOnTarget) MemberAction.unlink,
    if (!left && !self && !targetIsOwner && mayActOnTarget) MemberAction.markLeft,
    if (left) MemberAction.reactivate,
    if (viewer.canTransferOwnership && !left && !self && linked) MemberAction.transferOwnership,
  };
}

/// Active members with an account, other than the viewer: who ownership can be handed to.
List<MemberDto> transferCandidates(Iterable<MemberDto> members) =>
    members.where((m) => m.status != 'LEFT' && m.hasAccount && !m.isYou).toList();
