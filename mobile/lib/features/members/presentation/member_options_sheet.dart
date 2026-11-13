import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/member_actions.dart';

/// Order of the rows: the role and lifecycle actions first, the Phase 1 rename and delete last.
const _order = [
  MemberAction.promote,
  MemberAction.demote,
  MemberAction.transferOwnership,
  MemberAction.unlink,
  MemberAction.markLeft,
  MemberAction.reactivate,
  MemberAction.rename,
  MemberAction.delete,
];

({IconData icon, String title, String? hint}) _copy(AppLocalizations l10n, MemberAction action) => switch (action) {
      MemberAction.promote => (icon: Icons.verified_user_outlined, title: l10n.membersActionPromote, hint: l10n.membersActionPromoteHint),
      MemberAction.demote => (icon: Icons.remove_moderator_outlined, title: l10n.membersActionDemote, hint: l10n.membersActionDemoteHint),
      MemberAction.transferOwnership => (icon: Icons.swap_horiz, title: l10n.membersActionTransfer, hint: l10n.membersActionTransferHint),
      MemberAction.unlink => (icon: Icons.link_off, title: l10n.membersActionUnlink, hint: l10n.membersActionUnlinkHint),
      MemberAction.markLeft => (icon: Icons.logout, title: l10n.membersActionMarkLeft, hint: l10n.membersActionMarkLeftHint),
      MemberAction.reactivate => (icon: Icons.settings_backup_restore, title: l10n.membersActionReactivate, hint: l10n.membersActionReactivateHint),
      MemberAction.rename => (icon: Icons.edit_outlined, title: l10n.membersRename, hint: null),
      MemberAction.delete => (icon: Icons.delete_outline, title: l10n.membersDelete, hint: null),
    };

/// Options of one member (P12-03). Shows exactly [actions] (decided by [memberActionsFor]); returns the chosen one.
Future<MemberAction?> showMemberOptionsSheet(BuildContext context, {required MemberDto member, required Set<MemberAction> actions}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<MemberAction>(
    context,
    title: l10n.membersOptions(member.displayName),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in _order)
          if (actions.contains(action)) ...[
            Builder(
              builder: (sheetContext) {
                final copy = _copy(l10n, action);
                final destructive = action == MemberAction.delete || action == MemberAction.markLeft || action == MemberAction.unlink;
                return _OptionRow(
                  icon: copy.icon,
                  title: copy.title,
                  hint: copy.hint,
                  destructive: destructive,
                  onTap: () => Navigator.of(sheetContext).pop(action),
                );
              },
            ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
      ],
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.title, required this.hint, required this.destructive, required this.onTap});

  final IconData icon;
  final String title;
  final String? hint;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final fg = destructive ? colors.error : colors.textPrimary;
    return Semantics(
      button: true,
      label: hint == null ? title : '$title. $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(QesmaRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.card),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.md),
              child: Row(
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: QesmaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                        if (hint != null) Text(hint!, style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
