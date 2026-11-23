import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/budget_summary_repository.dart';

/// The headline of the trip budget (SA20, STANDALONE_SPEC 20.2): what is left (or by how much it was exceeded, in
/// words with a warning icon), "spent X of Y" and the capped bar with the uncapped percentage as text. Every figure is
/// a field of [BudgetSummary]; nothing here adds, subtracts or divides money.
class BudgetOverview extends StatelessWidget {
  const BudgetOverview({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final over = summary.overBudget;
    final accent = over ? colors.error : colors.primary;
    final progress = ltrIsolate('${Bps.format(summary.progressBps)}%');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(over ? Icons.warning_amber_rounded : Icons.track_changes, color: accent),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(child: Text(l10n.budgetCardTitle, style: theme.textTheme.titleSmall)),
          ],
        ),
        const SizedBox(height: QesmaSpacing.sm),
        if (over)
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.budgetOverBy(moneyDisplay(l10n, summary.overByMinor ?? 0)),
              style: theme.textTheme.titleMedium?.copyWith(color: colors.error),
            ),
          )
        else
          Align(alignment: AlignmentDirectional.centerStart, child: MoneyText(summary.remainingMinor, size: MoneySize.large)),
        const SizedBox(height: QesmaSpacing.xs),
        Text(
          l10n.budgetSpentOf(moneyDisplay(l10n, summary.spentMinor), moneyDisplay(l10n, summary.budgetMinor)),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: QesmaSpacing.sm),
        BpsBar(fillBps: summary.barFillBps, color: accent),
        const SizedBox(height: QesmaSpacing.xs),
        Text(l10n.budgetProgress(progress), style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}
