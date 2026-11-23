import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/budget_summary_provider.dart';
import '../../groups/presentation/group_ui.dart';
import '../../../local/insights/budget_summary_repository.dart';
import 'budget_overview.dart';

/// The trip budget (SA20, STANDALONE_SPEC 20.2): the headline, the daily average, what can be spent per remaining
/// day (only with trip dates), the per-person estimate and the spending per day, newest first. All figures come from
/// [BudgetSummary]; nothing here does arithmetic.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(budgetSummaryProvider(gid));
    final value = summary.value;
    return AppScaffold(
      title: l10n.budgetScreenTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.group(gid)),
      body: value == null
          ? (summary.isLoading ? const SkeletonList(itemCount: 3) : const SizedBox.shrink())
          : _BudgetBody(summary: value),
    );
  }
}

class _BudgetBody extends StatelessWidget {
  const _BudgetBody({required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final average = summary.dailyAverageMinor;
    final elapsed = summary.elapsedDays;
    final perDayLeft = summary.perDayLeftMinor;
    final daysLeft = summary.daysLeft;
    final perHead = summary.costPerHeadMinor;
    return ListView(
      padding: const EdgeInsets.all(QesmaSpacing.margin),
      children: [
        AppCard(child: BudgetOverview(summary: summary)),
        const SizedBox(height: QesmaSpacing.md),
        if (average != null)
          _StatRow(label: l10n.budgetDailyAverage, minor: average, note: elapsed == null ? null : l10n.budgetOverDays(elapsed)),
        if (perDayLeft != null)
          _StatRow(label: l10n.budgetPerDayLeft, minor: perDayLeft, note: daysLeft == null ? null : l10n.budgetDaysLeft(daysLeft)),
        if (perHead != null) _StatRow(label: l10n.budgetCostPerHead, minor: perHead, note: l10n.budgetCostPerHeadHint),
        const SizedBox(height: QesmaSpacing.md),
        Semantics(header: true, child: Text(l10n.budgetPerDayTitle, style: theme.textTheme.titleMedium)),
        const SizedBox(height: QesmaSpacing.sm),
        if (summary.perDay.isEmpty)
          Text(l10n.budgetNoExpenses, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))
        else
          for (final day in summary.perDay)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(ltrIsolate(day.date), style: theme.textTheme.bodyMedium)),
                  const SizedBox(width: QesmaSpacing.sm),
                  MoneyText(day.totalMinor),
                ],
              ),
            ),
      ],
    );
  }
}

/// A label with its amount and an optional one-line note under it. Wraps instead of truncating at large text sizes.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.minor, this.note});

  final String label;
  final int minor;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: QesmaSpacing.sm),
              MoneyText(minor),
            ],
          ),
          if (note != null)
            Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
