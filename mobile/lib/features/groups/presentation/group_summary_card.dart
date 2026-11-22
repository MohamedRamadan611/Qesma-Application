import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// The "total shared" card (P3-01 style), used on the Groups screen (all groups) and on each group's home.
/// Server numbers only: [totalSpentMinor] and [netMinor] come from the DTOs, nothing is recomputed here.
///
/// * Top: tile icon, title, the big total, and a chip with the member (or group) count.
/// * Bottom strip: "your position" (the same chip as everywhere) and the settlement status text.
class GroupSummaryCard extends StatelessWidget {
  const GroupSummaryCard({
    super.key,
    required this.title,
    required this.totalSpentMinor,
    required this.countLabel,
    required this.netMinor,
    required this.statusLabel,
    required this.settled,
    this.footnote,
  });

  final String title;

  /// Null hides the amount (several currencies, or not every page loaded: a partial sum would be wrong).
  final int? totalSpentMinor;
  final String countLabel;

  /// Null hides the position (see [totalSpentMinor]).
  final int? netMinor;
  final String statusLabel;
  final bool settled;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final total = totalSpentMinor;
    final net = netMinor;
    return AppCard(
      color: colors.successContainer,
      padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                child: Padding(padding: const EdgeInsets.all(QesmaSpacing.sm), child: Icon(Icons.receipt_long_outlined, color: colors.success, size: 20)),
              ),
              const SizedBox(width: QesmaSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                    if (total != null) MoneyText(total, size: MoneySize.medium),
                  ],
                ),
              ),
              AppTag(label: countLabel, icon: Icons.groups_outlined),
            ],
          ),
          const SizedBox(height: QesmaSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
              child: Row(
                children: [
                  if (net != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.summaryYourPosition, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                          const SizedBox(height: QesmaSpacing.xs),
                          BalanceStatusChip(net),
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.summaryStatus, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: QesmaSpacing.xs),
                        Text(
                          statusLabel,
                          style: theme.textTheme.titleSmall?.copyWith(color: settled ? colors.success : colors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: QesmaSpacing.sm),
            Text(footnote!, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
