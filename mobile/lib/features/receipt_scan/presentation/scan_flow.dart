import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/application/expense_draft.dart';
import '../application/receipt_draft_mapper.dart';
import '../application/receipt_reader.dart';
import '../application/receipt_scan_providers.dart';
import 'consent_screen.dart';

/// How a scan attempt ended.
sealed class ScanFlowResult {
  const ScanFlowResult();
}

/// A proposal: open the itemized editor with it (unsaved).
final class ScanFlowDraft extends ScanFlowResult {
  const ScanFlowDraft(this.draft);
  final ScanDraft draft;
}

/// The user chose (or had to fall back to) typing by hand.
final class ScanFlowManual extends ScanFlowResult {
  const ScanFlowManual();
}

/// The user backed out; do nothing.
final class ScanFlowCancelled extends ScanFlowResult {
  const ScanFlowCancelled();
}

enum _Source { camera, gallery, manual }

enum _Retry { again, manual }

/// Consent (once) -> camera or gallery -> reading -> a proposal, or an error with "type manually". Used by the FAB
/// menu and by the itemized editor. Nothing is saved here.
Future<ScanFlowResult> runReceiptScan(BuildContext context, WidgetRef ref) async {
  final service = ref.read(receiptScanServiceProvider);
  if (service == null) return const ScanFlowManual();

  final settings = await service.settings();
  if (!context.mounted) return const ScanFlowCancelled();
  if (!settings.consented) {
    final agreed = await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ScanConsentScreen()));
    if (agreed == null) return const ScanFlowCancelled();
    if (!agreed) return const ScanFlowManual();
    await service.giveConsent();
    ref.invalidate(ocrSettingsProvider);
    if (!context.mounted) return const ScanFlowCancelled();
  }

  while (true) {
    final source = await _askSource(context);
    if (source == null || !context.mounted) return const ScanFlowCancelled();
    if (source == _Source.manual) return const ScanFlowManual();

    final photo = await ref.read(receiptPhotoPickerProvider).pick(source == _Source.camera ? ReceiptPhotoSource.camera : ReceiptPhotoSource.gallery);
    if (photo == null || !context.mounted) return const ScanFlowCancelled();

    _showReading(context);
    ReceiptScanException? failure;
    ScanDraft? draft;
    try {
      draft = scanDraftFrom(await service.scan(photo));
    } on ReceiptScanException catch (e) {
      failure = e;
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // the reading dialog
    ref.invalidate(ocrSettingsProvider);
    if (!context.mounted) return const ScanFlowCancelled();
    if (draft != null) return ScanFlowDraft(draft);

    final next = await _showError(context, failure!.failure);
    if (next == null || !context.mounted) return const ScanFlowCancelled();
    if (next == _Retry.manual) return const ScanFlowManual();
  }
}

Future<_Source?> _askSource(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<_Source>(
    context,
    title: l10n.scanSourceTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(l10n.scanSourceCamera), onTap: () => Navigator.of(context).pop(_Source.camera)),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(l10n.scanSourceGallery), onTap: () => Navigator.of(context).pop(_Source.gallery)),
        ListTile(leading: const Icon(Icons.edit_note), title: Text(l10n.scanTypeManually), onTap: () => Navigator.of(context).pop(_Source.manual)),
      ],
    ),
  );
}

void _showReading(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: QesmaSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.scanReading, style: Theme.of(context).textTheme.titleMedium),
                    Text(l10n.scanReadingHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The message of each failure (one string per kind).
String scanFailureMessage(AppLocalizations l10n, ReceiptScanFailure failure) => switch (failure) {
      ReceiptScanFailure.offline => l10n.scanErrorOffline,
      ReceiptScanFailure.timeout => l10n.scanErrorTimeout,
      ReceiptScanFailure.quotaExhausted => l10n.scanErrorQuota,
      ReceiptScanFailure.permissionDenied => l10n.scanErrorPermission,
      ReceiptScanFailure.unreadablePhoto => l10n.scanErrorPhoto,
      ReceiptScanFailure.invalidResponse => l10n.scanErrorInvalid,
      ReceiptScanFailure.dailyCapReached => l10n.scanErrorCap,
      ReceiptScanFailure.unavailable => l10n.scanErrorUnavailable,
    };

/// Whether trying again can help (a cap, a refusal or a missing feature will not change by retrying).
bool scanFailureRetryable(ReceiptScanFailure failure) => switch (failure) {
      ReceiptScanFailure.offline || ReceiptScanFailure.timeout || ReceiptScanFailure.unreadablePhoto || ReceiptScanFailure.invalidResponse => true,
      _ => false,
    };

Future<_Retry?> _showError(BuildContext context, ReceiptScanFailure failure) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<_Retry>(
    context,
    title: l10n.scanErrorTitle,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Text(scanFailureMessage(l10n, failure), style: Theme.of(context).textTheme.bodyLarge)),
        const SizedBox(height: QesmaSpacing.md),
        if (scanFailureRetryable(failure)) ...[
          AppButton(label: l10n.scanTryAgain, icon: Icons.refresh, onPressed: () => Navigator.of(context).pop(_Retry.again)),
          const SizedBox(height: QesmaSpacing.sm),
        ],
        AppButton(
          label: l10n.scanTypeManually,
          icon: Icons.edit_note,
          variant: scanFailureRetryable(failure) ? AppButtonVariant.secondary : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(_Retry.manual),
        ),
      ],
    ),
  );
}
