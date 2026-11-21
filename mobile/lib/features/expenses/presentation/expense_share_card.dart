import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';

/// One expense as a shareable image: title, total, who paid and what each member owes (server numbers only).
class ExpenseShareCard extends StatelessWidget {
  const ExpenseShareCard({super.key, required this.expense, required this.groupName, required this.nameOf});

  final ExpenseView expense;
  final String? groupName;
  final String Function(String memberId) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payers = payerLines(expense).map((p) => nameOf(p.memberId)).join('، ');
    return ShareCardFrame(
      title: expense.title,
      subtitle: groupName,
      children: [
        ShareCardRow(label: l10n.expenseDetailsTotal, value: moneyDisplay(l10n, expense.totalMinor)),
        if (payers.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l10n.expensePaidBy(payers))),
        const Divider(),
        Text(l10n.shareWhoOwes, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final s in expense.shares) ShareCardRow(label: nameOf(s.memberId), value: moneyDisplay(l10n, s.owedMinor)),
      ],
    );
  }
}
