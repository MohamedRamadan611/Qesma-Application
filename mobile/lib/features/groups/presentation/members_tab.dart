import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_problem.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/group_detail_controller.dart';
import 'group_dialogs.dart';
import 'group_ui.dart';
import 'member_sheets.dart';

/// Members tab: list with initials avatars, the "(you)" badge from `isYou`, add, rename,
/// delete. The owner's own member can be renamed but is never offered for deletion.
class MembersTab extends ConsumerWidget {
  const MembersTab({super.key, required this.group});

  final GroupDto group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(groupDetailControllerProvider(group.id).notifier);
    final busy = ref.watch(groupDetailControllerProvider(group.id)).busy;
    final members = group.members.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.all(QesmaSpacing.margin),
      children: [
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
        const SizedBox(height: QesmaSpacing.md),
        for (final member in members) ...[
          _MemberRow(
            member: member,
            busy: busy,
            onOptions: () => _options(context, controller, member),
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _options(BuildContext context, GroupDetailController controller, MemberDto member) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showAppBottomSheet<String>(
      context,
      title: member.displayName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (sheetContext) => AppButton(
              label: l10n.membersRename,
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(sheetContext).pop('rename'),
            ),
          ),
          if (!member.isYou) ...[
            const SizedBox(height: QesmaSpacing.sm),
            Builder(
              builder: (sheetContext) => AppButton(
                label: l10n.membersDelete,
                icon: Icons.delete_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(sheetContext).pop('delete'),
              ),
            ),
          ],
        ],
      ),
    );
    if (choice == null || !context.mounted) return;

    if (choice == 'rename') {
      await showMemberNameSheet(
        context,
        title: l10n.memberRenameTitle,
        initialName: member.displayName,
        onSave: (name) => name == member.displayName ? Future.value() : controller.renameMember(member.id, name),
      );
    } else {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.memberDeleteConfirmTitle,
        message: l10n.memberDeleteConfirmBody(member.displayName),
        confirmLabel: l10n.commonDelete,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller.deleteMember(member.id);
      if (failure == null || !context.mounted) return;
      switch (codeOf(failure)) {
        case ApiErrorCode.memberHasTransactions || ApiErrorCode.ownerMemberProtected:
          await showBlockedFor(context, failure);
        default:
          showFailureSnack(context, failure);
      }
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.busy, required this.onOptions});

  final MemberDto member;
  final bool busy;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.sm, QesmaSpacing.sm),
      child: Row(
        children: [
          MemberAvatar(memberId: member.id, name: member.displayName, size: 44),
          const SizedBox(width: QesmaSpacing.md),
          Expanded(
            child: Wrap(
              spacing: QesmaSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(member.displayName, style: theme.textTheme.titleMedium),
                if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
              ],
            ),
          ),
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
