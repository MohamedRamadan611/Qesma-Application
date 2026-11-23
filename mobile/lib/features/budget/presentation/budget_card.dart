import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/budget_summary_provider.dart';

/// The compact budget card on the group home (SA20), the size of the pool card so the header stays short at large
/// text sizes: what is left (or "over budget by X" in words with a warning icon), "spent X of Y", the capped bar and
/// the uncapped percentage as text. Tapping it opens the budget screen with the full breakdown. The caller shows it
/// only when the mode has a budget and the group has one; while the figures load (or fail) it draws nothing. Every
/// figure is a field of `BudgetSummary`: nothing here adds, subtracts or divides money.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(budgetSummaryProvider(gid)).value;
    if (summary == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final over = summary.overBudget;
    final accent = over ? colors.error : colors.primary;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return Semantics(
      button: true,
      label: l10n.budgetOpenDetails,
      child: AppCard(
        onTap: () => context.push(Routes.budget(gid)),
        padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(over ? Icons.warning_amber_rounded : Icons.track_changes, color: accent),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.budgetCardTitle, style: theme.textTheme.titleSmall),
                      if (over)
                        Text(
                          l10n.budgetOverBy(moneyDisplay(l10n, summary.overByMinor ?? 0)),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                        )
                      else
                        Text(
                          l10n.budgetSpentOf(moneyDisplay(l10n, summary.spentMinor), moneyDisplay(l10n, summary.budgetMinor)),
                          style: secondary,
                        ),
                    ],
                  ),
                ),
                if (!over) ...[
                  const SizedBox(width: QesmaSpacing.sm),
                  MoneyText(summary.remainingMinor, size: MoneySize.small),
                ],
              ],
            ),
            const SizedBox(height: QesmaSpacing.xs),
            Row(
              children: [
                Expanded(child: BpsBar(fillBps: summary.barFillBps, color: accent, height: 6)),
                const SizedBox(width: QesmaSpacing.sm),
                Text(l10n.budgetProgress(ltrIsolate('${Bps.format(summary.progressBps)}%')), style: secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
