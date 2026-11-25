import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/qesma_text.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(QesmaRadii.control),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(QesmaSpacing.xs + 2),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: colors.success,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (total != null) MoneyText(total, size: MoneySize.medium),
                  ],
                ),
              ),
              AppTag(label: countLabel, icon: Icons.groups_outlined),
            ],
          ),
          const SizedBox(height: QesmaSpacing.xs),
          Padding(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (net != null) ...[
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.summaryYourPosition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: BalanceStatusChip(net, plain: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: QesmaSpacing.md),
                  ],
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.summaryStatus,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                statusLabel,
                                style: QesmaText.amountInline().copyWith(
                                  color: settled
                                      ? colors.success
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: QesmaSpacing.xs),
            Text(
              footnote!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
