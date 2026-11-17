import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/my_share_repository.dart';
import '../../expenses/data/expense_category.dart';

/// Modal bottom sheet showing expenses contributing to a category in a month.
class CategoryDrilldownSheet extends StatelessWidget {
  const CategoryDrilldownSheet({
    super.key,
    required this.breakdown,
    required this.currencyCode,
  });

  final MyShareCategoryBreakdown breakdown;
  final String currencyCode;

  static Future<void> show(
    BuildContext context, {
    required MyShareCategoryBreakdown breakdown,
    required String currencyCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CategoryDrilldownSheet(
        breakdown: breakdown,
        currencyCode: currencyCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cat = ExpenseCategory.fromWire(breakdown.category);
    final (catBg, catFg) = cat.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(QesmaSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius: BorderRadius.circular(QesmaRadii.control),
                    ),
                    child: Icon(cat.icon, color: catFg, size: 24),
                  ),
                  const SizedBox(width: QesmaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.label(l10n),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.myShareExpensesCount(breakdown.expenses.length),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (breakdown.expenses.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.myShareNoExpensesInCategory,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(QesmaSpacing.md),
                  itemCount: breakdown.expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: QesmaSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = breakdown.expenses[index];
                    return AppCard(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(Routes.expense(item.groupId, item.expenseId));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.expenseTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.groupName} • ${ltrIsolate(item.expenseDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: QesmaSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: QesmaSpacing.sm,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${l10n.myShareConsumed}: ${moneyDisplay(l10n, item.owedMinor)}',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (item.paidMinor > 0)
                                Text(
                                  '${l10n.mySharePaidUpFront}: ${moneyDisplay(l10n, item.paidMinor)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
