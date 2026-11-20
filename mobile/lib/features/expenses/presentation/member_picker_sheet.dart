import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Search is offered above this many members (SA16, STANDALONE_SPEC 18.5).
const int kPickerSearchThreshold = 8;

/// Members whose name contains [query] (case-insensitive, trimmed); everyone while the query is empty.
List<MemberDto> filterMembers(List<MemberDto> members, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty ? members : [for (final m in members) if (m.displayName.toLowerCase().contains(q)) m];
}

/// Opens the picker for several members (an item's assignees) and returns the chosen ids, or null when dismissed.
/// Search above 8 members, an all/none toggle, 48 dp rows and a sticky "Done (n)" button.
Future<Set<String>?> showMemberPicker(
  BuildContext context, {
  required String title,
  required List<MemberDto> members,
  required Set<String> selected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _MultiPickerSheet(title: title, members: members, initial: selected),
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
  const _MultiPickerSheet({required this.title, required this.members, required this.initial});

  final String title;
  final List<MemberDto> members;
  final Set<String> initial;

  @override
  State<_MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<_MultiPickerSheet> {
  late Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBottomSheet(
      title: widget.title,
      action: AppButton(
        label: l10n.expenseItzPickerDone('${_selected.length}'),
        icon: Icons.check,
        onPressed: () => Navigator.of(context).pop(_selected),
      ),
      child: _PickerBody(members: widget.members, initial: _selected, multi: true, title: widget.title, onChanged: (value) => setState(() => _selected = value)),
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
