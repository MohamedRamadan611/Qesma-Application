import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/presentation/group_dialogs.dart';
import '../../groups/presentation/group_ui.dart';
import '../../groups/presentation/member_sheets.dart';
import '../application/member_actions.dart';

/// Runs one action chosen in the options sheet: confirmation (when it changes who can do what), the call, then the
/// error handling. The group (so the members, roles and statuses) is re-read by the controller after each success;
/// roles are never edited locally.
Future<void> runMemberAction(
  BuildContext context,
  WidgetRef ref, {
  required GroupDto group,
  required MemberDto member,
  required MemberAction action,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(groupDetailControllerProvider(group.id).notifier);
  final name = member.displayName;

  switch (action) {
    case MemberAction.rename:
      await showMemberNameSheet(
        context,
        title: l10n.memberRenameTitle,
        initialName: name,
        onSave: (value) => value == name ? Future.value() : controller.renameMember(member.id, value),
      );
    case MemberAction.delete:
      if (!await showConfirmDialog(
        context,
        title: l10n.memberDeleteConfirmTitle,
        message: l10n.memberDeleteConfirmBody(name),
        confirmLabel: l10n.commonDelete,
        destructive: true,
      )) {
        return;
      }
      final failure = await controller.deleteMember(member.id);
      if (!context.mounted) return;
      await _finish(context, controller, failure);
    case MemberAction.promote:
      if (!await showConfirmDialog(
        context,
        title: l10n.memberPromoteConfirmTitle(name),
        message: l10n.memberPromoteConfirmBody(name),
        confirmLabel: l10n.memberPromoteConfirmAction,
      )) {
        return;
      }
      final failure = await controller.setRole(member.id, 'ADMIN');
      if (!context.mounted) return;
      await _finish(context, controller, failure);
    case MemberAction.demote:
      if (!await showConfirmDialog(
        context,
        title: l10n.memberDemoteConfirmTitle(name),
        message: l10n.memberDemoteConfirmBody(name),
        confirmLabel: l10n.memberDemoteConfirmAction,
      )) {
        return;
      }
      final failure = await controller.setRole(member.id, 'MEMBER');
      if (!context.mounted) return;
      await _finish(context, controller, failure);
    case MemberAction.unlink:
      if (!await showConfirmDialog(
        context,
        title: l10n.memberUnlinkConfirmTitle(name),
        message: l10n.memberUnlinkConfirmBody(name),
        confirmLabel: l10n.memberUnlinkConfirmAction,
        destructive: true,
      )) {
        return;
      }
      final failure = await controller.unlinkMember(member.id);
      if (!context.mounted) return;
      await _finish(context, controller, failure);
    case MemberAction.markLeft:
      if (!await showConfirmDialog(
        context,
        title: l10n.memberMarkLeftConfirmTitle(name),
        message: l10n.memberMarkLeftConfirmBody(name),
        confirmLabel: l10n.memberMarkLeftConfirmAction,
        destructive: true,
      )) {
        return;
      }
      final failure = await controller.setStatus(member.id, 'LEFT');
      if (!context.mounted) return;
      await _finish(context, controller, failure);
    case MemberAction.reactivate:
      final failure = await controller.setStatus(member.id, 'ACTIVE');
      if (!context.mounted) return;
      await _finish(context, controller, failure, success: l10n.memberReactivatedNotice(name));
    case MemberAction.transferOwnership:
      await _confirmAndTransfer(context, ref, group, member);
  }
}

/// "Transfer ownership" from the tab: pick an ACTIVE linked member, confirm, call.
Future<void> runTransferFlow(BuildContext context, WidgetRef ref, GroupDto group) async {
  final picked = await showTransferPicker(context, transferCandidates(group.members));
  if (picked == null || !context.mounted) return;
  await _confirmAndTransfer(context, ref, group, picked);
}

Future<void> _confirmAndTransfer(BuildContext context, WidgetRef ref, GroupDto group, MemberDto target) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(groupDetailControllerProvider(group.id).notifier);
  if (!await showConfirmDialog(
    context,
    title: l10n.memberTransferConfirmTitle(target.displayName),
    message: l10n.memberTransferConfirmBody(target.displayName),
    confirmLabel: l10n.memberTransferConfirmAction,
    destructive: true,
  )) {
    return;
  }
  if (!context.mounted) return;
  final failure = await controller.transferOwnership(target.id);
  if (!context.mounted) return;
  await _finish(context, controller, failure, success: l10n.memberTransferDoneNotice);
}

/// "Leave group" (non-owners): confirm, call, then back to the groups list (the group is gone for this person).
/// `OWNER_MUST_TRANSFER` (a stale role) sends the owner to the transfer flow.
Future<void> runLeaveFlow(BuildContext context, WidgetRef ref, GroupDto group) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(groupDetailControllerProvider(group.id).notifier);
  if (!await showConfirmDialog(
    context,
    title: l10n.groupLeaveConfirmTitle,
    message: l10n.groupLeaveConfirmBody,
    confirmLabel: l10n.groupLeaveConfirmAction,
    destructive: true,
  )) {
    return;
  }
  if (!context.mounted) return;
  final failure = await controller.leave();
  if (!context.mounted) return;
  if (failure == null) {
    showAppSnackBar(context, l10n.groupLeftNotice);
    context.go(Routes.home);
    return;
  }
  if (codeOf(failure) == ApiErrorCode.ownerMustTransfer) {
    await controller.load(); // the role caught up: this person is the owner
    if (!context.mounted) return;
    await showBlockedFor(context, failure);
    if (!context.mounted) return;
    final current = ref.read(groupDetailControllerProvider(group.id)).group;
    if (current != null) await runTransferFlow(context, ref, current);
    return;
  }
  await _finish(context, controller, failure);
}

/// Shows the outcome of a change: a notice on success, the right message on failure. 403 re-reads the group by itself
/// (the forbidden interceptor); the other stale-data failures re-read it here.
Future<void> _finish(BuildContext context, GroupDetailController controller, ApiFailure? failure, {String? success}) async {
  if (failure == null) {
    if (success != null) showAppSnackBar(context, success);
    return;
  }
  switch (codeOf(failure)) {
    case ApiErrorCode.memberHasTransactions || ApiErrorCode.ownerMemberProtected:
      await showBlockedFor(context, failure);
    case ApiErrorCode.memberInactive || ApiErrorCode.notFound:
      showFailureSnack(context, failure);
      await controller.load();
    default:
      showFailureSnack(context, failure);
  }
}

/// Who ownership can go to: only [candidates] (ACTIVE, linked, not me). Empty: says why and how to fix it.
Future<MemberDto?> showTransferPicker(BuildContext context, List<MemberDto> candidates) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<MemberDto>(
    context,
    title: l10n.memberTransferPickerTitle,
    subtitle: l10n.memberTransferPickerSubtitle,
    child: candidates.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.md),
            child: Column(
              children: [
                Text(l10n.memberTransferPickerEmptyTitle, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: QesmaSpacing.xs),
                Text(
                  l10n.memberTransferPickerEmptyBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final member in candidates) ...[
                Builder(
                  builder: (sheetContext) => AppCard(
                    onTap: () => Navigator.of(sheetContext).pop(member),
                    semanticLabel: member.displayName,
                    child: Row(
                      children: [
                        MemberAvatar(memberId: member.id, name: member.displayName, size: 40),
                        const SizedBox(width: QesmaSpacing.md),
                        Expanded(child: Text(member.displayName, style: Theme.of(sheetContext).textTheme.titleMedium)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: QesmaSpacing.sm),
              ],
            ],
          ),
  );
}
