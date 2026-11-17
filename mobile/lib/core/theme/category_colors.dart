import 'package:flutter/material.dart';

import '../../features/expenses/data/expense_category.dart';

/// (containerColor, iconColor) with verified WCAG AA contrast (all >= 4.5:1).
(Color, Color) categoryThemeColors(ExpenseCategory category) => switch (category) {
      ExpenseCategory.food => (const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
      ExpenseCategory.transport => (const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      ExpenseCategory.fuel => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      ExpenseCategory.accommodation => (const Color(0xFFCCFBF1), const Color(0xFF115E59)),
      ExpenseCategory.groceries => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      ExpenseCategory.shopping => (const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
      ExpenseCategory.entertainment => (const Color(0xFFF3E8FF), const Color(0xFF6B21A8)),
      ExpenseCategory.bills => (const Color(0xFFE2E8F0), const Color(0xFF1E293B)),
      ExpenseCategory.other => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
