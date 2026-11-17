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
