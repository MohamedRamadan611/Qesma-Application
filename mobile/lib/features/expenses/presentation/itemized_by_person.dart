import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import 'expense_ui.dart';
import 'itemized_items_card.dart' show QuantityStepper;

/// "By person" (the redesign): one card per member who has items, with their items, "copy an existing item" chips for
/// the items they are not on, and an inline "add an item for X" form; members with no items are folded under one
/// section. An item nobody shares is flagged at the top. Each person's total is the preview's (SA16, 18.5).
///
/// One card is open at a time. [personId] is the open person (the editor keeps it so switching modes does not lose it).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final items = form.itemized.items;
    final memberIds = [for (final m in members) m.id];
    if (members.isEmpty) return const SizedBox.shrink();

    final withItems = [for (final m in members) if (items.any((i) => i.assigneeIds.contains(m.id))) m];
    final without = [for (final m in members) if (!withItems.contains(m)) m];
    final open = members.any((m) => m.id == personId) ? personId! : (withItems.firstOrNull ?? members.first).id;
    final nobody = [for (var i = 0; i < items.length; i++) if (items[i].assigneesAmong(memberIds).isEmpty) (i, items[i])];

    Widget card(MemberDto m) => _PersonCard(
          key: ValueKey('person-${m.id}'),
          member: m,
          items: items,
          owedMinor: _owed(m.id),
          open: m.id == open,
          onTap: () => onPerson(m.id),
          controller: controller,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.expenseItzPersonByPersonHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: QesmaSpacing.sm),
        if (items.isEmpty)
          Text(l10n.expenseItzPersonNoItemsYet, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
        for (final (index, item) in nobody)
          Padding(
            padding: const EdgeInsets.only(bottom: QesmaSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                  const SizedBox(width: QesmaSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.expenseItzPersonUnassigned(item.trimmedName.isEmpty ? l10n.expenseItemizedItemHeading('${index + 1}') : item.trimmedName),
                      style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (final m in withItems) ...[card(m), const SizedBox(height: QesmaSpacing.sm)],
        if (without.isNotEmpty)
          _WithoutItems(title: l10n.expenseItzMembersWithoutItems('${without.length}'), openInside: without.any((m) => m.id == open), children: [for (final m in without) ...[card(m), const SizedBox(height: QesmaSpacing.sm)]]),
      ],
    );
  }
}

/// The folded "members with no items (n)" section; it opens by itself while one of its people is the open card.
class _WithoutItems extends StatefulWidget {
  const _WithoutItems({required this.title, required this.openInside, required this.children});

  final String title;
  final bool openInside;
  final List<Widget> children;

  @override
  State<_WithoutItems> createState() => _WithoutItemsState();
}

class _WithoutItemsState extends State<_WithoutItems> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = _expanded || widget.openInside;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          label: widget.title,
          onTap: () => setState(() => _expanded = !open),
          child: ExcludeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(QesmaRadii.control),
              onTap: () => setState(() => _expanded = !open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTouch),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.title, style: theme.textTheme.titleSmall?.copyWith(color: context.colors.textSecondary))),
                    Icon(open ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (open) ...[const SizedBox(height: QesmaSpacing.xs), ...widget.children],
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({super.key, required this.member, required this.items, required this.owedMinor, required this.open, required this.onTap, required this.controller});

  final MemberDto member;
  final List<ItemDraft> items;
  final int? owedMinor;
  final bool open;
  final VoidCallback onTap;
  final ExpenseFormController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mine = [for (var i = 0; i < items.length; i++) if (items[i].assigneeIds.contains(member.id)) (i, items[i])];
    final others = [for (var i = 0; i < items.length; i++) if (!items[i].assigneeIds.contains(member.id)) (i, items[i])];
    final count = mine.length;
    final countText = count == 0
        ? l10n.expenseItzPersonNoItemsLine
        : countPhrase(count, one: l10n.expenseItemsCountOne, two: l10n.expenseItemsCountTwo, few: l10n.expenseItemsCount, many: l10n.expenseItemsCountMany);
    String headingOf(int index, ItemDraft item) => item.trimmedName.isEmpty ? l10n.expenseItemizedItemHeading('${index + 1}') : item.trimmedName;

    final header = Semantics(
      button: true,
      expanded: open,
      label: '${member.displayName}, $countText',
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch + 8),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm + 4, QesmaSpacing.xs, QesmaSpacing.sm, QesmaSpacing.xs),
              child: Row(
                children: [
                  MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
                  const SizedBox(width: QesmaSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: QesmaSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(member.displayName, style: theme.textTheme.titleMedium),
                            if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
                          ],
                        ),
                        Text(countText, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (owedMinor != null) MoneyText(owedMinor!, size: MoneySize.small),
                  const SizedBox(width: QesmaSpacing.xs),
                  Icon(open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(QesmaRadii.control), border: Border.all(color: context.colors.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (open)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm + 4, 0, QesmaSpacing.sm + 4, QesmaSpacing.sm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, item) in mine)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: kMinTouch),
                      child: Row(
                        children: [
                          Expanded(child: Text(headingOf(index, item), style: theme.textTheme.titleSmall)),
                          if (item.quantity > 1) Text('× ${ltrIsolate('${item.quantity}')}  ', style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                          if (item.amountMinor != null) MoneyText(item.amountMinor!, size: MoneySize.small),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: l10n.expenseItzPersonRemoveItem(headingOf(index, item), member.displayName),
                            onPressed: () => controller.toggleAssigneeForPerson(member.id, item.id),
                          ),
                        ],
                      ),
                    ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: QesmaSpacing.sm),
                    Text(l10n.expenseItzCopyItem, style: theme.textTheme.labelLarge),
                    const SizedBox(height: QesmaSpacing.xs),
                    Wrap(
                      spacing: QesmaSpacing.sm,
                      runSpacing: QesmaSpacing.xs,
                      children: [
                        for (final (index, item) in others)
                          Semantics(
                            label: l10n.expenseItzCopyItemSpoken(headingOf(index, item), member.displayName),
                            excludeSemantics: true,
                            button: true,
                            child: AppChoiceChip(
                              label: item.amountMinor == null ? headingOf(index, item) : '${headingOf(index, item)} · ${plainAmount(item.amountMinor!)}',
                              selected: false,
                              onSelected: (_) => controller.toggleAssigneeForPerson(member.id, item.id),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: QesmaSpacing.sm),
                  _AddItemForm(member: member, controller: controller, atLimit: items.length >= kMaxItems),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The inline "add an item for X": name, price and quantity typed here, then one button puts the item on the bill with
/// this person as its only assignee. Errors show only after the button was tapped with something missing.
class _AddItemForm extends StatefulWidget {
  const _AddItemForm({required this.member, required this.controller, required this.atLimit});

  final MemberDto member;
  final ExpenseFormController controller;
  final bool atLimit;

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  int _quantity = 1;
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _add() {
    final draft = ItemDraft(id: 'probe', name: _name.text, amountText: _price.text, quantity: _quantity);
    if (!draft.nameValid || draft.amountMinor == null) {
      setState(() => _tried = true);
      return;
    }
    final id = widget.controller.addItemFor(widget.member.id);
    if (id == null) return;
    widget.controller
      ..setItemName(id, _name.text)
      ..setItemAmount(id, _price.text)
      ..setItemQuantity(id, _quantity);
    _name.clear();
    _price.clear();
    setState(() {
      _quantity = 1;
      _tried = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nameOk = ItemDraft(id: 'probe', name: _name.text).nameValid;
    final priceOk = ItemDraft(id: 'probe', amountText: _price.text).amountMinor != null;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final priceField = AppTextField(
      controller: _price,
      label: '${l10n.expenseItemizedAmountLabel} *',
      hint: l10n.expenseFormAmountHint,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [amountInputFormatter],
      showClear: false,
      errorText: _tried && !priceOk ? l10n.expenseItemizedAmountInvalid : null,
    );
    final stepper = QuantityStepper(quantity: _quantity, name: l10n.expenseItzAddItemFor(widget.member.displayName), onStep: (d) => setState(() => _quantity = (_quantity + d).clamp(kMinQuantity, kMaxQuantity)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _name,
          label: '${l10n.expenseItemizedNameLabel} *',
          hint: l10n.expenseItemizedNameHint,
          maxLength: kItemNameMax,
          showClear: false,
          errorText: _tried && !nameOk ? l10n.expenseItemizedNameRequired : null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: QesmaSpacing.sm),
        if (stacked) ...[priceField, const SizedBox(height: QesmaSpacing.sm), Align(alignment: AlignmentDirectional.centerStart, child: stepper)] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: priceField), const SizedBox(width: QesmaSpacing.sm), stepper]),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(
          label: l10n.expenseItzAddItemFor(widget.member.displayName),
          icon: Icons.add_circle_outline,
          variant: AppButtonVariant.secondary,
          onPressed: widget.atLimit ? null : _add,
        ),
      ],
    );
  }
}
