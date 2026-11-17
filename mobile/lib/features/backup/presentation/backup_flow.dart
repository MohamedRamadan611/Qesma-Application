import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/backup/backup_format.dart';
import '../../../local/backup/backup_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../groups/application/groups_list_controller.dart';
import '../application/backup_gateway.dart';

/// "YYYY-MM-DD" of a UTC epoch-ms instant, in the phone's time zone, Western digits (the app shows no Arabic-Indic digits).
String backupDate(int epochMillis) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

String backupErrorMessage(AppLocalizations l10n, BackupError code) => switch (code) {
      BackupError.unreadable => l10n.backupErrorUnreadable,
      BackupError.tooLarge => l10n.backupErrorTooLarge,
      BackupError.newerFormat => l10n.backupErrorNewer,
      BackupError.invalid => l10n.backupErrorInvalid,
      BackupError.inconsistent => l10n.backupErrorInconsistent,
      BackupError.failed => l10n.backupErrorFailed,
    };

/// Export: an explicit confirm (the file contains names and amounts), then the share sheet. Nothing is kept on the
/// phone afterwards: the temporary file is deleted whatever the user chose.
Future<void> startExport(BuildContext context, WidgetRef ref, {bool askFirst = true}) async {
  final l10n = AppLocalizations.of(context);
  if (askFirst) {
    final ok = await showConfirmDialog(
      context,
      title: l10n.backupExportTitle,
      message: l10n.backupExportBody,
      confirmLabel: l10n.backupExportConfirm,
    );
    if (!ok || !context.mounted) return;
  }
  final service = ref.read(backupServiceProvider);
  final gateway = ref.read(backupFileGatewayProvider);
  try {
    final data = await service.snapshot();
    final shared = await gateway.share(service.encode(data), l10n.backupShareText);
    if (shared) await service.markExported(data);
    ref.invalidate(backupStatusProvider);
    if (context.mounted) showAppSnackBar(context, l10n.backupExportDone);
  } catch (_) {
    if (context.mounted) showAppSnackBar(context, l10n.backupExportFailed);
  }
}

/// Restore: pick a file, validate it completely, show what it holds, and only after an explicit destructive confirm
/// replace everything in one transaction. Any problem leaves the data untouched and says so.
Future<void> startRestore(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final service = ref.read(backupServiceProvider);
  final gateway = ref.read(backupFileGatewayProvider);
  try {
    final bytes = await gateway.pick();
    if (bytes == null) return;
    final data = await service.prepareRestore(Uint8List.fromList(bytes));
    if (!context.mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: l10n.backupRestoreConfirmTitle,
      message: l10n.backupRestoreConfirmBody(data.groups.length.toString(), data.liveExpenseCount.toString(), backupDate(data.exportedAt)),
      confirmLabel: l10n.backupRestoreConfirm,
      destructive: true,
    );
    if (!ok) return;
    await service.restore(data);
    // The app's cached state described the old data: reload the "session" (profile) and the groups list.
    ref.invalidate(backupStatusProvider);
    ref.invalidate(groupsListControllerProvider);
    ref.invalidate(authControllerProvider);
    if (!context.mounted) return;
    context.go(Routes.home);
    showAppSnackBar(context, l10n.backupRestoreDone);
  } on BackupException catch (e) {
    if (context.mounted) await showBlockedDialog(context, title: l10n.backupRestoreTitle, message: backupErrorMessage(l10n, e.code));
  } catch (_) {
    if (context.mounted) await showBlockedDialog(context, title: l10n.backupRestoreTitle, message: l10n.backupErrorFailed);
  }
}
