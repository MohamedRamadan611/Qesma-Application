import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../data/group_type.dart';

/// Group type as a dropdown (same pattern as the currency picker), with the type icon on each row.
class GroupTypeDropdown extends StatelessWidget {
  const GroupTypeDropdown({super.key, required this.value, required this.onChanged});

  final GroupType value;

  /// Null disables the field.
  final ValueChanged<GroupType>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<GroupType>(
      initialValue: value,
      isExpanded: true,
      items: [
        for (final t in GroupType.values)
          DropdownMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(t.icon, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(t.label(l10n), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: onChanged == null ? null : (t) => t == null ? null : onChanged!(t),
    );
  }
}
