import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_filters.dart';
import 'expense_ui.dart';

/// The two filter chips (date range, member) with a remove button next to an active one.
class ExpenseFilterBar extends StatelessWidget {
  const ExpenseFilterBar({super.key, required this.filters, required this.nameOf, required this.onDate, required this.onMember, required this.onClearDate, required this.onClearMember});

  final ExpenseFilters filters;
  final String Function(String memberId) nameOf;
  final VoidCallback onDate;
  final VoidCallback onMember;
  final VoidCallback onClearDate;
  final VoidCallback onClearMember;

  String _dateValue(AppLocalizations l10n) {
    final from = filters.from;
    final to = filters.to;
    if (from != null && to != null) return l10n.expenseFilterRange(dateText(from), dateText(to));
    if (from != null) return l10n.expenseFilterFrom(dateText(from));
    if (to != null) return l10n.expenseFilterUntil(dateText(to));
    return l10n.expenseFilterAll;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = '${l10n.expenseFilterDate}: ${_dateValue(l10n)}';
    final memberId = filters.memberId;
    final memberLabel = '${l10n.expenseFilterMember}: ${memberId == null ? l10n.expenseFilterAll : nameOf(memberId)}';
    return Wrap(
      spacing: QesmaSpacing.sm,
      runSpacing: QesmaSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RemovableChip(label: dateLabel, icon: Icons.calendar_today_outlined, active: filters.hasDateRange, onTap: onDate, onClear: onClearDate),
        _RemovableChip(label: memberLabel, icon: Icons.person_outline, active: memberId != null, onTap: onMember, onClear: onClearMember),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.icon, required this.active, required this.onTap, required this.onClear});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: AppChoiceChip(label: label, selected: active, icon: icon, onSelected: (_) => onTap())),
        if (active)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.expenseFilterRemove(label),
            onPressed: onClear,
          ),
      ],
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
          Semantics(liveRegion: true, child: Text(l10n.expenseFilterRangeInvalid, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.error))),
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
            if (selected) const Icon(Icons.check, color: QesmaColors.primary),
          ],
        ),
      ),
    );
  }
}
