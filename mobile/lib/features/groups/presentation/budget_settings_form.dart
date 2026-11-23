import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/application/expense_form_state.dart' show kFirstExpenseDate, kLastExpenseDate;
import '../../expenses/presentation/expense_ui.dart';

/// Picks a trip date between the lowest allowed date (or the expense floor) and the expense ceiling. Null = cancelled.
Future<Date?> pickTripDate(BuildContext context, {required Date today, Date? current, Date? notBefore}) async {
  final lowest = notBefore ?? kFirstExpenseDate;
  final picked = await showDatePicker(
    context: context,
    initialDate: (current ?? (lowest.compareTo(today) > 0 ? lowest : today)).toDateTime(),
    firstDate: lowest.toDateTime(),
    lastDate: kLastExpenseDate.toDateTime(),
  );
  return picked?.toDate();
}

/// SA20 / A199: the budget amount, the optional trip dates and (when [showClear]) "Remove budget". Shared by the
/// create-group screen (under the "Trip budget" choice) and the edit-group screen. The budget only tracks spending;
/// it never changes anyone's balance. An empty amount means "no budget".
class BudgetSettingsForm extends StatelessWidget {
  const BudgetSettingsForm({
    super.key,
    required this.amountText,
    required this.amountInvalid,
    required this.start,
    required this.end,
    required this.enabled,
    required this.onAmount,
    required this.onPick,
    required this.onClearDate,
    this.showHeader = true,
    this.onClear,
    this.topUpText,
    this.topUpInvalid = false,
    this.onTopUpText,
    this.onTopUp,
  });

  final String amountText;
  final bool amountInvalid;
  final Date? start;
  final Date? end;
  final bool enabled;
  final ValueChanged<String> onAmount;
  final ValueChanged<bool> onPick;
  final ValueChanged<bool> onClearDate;

  /// The section title and hint (the edit screen); the create screen shows its own radio label instead.
  final bool showHeader;

  /// Null = no "Remove budget" button.
  final VoidCallback? onClear;

  /// "Add to the budget" (edit screen, when a budget is saved): the typed extra amount, an inline error flag, the text
  /// callback and the "Add" button, which adds the amount to [amountText]. Null [topUpText] hides the row.
  final String? topUpText;
  final bool topUpInvalid;
  final ValueChanged<String>? onTopUpText;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Semantics(header: true, child: Text(l10n.budgetSectionTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.xs),
          Text(l10n.budgetSectionHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.sm),
        ],
        Text(l10n.budgetAmountLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.xs),
        AmountBox(
          text: amountText,
          semanticLabel: l10n.budgetAmountLabel,
          expand: true,
          hasError: amountInvalid,
          enabled: enabled,
          onChanged: onAmount,
        ),
        if (amountInvalid) ...[
          const SizedBox(height: QesmaSpacing.xs),
          Text(l10n.budgetAmountError, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)),
        ],
        if (topUpText != null) ...[
          const SizedBox(height: QesmaSpacing.md),
          Text(l10n.budgetTopUpLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: QesmaSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AmountBox(
                  text: topUpText!,
                  semanticLabel: l10n.budgetTopUpLabel,
                  expand: true,
                  hasError: topUpInvalid,
                  enabled: enabled,
                  onChanged: onTopUpText ?? (_) {},
                ),
              ),
              const SizedBox(width: QesmaSpacing.sm),
              AppButton(
                label: l10n.budgetTopUpAction,
                icon: Icons.add,
                expand: false,
                onPressed: enabled && topUpText!.trim().isNotEmpty ? onTopUp : null,
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.xs),
          Text(
            topUpInvalid ? l10n.budgetTopUpError : l10n.budgetTopUpHint,
            style: theme.textTheme.bodySmall?.copyWith(color: topUpInvalid ? context.colors.error : context.colors.textSecondary),
          ),
        ],
        const SizedBox(height: QesmaSpacing.sm),
        TripDateRow(label: l10n.budgetStartLabel, date: start, enabled: enabled, onPick: () => onPick(true), onClear: () => onClearDate(true)),
        const SizedBox(height: QesmaSpacing.sm),
        TripDateRow(label: l10n.budgetEndLabel, date: end, enabled: enabled, onPick: () => onPick(false), onClear: () => onClearDate(false)),
        if (onClear != null && amountText.trim().isNotEmpty) ...[
          const SizedBox(height: QesmaSpacing.sm),
          AppButton(
            label: l10n.budgetClear,
            icon: Icons.delete_outline,
            variant: AppButtonVariant.secondary,
            onPressed: enabled ? onClear : null,
          ),
        ],
      ],
    );
  }
}

class TripDateRow extends StatelessWidget {
  const TripDateRow({super.key, required this.label, required this.date, required this.enabled, required this.onPick, required this.onClear});

  final String label;
  final Date? date;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = date == null ? l10n.budgetDateNotSet : dateText(date!);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            enabled: enabled,
            excludeSemantics: true,
            label: '$label: $value',
            onTap: enabled ? onPick : null,
            child: AppCard(
              onTap: enabled ? onPick : null,
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: context.colors.textHelper),
                  const SizedBox(width: QesmaSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                        Text(value, style: theme.textTheme.titleSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (date != null)
          IconButton(icon: const Icon(Icons.close), tooltip: l10n.budgetDateClear, onPressed: enabled ? onClear : null),
      ],
    );
  }
}
