import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../receipt_scan/application/receipt_scan_providers.dart';
import '../../receipt_scan/presentation/scan_flow.dart';
import '../application/expense_draft.dart' show ScanNote;
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import 'assignee_summary_chip.dart';
import 'expense_ui.dart';
import 'itemized_by_person.dart';
import 'member_picker_sheet.dart';
import 'status_banner.dart';
import 'unit_split_sheet.dart';

/// How the items are handed out: one card per item, or one person at a time (SA16, STANDALONE_SPEC 18.5).
enum AssignmentMode { byItem, byPerson }

/// The items: header, scan button, the mode switch and either the cards (by item) or the checklist (by person), then
/// "add an item" and the server's subtotal. Nothing here calculates money: the subtotal and the person totals are the
/// preview's, the line shows the typed quantity and price as typed.
class ItemsCard extends ConsumerWidget {
  const ItemsCard({
    super.key,
    required this.formKey,
    required this.form,
    required this.members,
    required this.current,
    required this.mode,
    required this.onMode,
    required this.personId,
    required this.onPerson,
  });

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;

  /// The preview for the bill as it is now (null until it arrives).
  final ExpensePreview? current;
  final AssignmentMode mode;
  final ValueChanged<AssignmentMode> onMode;
  final String? personId;
  final ValueChanged<String> onPerson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final items = form.itemized.items;
    final atLimit = items.length >= kMaxItems;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(Icons.receipt_long_outlined, color: context.colors.primary)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(child: Semantics(header: true, child: Text(l10n.expenseItemizedItemsTitle, style: theme.textTheme.titleMedium))),
              Text(
                countPhrase(items.length, one: l10n.expenseItemsCountOne, two: l10n.expenseItemsCountTwo, few: l10n.expenseItemsCount, many: l10n.expenseItemsCountMany),
                style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.xs),
          Text(l10n.expenseItzRequiredFieldsNote, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.md),
          // SA12: scan the receipt into these items (the user still assigns members and confirms every number).
          if (ref.watch(receiptScanVisibleProvider)) ...[
            AppButton(
              label: l10n.scanReceiptAction,
              icon: Icons.document_scanner_outlined,
              variant: AppButtonVariant.tonal,
              onPressed: () => _scan(context, ref, formKey, form),
            ),
            const SizedBox(height: QesmaSpacing.md),
          ],
          for (final note in form.scanNotes) ...[
            StatusBanner(
              icon: Icons.warning_amber_outlined,
              text: switch (note) {
                ScanNote.flaggedItems => l10n.scanFlaggedHint,
                ScanNote.needsPercent => l10n.scanNeedsPercent,
                ScanNote.truncated => l10n.scanTruncated,
              },
              tone: BannerTone.warning,
            ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          _ModeSwitch(mode: mode, onMode: onMode),
          const SizedBox(height: QesmaSpacing.md),
          if (mode == AssignmentMode.byItem)
            for (var i = 0; i < items.length; i++) ...[
              ItemCard(
                key: ValueKey(items[i].id),
                index: i + 1,
                item: items[i],
                members: members,
                showAllErrors: form.showAllErrors,
                onName: (v) => controller.setItemName(items[i].id, v),
                onAmount: (v) => controller.setItemAmount(items[i].id, v),
                onQuantity: (delta) => controller.stepItemQuantity(items[i].id, delta),
                onAssignees: (ids) => controller.setAssignees(items[i].id, ids),
                onToggle: (memberId) => controller.toggleAssignee(items[i].id, memberId),
                onDuplicate: atLimit ? null : () => controller.duplicateItem(items[i].id),
                onSplit: (map) => controller.splitItemUnits(items[i].id, map),
                onRemove: () {
                  final removed = controller.removeItem(items[i].id);
                  if (removed == null) return;
                  showAppSnackBar(context, l10n.expenseItzItemDeleted, actionLabel: l10n.expenseItzUndo, onAction: () => controller.restoreItem(removed.item, removed.index));
                },
              ),
              const SizedBox(height: QesmaSpacing.sm + 4),
            ]
          else
            ByPersonView(formKey: formKey, form: form, members: members, current: current, personId: personId, onPerson: onPerson),
          const SizedBox(height: QesmaSpacing.xs),
          AppButton(
            label: l10n.expenseItemizedAdd,
            icon: Icons.add_circle_outline,
            variant: AppButtonVariant.secondary,
            onPressed: atLimit ? null : controller.addItem,
          ),
          if (atLimit)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.sm),
              child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedLimit, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary))),
            ),
          if (current?.subtotalMinor != null) ...[
            const SizedBox(height: QesmaSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
              child: Padding(
                padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.expenseSubtotal, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))),
                    MoneyText(current!.subtotalMinor!, size: MoneySize.medium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "By item | By person".
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onMode});

  final AssignmentMode mode;
  final ValueChanged<AssignmentMode> onMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.expenseItzModeLabel,
      child: SegmentedButton<AssignmentMode>(
        showSelectedIcon: true,
        segments: [
          ButtonSegment(value: AssignmentMode.byItem, label: Text(l10n.expenseItzModeByItem), icon: const Icon(Icons.receipt_long_outlined)),
          ButtonSegment(value: AssignmentMode.byPerson, label: Text(l10n.expenseItzModeByPerson), icon: const Icon(Icons.person_outline)),
        ],
        selected: {mode},
        onSelectionChanged: (value) => onMode(value.first),
        style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, kMinTouch))),
      ),
    );
  }
}

/// Runs the receipt scan from the editor; a proposal replaces the items (after asking when some were typed).
Future<void> _scan(BuildContext context, WidgetRef ref, ExpenseFormKey key, ExpenseFormState form) async {
  final l10n = AppLocalizations.of(context);
  final typed = form.itemized.items.any((i) => i.name.trim().isNotEmpty || i.amountText.trim().isNotEmpty);
  if (typed) {
    final replace = await showConfirmDialog(
      context,
      title: l10n.scanReplaceTitle,
      message: l10n.scanReplaceBody,
      confirmLabel: l10n.scanReplaceConfirm,
    );
    if (!replace || !context.mounted) return;
  }
  final result = await runReceiptScan(context, ref);
  if (result case ScanFlowDraft(:final draft)) {
    ref.read(expenseFormControllerProvider(key).notifier).applyScan(draft);
  }
}

enum _ItemAction { duplicate, split, delete }

/// One item, compact: name and the ⋮ menu, then quantity and unit price, then who shared it and the line. Groups of
/// [kInlineChipMembers] or fewer keep inline chips; bigger groups get the summary chip and the member picker.
class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.members,
    required this.showAllErrors,
    required this.onName,
    required this.onAmount,
    required this.onQuantity,
    required this.onAssignees,
    required this.onToggle,
    required this.onDuplicate,
    required this.onSplit,
    required this.onRemove,
  });

  final int index;
  final ItemDraft item;
  final List<MemberDto> members;
  final bool showAllErrors;
  final ValueChanged<String> onName;
  final ValueChanged<String> onAmount;
  final ValueChanged<int> onQuantity;
  final ValueChanged<Set<String>> onAssignees;
  final ValueChanged<String> onToggle;
  final VoidCallback? onDuplicate;
  final bool Function(Map<String, int>) onSplit;
  final VoidCallback onRemove;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  late final TextEditingController _name = TextEditingController(text: widget.item.name);
  late final TextEditingController _amount = TextEditingController(text: widget.item.amountText);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  String get _heading => widget.item.trimmedName.isEmpty ? AppLocalizations.of(context).expenseItemizedItemHeading('${widget.index}') : widget.item.trimmedName;

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final memberIds = [for (final m in widget.members) m.id];
    final chosen = await showMemberPicker(
      context,
      title: l10n.expenseItzPickerTitle(_heading),
      members: widget.members,
      selected: widget.item.assigneesAmong(memberIds),
    );
    if (chosen != null) widget.onAssignees(chosen);
  }

  Future<void> _split() async {
    final result = await showUnitSplitSheet(context, itemName: widget.item.trimmedName, quantity: widget.item.quantity, members: widget.members);
    if (result != null) widget.onSplit(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final memberIds = [for (final m in widget.members) m.id];
    final assignees = item.assigneesAmong(memberIds);
    final shown = item.touched || widget.showAllErrors;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final inline = widget.members.length <= kInlineChipMembers;

    final menu = PopupMenuButton<_ItemAction>(
      tooltip: l10n.expenseItzItemMenuSpoken('${widget.index}'),
      icon: const Icon(Icons.more_vert),
      constraints: const BoxConstraints(minWidth: 200),
      onSelected: (action) {
        switch (action) {
          case _ItemAction.duplicate:
            widget.onDuplicate?.call();
          case _ItemAction.split:
            _split();
          case _ItemAction.delete:
            widget.onRemove();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: _ItemAction.duplicate, enabled: widget.onDuplicate != null, height: kMinTouch, child: Row(children: [const Icon(Icons.copy_outlined, size: 20), const SizedBox(width: QesmaSpacing.sm), Flexible(child: Text(l10n.expenseItzDuplicate))])),
        if (item.quantity > 1 && widget.members.length > 1)
          PopupMenuItem(value: _ItemAction.split, height: kMinTouch, child: Row(children: [const Icon(Icons.call_split, size: 20), const SizedBox(width: QesmaSpacing.sm), Flexible(child: Text(l10n.expenseItzSplitUnits))])),
        PopupMenuItem(
          value: _ItemAction.delete,
          height: kMinTouch,
          child: Row(children: [Icon(Icons.delete_outline, size: 20, color: context.colors.error), const SizedBox(width: QesmaSpacing.sm), Flexible(child: Text(l10n.expenseItzDeleteItem, style: TextStyle(color: context.colors.error)))]),
        ),
      ],
    );

    final nameField = AppTextField(
      controller: _name,
      label: '${l10n.expenseItemizedNameLabel} *',
      hint: l10n.expenseItemizedNameHint,
      maxLength: kItemNameMax,
      showClear: false,
      errorText: shown && !item.nameValid ? l10n.expenseItemizedNameRequired : null,
      textInputAction: TextInputAction.next,
      onChanged: widget.onName,
    );
    final stepper = QuantityStepper(quantity: item.quantity, name: _heading, onStep: widget.onQuantity);
    final priceField = AppTextField(
      controller: _amount,
      label: '${item.quantity > 1 ? l10n.expenseItzUnitPriceLabel : l10n.expenseItemizedAmountLabel} *',
      hint: l10n.expenseFormAmountHint,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [amountInputFormatter],
      showClear: false,
      errorText: shown && item.amountMinor == null ? l10n.expenseItemizedAmountInvalid : null,
      onChanged: widget.onAmount,
    );
    final line = _LineText.of(item);

    final chips = inline
        ? Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.xs,
            children: [
              for (final member in widget.members)
                AppChoiceChip(label: member.displayName, selected: item.assigneeIds.contains(member.id), onSelected: (_) => widget.onToggle(member.id)),
            ],
          )
        : AssigneeSummaryChip(
            people: [for (final m in widget.members) if (assignees.contains(m.id)) m],
            totalMembers: widget.members.length,
            hasError: assignees.isEmpty,
            onTap: _pick,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: context.colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm + 4, QesmaSpacing.sm, QesmaSpacing.xs, QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(top: QesmaSpacing.xs), child: nameField)),
                menu,
              ],
            ),
            const SizedBox(height: QesmaSpacing.sm),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: QesmaSpacing.sm + 4),
              child: stacked
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Align(alignment: AlignmentDirectional.centerStart, child: stepper), const SizedBox(height: QesmaSpacing.sm), priceField])
                  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [stepper, const SizedBox(width: QesmaSpacing.sm), Expanded(child: priceField)]),
            ),
            const SizedBox(height: QesmaSpacing.sm),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: QesmaSpacing.sm + 4),
              child: inline
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chips, if (line != null) Align(alignment: AlignmentDirectional.centerEnd, child: line)])
                  : Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: QesmaSpacing.sm,
                      runSpacing: QesmaSpacing.xs,
                      children: [chips, ?line],
                    ),
            ),
            if (assignees.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: QesmaSpacing.xs, end: QesmaSpacing.sm + 4),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                      const SizedBox(width: QesmaSpacing.xs),
                      Expanded(child: Text(l10n.expenseItemizedNoAssignee, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
                    ],
                  ),
                ),
              ),
            if (shown && item.quantityValid == false)
              Text(l10n.expenseItzQuantityInvalid, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)),
          ],
        ),
      ),
    );
  }
}

/// The line of an item as typed: the price for one unit, or "3 × 15.25 EGP" for several. Never multiplied here; the
/// saved bill shows the server's line total (SA16 decision).
class _LineText extends StatelessWidget {
  const _LineText({required this.item});

  final ItemDraft item;

  static _LineText? of(ItemDraft item) => item.amountMinor == null ? null : _LineText(item: item);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = item.amountMinor;
    if (unit == null) return const SizedBox.shrink();
    if (item.quantity == 1) return MoneyText(unit, size: MoneySize.small);
    final text = l10n.expenseItzLineTimes(ltrIsolate('${item.quantity}'), moneyDisplay(l10n, unit));
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

/// − n +: two 48 dp buttons around the number; a screen reader hears "Quantity n" and can adjust it.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.quantity, required this.name, required this.onStep});

  final int quantity;
  final String name;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$name: ${l10n.expenseItzQuantityLabel}',
      value: '$quantity',
      increasedValue: '${quantity + 1}',
      decreasedValue: '${quantity - 1}',
      onIncrease: quantity < kMaxQuantity ? () => onStep(1) : null,
      onDecrease: quantity > kMinQuantity ? () => onStep(-1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: l10n.expenseItzQuantityMinus, onPressed: quantity > kMinQuantity ? () => onStep(-1) : null),
          ExcludeSemantics(child: SizedBox(width: 32, child: Center(child: Text(ltrIsolate('$quantity'), style: theme.textTheme.titleMedium)))),
          IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: l10n.expenseItzQuantityPlus, onPressed: quantity < kMaxQuantity ? () => onStep(1) : null),
        ],
      ),
    );
  }
}
