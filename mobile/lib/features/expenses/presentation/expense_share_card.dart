import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';

/// One expense as a shareable image: the title, total and date, then only each person's share (name in bold, with the parts
/// of that share). Server numbers only; nothing is added up here.
class ExpenseShareCard extends StatelessWidget {
  const ExpenseShareCard({super.key, required this.expense, required this.groupName, required this.nameOf});

  final ExpenseView expense;
  final String? groupName;
  final String Function(String memberId) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final bold = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    final items = expense.items?.toList() ?? const <ItemView>[];

    Widget section(String text) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(text, style: bold),
        );

    return ShareCardFrame(
      title: expense.title,
      subtitle: groupName,
      children: [
        ShareCardRow(label: l10n.expenseDetailsTotal, value: moneyDisplay(l10n, expense.totalMinor)),
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(ltrIsolate('${expense.expenseDate}'), style: muted)),
        const Divider(),
        section(l10n.expenseBreakdownTitle),
        for (final s in expense.shares) ...[
          ShareCardRow(label: nameOf(s.memberId), value: moneyDisplay(l10n, s.owedMinor), boldLabel: true),
          ..._detailLines(l10n, s, items, muted),
        ],
      ],
    );
  }

  /// The parts of one person's share as a small grey line under their row.
  List<Widget> _detailLines(AppLocalizations l10n, ShareView share, List<ItemView> items, TextStyle? style) {
    final parts = breakdownOf(share);
    final texts = [
      if (parts.itemsMinor != null) l10n.expensePartItems(moneyDisplay(l10n, parts.itemsMinor!)),
      if (parts.discountMinor != null) l10n.expenseItzPartDiscount('${Money.minus}${moneyDisplay(l10n, parts.discountMinor!)}'),
      if (parts.serviceMinor != null) l10n.expensePartService(moneyDisplay(l10n, parts.serviceMinor!)),
      if (parts.taxMinor != null) l10n.expensePartTax(moneyDisplay(l10n, parts.taxMinor!)),
      if (parts.deliveryMinor != null) l10n.expensePartDelivery(moneyDisplay(l10n, parts.deliveryMinor!)),
      if (parts.adjustmentMinor != null) l10n.expensePartAdjustment(moneyDisplay(l10n, parts.adjustmentMinor!, signed: true)),
    ];
    return [
      if (texts.isNotEmpty) Text(texts.join(' + '), style: style),
      const SizedBox(height: 6),
    ];
  }
}
