import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_problem.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/permissions/group_role.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../invites/presentation/invite_sheet.dart';
import '../../members/application/join_requests_controller.dart';
import '../../members/application/member_actions.dart';
import '../../members/presentation/member_flows.dart';
import '../../members/presentation/member_options_sheet.dart';
import '../application/group_detail_controller.dart';
import '../application/group_permissions.dart';
import 'group_dialogs.dart';
import 'member_sheets.dart';

/// Members tab (P12-03): list with initials avatars, the "(you)" badge, the account badge (linked / name only),
/// role chips, LEFT members greyed but kept, the join-requests banner and the lifecycle actions of FL12.
/// What is shown only follows `Permissions`; the server decides and every call handles 403/404/409/422.
class MembersTab extends ConsumerWidget {
  const MembersTab({super.key, required this.group});

  final GroupDto group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(groupDetailControllerProvider(group.id).notifier);
    final busy = ref.watch(groupDetailControllerProvider(group.id)).busy;
    final members = group.members.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final permissions = ref.watch(groupPermissionsProvider(group.id));
    final canManage = permissions.canManageMembers;
    final canInvite = permissions.canManageInvites;
    final pendingRequests = permissions.canApproveJoins ? ref.watch(joinRequestsControllerProvider(group.id)).items.length : 0;

    return RefreshIndicator(
      onRefresh: () async {
        await controller.load();
        if (permissions.canApproveJoins) await ref.read(joinRequestsControllerProvider(group.id).notifier).load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          if (pendingRequests > 0) ...[
            _JoinRequestsBanner(count: pendingRequests, onTap: () => context.push(Routes.joinRequests(group.id))),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          if (canManage) ...[
            AppButton(
              label: l10n.membersAdd,
              icon: Icons.person_add_alt,
              variant: AppButtonVariant.secondary,
              onPressed: busy
                  ? null
                  : () => showMemberNameSheet(
                        context,
                        title: l10n.memberAddTitle,
                        subtitle: l10n.memberAddSubtitle,
                        onSave: (name) async {
                          final failure = await controller.addMember(name);
                          // The reply may have been lost although the member exists: show the real list.
                          if (failure != null && codeOf(failure) == ApiErrorCode.duplicateMemberName) await controller.load();
                          return failure;
                        },
                      ),
            ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          if (canInvite) ...[
            AppButton(
              label: l10n.inviteAction,
              icon: Icons.group_add,
              variant: AppButtonVariant.secondary,
              onPressed: () => showInviteSheet(context, gid: group.id, groupName: group.name),
            ),
          ],
          if (canManage || canInvite) const SizedBox(height: QesmaSpacing.md),
          for (final member in members) ...[
            Builder(builder: (context) {
              final actions = memberActionsFor(viewer: permissions, target: member);
              return _MemberRow(
                member: member,
                busy: busy,
                onOptions: actions.isEmpty ? null : () => _options(context, ref, member, actions),
              );
            }),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          if (permissions.canTransferOwnership) ...[
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.membersTransfer,
              icon: Icons.swap_horiz,
              variant: AppButtonVariant.secondary,
              onPressed: busy ? null : () => runTransferFlow(context, ref, group),
            ),
          ],
          if (permissions.canLeave) ...[
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.membersLeave,
              icon: Icons.logout,
              variant: AppButtonVariant.secondary,
              onPressed: busy ? null : () => runLeaveFlow(context, ref, group),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _options(BuildContext context, WidgetRef ref, MemberDto member, Set<MemberAction> actions) async {
    final choice = await showMemberOptionsSheet(context, member: member, actions: actions);
    if (choice == null || !context.mounted) return;
    await runMemberAction(context, ref, group: group, member: member, action: choice);
  }
}

class _JoinRequestsBanner extends StatelessWidget {
  const _JoinRequestsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      color: colors.warningContainer,
      child: Row(
        children: [
          Icon(Icons.how_to_reg_outlined, color: colors.textPrimary),
          const SizedBox(width: QesmaSpacing.md),
          Expanded(child: Text(l10n.inviteRequestsBanner(count.toString()), style: Theme.of(context).textTheme.titleMedium)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.busy, required this.onOptions});

  final MemberDto member;
  final bool busy;
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final left = member.status == 'LEFT';
    final role = GroupRole.parse(member.role);
    final content = Row(
      children: [
        MemberAvatar(memberId: member.id, name: member.displayName, size: 44),
        const SizedBox(width: QesmaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: QesmaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(member.displayName, style: theme.textTheme.titleMedium),
                  if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
                ],
              ),
              const SizedBox(height: QesmaSpacing.xs),
              // Every badge is icon + text: never colour alone.
              Wrap(
                spacing: QesmaSpacing.xs,
                runSpacing: QesmaSpacing.xs,
                children: [
                  if (role == GroupRole.owner) AppTag(label: l10n.membersRoleOwner, tone: AppTagTone.primary, icon: Icons.workspace_premium_outlined),
                  if (role == GroupRole.admin) AppTag(label: l10n.membersRoleAdmin, tone: AppTagTone.info, icon: Icons.verified_user_outlined),
                  if (member.hasAccount)
                    AppTag(label: l10n.membersBadgeConnected, tone: AppTagTone.success, icon: Icons.link)
                  else
                    AppTag(label: l10n.membersBadgeNameOnly, icon: Icons.person_outline),
                  if (left) AppTag(label: l10n.membersLeftChip, tone: AppTagTone.warning, icon: Icons.logout),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.sm, QesmaSpacing.sm),
      child: Row(
        children: [
          // A member who left is greyed (and says so in the chip), never hidden.
          Expanded(child: left ? Opacity(opacity: 0.6, child: content) : content),
          if (onOptions != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n.membersOptions(member.displayName),
              onPressed: busy ? null : onOptions,
            ),
        ],
      ),
    );
  }
}
