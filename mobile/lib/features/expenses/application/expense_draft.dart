import 'expense_form_state.dart';

/// SA12: an unsaved restaurant bill proposed by the receipt scan. The form opens in itemized mode with these items,
/// service / tax switches and percentages; nobody is assigned yet and nothing is saved. [printedTotalMinor] is the
/// total printed on the receipt (piasters), used only to compare with the editor's own preview total.
final class ScanDraft {
  const ScanDraft({required this.itemized, this.printedTotalMinor, this.notes = const {}});

  final ItemizedDraft itemized;
  final int? printedTotalMinor;

  /// What the user should look at first (shown as notices above the items).
  final Set<ScanNote> notes;
}

/// Things a scan could not settle by itself.
enum ScanNote {
  /// An amount did not parse: its item is empty and marked.
  flaggedItems,

  /// Only a service or tax amount was printed: its percentage is empty.
  needsPercent,

  /// More items than the app accepts: the rest were dropped.
  truncated,
}

/// An unsaved expense another screen hands to the add-expense form (SA11 calculator; SA14 voice may reuse it). The
/// form opens with it filled in and the user reviews and saves as usual; nothing is saved here (A142).
///
/// [exactShares] (memberId -> piasters) makes the form EXACT among exactly those members; the numbers come from
/// the engine through the local facade, so the form never computes them.
final class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.totalMinor,
    required this.category,
    required this.payerId,
    required this.exactShares,
  });

  final String title;
  final int totalMinor;

  /// Wire value (`FUEL`, `TRANSPORT`, ...).
  final String category;
  final String payerId;
  final Map<String, int> exactShares;
}
