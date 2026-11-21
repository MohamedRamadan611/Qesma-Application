/// What the scan proposes, after parsing (SA12, SA17, STANDALONE_SPEC 13 and 18.4). Plain text and integers only:
/// nothing here is summed, multiplied, divided or checked; the model's arithmetic is never trusted. Amounts are kept
/// as the text the editor shows.
final class ParsedItem {
  const ParsedItem({
    required this.name,
    required this.amountText,
    required this.flagged,
    this.quantity = 1,
    this.quantityNeedsCheck = false,
    this.needsUnitPrice = false,
  });

  final String name;

  /// Plain number ("45", "12.5") or '' when the model's string did not parse (then [flagged] is true). It is the
  /// UNIT price when [quantity] is above 1, otherwise the printed line total.
  final String amountText;

  /// The user must look at this line: the amount did not parse, or the name was cut.
  final bool flagged;

  /// 1..999 as printed; 1 when none was printed or it could not be read.
  final int quantity;

  /// A quantity was printed but could not be read (not a whole number in 1..999): the item opens as quantity 1.
  final bool quantityNeedsCheck;

  /// A quantity above 1 was printed with a line total but no unit price: the item opens as quantity 1 with the line
  /// total, for the user to confirm or split (the client never divides).
  final bool needsUnitPrice;

  @override
  bool operator ==(Object other) =>
      other is ParsedItem &&
      other.name == name &&
      other.amountText == amountText &&
      other.flagged == flagged &&
      other.quantity == quantity &&
      other.quantityNeedsCheck == quantityNeedsCheck &&
      other.needsUnitPrice == needsUnitPrice;

  @override
  int get hashCode => Object.hash(name, amountText, flagged, quantity, quantityNeedsCheck, needsUnitPrice);

  @override
  String toString() => 'ParsedItem($name, $amountText, x$quantity, flagged: $flagged, qtyCheck: $quantityNeedsCheck, unitPrice: $needsUnitPrice)';
}

final class ParsedReceipt {
  const ParsedReceipt({
    required this.items,
    this.serviceOn = false,
    this.servicePercentText = '',
    this.serviceAmountText = '',
    this.taxOn = false,
    this.taxPercentText = '',
    this.taxAmountText = '',
    this.deliveryAmountText = '',
    this.discountPercentText = '',
    this.discountAmountText = '',
    this.discountBothPrinted = false,
    this.discountDropped = false,
    this.merchantName,
    this.category,
    this.printedTotalMinor,
    this.totalBeforeTaxMinor,
    this.subtotalMinor,
    this.currency,
    this.truncated = false,
  });

  final List<ParsedItem> items;
  final bool serviceOn;
  final String servicePercentText;

  /// Only an amount was printed for the service (no percentage): the editor opens it in amount mode (A179).
  final String serviceAmountText;
  final bool taxOn;
  final String taxPercentText;
  final String taxAmountText;

  /// A delivery fee line as printed (amount only); empty when none was printed.
  final String deliveryAmountText;

  /// The discount as printed: at most one of the two is non-empty. A percentage wins over an amount (A179).
  final String discountPercentText;
  final String discountAmountText;

  /// Both a percentage and an amount were printed for the discount: the percentage was kept.
  final bool discountBothPrinted;

  /// A discount was printed but unusable (as large as the printed subtotal, or 100%): it was left out.
  final bool discountDropped;

  /// The shop name as printed (trimmed, at most the title limit), or null.
  final String? merchantName;

  /// A category wire value suggested by the model (never `OTHER`), or null.
  final String? category;

  /// The total printed on the receipt, in piasters (from `Money.parse`), only used to compare with the editor's preview.
  final int? printedTotalMinor;

  /// Printed total before VAT and printed subtotal (piasters); only compared, never added up.
  final int? totalBeforeTaxMinor;
  final int? subtotalMinor;

  /// VAT is on the subtotal alone only when the printed total before VAT equals the printed subtotal.
  bool get taxOnSubtotalOnly => totalBeforeTaxMinor != null && totalBeforeTaxMinor == subtotalMinor;

  /// Currency code or symbol as printed (informational; the app is EGP only).
  final String? currency;

  /// More items than the app accepts: the extra ones were dropped.
  final bool truncated;

  bool get discountOn => discountPercentText.isNotEmpty || discountAmountText.isNotEmpty;

  bool get hasFlaggedItems => items.any((i) => i.flagged);
  bool get hasQuantityToCheck => items.any((i) => i.quantityNeedsCheck);
  bool get hasUnitPriceToCheck => items.any((i) => i.needsUnitPrice);
}
