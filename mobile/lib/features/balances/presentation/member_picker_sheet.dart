import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/palette.dart';

/// Picks one member for the "from" or "to" side of a payment. [excludeId] (the member on the other
/// side) is not offered, so the two can never be the same. Returns the chosen id, or null when dismissed.
Future<String?> showMemberPicker(
  BuildContext context, {
  required List<MemberDto> members,
  required String? selectedId,
  required String? excludeId,
}) {
  final l10n = AppLocalizations.of(context);
  final sorted = members.where((m) => m.id != excludeId).toList()
    ..sort((a, b) {
      if (a.isYou != b.isYou) return a.isYou ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  return showAppBottomSheet<String>(
    context,
    title: l10n.paymentPickMember,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final member in sorted) ...[
          Builder(
            builder: (sheetContext) => _PickerRow(
              member: member,
              selected: member.id == selectedId,
              onTap: () => Navigator.of(sheetContext).pop(member.id),
            ),
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],
      ],
    ),
  );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.member, required this.selected, required this.onTap});

  final MemberDto member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = member.isYou ? '${member.displayName} ${l10n.membersYouTag}' : member.displayName;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
            const SizedBox(width: QesmaSpacing.sm + 4),
            Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
            if (selected) Icon(Icons.check_circle, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
