import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/category_colors.dart';

/// The 9 fixed categories for expenses (STANDALONE_SPEC 7, Decision A129).
/// Strict order: FOOD, TRANSPORT, FUEL, ACCOMMODATION, GROCERIES, SHOPPING, ENTERTAINMENT, BILLS, OTHER.
enum ExpenseCategory {
  food('FOOD'),
  transport('TRANSPORT'),
  fuel('FUEL'),
  accommodation('ACCOMMODATION'),
  groceries('GROCERIES'),
  shopping('SHOPPING'),
  entertainment('ENTERTAINMENT'),
  bills('BILLS'),
  other('OTHER');

  const ExpenseCategory(this.wire);

  final String wire;

  static ExpenseCategory fromWire(String? value) {
    if (value == null) return ExpenseCategory.other;
    final upper = value.trim().toUpperCase();
    for (final c in ExpenseCategory.values) {
      if (c.wire == upper) return c;
    }
    return ExpenseCategory.other;
  }

  String label(AppLocalizations l10n) => switch (this) {
        ExpenseCategory.food => l10n.categoryFood,
        ExpenseCategory.transport => l10n.categoryTransport,
        ExpenseCategory.fuel => l10n.categoryFuel,
        ExpenseCategory.accommodation => l10n.categoryAccommodation,
        ExpenseCategory.groceries => l10n.categoryGroceries,
        ExpenseCategory.shopping => l10n.categoryShopping,
        ExpenseCategory.entertainment => l10n.categoryEntertainment,
        ExpenseCategory.bills => l10n.categoryBills,
        ExpenseCategory.other => l10n.categoryOther,
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant_outlined,
        ExpenseCategory.transport => Icons.directions_bus_outlined,
        ExpenseCategory.fuel => Icons.local_gas_station_outlined,
        ExpenseCategory.accommodation => Icons.hotel_outlined,
        ExpenseCategory.groceries => Icons.shopping_basket_outlined,
        ExpenseCategory.shopping => Icons.shopping_bag_outlined,
        ExpenseCategory.entertainment => Icons.attractions_outlined,
        ExpenseCategory.bills => Icons.receipt_long_outlined,
        ExpenseCategory.other => Icons.category_outlined,
      };

  /// (containerColor, iconColor) with verified WCAG AA contrast (all >= 4.5:1).
  (Color, Color) get colors => categoryThemeColors(this);
}
