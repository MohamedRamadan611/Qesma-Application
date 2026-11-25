import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_filters.dart';
import '../data/expense_category.dart';
import 'expense_ui.dart';
import '../../../core/theme/palette.dart';

/// One line: a single "Filter" button (with the number of active filters) and, beside it, one removable chip per
/// active filter. Nothing is shown for a filter that is off, so the common case is just the button.
/// The button opens a small sheet with the three filters; each one then opens its own picker.
class ExpenseFilterBar extends StatelessWidget {
  const ExpenseFilterBar({
    super.key,
    required this.filters,
    required this.nameOf,
    required this.onDate,
    required this.onMember,
    required this.onCategory,
    required this.onClearDate,
    required this.onClearMember,
    required this.onClearCategory,
  });

  final ExpenseFilters filters;
  final String Function(String memberId) nameOf;
  final VoidCallback onDate;
  final VoidCallback onMember;
  final VoidCallback onCategory;
  final VoidCallback onClearDate;
  final VoidCallback onClearMember;
  final VoidCallback onClearCategory;

  String _dateValue(AppLocalizations l10n) {
    final from = filters.from;
    final to = filters.to;
    if (from != null && to != null) return l10n.expenseFilterRange(dateText(from), dateText(to));
    if (from != null) return l10n.expenseFilterFrom(dateText(from));
    if (to != null) return l10n.expenseFilterUntil(dateText(to));
    return l10n.expenseFilterAll;
  }

  void _openMenu(BuildContext context, AppLocalizations l10n, {required String? memberValue, required ExpenseCategory? category}) {
    Widget row(IconData icon, String name, String value, bool active, VoidCallback open) => Builder(
          builder: (sheetContext) => ListTile(
            leading: Icon(icon, color: active ? sheetContext.colors.primary : null),
            title: Text(name),
            subtitle: Text(value),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(sheetContext).pop();
              open();
            },
          ),
        );
    showAppBottomSheet<void>(
      context,
      title: l10n.expenseFilterSheetTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(Icons.calendar_today_outlined, l10n.expenseFilterDate, _dateValue(l10n), filters.hasDateRange, onDate),
          row(Icons.person_outline, l10n.expenseFilterMember, memberValue ?? l10n.expenseFilterAll, memberValue != null, onMember),
          row(category?.icon ?? Icons.category_outlined, l10n.expenseFilterCategory, category?.label(l10n) ?? l10n.expenseFilterAllCategories,
              category != null, onCategory),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final memberId = filters.memberId;
    final memberValue = memberId == null ? null : nameOf(memberId);
    final category = filters.category != null ? ExpenseCategory.fromWire(filters.category) : null;
    final count = (filters.hasDateRange ? 1 : 0) + (memberId != null ? 1 : 0) + (category != null ? 1 : 0);

    final chips = <Widget>[
      if (filters.hasDateRange)
        _ActiveFilterChip(name: l10n.expenseFilterDate, value: _dateValue(l10n), icon: Icons.calendar_today_outlined, onTap: onDate, onClear: onClearDate),
      if (memberValue != null)
        _ActiveFilterChip(name: l10n.expenseFilterMember, value: memberValue, icon: Icons.person_outline, onTap: onMember, onClear: onClearMember),
      if (category != null)
        _ActiveFilterChip(name: l10n.expenseFilterCategory, value: category.label(l10n), icon: category.icon, onTap: onCategory, onClear: onClearCategory),
    ];

    return Row(
      children: [
        _FilterButton(count: count, onTap: () => _openMenu(context, l10n, memberValue: memberValue, category: category)),
        if (chips.isNotEmpty) ...[
          const SizedBox(width: QesmaSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: QesmaSpacing.xs + 2),
                itemBuilder: (_, i) => Center(child: chips[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final active = count > 0;
    final fg = active ? colors.primary : colors.textSecondary;
    return Semantics(
      button: true,
      selected: active,
      label: active ? '${l10n.expenseFilterButton} ($count)' : l10n.expenseFilterButton,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: active ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : colors.card,
        shape: StadiumBorder(side: BorderSide(color: active ? colors.primary : colors.buttonBorder)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 18, color: fg),
                  const SizedBox(width: QesmaSpacing.xs + 2),
                  Text(l10n.expenseFilterButton, style: theme.textTheme.labelLarge?.copyWith(color: fg)),
                  if (active) ...[
                    const SizedBox(width: QesmaSpacing.xs + 2),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: colors.primary,
                      child: Text('$count', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An active filter: its value (tap to change it) and a clear button.
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.name, required this.value, required this.icon, required this.onTap, required this.onClear});

  final String name;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final spoken = '$name: $value';
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      shape: StadiumBorder(side: BorderSide(color: colors.primary)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: spoken,
            excludeSemantics: true,
            onTap: onTap,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, maxWidth: 190),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: QesmaSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: colors.primary),
                      const SizedBox(width: QesmaSpacing.xs),
                      Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge?.copyWith(color: colors.primary))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colors.primary),
            tooltip: l10n.expenseFilterRemove(spoken),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.zero,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// A date range as the user picked it; both null means "no date filter".
typedef DateRangeChoice = ({Date? from, Date? to});

/// Date filter sheet: two date pickers, `from <= to` enforced, apply or clear.
/// Returns null when dismissed (nothing changes).
Future<DateRangeChoice?> showDateFilterSheet(BuildContext context, {required Date? from, required Date? to}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<DateRangeChoice>(
    context,
    title: l10n.expenseFilterDateTitle,
    child: _DateFilterBody(initialFrom: from, initialTo: to),
  );
}

final Date _firstDate = Date(2000, 1, 1);
final Date _lastDate = Date(2100, 12, 31);

class _DateFilterBody extends StatefulWidget {
  const _DateFilterBody({required this.initialFrom, required this.initialTo});

  final Date? initialFrom;
  final Date? initialTo;

  @override
  State<_DateFilterBody> createState() => _DateFilterBodyState();
}

class _DateFilterBodyState extends State<_DateFilterBody> {
  late Date? _from = widget.initialFrom;
  late Date? _to = widget.initialTo;

  bool get _valid => _from == null || _to == null || _from!.compareTo(_to!) <= 0;

  Future<void> _pick({required bool isFrom}) async {
    final current = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: (current ?? Date.now()).toDateTime(),
      firstDate: _firstDate.toDateTime(),
      lastDate: _lastDate.toDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked.toDate();
      } else {
        _to = picked.toDate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget dateRow(String label, Date? value, bool isFrom) => AppButton(
          label: '$label: ${value == null ? l10n.expenseFilterPickDate : dateText(value)}',
          icon: Icons.calendar_today_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => _pick(isFrom: isFrom),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dateRow(l10n.expenseFilterFromLabel, _from, true),
        const SizedBox(height: QesmaSpacing.sm),
        dateRow(l10n.expenseFilterToLabel, _to, false),
        if (!_valid) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Semantics(liveRegion: true, child: Text(l10n.expenseFilterRangeInvalid, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
        ],
        const SizedBox(height: QesmaSpacing.md),
        AppButton(
          label: l10n.expenseFilterApply,
          onPressed: _valid && (_from != null || _to != null) ? () => Navigator.of(context).pop<DateRangeChoice>((from: _from, to: _to)) : null,
        ),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(
          label: l10n.expenseFilterClear,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop<DateRangeChoice>((from: null, to: null)),
        ),
      ],
    );
  }
}

/// Member filter sheet. Returns the chosen member id, an empty string for "all members",
/// or null when dismissed.
Future<String?> showMemberFilterSheet(BuildContext context, {required List<MemberDto> members, required String? selectedId}) {
  final l10n = AppLocalizations.of(context);
  final sorted = members.toList()
    ..sort((a, b) {
      if (a.isYou != b.isYou) return a.isYou ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  return showAppBottomSheet<String>(
    context,
    title: l10n.expenseFilterMemberTitle,
    subtitle: l10n.expenseFilterMemberHint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (sheetContext) => _MemberChoiceRow(
            title: l10n.expenseFilterAllMembers,
            selected: selectedId == null,
            leading: const Icon(Icons.groups_outlined),
            onTap: () => Navigator.of(sheetContext).pop(''),
          ),
        ),
        for (final member in sorted) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Builder(
            builder: (sheetContext) => _MemberChoiceRow(
              title: member.displayName,
              tag: member.isYou ? l10n.membersYouTag : null,
              selected: selectedId == member.id,
              leading: MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
              onTap: () => Navigator.of(sheetContext).pop(member.id),
            ),
          ),
        ],
      ],
    ),
  );
}

class _MemberChoiceRow extends StatelessWidget {
  const _MemberChoiceRow({required this.title, required this.selected, required this.leading, required this.onTap, this.tag});

  final String title;
  final String? tag;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.md, QesmaSpacing.sm),
        child: Row(
          children: [
            leading,
            const SizedBox(width: QesmaSpacing.md),
            Expanded(
              child: Wrap(
                spacing: QesmaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (tag != null) AppTag(label: tag!, tone: AppTagTone.primary),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}

/// Category filter sheet. Returns the chosen category wire value, an empty string for "all categories",
/// or null when dismissed.
Future<String?> showCategoryFilterSheet(BuildContext context, {required String? selectedCategory}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<String>(
    context,
    title: l10n.expenseFilterCategoryTitle,
    subtitle: l10n.expenseFilterCategoryHint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (sheetContext) => _CategoryChoiceRow(
            title: l10n.expenseFilterAllCategories,
            selected: selectedCategory == null || selectedCategory.isEmpty,
            leading: const Icon(Icons.category_outlined),
            onTap: () => Navigator.of(sheetContext).pop(''),
          ),
        ),
        for (final cat in ExpenseCategory.values) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Builder(
            builder: (sheetContext) {
              final (catBg, catFg) = cat.colors;
              return _CategoryChoiceRow(
                title: cat.label(l10n),
                selected: selectedCategory == cat.wire,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                  child: Icon(cat.icon, color: catFg, size: 20),
                ),
                onTap: () => Navigator.of(sheetContext).pop(cat.wire),
              );
            },
          ),
        ],
      ],
    ),
  );
}

class _CategoryChoiceRow extends StatelessWidget {
  const _CategoryChoiceRow({required this.title, required this.selected, required this.leading, required this.onTap});

  final String title;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.md, QesmaSpacing.sm),
        child: Row(
          children: [
            leading,
            const SizedBox(width: QesmaSpacing.md),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            if (selected) Icon(Icons.check, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
