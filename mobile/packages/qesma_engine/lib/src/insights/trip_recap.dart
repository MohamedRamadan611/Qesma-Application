import '../engine_exception.dart';
import '../lrm.dart';
import 'my_share.dart' show myShareCategoryOrder;

/// One member in the trip recap calculation.
final class TripRecapMemberInput {
  const TripRecapMemberInput({
    required this.memberId,
    required this.displayName,
    required this.sortOrder,
  });

  final String memberId;
  final String displayName;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'displayName': displayName,
        'sortOrder': sortOrder,
      };

  factory TripRecapMemberInput.fromJson(Map<String, dynamic> json) =>
      TripRecapMemberInput(
        memberId: json['memberId'] as String,
        displayName: json['displayName'] as String,
        sortOrder: json['sortOrder'] as int,
      );
}

/// One payer contribution in an expense.
final class TripRecapPayerInput {
  const TripRecapPayerInput({
    required this.memberId,
    required this.amountMinor,
  });

  final String memberId;
  final int amountMinor;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'amountMinor': amountMinor,
      };

  factory TripRecapPayerInput.fromJson(Map<String, dynamic> json) =>
      TripRecapPayerInput(
        memberId: json['memberId'] as String,
        amountMinor: json['amountMinor'] as int,
      );
}

/// One expense input for the trip recap calculation.
final class TripRecapExpenseInput {
  const TripRecapExpenseInput({
    required this.expenseId,
    required this.title,
    required this.totalMinor,
    required this.expenseDate,
    required this.createdAt,
    required this.category,
    required this.payers,
  });

  final String expenseId;
  final String title;
  final int totalMinor;
  final String expenseDate;
  final int createdAt;
  final String category;
  final List<TripRecapPayerInput> payers;

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'title': title,
        'totalMinor': totalMinor,
        'expenseDate': expenseDate,
        'createdAt': createdAt,
        'category': category,
        'payers': payers.map((p) => p.toJson()).toList(),
      };

  factory TripRecapExpenseInput.fromJson(Map<String, dynamic> json) =>
      TripRecapExpenseInput(
        expenseId: json['expenseId'] as String,
        title: json['title'] as String,
        totalMinor: json['totalMinor'] as int,
        expenseDate: json['expenseDate'] as String,
        createdAt: json['createdAt'] as int,
        category: json['category'] as String,
        payers: (json['payers'] as List<dynamic>)
            .map((p) => TripRecapPayerInput.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// Category spending total and percentage in basis points (summing to 10000 bps).
final class TripRecapCategoryBreakdown {
  const TripRecapCategoryBreakdown({
    required this.category,
    required this.totalMinor,
    required this.percentageBps,
  });

  final String category;
  final int totalMinor;
  final int percentageBps;

  Map<String, dynamic> toJson() => {
        'category': category,
        'totalMinor': totalMinor,
        'percentageBps': percentageBps,
      };

  factory TripRecapCategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      TripRecapCategoryBreakdown(
        category: json['category'] as String,
        totalMinor: json['totalMinor'] as int,
        percentageBps: json['percentageBps'] as int,
      );
}

/// The member who paid the most overall (A132: largest sum of payer amounts; tie -> lower sortOrder).
final class TripRecapTopPayer {
  const TripRecapTopPayer({
    required this.memberId,
    required this.displayName,
    required this.amountPaidMinor,
  });

  final String memberId;
  final String displayName;
  final int amountPaidMinor;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'displayName': displayName,
        'amountPaidMinor': amountPaidMinor,
      };

  factory TripRecapTopPayer.fromJson(Map<String, dynamic> json) =>
      TripRecapTopPayer(
        memberId: json['memberId'] as String,
        displayName: json['displayName'] as String,
        amountPaidMinor: json['amountPaidMinor'] as int,
      );
}

/// The single largest expense (A132: largest totalMinor; tie -> earlier expenseDate, then earlier createdAt).
final class TripRecapBiggestExpense {
  const TripRecapBiggestExpense({
    required this.expenseId,
    required this.title,
    required this.totalMinor,
    required this.expenseDate,
  });

  final String expenseId;
  final String title;
  final int totalMinor;
  final String expenseDate;

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'title': title,
        'totalMinor': totalMinor,
        'expenseDate': expenseDate,
      };

  factory TripRecapBiggestExpense.fromJson(Map<String, dynamic> json) =>
      TripRecapBiggestExpense(
        expenseId: json['expenseId'] as String,
        title: json['title'] as String,
        totalMinor: json['totalMinor'] as int,
        expenseDate: json['expenseDate'] as String,
      );
}

/// Per-member paid total for the trip.
final class TripRecapMemberPaidTotal {
  const TripRecapMemberPaidTotal({
    required this.memberId,
    required this.displayName,
    required this.sortOrder,
    required this.amountPaidMinor,
  });

  final String memberId;
  final String displayName;
  final int sortOrder;
  final int amountPaidMinor;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'displayName': displayName,
        'sortOrder': sortOrder,
        'amountPaidMinor': amountPaidMinor,
      };

  factory TripRecapMemberPaidTotal.fromJson(Map<String, dynamic> json) =>
      TripRecapMemberPaidTotal(
        memberId: json['memberId'] as String,
        displayName: json['displayName'] as String,
        sortOrder: json['sortOrder'] as int,
        amountPaidMinor: json['amountPaidMinor'] as int,
      );
}

/// Output of the pure Trip Recap calculation.
final class TripRecapResult {
  const TripRecapResult({
    required this.totalSpentMinor,
    required this.expenseCount,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.topPayer,
    required this.biggestExpense,
    required this.categoryBreakdown,
    required this.memberPaidTotals,
  });

  final int totalSpentMinor;
  final int expenseCount;
  final String dateRangeStart;
  final String dateRangeEnd;
  final TripRecapTopPayer topPayer;
  final TripRecapBiggestExpense biggestExpense;
  final List<TripRecapCategoryBreakdown> categoryBreakdown;
  final List<TripRecapMemberPaidTotal> memberPaidTotals;

  Map<String, dynamic> toJson() => {
        'totalSpentMinor': totalSpentMinor,
        'expenseCount': expenseCount,
        'dateRangeStart': dateRangeStart,
        'dateRangeEnd': dateRangeEnd,
        'topPayer': topPayer.toJson(),
        'biggestExpense': biggestExpense.toJson(),
        'categoryBreakdown': categoryBreakdown.map((c) => c.toJson()).toList(),
        'memberPaidTotals': memberPaidTotals.map((m) => m.toJson()).toList(),
      };

  factory TripRecapResult.fromJson(Map<String, dynamic> json) =>
      TripRecapResult(
        totalSpentMinor: json['totalSpentMinor'] as int,
        expenseCount: json['expenseCount'] as int,
        dateRangeStart: json['dateRangeStart'] as String,
        dateRangeEnd: json['dateRangeEnd'] as String,
        topPayer: TripRecapTopPayer.fromJson(
            json['topPayer'] as Map<String, dynamic>),
        biggestExpense: TripRecapBiggestExpense.fromJson(
            json['biggestExpense'] as Map<String, dynamic>),
        categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>)
            .map((c) =>
                TripRecapCategoryBreakdown.fromJson(c as Map<String, dynamic>))
            .toList(),
        memberPaidTotals: (json['memberPaidTotals'] as List<dynamic>)
            .map((m) =>
                TripRecapMemberPaidTotal.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// Pure computation engine for Trip Recap (STANDALONE_SPEC 9, Decisions A132, A133).
abstract final class TripRecapCalculator {
  /// Computes the trip recap metrics for a group's non-deleted expenses.
  /// Throws [EngineException] if [expenses] or [members] is empty.
  static TripRecapResult compute({
    required List<TripRecapMemberInput> members,
    required List<TripRecapExpenseInput> expenses,
  }) {
    if (expenses.isEmpty) {
      throw EngineException.invalid('A group with no expenses has no recap');
    }
    if (members.isEmpty) {
      throw EngineException.invalid('At least one member is required');
    }

    // 1. Total spent and expense count
    var totalSpent = 0;
    String? earliestDate;
    String? latestDate;

    // Category totals accumulator (indexed by myShareCategoryOrder)
    final categoryTotalsMap = <String, int>{
      for (final cat in myShareCategoryOrder) cat: 0,
    };

    // Member paid totals accumulator
    final memberPaidMap = <String, int>{
      for (final m in members) m.memberId: 0,
    };

    TripRecapExpenseInput? biggestExpenseInput;

    for (final exp in expenses) {
      if (exp.totalMinor < 0) {
        throw EngineException.invalid('Expense total must not be negative');
      }
      totalSpent += exp.totalMinor;

      // Date range
      if (earliestDate == null || exp.expenseDate.compareTo(earliestDate) < 0) {
        earliestDate = exp.expenseDate;
      }
      if (latestDate == null || exp.expenseDate.compareTo(latestDate) > 0) {
        latestDate = exp.expenseDate;
      }

      // Category breakdown sum
      final normalizedCat = exp.category.trim().toUpperCase();
      final catKey = categoryTotalsMap.containsKey(normalizedCat)
          ? normalizedCat
          : 'OTHER';
      categoryTotalsMap[catKey] = categoryTotalsMap[catKey]! + exp.totalMinor;

      // Payers sum
      for (final payer in exp.payers) {
        if (memberPaidMap.containsKey(payer.memberId)) {
          memberPaidMap[payer.memberId] =
              memberPaidMap[payer.memberId]! + payer.amountMinor;
        }
      }

      // Biggest expense evaluation
      // A132: largest totalMinor; tie -> earlier expenseDate, then earlier createdAt
      if (biggestExpenseInput == null) {
        biggestExpenseInput = exp;
      } else {
        final cmpAmount = exp.totalMinor.compareTo(biggestExpenseInput.totalMinor);
        if (cmpAmount > 0) {
          biggestExpenseInput = exp;
        } else if (cmpAmount == 0) {
          final cmpDate = exp.expenseDate.compareTo(biggestExpenseInput.expenseDate);
          if (cmpDate < 0) {
            biggestExpenseInput = exp;
          } else if (cmpDate == 0) {
            if (exp.createdAt < biggestExpenseInput.createdAt) {
              biggestExpenseInput = exp;
            }
          }
        }
      }
    }

    // 2. Member paid totals list (sorted by member sortOrder)
    final sortedMembers = List<TripRecapMemberInput>.from(members)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final memberPaidTotals = sortedMembers
        .map((m) => TripRecapMemberPaidTotal(
              memberId: m.memberId,
              displayName: m.displayName,
              sortOrder: m.sortOrder,
              amountPaidMinor: memberPaidMap[m.memberId] ?? 0,
            ))
        .toList();

    // 3. Top payer
    // A132: largest sum of payer amounts; tie -> lower sortOrder
    TripRecapMemberPaidTotal topPayerMember = memberPaidTotals.first;
    for (var i = 1; i < memberPaidTotals.length; i++) {
      final current = memberPaidTotals[i];
      if (current.amountPaidMinor > topPayerMember.amountPaidMinor) {
        topPayerMember = current;
      } else if (current.amountPaidMinor == topPayerMember.amountPaidMinor) {
        if (current.sortOrder < topPayerMember.sortOrder) {
          topPayerMember = current;
        }
      }
    }

    final topPayer = TripRecapTopPayer(
      memberId: topPayerMember.memberId,
      displayName: topPayerMember.displayName,
      amountPaidMinor: topPayerMember.amountPaidMinor,
    );

    final biggestExpense = TripRecapBiggestExpense(
      expenseId: biggestExpenseInput!.expenseId,
      title: biggestExpenseInput.title,
      totalMinor: biggestExpenseInput.totalMinor,
      expenseDate: biggestExpenseInput.expenseDate,
    );

    // 4. Category percentages via LRM summing to exactly 10000 bps
    // A133: LRM tie-break uses the category enum order as sortOrder
    final weights = <int>[];
    final sortOrders = <int>[];
    for (var i = 0; i < myShareCategoryOrder.length; i++) {
      final cat = myShareCategoryOrder[i];
      weights.add(categoryTotalsMap[cat]!);
      sortOrders.add(i);
    }

    final parts = Lrm.allocate(10000, weights, sortOrders);
    final categoryBreakdown = <TripRecapCategoryBreakdown>[];
    for (var i = 0; i < myShareCategoryOrder.length; i++) {
      final cat = myShareCategoryOrder[i];
      categoryBreakdown.add(TripRecapCategoryBreakdown(
        category: cat,
        totalMinor: categoryTotalsMap[cat]!,
        percentageBps: parts[i],
      ));
    }

    return TripRecapResult(
      totalSpentMinor: totalSpent,
      expenseCount: expenses.length,
      dateRangeStart: earliestDate!,
      dateRangeEnd: latestDate!,
      topPayer: topPayer,
      biggestExpense: biggestExpense,
      categoryBreakdown: categoryBreakdown,
      memberPaidTotals: memberPaidTotals,
    );
  }
}
