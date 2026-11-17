import 'package:qesma_api/qesma_api.dart';

/// The list filters (FL4, SA6): a date range, one member (payer or participant), and/or a category.
/// Immutable; the list controller replaces it as a whole.
class ExpenseFilters {
  const ExpenseFilters({this.from, this.to, this.memberId, this.category});

  final Date? from;
  final Date? to;
  final String? memberId;
  final String? category;

  static const ExpenseFilters none = ExpenseFilters();

  bool get isActive => from != null || to != null || memberId != null || category != null;

  bool get hasDateRange => from != null || to != null;

  /// `from <= to` when both are set (the pickers enforce it; the controller re-checks).
  bool get rangeValid => from == null || to == null || from!.compareTo(to!) <= 0;

  ExpenseFilters copyWith({
    Date? from,
    Date? to,
    String? memberId,
    String? category,
    bool clearDates = false,
    bool clearMember = false,
    bool clearCategory = false,
  }) =>
      ExpenseFilters(
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        memberId: clearMember ? null : (memberId ?? this.memberId),
        category: clearCategory ? null : (category ?? this.category),
      );

  @override
  bool operator ==(Object other) =>
      other is ExpenseFilters &&
      other.from == from &&
      other.to == to &&
      other.memberId == memberId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(from, to, memberId, category);
}
