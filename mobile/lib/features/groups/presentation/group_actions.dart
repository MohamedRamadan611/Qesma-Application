import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/permissions/group_role.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/errors.dart';
import '../../../local/insights/archive_provider.dart';
import '../application/groups_list_controller.dart';
import '../data/groups_repository.dart';
import 'group_dialogs.dart';
import 'group_ui.dart';

enum _GroupAction { archive, delete }

/// Long press on a group in the list: a menu with Archive (local mode) and Delete. Only the owner sees it, as in the
/// edit screen; the same rules apply (a group with an open balance or pool cannot be archived, one with history
/// that is not fully settled cannot be deleted) and the same confirmations are asked.
Future<void> showGroupActions(BuildContext context, WidgetRef ref, GroupSummaryDto group) async {
  if (GroupRole.parse(group.yourRole) != GroupRole.owner) return;
  final l10n = AppLocalizations.of(context);
  final canArchive = ref.read(modeFeaturesProvider).archive;
  final action = await showAppBottomSheet<_GroupAction>(
    context,
    title: group.name,
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canArchive)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l10n.archiveAction),
              onTap: () => Navigator.of(sheetContext).pop(_GroupAction.archive),
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(sheetContext).colorScheme.error),
            title: Text(l10n.groupDelete, style: TextStyle(color: Theme.of(sheetContext).colorScheme.error)),
            onTap: () => Navigator.of(sheetContext).pop(_GroupAction.delete),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _GroupAction.archive:
      await _archive(context, ref, group);
    case _GroupAction.delete:
      await _delete(context, ref, group);
  }
}

Future<void> _archive(BuildContext context, WidgetRef ref, GroupSummaryDto group) async {
  final l10n = AppLocalizations.of(context);
  final days = await ref.read(archiveRetentionProvider.future);
  if (!context.mounted) return;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.archiveConfirmTitle,
    message: l10n.archiveConfirmBody(group.name, '$days'),
    confirmLabel: l10n.archiveAction,
  );
  if (!confirmed || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(archiveServiceProvider).archive(group.id);
  } on LocalApiException {
    if (context.mounted) await showBlockedDialog(context, title: l10n.archiveBlockedTitle, message: l10n.archiveBlocked);
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(l10n.archiveDone)));
  ref.invalidate(archivedGroupsProvider);
  await ref.read(groupsListControllerProvider.notifier).refresh();
}

Future<void> _delete(BuildContext context, WidgetRef ref, GroupSummaryDto group) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.groupDeleteConfirmTitle,
    message: l10n.groupDeleteConfirmBody(group.name),
    confirmLabel: l10n.commonDelete,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(groupsRepositoryProvider).delete(group.id);
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    switch (codeOf(failure)) {
      case ApiErrorCode.groupNotEmpty:
        await showBlockedFor(context, failure, extra: l10n.groupBlockedTotal(moneyDisplay(l10n, group.totalSpentMinor)));
      case ApiErrorCode.notFound:
        break; // already gone: the refresh below removes it
      default:
        showFailureSnack(context, failure);
        return;
    }
  }
  await ref.read(groupsListControllerProvider.notifier).refresh();
}
