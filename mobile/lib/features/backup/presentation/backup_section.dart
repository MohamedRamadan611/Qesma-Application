import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../local/backup/backup_service.dart';
import '../../profile/presentation/profile_rows.dart';
import 'backup_flow.dart';

/// The hub's "Backup" section (local mode only): export and restore, and when the last export happened.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(backupStatusProvider).asData?.value;
    final last = status == null ? null : (status.lastExportAt == null ? l10n.backupNeverExported : l10n.backupLastExport(backupDate(status.lastExportAt!)));
    return ProfileSection(
      title: l10n.backupSectionTitle,
      children: [
        ProfileRow(icon: Icons.upload, title: l10n.backupExportTitle, value: last, onTap: () => startExport(context, ref)),
        ProfileRow(icon: Icons.download, title: l10n.backupRestoreTitle, onTap: () => startRestore(context, ref)),
      ],
    );
  }
}
