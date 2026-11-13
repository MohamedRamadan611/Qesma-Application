import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../application/settlement_rules.dart';

/// The word for a status ("Waiting for confirmation", "Confirmed", "Disputed", "Cancelled").
String settlementStatusLabel(AppLocalizations l10n, SettlementStatus status) => switch (status) {
      SettlementStatus.pending => l10n.settlementChipPending,
      SettlementStatus.confirmed => l10n.settlementChipConfirmed,
      SettlementStatus.disputed => l10n.settlementChipDisputed,
      SettlementStatus.cancelled => l10n.settlementChipCancelled,
      SettlementStatus.unknown => l10n.settlementChipUnknown,
    };

/// A settlement's status as a pill: **word + icon + colour** (colour is never the only signal), one semantic label.
/// Pending is amber, confirmed green, disputed red, cancelled neutral.
class SettlementStatusChip extends StatelessWidget {
  const SettlementStatusChip(this.status, {super.key});

  final SettlementStatus status;

  static IconData iconFor(SettlementStatus status) => switch (status) {
        SettlementStatus.pending => Icons.hourglass_top,
        SettlementStatus.confirmed => Icons.check_circle,
        SettlementStatus.disputed => Icons.warning_amber_rounded,
        SettlementStatus.cancelled => Icons.cancel_outlined,
        SettlementStatus.unknown => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final (fg, bg) = switch (status) {
      SettlementStatus.pending => (c.warning, c.warningContainer),
      SettlementStatus.confirmed => (c.success, c.successContainer),
      SettlementStatus.disputed => (c.error, c.errorContainer),
      SettlementStatus.cancelled || SettlementStatus.unknown => (c.textSecondary, c.surfaceLow),
    };
    final word = settlementStatusLabel(l10n, status);
    return Semantics(
      container: true,
      label: l10n.settlementChipSpoken(word),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.control), border: Border.all(color: fg.withValues(alpha: 0.35))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm, vertical: QesmaSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconFor(status), size: 16, color: fg),
                const SizedBox(width: QesmaSpacing.xs),
                Flexible(child: Text(word, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
