import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/features_for_mode.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/backup/backup_service.dart';
import 'backup_flow.dart';

/// Dismissible "back up your data" banner at the top of the groups list (local mode). The rule is
/// `BackupReminder.shouldShow`; dismissing hides it for a week and exporting resets it.
class BackupBanner extends ConsumerWidget {
  const BackupBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(modeFeaturesProvider).backup) return const SizedBox.shrink();
    final show = ref.watch(backupStatusProvider).asData?.value.showReminder ?? false;
    if (!show) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: QesmaSpacing.md - 4),
      child: AppCard(
        color: context.colors.tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.upload, color: context.colors.onPrimaryContainer),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(child: Semantics(header: true, child: Text(l10n.backupBannerTitle, style: theme.textTheme.titleSmall))),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.backupBannerDismiss,
                  onPressed: () async {
                    await ref.read(backupServiceProvider).snoozeReminder();
                    ref.invalidate(backupStatusProvider);
                  },
                ),
              ],
            ),
            Text(l10n.backupBannerBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(label: l10n.backupBannerAction, variant: AppButtonVariant.secondary, onPressed: () => startExport(context, ref, askFirst: false)),
          ],
        ),
      ),
    );
  }
}
