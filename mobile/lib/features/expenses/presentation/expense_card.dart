import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';
import '../data/split_type.dart';
import 'expense_ui.dart';
import '../../../core/theme/palette.dart';

/// One row of the expenses list (P3-01): title, split-type chip, who paid, how many people
/// share it, the total and, when the server has an entry for you, your share.
/// Every number is a server value; nothing is computed here.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense, required this.nameOf, required this.yourMemberId, required this.onTap});

  final ExpenseView expense;
  final String Function(String memberId) nameOf;
  final String? yourMemberId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final split = SplitType.fromWire(expense.splitType);
    final payers = payersText(l10n, expense, nameOf);
    final payersSaid = payersSpoken(l10n, expense, nameOf);
    final splitSaid = split?.label(l10n) ?? l10n.expenseSplitUnknown;
    final participants = participantsText(l10n, participantCount(expense));
    final share = yourShareMinor(expense, yourMemberId);
    final shareText = share == null ? null : l10n.expenseYourShare(moneyDisplay(l10n, share));
    final spoken = shareText == null
        ? l10n.expenseCardSpoken(expense.title, moneySpoken(l10n, expense.totalMinor), splitSaid, payersSaid, participants)
        : l10n.expenseCardSpokenWithShare(
            expense.title,
            moneySpoken(l10n, expense.totalMinor),
            splitSaid,
            payersSaid,
            participants,
            l10n.expenseYourShare(moneySpoken(l10n, share!)),
          );

    // At large text sizes the amount drops under the title instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amounts = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneyText(expense.totalMinor, size: MoneySize.medium),
        if (shareText != null)
          Text(shareText, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.owed, fontWeight: FontWeight.w600)),
      ],
    );

    return AppCard(
      onTap: onTap,
      semanticLabel: spoken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                child: Icon(split?.icon ?? Icons.receipt_long, color: context.colors.onPrimaryContainer),
              ),
              const SizedBox(width: QesmaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (split != null) ...[
                      const SizedBox(height: QesmaSpacing.xs),
                      AppTag(label: split.label(l10n), tone: split == SplitType.itemized ? AppTagTone.warning : AppTagTone.primary),
                    ],
                  ],
                ),
              ),
              if (!stacked) ...[
                const SizedBox(width: QesmaSpacing.sm),
                amounts,
              ],
            ],
          ),
          if (stacked) ...[
            const SizedBox(height: QesmaSpacing.sm),
            Align(alignment: AlignmentDirectional.centerStart, child: amounts),
          ],
          const SizedBox(height: QesmaSpacing.sm),
          Text(payers, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.xs),
          Row(
            children: [
              ExcludeSemantics(child: Icon(Icons.group_outlined, size: 16, color: context.colors.textHelper)),
              const SizedBox(width: QesmaSpacing.xs),
              Expanded(child: Text(participants, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper))),
            ],
          ),
        ],
      ),
    );
  }
}
