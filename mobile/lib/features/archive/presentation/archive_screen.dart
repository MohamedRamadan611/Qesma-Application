import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/errors.dart';
import '../../../local/insights/archive_provider.dart';
import '../../../local/service/archive_service.dart';
import '../../groups/application/groups_list_controller.dart';
import '../../groups/data/group_type.dart';
import '../../groups/presentation/group_ui.dart';

String _day(int millis) => ltrIsolate(isoDate(DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)));

/// The archive (A184): settled groups hidden from the list. The retention period (7, 15 or 30 days) is chosen here;
/// each archived group shows when it is deleted for good, and can be restored or deleted at once.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref, ArchivedGroup g) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(archiveServiceProvider).restore(g.id);
    ref.invalidate(archivedGroupsProvider);
    ref.invalidate(groupsListControllerProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.archiveRestored)));
  }

  Future<void> _deleteNow(BuildContext context, WidgetRef ref, ArchivedGroup g) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.groupDeleteConfirmTitle,
      message: l10n.groupDeleteConfirmBody(g.name),
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(archiveServiceProvider).deleteNow(g.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.archiveDeleted)));
    } on LocalApiException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGroupNotEmptyMessage)));
    }
    ref.invalidate(archivedGroupsProvider);
    ref.invalidate(groupsListControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final archived = ref.watch(archivedGroupsProvider);
    final retention = ref.watch(archiveRetentionProvider).value;
    final labels = {7: l10n.archiveRetention7, 15: l10n.archiveRetention15, 30: l10n.archiveRetention30};

    return AppScaffold(
      title: l10n.archiveTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.account),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(QesmaSpacing.margin, QesmaSpacing.margin, QesmaSpacing.margin, 0),
            child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.archiveRetentionLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: QesmaSpacing.sm),
                if (retention != null)
                  DropdownButtonFormField<int>(
                    key: ValueKey('retention-$retention'),
                    initialValue: retention,
                    isExpanded: true,
                    items: [for (final e in labels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                    onChanged: (days) async {
                      if (days == null) return;
                      await ref.read(archiveServiceProvider).setRetentionDays(days);
                      ref.invalidate(archiveRetentionProvider);
                      ref.invalidate(archivedGroupsProvider);
                    },
                  ),
                const SizedBox(height: QesmaSpacing.sm),
                Text(l10n.archiveRetentionHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ],
            ),
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          Expanded(
            child: archived.when(
            loading: () => const SkeletonList(itemCount: 2),
            error: (_, _) => ErrorState(onRetry: () => ref.invalidate(archivedGroupsProvider)),
            data: (groups) => groups.isEmpty
                ? EmptyState(icon: Icons.inventory_2_outlined, title: l10n.archiveEmptyTitle, message: l10n.archiveEmptyBody)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.margin),
                    children: [
                      for (final g in groups) ...[
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(GroupType.fromWire(g.type).icon, color: context.colors.primary),
                                  const SizedBox(width: QesmaSpacing.sm),
                                  Expanded(child: Text(g.name, style: theme.textTheme.titleMedium)),
                                  MoneyText(g.totalSpentMinor, size: MoneySize.small),
                                ],
                              ),
                              const SizedBox(height: QesmaSpacing.xs),
                              Text(l10n.archiveArchivedOn(_day(g.archivedAt)), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                              Text(
                                l10n.archiveDeletesOn(_day(g.deletesAt)),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                              ),
                              const SizedBox(height: QesmaSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(label: l10n.archiveRestore, icon: Icons.unarchive_outlined, variant: AppButtonVariant.secondary, onPressed: () => _restore(context, ref, g)),
                                  ),
                                  const SizedBox(width: QesmaSpacing.sm),
                                  Expanded(
                                    child: AppButton(label: l10n.archiveDeleteNow, icon: Icons.delete_outline, variant: AppButtonVariant.secondary, onPressed: () => _deleteNow(context, ref, g)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: QesmaSpacing.sm),
                      ],
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
