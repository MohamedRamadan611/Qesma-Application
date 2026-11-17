import '../engine_exception.dart';
import '../lrm.dart';

/// The 9 fixed categories for expenses (STANDALONE_SPEC 7, Decision A129).
/// Strict order: FOOD, TRANSPORT, FUEL, ACCOMMODATION, GROCERIES, SHOPPING, ENTERTAINMENT, BILLS, OTHER.
const List<String> myShareCategoryOrder = [
  'FOOD',
  'TRANSPORT',
  'FUEL',
  'ACCOMMODATION',
  'GROCERIES',
  'SHOPPING',
  'ENTERTAINMENT',
  'BILLS',
  'OTHER',
];

int _categorySortOrder(String category) {
  final index = myShareCategoryOrder.indexOf(category.toUpperCase());
  return index >= 0 ? index : myShareCategoryOrder.length; // fallback to last
}

/// One expense input for the My Share calculation.
final class MyShareExpenseInput {
  const MyShareExpenseInput({
    required this.expenseId,
    required this.groupId,
    required this.expenseTitle,
    required this.groupName,
    required this.expenseDate,
    required this.category,
    required this.currencyCode,
    required this.owedMinor,
    required this.paidMinor,
  });

  final String expenseId;
  final String groupId;
  final String expenseTitle;
  final String groupName;
  final String expenseDate;
  final String category;
  final String currencyCode;
  final int owedMinor;
  final int paidMinor;

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'groupId': groupId,
        'expenseTitle': expenseTitle,
        'groupName': groupName,
        'expenseDate': expenseDate,
        'category': category,
        'currencyCode': currencyCode,
        'owedMinor': owedMinor,
        'paidMinor': paidMinor,
      };

  factory MyShareExpenseInput.fromJson(Map<String, dynamic> json) => MyShareExpenseInput(
        expenseId: json['expenseId'] as String,
        groupId: json['groupId'] as String,
        expenseTitle: json['expenseTitle'] as String,
        groupName: json['groupName'] as String,
        expenseDate: json['expenseDate'] as String,
        category: json['category'] as String,
        currencyCode: json['currencyCode'] as String,
        owedMinor: json['owedMinor'] as int,
        paidMinor: json['paidMinor'] as int,
      );
}

/// Detail of a single expense contributing to a category in a month.
final class MyShareExpenseDetail {
  const MyShareExpenseDetail({
    required this.expenseId,
    required this.groupId,
    required this.expenseTitle,
    required this.groupName,
    required this.expenseDate,
    required this.owedMinor,
    required this.paidMinor,
  });

  final String expenseId;
  final String groupId;
  final String expenseTitle;
  final String groupName;
  final String expenseDate;
  final int owedMinor;
  final int paidMinor;

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'groupId': groupId,
        'expenseTitle': expenseTitle,
        'groupName': groupName,
        'expenseDate': expenseDate,
        'owedMinor': owedMinor,
        'paidMinor': paidMinor,
      };

  factory MyShareExpenseDetail.fromJson(Map<String, dynamic> json) => MyShareExpenseDetail(
        expenseId: json['expenseId'] as String,
        groupId: json['groupId'] as String,
        expenseTitle: json['expenseTitle'] as String,
        groupName: json['groupName'] as String,
        expenseDate: json['expenseDate'] as String,
        owedMinor: json['owedMinor'] as int,
        paidMinor: json['paidMinor'] as int,
      );
}

/// Breakdown for a single category within a month.
final class MyShareCategoryBreakdown {
  const MyShareCategoryBreakdown({
    required this.category,
    required this.consumedMinor,
    required this.paidUpFrontMinor,
    required this.percentageBps,
    required this.expenses,
  });

  final String category;
  final int consumedMinor;
  final int paidUpFrontMinor;

  /// Share of the month's total consumed in basis points (0..10000).
  /// Allocations sum to exactly 10000 bps across categories with consumedMinor > 0 (or 0 when total consumed is 0).
  final int percentageBps;
  final List<MyShareExpenseDetail> expenses;

  Map<String, dynamic> toJson() => {
        'category': category,
        'consumedMinor': consumedMinor,
        'paidUpFrontMinor': paidUpFrontMinor,
        'percentageBps': percentageBps,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  factory MyShareCategoryBreakdown.fromJson(Map<String, dynamic> json) => MyShareCategoryBreakdown(
        category: json['category'] as String,
        consumedMinor: json['consumedMinor'] as int,
        paidUpFrontMinor: json['paidUpFrontMinor'] as int,
        percentageBps: json['percentageBps'] as int,
        expenses: (json['expenses'] as List<dynamic>)
            .map((e) => MyShareExpenseDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Summary for one month in one currency.
final class MyShareMonth {
  const MyShareMonth({
    required this.month,
    required this.totalConsumedMinor,
    required this.totalPaidUpFrontMinor,
    required this.categories,
  });

  /// 'YYYY-MM'
  final String month;
  final int totalConsumedMinor;
  final int totalPaidUpFrontMinor;
  final List<MyShareCategoryBreakdown> categories;

  int get netDiffMinor => totalPaidUpFrontMinor - totalConsumedMinor;

  Map<String, dynamic> toJson() => {
        'month': month,
        'totalConsumedMinor': totalConsumedMinor,
        'totalPaidUpFrontMinor': totalPaidUpFrontMinor,
        'netDiffMinor': netDiffMinor,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory MyShareMonth.fromJson(Map<String, dynamic> json) => MyShareMonth(
        month: json['month'] as String,
        totalConsumedMinor: json['totalConsumedMinor'] as int,
        totalPaidUpFrontMinor: json['totalPaidUpFrontMinor'] as int,
        categories: (json['categories'] as List<dynamic>)
            .map((c) => MyShareCategoryBreakdown.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// Section for one currency.
final class MyShareCurrencySection {
  const MyShareCurrencySection({
    required this.currencyCode,
    required this.months,
  });

  final String currencyCode;
  final List<MyShareMonth> months;

  Map<String, dynamic> toJson() => {
        'currencyCode': currencyCode,
        'months': months.map((m) => m.toJson()).toList(),
      };

  factory MyShareCurrencySection.fromJson(Map<String, dynamic> json) => MyShareCurrencySection(
        currencyCode: json['currencyCode'] as String,
        months: (json['months'] as List<dynamic>)
            .map((m) => MyShareMonth.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// The complete output of My Share across all currencies and months.
final class MyShareResult {
  const MyShareResult({
    required this.sections,
  });

  final List<MyShareCurrencySection> sections;

  Map<String, dynamic> toJson() => {
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory MyShareResult.fromJson(Map<String, dynamic> json) => MyShareResult(
        sections: (json['sections'] as List<dynamic>)
            .map((s) => MyShareCurrencySection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Pure computation of My Share (STANDALONE_SPEC 8, Decision A130, A131).
abstract final class MyShareCalculator {
  /// Computes My Share from the provided expense inputs.
  ///
  /// - Deterministic currency ordering: 'EGP' first, then alphabetical.
  /// - Deterministic month ordering: descending 'YYYY-MM'.
  /// - Deterministic category ordering: enum order (`myShareCategoryOrder`).
  /// - Category percentages in basis points (LRM summing to 10000 bps when total consumed > 0).
  static MyShareResult compute(List<MyShareExpenseInput> inputs) {
    if (inputs.isEmpty) {
      return const MyShareResult(sections: []);
    }

    // 1. Group by currency
    final byCurrency = <String, List<MyShareExpenseInput>>{};
    for (final input in inputs) {
      if (input.owedMinor < 0 || input.paidMinor < 0) {
        throw EngineException.invalid('Owed and paid amounts must be non-negative');
      }
      final cur = input.currencyCode.toUpperCase();
      byCurrency.putIfAbsent(cur, () => []).add(input);
    }

    // Sort currencies: EGP first, then alphabetical
    final sortedCurrencies = byCurrency.keys.toList()
      ..sort((a, b) {
        if (a == 'EGP' && b != 'EGP') return -1;
        if (b == 'EGP' && a != 'EGP') return 1;
        return a.compareTo(b);
      });

    final sections = <MyShareCurrencySection>[];

    for (final currency in sortedCurrencies) {
      final currencyInputs = byCurrency[currency]!;

      // 2. Group by month YYYY-MM
      final byMonth = <String, List<MyShareExpenseInput>>{};
      for (final input in currencyInputs) {
        if (input.expenseDate.length < 7) {
          throw EngineException.invalid('Invalid expenseDate format: ${input.expenseDate}');
        }
        final month = input.expenseDate.substring(0, 7);
        byMonth.putIfAbsent(month, () => []).add(input);
      }

      // Sort months descending
      final sortedMonths = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

      final months = <MyShareMonth>[];

      for (final month in sortedMonths) {
        final monthInputs = byMonth[month]!;

        // 3. Group by category
        final byCategory = <String, List<MyShareExpenseInput>>{};
        var totalConsumed = 0;
        var totalPaidUpFront = 0;

        for (final input in monthInputs) {
          final cat = input.category.toUpperCase();
          byCategory.putIfAbsent(cat, () => []).add(input);
          totalConsumed += input.owedMinor;
          totalPaidUpFront += input.paidMinor;
        }

        // Filter to categories that have activity (consumed > 0 or paid > 0)
        // Sort categories by enum order
        final activeCategories = byCategory.keys.where((cat) {
          final items = byCategory[cat]!;
          final c = items.fold(0, (sum, i) => sum + i.owedMinor);
          final p = items.fold(0, (sum, i) => sum + i.paidMinor);
          return c > 0 || p > 0;
        }).toList()
          ..sort((a, b) {
            final orderA = _categorySortOrder(a);
            final orderB = _categorySortOrder(b);
            if (orderA != orderB) return orderA.compareTo(orderB);
            return a.compareTo(b);
          });

        // Compute category totals
        final catConsumed = <String, int>{};
        final catPaid = <String, int>{};
        final catDetails = <String, List<MyShareExpenseDetail>>{};

        for (final cat in activeCategories) {
          final items = byCategory[cat]!;
          var c = 0;
          var p = 0;
          final details = <MyShareExpenseDetail>[];
          for (final item in items) {
            c += item.owedMinor;
            p += item.paidMinor;
            if (item.owedMinor > 0 || item.paidMinor > 0) {
              details.add(MyShareExpenseDetail(
                expenseId: item.expenseId,
                groupId: item.groupId,
                expenseTitle: item.expenseTitle,
                groupName: item.groupName,
                expenseDate: item.expenseDate,
                owedMinor: item.owedMinor,
                paidMinor: item.paidMinor,
              ));
            }
          }
          // Sort details by date desc, then expenseId desc
          details.sort((a, b) {
            final cmpDate = b.expenseDate.compareTo(a.expenseDate);
            if (cmpDate != 0) return cmpDate;
            return b.expenseId.compareTo(a.expenseId);
          });

          catConsumed[cat] = c;
          catPaid[cat] = p;
          catDetails[cat] = details;
        }

        // 4. Calculate LRM percentage bps across active categories with consumed > 0
        final catBps = <String, int>{};
        final positiveCategories = activeCategories.where((c) => (catConsumed[c] ?? 0) > 0).toList();

        if (totalConsumed > 0 && positiveCategories.isNotEmpty) {
          final weights = positiveCategories.map((c) => catConsumed[c]!).toList();
          final sortOrders = positiveCategories.map(_categorySortOrder).toList();
          final allocated = Lrm.allocate(10000, weights, sortOrders);
          for (var i = 0; i < positiveCategories.length; i++) {
            catBps[positiveCategories[i]] = allocated[i];
          }
        }

        final categoryBreakdowns = <MyShareCategoryBreakdown>[];
        for (final cat in activeCategories) {
          categoryBreakdowns.add(MyShareCategoryBreakdown(
            category: cat,
            consumedMinor: catConsumed[cat] ?? 0,
            paidUpFrontMinor: catPaid[cat] ?? 0,
            percentageBps: catBps[cat] ?? 0,
            expenses: catDetails[cat] ?? const [],
          ));
        }

        months.add(MyShareMonth(
          month: month,
          totalConsumedMinor: totalConsumed,
          totalPaidUpFrontMinor: totalPaidUpFront,
          categories: categoryBreakdowns,
        ));
      }

      sections.add(MyShareCurrencySection(
        currencyCode: currency,
        months: months,
      ));
    }

    return MyShareResult(sections: sections);
  }
}
