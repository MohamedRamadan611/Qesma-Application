import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import 'status_banner.dart';

/// What the picker returns for an item: the same units for everybody who is chosen (equal), or each person's number of
/// units (by quantity; the controller turns that into one item per person, A172).
sealed class MemberPick {
  const MemberPick();
}

class PickedEqual extends MemberPick {
  const PickedEqual(this.ids);

  final Set<String> ids;
}

class PickedUnits extends MemberPick {
  const PickedUnits(this.units);

  /// Member id to units (only people with at least one); the units add up to the item's quantity.
  final Map<String, int> units;
}

/// Search is offered above this many members (SA16, STANDALONE_SPEC 18.5).
const int kPickerSearchThreshold = 8;

/// Members whose name contains [query] (case-insensitive, trimmed); everyone while the query is empty.
List<MemberDto> filterMembers(List<MemberDto> members, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty ? members : [for (final m in members) if (m.displayName.toLowerCase().contains(q)) m];
}

/// Opens the picker for several members (an item's assignees) and returns the choice, or null when dismissed.
/// Search above 8 members, an all/none toggle, 48 dp rows and a sticky "Done (n)" button. An item with a quantity above
/// 1 (and more than one member) also offers "by quantity": each person gets a number of the units, and the units given
/// must add up to the quantity (counts, never money). [unitPriceMinor] is the typed price, shown as typed.
Future<MemberPick?> showMemberPicker(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<MemberDto> members,
  required Set<String> selected,
  int quantity = 1,
  int? unitPriceMinor,
}) {
  return showModalBottomSheet<MemberPick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _MultiPickerSheet(title: title, subtitle: subtitle, members: members, initial: selected, quantity: quantity, unitPriceMinor: unitPriceMinor),
    ),
  );
}

/// Opens the picker for ONE member (the person selector of the by-person mode) and returns the id, or null.
/// [trailingFor] draws something at the end of a row (the person's running total from the preview).
Future<String?> showSingleMemberPicker(
  BuildContext context, {
  required String title,
  required List<MemberDto> members,
  required String? selectedId,
  Widget? Function(String memberId)? trailingFor,
}) {
  return showAppBottomSheet<String>(
    context,
    title: title,
    child: _PickerBody(members: members, initial: {?selectedId}, multi: false, title: title, trailingFor: trailingFor),
  );
}

class _MultiPickerSheet extends StatefulWidget {
  const _MultiPickerSheet({required this.title, this.subtitle, required this.members, required this.initial, required this.quantity, required this.unitPriceMinor});

  final String title;
  final String? subtitle;
  final List<MemberDto> members;
  final Set<String> initial;
  final int quantity;
  final int? unitPriceMinor;

  @override
  State<_MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<_MultiPickerSheet> {
  late Set<String> _selected = {...widget.initial};
  bool _byQuantity = false;
  final Map<String, int> _units = {};
  String _query = '';

  bool get _canSplitUnits => widget.quantity > 1 && widget.members.length > 1;
  int get _given => _units.values.fold<int>(0, (sum, n) => sum + n);

  void _step(String id, int delta) {
    final next = (_units[id] ?? 0) + delta;
    if (next < 0 || next > widget.quantity) return;
    setState(() => next == 0 ? _units.remove(id) : _units[id] = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quantityMode = _byQuantity && _canSplitUnits;
    final doneEnabled = !quantityMode || (_given == widget.quantity && _units.isNotEmpty);
    final names = quantityMode
        ? [for (final m in widget.members) if ((_units[m.id] ?? 0) > 0) '${m.displayName} ×${ltrIsolate('${_units[m.id]}')}']
        : [for (final m in widget.members) if (_selected.contains(m.id)) m.displayName];
    final count = quantityMode ? _units.length : _selected.length;
    return AppBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (names.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text('${l10n.expenseItzPickerCount('$count', '${widget.members.length}')} · ${names.join(l10n.expenseListSeparator)}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ),
            ),
          AppButton(
        label: l10n.expenseItzPickerDone('${quantityMode ? _units.length : _selected.length}'),
        icon: Icons.check,
        onPressed: doneEnabled ? () => Navigator.of(context).pop(quantityMode ? PickedUnits(Map<String, int>.of(_units)) : PickedEqual(_selected)) : null,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_canSplitUnits) ...[
            Semantics(
              container: true,
              label: l10n.expenseItzModeLabel,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.expenseItzPickerModeEqual)),
                  ButtonSegment(value: true, label: Text(l10n.expenseItzPickerModeQuantity)),
                ],
                selected: {_byQuantity},
                onSelectionChanged: (value) => setState(() => _byQuantity = value.first),
                style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, kMinTouch))),
              ),
            ),
            const SizedBox(height: QesmaSpacing.md),
          ],
          if (quantityMode)
            _QuantityBody(
              quantity: widget.quantity,
              unitPriceMinor: widget.unitPriceMinor,
              members: widget.members,
              units: _units,
              query: _query,
              onQuery: (value) => setState(() => _query = value),
              onStep: _step,
              onClear: () => setState(_units.clear),
            )
          else
            _PickerBody(members: widget.members, initial: _selected, multi: true, title: widget.title, onChanged: (value) => setState(() => _selected = value)),
        ],
      ),
    );
  }
}

/// "By quantity": how many of the units are given out (a count, status with icon and words), the typed line, a row with
/// a stepper per person, and who got what. Nothing here is money arithmetic: the quantity line is shown as typed.
class _QuantityBody extends StatelessWidget {
  const _QuantityBody({
    required this.quantity,
    required this.unitPriceMinor,
    required this.members,
    required this.units,
    required this.query,
    required this.onQuery,
    required this.onStep,
    required this.onClear,
  });

  final int quantity;
  final int? unitPriceMinor;
  final List<MemberDto> members;
  final Map<String, int> units;
  final String query;
  final ValueChanged<String> onQuery;
  final void Function(String id, int delta) onStep;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final given = units.values.fold<int>(0, (sum, n) => sum + n);
    final left = quantity - given;
    final (icon, text, tone) = left == 0
        ? (Icons.check_circle_outline, l10n.expenseItzSplitMatches, BannerTone.success)
        : left > 0
            ? (Icons.warning_amber_rounded, l10n.expenseItzPickerDistributed('$given', '$quantity'), BannerTone.warning)
            : (Icons.error_outline, l10n.expenseItzSplitOver('${-left}'), BannerTone.error);
    final shown = filterMembers(members, query);
    final who = [for (final m in members) if ((units[m.id] ?? 0) > 0) '${m.displayName} ×${ltrIsolate('${units[m.id]}')}'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(icon: icon, text: text, tone: tone),
        const SizedBox(height: QesmaSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                unitPriceMinor == null ? '${l10n.expenseItzQuantityLabel} ${ltrIsolate('$quantity')}' : l10n.expenseItzPickerQtyLine(ltrIsolate('$quantity'), moneyDisplay(l10n, unitPriceMinor!)),
                style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
              ),
            ),
            TextButton(onPressed: units.isEmpty ? null : onClear, child: Text(l10n.expenseItzPickerClearAll)),
          ],
        ),
        if (members.length > kPickerSearchThreshold) ...[
          MemberSearchField(onChanged: onQuery),
          const SizedBox(height: QesmaSpacing.sm),
        ],
        for (final member in shown) _UnitRow(member: member, units: units[member.id] ?? 0, onStep: (d) => onStep(member.id, d)),
        if (who.isNotEmpty) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Semantics(liveRegion: true, child: Text(who.join(l10n.expenseListSeparator), style: theme.textTheme.bodyMedium)),
          const SizedBox(height: QesmaSpacing.xs),
          Text(l10n.expenseItzSplitHint(l10n.expenseItzSplitUnits, '$quantity'), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        ],
      ],
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.member, required this.units, required this.onStep});

  final MemberDto member;
  final int units;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: l10n.expenseItzSplitPersonSpoken(member.displayName, '$units'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouch),
        child: Row(
          children: [
            ExcludeSemantics(child: MemberAvatar(memberId: member.id, name: member.displayName, size: 36)),
            const SizedBox(width: QesmaSpacing.sm + 4),
            Expanded(child: ExcludeSemantics(child: Text(member.displayName, style: theme.textTheme.titleMedium))),
            IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: l10n.expenseItzQuantityMinus, onPressed: units > 0 ? () => onStep(-1) : null),
            ExcludeSemantics(child: SizedBox(width: 28, child: Center(child: Text(ltrIsolate('$units'), style: theme.textTheme.titleMedium)))),
            IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: l10n.expenseItzQuantityPlus, onPressed: () => onStep(1)),
          ],
        ),
      ),
    );
  }
}

/// Search, all/none and the 48 dp rows.
class _PickerBody extends StatefulWidget {
  const _PickerBody({required this.members, required this.initial, required this.multi, required this.title, this.onChanged, this.trailingFor});

  final List<MemberDto> members;
  final Set<String> initial;
  final bool multi;
  final String title;
  final ValueChanged<Set<String>>? onChanged;
  final Widget? Function(String memberId)? trailingFor;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late Set<String> _selected = {...widget.initial};
  String _query = '';

  void _set(Set<String> value) {
    setState(() => _selected = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shown = filterMembers(widget.members, _query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.members.length > kPickerSearchThreshold) ...[
          MemberSearchField(onChanged: (value) => setState(() => _query = value)),
          const SizedBox(height: QesmaSpacing.sm),
        ],
        if (widget.multi) ...[
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppChoiceChip(
                label: l10n.expenseItzPickerAll,
                selected: _selected.length == widget.members.length,
                onSelected: (_) => _set({for (final m in widget.members) m.id}),
              ),
              AppChoiceChip(label: l10n.expenseItzPickerNone, selected: false, onSelected: (_) => _set(<String>{})),
              Semantics(
                liveRegion: true,
                child: Text(l10n.expenseItzPickerCount('${_selected.length}', '${widget.members.length}'), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            child: Text(l10n.expenseItzPickerNoResults, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          ),
        for (final member in shown)
          MemberPickRow(
            member: member,
            selected: _selected.contains(member.id),
            multi: widget.multi,
            trailing: widget.trailingFor?.call(member.id),
            onTap: () {
              if (!widget.multi) {
                Navigator.of(context).pop(member.id);
                return;
              }
              final next = {..._selected};
              if (!next.add(member.id)) next.remove(member.id);
              _set(next);
            },
          ),
      ],
    );
  }
}

/// The search box shown above [kPickerSearchThreshold] members (picker and paid-by sheet).
class MemberSearchField extends StatelessWidget {
  const MemberSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      textField: true,
      label: l10n.expenseItzPickerSearch,
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.expenseItzPickerSearch,
          prefixIcon: const ExcludeSemantics(child: Icon(Icons.search)),
        ),
      ),
    );
  }
}

/// One member row: avatar, name, a check (box when [multi], tick when single) and an optional trailing widget. 48 dp.
class MemberPickRow extends StatelessWidget {
  const MemberPickRow({super.key, required this.member, required this.selected, required this.multi, required this.onTap, this.trailing});

  final MemberDto member;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      checked: multi ? selected : null,
      selected: multi ? null : selected,
      inMutuallyExclusiveGroup: !multi,
      button: !multi,
      label: member.isYou ? '${member.displayName} ${l10n.membersYouTag}' : member.displayName,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Row(
              children: [
                if (multi) Checkbox(value: selected, onChanged: (_) => onTap()) else SizedBox(width: kMinTouch, child: selected ? Icon(Icons.check, color: context.colors.primary) : null),
                MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(
                  child: Wrap(
                    spacing: QesmaSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(member.displayName, style: theme.textTheme.titleMedium),
                      if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
