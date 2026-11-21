import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/expense_category.dart';

/// The category as one button next to the date (the redesign): the selected category's icon and name; a tap opens the
/// nine categories as chips in a sheet, and choosing one closes it.
class CategoryButton extends StatelessWidget {
  const CategoryButton({super.key, required this.selectedCategory, required this.onChanged});

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = ExpenseCategory.fromWire(selectedCategory);
    return AppButton(
      label: selected.label(l10n),
      icon: selected.icon,
      variant: AppButtonVariant.secondary,
      onPressed: () => showAppBottomSheet<void>(
        context,
        title: l10n.expenseCategoryPickerTitle,
        child: Builder(
          builder: (sheetContext) => CategoryPicker(
            selectedCategory: selectedCategory,
            showTitle: false,
            onChanged: (wire) {
              onChanged(wire);
              Navigator.of(sheetContext).pop();
            },
          ),
        ),
      ),
    );
  }
}

/// One-tap category picker (SA6, STANDALONE_SPEC 7).
/// Shows all 9 categories with icons, labels, and accessible touch targets.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.showTitle = true,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  /// False inside the category sheet, whose own title says it.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = ExpenseCategory.fromWire(selectedCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            l10n.expenseCategoryPickerTitle,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],
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
