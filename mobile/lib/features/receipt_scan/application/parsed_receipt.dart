/// What the scan proposes, after parsing (SA12, STANDALONE_SPEC 13). Plain text and integers only: nothing here is
/// summed or checked; the model's arithmetic is never trusted. Amounts are kept as the text the editor shows.
final class ParsedItem {
  const ParsedItem({required this.name, required this.amountText, required this.flagged});

  final String name;

  /// Plain number ("45", "12.5") or '' when the model's string did not parse (then [flagged] is true).
  final String amountText;

  /// The user must look at this line: the amount did not parse, or the name was cut.
  final bool flagged;

  @override
  bool operator ==(Object other) =>
      other is ParsedItem && other.name == name && other.amountText == amountText && other.flagged == flagged;

  @override
  int get hashCode => Object.hash(name, amountText, flagged);

  @override
  String toString() => 'ParsedItem($name, $amountText, $flagged)';
}

final class ParsedReceipt {
  const ParsedReceipt({
    required this.items,
    this.serviceOn = false,
    this.servicePercentText = '',
    this.taxOn = false,
    this.taxPercentText = '',
    this.printedTotalMinor,
    this.currency,
    this.truncated = false,
    this.chargeNeedsPercent = false,
  });

  final List<ParsedItem> items;
  final bool serviceOn;
  final String servicePercentText;
  final bool taxOn;
  final String taxPercentText;

  /// The total printed on the receipt, in piasters (from `Money.parse`), only used to compare with the editor's preview.
  final int? printedTotalMinor;

  /// Currency code or symbol as printed (informational; the app is EGP only).
  final String? currency;

  /// More items than the app accepts: the extra ones were dropped.
  final bool truncated;

  /// Only an amount was printed for service or tax, so it is on with an empty percent for the user to type.
  final bool chargeNeedsPercent;

  bool get hasFlaggedItems => items.any((i) => i.flagged);
}
