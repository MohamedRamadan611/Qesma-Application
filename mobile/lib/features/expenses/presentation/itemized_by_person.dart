import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import 'member_picker_sheet.dart';

/// "By person": choose one person (their running total is the preview's), then tick the items they shared. An item
/// nobody shares is flagged (SA16, STANDALONE_SPEC 18.5).
class ByPersonView extends ConsumerWidget {
  const ByPersonView({super.key, required this.formKey, required this.form, required this.members, required this.current, required this.personId, required this.onPerson});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;
  final ExpensePreview? current;
  final String? personId;
  final ValueChanged<String> onPerson;

  /// What the preview says this person owes (null while the bill has no current preview or they owe nothing).
  int? _owed(String memberId) => current?.members.where((s) => s.memberId == memberId).firstOrNull?.owedMinor;

  Widget? _owedText(String memberId) {
    final owed = _owed(memberId);
    return owed == null ? null : Padding(padding: const EdgeInsetsDirectional.only(start: QesmaSpacing.sm), child: MoneyText(owed, size: MoneySize.small));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final items = form.itemized.items;
    final memberIds = [for (final m in members) m.id];
    final person = members.where((m) => m.id == personId).firstOrNull ?? members.firstOrNull;
    if (person == null) return const SizedBox.shrink();

    final selector = Semantics(
      button: true,
      label: '${l10n.expenseItzPersonPick}: ${person.displayName}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: () async {
            final chosen = await showSingleMemberPicker(context, title: l10n.expenseItzPersonPick, members: members, selectedId: person.id, trailingFor: _owedText);
            if (chosen != null) onPerson(chosen);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: DecoratedBox(
              decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(QesmaRadii.control), border: Border.all(color: context.colors.buttonBorder)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.xs),
                child: Row(
                  children: [
                    MemberAvatar(memberId: person.id, name: person.displayName, size: 32),
                    const SizedBox(width: QesmaSpacing.sm),
                    Expanded(child: Text(person.displayName, style: theme.textTheme.titleMedium)),
                    if (_owed(person.id) != null) MoneyText(_owed(person.id)!, size: MoneySize.small),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (items.isEmpty) {
      return Text(l10n.expenseItzPersonNoItemsYet, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        selector,
        const SizedBox(height: QesmaSpacing.sm),
        Text(l10n.expenseItzPersonHint(person.displayName), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: QesmaSpacing.sm),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            AppButton(label: l10n.expenseItzPersonAllItems, icon: Icons.done_all, variant: AppButtonVariant.secondary, expand: false, onPressed: () => controller.setPersonOnAllItems(person.id, on: true)),
            AppButton(label: l10n.expenseItzPersonNoItems, icon: Icons.remove_done, variant: AppButtonVariant.text, expand: false, onPressed: () => controller.setPersonOnAllItems(person.id, on: false)),
          ],
        ),
        const SizedBox(height: QesmaSpacing.xs),
        for (var i = 0; i < items.length; i++)
          _ItemCheckRow(
            item: items[i],
            heading: items[i].trimmedName.isEmpty ? l10n.expenseItemizedItemHeading('${i + 1}') : items[i].trimmedName,
            checked: items[i].assigneeIds.contains(person.id),
            nobody: items[i].assigneesAmong(memberIds).isEmpty,
            onToggle: () => controller.toggleAssigneeForPerson(person.id, items[i].id),
          ),
      ],
    );
  }
}

class _ItemCheckRow extends StatelessWidget {
  const _ItemCheckRow({required this.item, required this.heading, required this.checked, required this.nobody, required this.onToggle});

  final ItemDraft item;
  final String heading;
  final bool checked;
  final bool nobody;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unit = item.amountMinor;
    final line = unit == null ? null : l10n.expenseItzLineTimes(ltrIsolate('${item.quantity}'), moneyDisplay(l10n, unit));
    return Semantics(
      container: true,
      checked: checked,
      label: line == null ? heading : '$heading, $line',
      hint: nobody ? l10n.expenseItzPersonUnassigned(heading) : null,
      onTap: onToggle,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Checkbox(value: checked, onChanged: (_) => onToggle()),
                    Expanded(child: Text(heading, style: theme.textTheme.titleMedium)),
                    if (line != null) Text(line, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                  ],
                ),
                if (nobody)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: kMinTouch, bottom: QesmaSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: context.colors.error, size: 18),
                        const SizedBox(width: QesmaSpacing.xs),
                        Expanded(child: Text(l10n.expenseItzPersonUnassigned(heading), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
