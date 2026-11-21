import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../application/expense_form_state.dart';

/// "N things to fix before saving", shown at the top of the form after Save was tapped on an incomplete restaurant
/// bill: one row per problem, in screen order, each a tap that goes to it (an item problem also opens that item). It is
/// a live region, and every row has an icon and words, never colour alone.
class ValidationSummaryCard extends StatelessWidget {
  const ValidationSummaryCard({super.key, required this.issues, required this.onTap});

  final List<FormIssue> issues;
  final ValueChanged<FormIssue> onTap;

  static String textOf(AppLocalizations l10n, FormIssue issue) {
    final heading = (issue.itemName ?? '').isEmpty ? l10n.expenseItemizedItemHeading('${issue.itemIndex ?? 0}') : issue.itemName!;
    return switch (issue.kind) {
      IssueKind.title => l10n.expenseFormTitleLabel,
      IssueKind.payers => l10n.expenseFormPaidByTitle,
      IssueKind.itemsEmpty => l10n.expenseItzIssueItemsEmpty,
      IssueKind.itemName => l10n.expenseItzIssueItemName('${issue.itemIndex ?? 0}'),
      IssueKind.itemPrice => l10n.expenseItzIssueItemPrice(heading),
      IssueKind.itemQuantity => l10n.expenseItzIssueItemQuantity(heading),
      IssueKind.itemMembers => l10n.expenseItzIssueItemMembers(heading),
      IssueKind.discount => l10n.expenseItzDiscountLabel,
      IssueKind.service => l10n.expenseServiceLabel,
      IssueKind.tax => l10n.expenseTaxLabel,
      IssueKind.delivery => l10n.expenseItzDeliveryLabel,
      IssueKind.adjustment => l10n.expenseItemizedAdjustmentTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: context.colors.error),
      ),
      child: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              header: true,
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error)),
                  const SizedBox(width: QesmaSpacing.sm),
                  Expanded(child: Text(l10n.expenseItzSummaryTitle(issues.length), style: theme.textTheme.titleSmall?.copyWith(color: context.colors.error))),
                ],
              ),
            ),
            const SizedBox(height: QesmaSpacing.xs),
            for (final issue in issues)
              Semantics(
                button: true,
                label: textOf(l10n, issue),
                onTap: () => onTap(issue),
                child: ExcludeSemantics(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(QesmaRadii.control),
                    onTap: () => onTap(issue),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: kMinTouch),
                      child: Row(
                        children: [
                          Expanded(child: Text(textOf(l10n, issue), style: theme.textTheme.bodyMedium)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: QesmaSpacing.xs),
            Text(l10n.expenseItzSummaryHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
