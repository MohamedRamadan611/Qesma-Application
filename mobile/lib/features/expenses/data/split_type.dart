import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// How an expense is divided (the API's `splitType`).
enum SplitType {
  equal('EQUAL', Icons.balance),
  exact('EXACT', Icons.pin_outlined),
  itemized('ITEMIZED', Icons.receipt_long);

  const SplitType(this.wire, this.icon);

  final String wire;
  final IconData icon;

  /// Null for a value this app version does not know (a newer backend): the UI then
  /// shows no chip rather than a raw code.
  static SplitType? fromWire(String value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }

  String label(AppLocalizations l10n) => switch (this) {
        SplitType.equal => l10n.expenseSplitEqual,
        SplitType.exact => l10n.expenseSplitExact,
        SplitType.itemized => l10n.expenseSplitItemized,
      };
}
