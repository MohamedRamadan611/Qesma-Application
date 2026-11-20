import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import 'member_picker_sheet.dart';
import 'status_banner.dart';

/// "X got 2, Y got 1" (STANDALONE_SPEC 18.5, A172): the user gives each person a number of the item's units. The result
/// maps member id to units (only people with at least one); the controller turns it into one item per person. The units
/// given must add up to the item's [quantity] (counts, not money). Returns null when dismissed.
Future<Map<String, int>?> showUnitSplitSheet(
  BuildContext context, {
  required String itemName,
  required int quantity,
  required List<MemberDto> members,
}) {
  return showModalBottomSheet<Map<String, int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _UnitSplitSheet(itemName: itemName, quantity: quantity, members: members),
    ),
  );
}

class _UnitSplitSheet extends StatefulWidget {
  const _UnitSplitSheet({required this.itemName, required this.quantity, required this.members});

  final String itemName;
  final int quantity;
  final List<MemberDto> members;

  @override
  State<_UnitSplitSheet> createState() => _UnitSplitSheetState();
}

class _UnitSplitSheetState extends State<_UnitSplitSheet> {
  final Map<String, int> _units = {};
  String _query = '';

  int get _given => _units.values.fold<int>(0, (sum, n) => sum + n);

  void _step(String id, int delta) {
    final next = (_units[id] ?? 0) + delta;
    if (next < 0 || next > widget.quantity) return;
    setState(() => next == 0 ? _units.remove(id) : _units[id] = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = widget.quantity - _given;
    final (icon, text, tone) = left == 0
        ? (Icons.check_circle_outline, l10n.expenseItzSplitMatches, BannerTone.success)
        : left > 0
            ? (Icons.warning_amber_rounded, l10n.expenseItzSplitRemaining('$left'), BannerTone.warning)
            : (Icons.error_outline, l10n.expenseItzSplitOver('${-left}'), BannerTone.error);
    final shown = filterMembers(widget.members, _query);
    return AppBottomSheet(
      title: l10n.expenseItzSplitTitle,
      subtitle: l10n.expenseItzSplitHint(widget.itemName.trim().isEmpty ? '…' : widget.itemName.trim(), '${widget.quantity}'),
      action: AppButton(
        label: l10n.expenseItzSplitConfirm,
        icon: Icons.call_split,
        onPressed: left == 0 && _units.isNotEmpty ? () => Navigator.of(context).pop(Map<String, int>.of(_units)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBanner(icon: icon, text: text, tone: tone),
          const SizedBox(height: QesmaSpacing.sm),
          if (widget.members.length > kPickerSearchThreshold) ...[
            MemberSearchField(onChanged: (value) => setState(() => _query = value)),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          for (final member in shown) _UnitRow(member: member, units: _units[member.id] ?? 0, onStep: (d) => _step(member.id, d)),
        ],
      ),
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
            ExcludeSemantics(child: SizedBox(width: 28, child: Center(child: Text('$units', style: theme.textTheme.titleMedium)))),
            IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: l10n.expenseItzQuantityPlus, onPressed: () => onStep(1)),
          ],
        ),
      ),
    );
  }
}
