import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// The four group types the backend accepts (wire value = enum constant name in upper case).
enum GroupType {
  trip('TRIP', Icons.beach_access),
  housing('HOUSING', Icons.home_outlined),
  outing('OUTING', Icons.restaurant),
  other('OTHER', Icons.category_outlined);

  const GroupType(this.wire, this.icon);

  final String wire;
  final IconData icon;

  /// Unknown values fall back to [other] so a newer server never breaks the list.
  static GroupType fromWire(String? wire) => GroupType.values.firstWhere((t) => t.wire == wire, orElse: () => GroupType.other);

  String label(AppLocalizations l10n) => switch (this) {
        GroupType.trip => l10n.groupTypeTrip,
        GroupType.housing => l10n.groupTypeHousing,
        GroupType.outing => l10n.groupTypeOuting,
        GroupType.other => l10n.groupTypeOther,
      };
}
