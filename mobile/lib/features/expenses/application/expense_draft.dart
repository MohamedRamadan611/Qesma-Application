import 'expense_form_state.dart';

/// SA12: an unsaved restaurant bill proposed by the receipt scan. The form opens in itemized mode with these items,
/// discount, service / tax and quantities; nobody is assigned yet and nothing is saved. [printedTotalMinor] is the
/// total printed on the receipt (piasters), used only to compare with the editor's own preview total. SA17: the
/// shop name and a category guess are only suggestions; they fill the title and the category while those are empty
/// or untouched (A176).
final class ScanDraft {
  const ScanDraft({required this.itemized, this.printedTotalMinor, this.notes = const {}, this.merchantName, this.category});

  final ItemizedDraft itemized;
  final int? printedTotalMinor;

  /// What the user should look at first (shown as notices above the items).
  final Set<ScanNote> notes;

  /// The shop name as printed (already trimmed and cut to the title limit), or null.
  final String? merchantName;

  /// A category wire value (`FOOD`, ...; never `OTHER`), or null.
  final String? category;
}

/// Things a scan could not settle by itself, or settled and the user should know.
enum ScanNote {
  /// An amount did not parse: its item is empty and marked.
  flaggedItems,

  /// A quantity was printed but could not be read: those items opened as quantity 1.
  quantityCheck,

  /// A quantity above 1 was printed without a unit price: those items hold the line total as a quantity-1 price.
  unitPriceCheck,

  /// A discount was found and filled in (info).
  discountFound,

  /// Both a percentage and an amount were printed for the discount: the percentage was kept.
  discountPercentKept,

  /// A discount was printed but it was as large as the subtotal (or 100%): it was left out.
  discountDropped,

  /// The title and / or the category were filled from the receipt (info); added when applied, not by the mapper.
  titleCategorySuggested,

  /// More items than the app accepts: the rest were dropped.
  truncated,
}

/// Handed to the add-expense form as `extra` to open it on the "by shares" split (the flat-share bill entry).
final class SharesStart {
  const SharesStart();
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
