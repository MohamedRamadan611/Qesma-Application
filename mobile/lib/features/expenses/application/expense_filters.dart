import 'package:qesma_api/qesma_api.dart';

/// The list filters (FL4): a date range and/or one member (payer or participant).
/// Immutable; the list controller replaces it as a whole.
class ExpenseFilters {
  const ExpenseFilters({this.from, this.to, this.memberId});

  final Date? from;
  final Date? to;
  final String? memberId;

  static const ExpenseFilters none = ExpenseFilters();

  bool get isActive => from != null || to != null || memberId != null;

  bool get hasDateRange => from != null || to != null;

  /// `from <= to` when both are set (the pickers enforce it; the controller re-checks).
  bool get rangeValid => from == null || to == null || from!.compareTo(to!) <= 0;

  ExpenseFilters copyWith({Date? from, Date? to, String? memberId, bool clearDates = false, bool clearMember = false}) => ExpenseFilters(
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        memberId: clearMember ? null : (memberId ?? this.memberId),
      );

  @override
  bool operator ==(Object other) => other is ExpenseFilters && other.from == from && other.to == to && other.memberId == memberId;

  @override
  int get hashCode => Object.hash(from, to, memberId);
}
