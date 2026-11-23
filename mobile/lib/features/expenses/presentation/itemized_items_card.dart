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

/// How the items are handed out: one card per item, or one person at a time (SA16, STANDALONE_SPEC 18.5).
enum AssignmentMode { byItem, byPerson }

/// The items: header with the scan button, scan notices, the mode switch and either the item accordion (by item) or the
/// person cards (by person), then "add an item" and the server's subtotal. Nothing here calculates money: the subtotal
/// and the person totals are the preview's, the line shows the typed quantity and price as typed.
///
/// By item, one item is open at a time (the redesign): the others are a one-line row with the name, who shares it and
/// the typed price. A new item opens; a tap on a problem in the validation summary opens that item.
class ItemsCard extends ConsumerStatefulWidget {
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
  ConsumerState<ItemsCard> createState() => _ItemsCardState();
}

class _ItemsCardState extends ConsumerState<ItemsCard> {
  /// The open item: null until decided (then the first item is open), [_none] when the user closed it.
  String? _expandedId;
  static const String _none = '';
  int _seenNonce = 0;
  final Map<String, GlobalKey> _keys = {};

  GlobalKey _keyOf(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  /// The open item's id: the chosen one while it still exists, else the first item (nothing when the user closed it).
  String? _effectiveOpen(List<ItemDraft> items) {
    if (items.isEmpty) return null;
    final id = _expandedId;
    if (id == _none) return null;
    if (id != null && items.any((i) => i.id == id)) return id;
    return items.first.id;
  }

  void _open(String id, {bool scroll = false}) {
    setState(() => _expandedId = id);
    if (!scroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keyOf(id).currentContext;
      if (mounted && context != null && context.mounted) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 250), alignment: 0.05);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _seenNonce = widget.form.openItemNonce;
  }

  @override
  void didUpdateWidget(ItemsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nonce = widget.form.openItemNonce;
    final id = widget.form.openItemId;
    if (nonce != _seenNonce) {
      _seenNonce = nonce;
      if (id != null) {
        if (widget.mode != AssignmentMode.byItem) widget.onMode(AssignmentMode.byItem);
        _open(id, scroll: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final form = widget.form;
    final controller = ref.read(expenseFormControllerProvider(widget.formKey).notifier);
    final items = form.itemized.items;
    final atLimit = items.length >= kMaxItems;
    final open = _effectiveOpen(items);
    final memberIds = [for (final m in widget.members) m.id];

    final scan = ref.watch(receiptScanVisibleProvider)
        ? AppButton(
            label: l10n.scanReceiptAction,
            icon: Icons.document_scanner_outlined,
            variant: AppButtonVariant.tonal,
            expand: false,
            onPressed: () => _scan(context, ref, widget.formKey, form),
          )
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The title, the count and (when the feature is on) the scan button: a wrap, so at large text the button
          // drops under the title instead of squeezing it.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: Icon(Icons.receipt_long_outlined, color: context.colors.primary)),
                  const SizedBox(width: QesmaSpacing.sm),
                  Flexible(
                    child: Semantics(header: true, child: Text(l10n.expenseItemizedItemsTitle, style: theme.textTheme.titleMedium)),
                  ),
                  const SizedBox(width: QesmaSpacing.sm),
                  Flexible(
                    child: Text(
                      countPhrase(
                        items.length,
                        one: l10n.expenseItemsCountOne,
                        two: l10n.expenseItemsCountTwo,
                        few: l10n.expenseItemsCount,
                        many: l10n.expenseItemsCountMany,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
                    ),
                  ),
                ],
              ),
              ?scan,
            ],
          ),
          const SizedBox(height: QesmaSpacing.md),
          for (final note in form.scanNotes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StatusBanner(
                    icon: _isInfoNote(note) ? Icons.info_outline : Icons.warning_amber_outlined,
                    text: switch (note) {
                      ScanNote.flaggedItems => l10n.scanFlaggedHint,
                      ScanNote.quantityCheck => l10n.scanQuantityCheck,
                      ScanNote.unitPriceCheck => l10n.scanUnitPriceCheck,
                      ScanNote.discountFound => l10n.scanDiscountFound,
                      ScanNote.discountPercentKept => l10n.scanDiscountPercentKept,
                      ScanNote.discountDropped => l10n.scanDiscountDropped,
                      ScanNote.titleCategorySuggested => l10n.scanTitleCategorySuggested,
                      ScanNote.truncated => l10n.scanTruncated,
                    },
                    tone: _isInfoNote(note) ? BannerTone.neutral : BannerTone.warning,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), tooltip: l10n.commonClose, onPressed: () => controller.dismissScanNote(note)),
              ],
            ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          _ModeSwitch(mode: widget.mode, onMode: widget.onMode),
          const SizedBox(height: QesmaSpacing.md),
          if (widget.mode == AssignmentMode.byItem)
            for (var i = 0; i < items.length; i++) ...[
              KeyedSubtree(
                key: _keyOf(items[i].id),
                child: items[i].id == open
                    ? ItemCard(
                        key: ValueKey(items[i].id),
                        index: i + 1,
                        item: items[i],
                        members: widget.members,
                        showAllErrors: form.showAllErrors,
                        onName: (v) => controller.setItemName(items[i].id, v),
                        onAmount: (v) => controller.setItemAmount(items[i].id, v),
                        onQuantity: (delta) => controller.stepItemQuantity(items[i].id, delta),
                        onAssignees: (ids) => controller.setAssignees(items[i].id, ids),
                        onDuplicate: atLimit ? null : () => controller.duplicateItem(items[i].id),
                        onSplit: (map) => controller.splitItemUnits(items[i].id, map),
                        onCollapse: items.length > 1 ? () => setState(() => _expandedId = _none) : null,
                        onRemove: () {
                          final removed = controller.removeItem(items[i].id);
                          if (removed == null) return;
                          showAppSnackBar(
                            context,
                            l10n.expenseItzItemDeleted,
                            actionLabel: l10n.expenseItzUndo,
                            onAction: () => controller.restoreItem(removed.item, removed.index),
                          );
                        },
                      )
                    : ItemSummaryRow(
                        index: i + 1,
                        item: items[i],
                        members: widget.members,
                        memberIds: memberIds,
                        showAllErrors: form.showAllErrors,
                        onTap: () => _open(items[i].id),
                      ),
              ),
              const SizedBox(height: QesmaSpacing.sm),
            ]
          else
            ByPersonView(
              formKey: widget.formKey,
              form: form,
              members: widget.members,
              current: widget.current,
              personId: widget.personId,
              onPerson: widget.onPerson,
            ),
          const SizedBox(height: QesmaSpacing.xs),
          AppButton(
            label: l10n.expenseItemizedAdd,
            icon: Icons.add_circle_outline,
            variant: AppButtonVariant.secondary,
            onPressed: atLimit
                ? null
                : () {
                    final id = controller.addItem();
                    if (id != null) _open(id, scroll: true);
                    if (widget.mode != AssignmentMode.byItem) widget.onMode(AssignmentMode.byItem);
                  },
          ),
          if (atLimit)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(l10n.expenseItemizedLimit, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ),
            ),
          if (widget.current?.subtotalMinor != null) ...[
            const SizedBox(height: QesmaSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
              child: Padding(
                padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.expenseSubtotal, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                    ),
                    MoneyText(widget.current!.subtotalMinor!, size: MoneySize.medium),
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
    final replace = await showConfirmDialog(context, title: l10n.scanReplaceTitle, message: l10n.scanReplaceBody, confirmLabel: l10n.scanReplaceConfirm);
    if (!replace || !context.mounted) return;
  }
  final result = await runReceiptScan(context, ref);
  if (result case ScanFlowDraft(:final draft)) {
    ref.read(expenseFormControllerProvider(key).notifier).applyScan(draft);
  }
}

enum _ItemAction { duplicate, delete }

/// A closed item: the name, "× quantity · who", the typed price and a chevron; an error icon (and a spoken hint) when
/// something in it is missing. One tap opens it.
class ItemSummaryRow extends StatelessWidget {
  const ItemSummaryRow({
    super.key,
    required this.index,
    required this.item,
    required this.members,
    required this.memberIds,
    required this.showAllErrors,
    required this.onTap,
  });

  final int index;
  final ItemDraft item;
  final List<MemberDto> members;
  final List<String> memberIds;
  final bool showAllErrors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final heading = item.trimmedName.isEmpty ? l10n.expenseItemizedItemHeading('$index') : item.trimmedName;
    final assignees = item.assigneesAmong(memberIds);
    final names = [
      for (final m in members)
        if (assignees.contains(m.id)) m.displayName,
    ];
    final shown = item.touched || showAllErrors;
    final broken = shown && !item.validFor(memberIds);
    final who = names.isEmpty
        ? l10n.expenseItzSummaryNone
        : (names.length == members.length && members.length > 1 ? l10n.expenseItzSummaryAll : names.join(l10n.expenseListSeparator));
    final line = _LineText.of(item);
    return Semantics(
      button: true,
      label: l10n.expenseItzItemExpandSpoken(heading),
      hint: broken ? l10n.expenseItzItemNeedsFixing : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch + 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(QesmaRadii.control),
                border: Border.all(color: broken ? context.colors.error : context.colors.hairline, width: broken ? 1.5 : 1),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm + 4, QesmaSpacing.sm, QesmaSpacing.sm, QesmaSpacing.sm),
                child: Row(
                  children: [
                    if (broken) ...[Icon(Icons.error_outline, color: context.colors.error, size: 20), const SizedBox(width: QesmaSpacing.sm)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(heading, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            '× ${ltrIsolate('${item.quantity}')} · $who',
                            style: theme.textTheme.bodySmall?.copyWith(color: names.isEmpty && shown ? context.colors.error : context.colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (line != null) ...[const SizedBox(width: QesmaSpacing.sm), Flexible(child: line)],
                    const SizedBox(width: QesmaSpacing.xs),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The open item: name and ⋮ menu, then price and quantity side by side, then who shared it (one button that opens the
/// member picker, whatever the group size) and the typed line. Inline errors always have an icon and words.
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
    required this.onDuplicate,
    required this.onSplit,
    required this.onRemove,
    this.onCollapse,
  });

  final int index;
  final ItemDraft item;
  final List<MemberDto> members;
  final bool showAllErrors;
  final ValueChanged<String> onName;
  final ValueChanged<String> onAmount;
  final ValueChanged<int> onQuantity;
  final ValueChanged<Set<String>> onAssignees;
  final VoidCallback? onDuplicate;
  final bool Function(Map<String, int>) onSplit;
  final VoidCallback onRemove;

  /// Closes the card (null when it is the only item).
  final VoidCallback? onCollapse;

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
      title: l10n.expenseItzPickerTitleShort,
      subtitle: _heading,
      members: widget.members,
      selected: widget.item.assigneesAmong(memberIds),
      quantity: widget.item.quantity,
      unitPriceMinor: widget.item.amountMinor,
    );
    switch (chosen) {
      case PickedEqual(:final ids):
        widget.onAssignees(ids);
      case PickedUnits(:final units):
        widget.onSplit(units);
      case null:
        break;
    }
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

    final menu = PopupMenuButton<_ItemAction>(
      tooltip: l10n.expenseItzItemMenuSpoken('${widget.index}'),
      icon: const Icon(Icons.more_vert),
      constraints: const BoxConstraints(minWidth: 200),
      onSelected: (action) {
        switch (action) {
          case _ItemAction.duplicate:
            widget.onDuplicate?.call();
          case _ItemAction.delete:
            widget.onRemove();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ItemAction.duplicate,
          enabled: widget.onDuplicate != null,
          height: kMinTouch,
          child: Row(
            children: [
              const Icon(Icons.copy_outlined, size: 20),
              const SizedBox(width: QesmaSpacing.sm),
              Flexible(child: Text(l10n.expenseItzDuplicate)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ItemAction.delete,
          height: kMinTouch,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: context.colors.error),
              const SizedBox(width: QesmaSpacing.sm),
              Flexible(
                child: Text(l10n.expenseItzDeleteItem, style: TextStyle(color: context.colors.error)),
              ),
            ],
          ),
        ),
      ],
    );

    final collapse = widget.onCollapse == null
        ? null
        : IconButton(icon: const Icon(Icons.expand_less), tooltip: l10n.expenseItzItemCollapseSpoken(_heading), onPressed: widget.onCollapse);
    final nameField = AppTextField(
      controller: _name,
      label: '${l10n.expenseItemizedNameLabel} *',
      hint: l10n.expenseItemizedNameHint,
      inputFormatters: const [CodePointLimitFormatter(kItemNameMax)],
      showClear: false,
      errorText: shown && !item.nameValid ? l10n.expenseItemizedNameRequired : null,
      textInputAction: TextInputAction.next,
      onChanged: widget.onName,
    );
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
    final stepper = LabeledStepper(quantity: item.quantity, name: _heading, onStep: widget.onQuantity);
    final line = _LineText.of(item);
    final people = [
      for (final m in widget.members)
        if (assignees.contains(m.id)) m,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.card),
        border: Border.all(color: context.colors.primaryLight.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.sm + 4, QesmaSpacing.sm + 4, QesmaSpacing.xs, QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // At large text the buttons go above the name field (two 48 dp buttons would squeeze it).
            if (stacked) ...[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(mainAxisSize: MainAxisSize.min, children: [?collapse, menu]),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: QesmaSpacing.sm + 4),
                child: nameField,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: QesmaSpacing.lg),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [?collapse, menu]),
                  ),
                ],
              ),
            const SizedBox(height: QesmaSpacing.sm + 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: QesmaSpacing.sm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Price and quantity share one row: the price takes what the stepper leaves; at large text they stack.
                  if (stacked) ...[
                    priceField,
                    const SizedBox(height: QesmaSpacing.sm + 4),
                    Align(alignment: AlignmentDirectional.centerStart, child: stepper),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: priceField),
                        const SizedBox(width: QesmaSpacing.sm + 4),
                        stepper,
                      ],
                    ),
                  if (shown && item.quantityValid == false)
                    Padding(
                      padding: const EdgeInsets.only(top: QesmaSpacing.xs),
                      child: Row(
                        children: [
                          ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                          const SizedBox(width: QesmaSpacing.xs),
                          Expanded(
                            child: Text(l10n.expenseItzQuantityInvalid, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: QesmaSpacing.sm + 4),
                  // Who shared it: its own full-width row (label above, the names inside), never squeezed beside the price.
                  Text('${l10n.expenseItzWhoShared} *', style: theme.textTheme.labelLarge),
                  const SizedBox(height: QesmaSpacing.xs + 2),
                  AssigneeSummaryChip(people: people, totalMembers: widget.members.length, hasError: assignees.isEmpty, expand: true, onTap: _pick),
                  if (assignees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: QesmaSpacing.xs),
                      child: Semantics(
                        liveRegion: true,
                        child: Row(
                          children: [
                            ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                            const SizedBox(width: QesmaSpacing.xs),
                            Expanded(
                              child: Text(l10n.expenseItemizedNoAssignee, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (line != null) ...[
                    const SizedBox(height: QesmaSpacing.sm + 4),
                    Divider(height: 1, color: context.colors.hairline),
                    const SizedBox(height: QesmaSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.expenseItzLineLabel, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        ),
                        line,
                      ],
                    ),
                  ],
                ],
              ),
            ),
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

/// "Quantity" label above the capsule (the open item card and the by-person fields).
class LabeledStepper extends StatelessWidget {
  const LabeledStepper({super.key, required this.quantity, required this.name, required this.onStep});

  final int quantity;
  final String name;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppLocalizations.of(context).expenseItzQuantityLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.sm),
        QuantityStepper(quantity: quantity, name: name, onStep: onStep),
      ],
    );
  }
}

/// − n + in one bordered capsule (44 dp tall, two 44 dp buttons around the number); a screen reader hears "Quantity n"
/// and can adjust it.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.name,
    required this.onStep,
    this.min = kMinQuantity,
    this.max = kMaxQuantity,
    this.label,
    this.decreaseTooltip,
    this.increaseTooltip,
    this.threeDigits = false,
  });

  final int quantity;
  final String name;
  final ValueChanged<int> onStep;

  /// The range the stepper stays in (an item's quantity by default; SA19 reuses it for shares).
  final int min;
  final int max;

  /// What the value is called for a screen reader and the buttons' tooltips; the item quantity by default.
  final String? label;
  final String? decreaseTooltip;
  final String? increaseTooltip;

  /// Leaves room for a value up to 100 (shares) instead of up to 99 wide.
  final bool threeDigits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget button(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
    return Semantics(
      container: true,
      label: '$name: ${label ?? l10n.expenseItzQuantityLabel}',
      value: '$quantity',
      increasedValue: '${quantity + 1}',
      decreasedValue: '${quantity - 1}',
      onIncrease: quantity < max ? () => onStep(1) : null,
      onDecrease: quantity > min ? () => onStep(-1) : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          border: Border.all(color: context.colors.buttonBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Icons.remove, decreaseTooltip ?? l10n.expenseItzQuantityMinus, quantity > min ? () => onStep(-1) : null),
            ExcludeSemantics(
              child: SizedBox(
                width: threeDigits ? 40 : 28,
                child: Center(child: Text(ltrIsolate('$quantity'), style: theme.textTheme.titleMedium)),
              ),
            ),
            button(Icons.add, increaseTooltip ?? l10n.expenseItzQuantityPlus, quantity < max ? () => onStep(1) : null),
          ],
        ),
      ),
    );
  }
}

/// Notes that tell the user what was filled in (neutral) rather than what needs fixing (warning).
bool _isInfoNote(ScanNote note) => note == ScanNote.discountFound || note == ScanNote.titleCategorySuggested;
