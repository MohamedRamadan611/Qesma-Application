/// A member as the engine sees it: an id and the creation-order [sortOrder] used for tie-breaks (spec A9).
final class MemberRef {
  const MemberRef(this.id, this.sortOrder);

  final String id;
  final int sortOrder;

  @override
  bool operator ==(Object other) => other is MemberRef && other.id == id && other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, sortOrder);

  @override
  String toString() => 'MemberRef($id, $sortOrder)';
}

/// A payer of an expense, in minor units (spec 7.5).
final class Payer {
  const Payer(this.memberId, this.amountMinor);

  final String memberId;
  final int amountMinor;

  @override
  bool operator ==(Object other) => other is Payer && other.memberId == memberId && other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(memberId, amountMinor);

  @override
  String toString() => 'Payer($memberId, $amountMinor)';
}

/// One explicit share of an EXACT split, in minor units (spec 7.3).
final class Share {
  const Share(this.memberId, this.amountMinor);

  final String memberId;
  final int amountMinor;

  @override
  bool operator ==(Object other) => other is Share && other.memberId == memberId && other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(memberId, amountMinor);

  @override
  String toString() => 'Share($memberId, $amountMinor)';
}

/// A suggested real-world payment `from -> to` produced by simplification (spec 7.7).
final class Transfer {
  const Transfer(this.fromMemberId, this.toMemberId, this.amountMinor);

  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.fromMemberId == fromMemberId &&
      other.toMemberId == toMemberId &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(fromMemberId, toMemberId, amountMinor);

  @override
  String toString() => 'Transfer($fromMemberId -> $toMemberId, $amountMinor)';
}

/// One SHARES participant (STANDALONE_SPEC 19.1, A185-A186): integer [shareUnits] (1..100) and, only when the expense
/// has a period, an optional inclusive presence inside it (`YYYY-MM-DD`; each bound defaults to the period bound).
final class WeightedShare {
  const WeightedShare(this.memberId, this.sortOrder, this.shareUnits, {this.presentFrom, this.presentTo});

  final String memberId;
  final int sortOrder;
  final int shareUnits;
  final String? presentFrom;
  final String? presentTo;

  @override
  String toString() => 'WeightedShare($memberId, $sortOrder, $shareUnits, $presentFrom..$presentTo)';
}

/// The optional inclusive period of a SHARES expense (A186), `YYYY-MM-DD`. Both bounds are required; one bound is
/// accepted here so the engine can reject it with `VALIDATION_ERROR` (Java `SharePeriod`).
final class SharePeriod {
  const SharePeriod(this.from, this.to);

  final String? from;
  final String? to;
}
