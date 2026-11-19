import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// The one-time consent before the first scan (SA12, STANDALONE_SPEC 13): what is sent, to whom, that the free tier
/// may use it to improve Google products, that nothing is kept, and how to avoid it. Pops `true` on agree, `false` on
/// "type manually instead" (and null when the user leaves with back).
class ScanConsentScreen extends StatelessWidget {
  const ScanConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final points = <(IconData, String)>[
      (Icons.cloud_upload_outlined, l10n.scanConsentSent),
      (Icons.info_outline, l10n.scanConsentFree),
      (Icons.delete_outline, l10n.scanConsentKept),
      (Icons.edit_note, l10n.scanConsentAvoid),
      (Icons.toggle_on_outlined, l10n.scanConsentRevoke),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanConsentTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QesmaSpacing.margin),
          children: [
            Semantics(header: true, child: Text(l10n.scanConsentTitle, style: theme.textTheme.headlineSmall)),
            const SizedBox(height: QesmaSpacing.md),
            for (final (icon, text) in points)
              Padding(
                padding: const EdgeInsets.only(bottom: QesmaSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Icon(icon, color: context.colors.primary)),
                    const SizedBox(width: QesmaSpacing.sm + 4),
                    Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: QesmaSpacing.md),
            AppButton(label: l10n.scanConsentAccept, onPressed: () => Navigator.of(context).pop(true)),
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(label: l10n.scanConsentDecline, variant: AppButtonVariant.secondary, onPressed: () => Navigator.of(context).pop(false)),
          ],
        ),
      ),
    );
  }
}
