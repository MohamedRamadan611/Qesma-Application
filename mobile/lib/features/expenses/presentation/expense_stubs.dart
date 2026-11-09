import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Placeholder for the add and edit expense screens. FL5 (equal / exact) and FL6 (itemized)
/// replace it; until then the buttons lead here and say so, with no fake form.
class ExpenseFormStub extends StatelessWidget {
  const ExpenseFormStub({super.key, required this.edit, this.itemized = false});

  final bool edit;

  /// The restaurant-bill screen (FL6) rather than the plain add/edit form.
  final bool itemized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: itemized ? l10n.expenseSplitItemized : (edit ? l10n.expenseEdit : l10n.expensesAdd),
      showBack: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.lg),
          child: Text(
            l10n.groupNotBuiltYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
