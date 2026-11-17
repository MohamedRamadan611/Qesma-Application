import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/expense_category.dart';

/// One-tap category picker (SA6, STANDALONE_SPEC 7).
/// Shows all 9 categories with icons, labels, and accessible touch targets.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = ExpenseCategory.fromWire(selectedCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseCategoryPickerTitle,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: QesmaSpacing.sm),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            for (final cat in ExpenseCategory.values)
              AppChoiceChip(
                label: cat.label(l10n),
                icon: cat.icon,
                selected: cat == selected,
                onSelected: (_) => onChanged(cat.wire),
              ),
          ],
        ),
      ],
    );
  }
}
