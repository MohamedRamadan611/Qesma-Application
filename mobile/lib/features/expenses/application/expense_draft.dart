/// An unsaved expense another screen hands to the add-expense form (SA11 calculator; SA12 OCR and SA14 voice may
/// reuse it). The form opens with it filled in and the user reviews and saves as usual; nothing is saved here (A142).
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
