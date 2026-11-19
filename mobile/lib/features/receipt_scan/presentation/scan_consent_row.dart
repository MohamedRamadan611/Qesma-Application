import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/clock.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../application/receipt_scan_providers.dart';
import 'consent_screen.dart';

/// Profile row to see and revoke the receipt-scan consent (SA12). Turning it on shows the consent screen; turning it
/// off forgets the consent, so the next scan asks again. Absent when scanning is not available on this run.
class ScanConsentRow extends ConsumerWidget {
  const ScanConsentRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(receiptScanServiceProvider);
    if (service == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(ocrSettingsProvider).value;
    final nowMs = ref.watch(clockProvider)().toUtc().millisecondsSinceEpoch;
    final hidden = settings?.isHidden(nowMs) ?? false;
    final on = settings?.consented ?? false;

    return SwitchListTile(
      secondary: const Icon(Icons.document_scanner_outlined),
      title: Text(l10n.scanProfileTitle),
      subtitle: Text(hidden ? l10n.scanProfileHidden : (on ? l10n.scanProfileOn : l10n.scanProfileOff)),
      value: on,
      onChanged: settings == null
          ? null
          : (value) async {
              if (value) {
                final agreed = await Navigator.of(context).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ScanConsentScreen()));
                if (agreed != true) return;
                await service.giveConsent();
              } else {
                await service.revokeConsent();
              }
              ref.invalidate(ocrSettingsProvider);
            },
    );
  }
}
