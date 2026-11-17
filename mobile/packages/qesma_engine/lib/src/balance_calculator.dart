import 'engine_exception.dart';
import 'exact.dart';
import 'internal.dart';
import 'values.dart';

/// A non-deleted expense reduced to what balances need: who paid what and who owes what.
final class ExpenseLedgerEntry {
  const ExpenseLedgerEntry(this.payers, this.owed);

  final List<Payer> payers;
  final Map<String, int> owed;
}

/// A recorded real-world payment `from -> to` (spec 7.8). Soft-deleted ones must not be passed in.
final class SettlementEntry {
  const SettlementEntry(this.fromMemberId, this.toMemberId, this.amountMinor);

  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
}

/// One member's sums over the live ledger: expenses paid and owed, settlements sent and received.
final class MemberTotals {
  const MemberTotals(this.memberId, this.paidMinor, this.owedMinor, this.sentMinor, this.receivedMinor);

  final String memberId;
  final int paidMinor;
  final int owedMinor;
  final int sentMinor;
  final int receivedMinor;
}

/// Net balances (spec 7.6). Balances are always computed from the ledger, never stored.
/// Port of the Java `BalanceCalculator`.
abstract final class BalanceCalculator {
  /// `net = paid - owed + settlements sent - settlements received`. Positive = is owed.
  /// Returns every roster member in sortOrder order (zeros included); the values always sum to 0.
  static Map<String, int> nets(
      List<MemberRef> members, List<ExpenseLedgerEntry> expenses, List<SettlementEntry> settlements) {
    final nets = _zeroNets(members);

    for (final e in expenses) {
      var paid = 0;
      var owed = 0;
      for (final p in e.payers) {
        _add(nets, p.memberId, p.amountMinor);
        paid = Exact.add(paid, p.amountMinor);
      }
      for (final o in e.owed.entries) {
        _add(nets, o.key, Exact.negate(o.value));
        owed = Exact.add(owed, o.value);
      }
      if (paid != owed) {
        throw EngineException(
            EngineErrorCode.payersTotalMismatch, "An expense's payers and shares do not add up to the same total");
      }
    }

    for (final s in settlements) {
      if (s.amountMinor <= 0) {
        throw EngineException.invalid('Settlement amounts must be greater than zero');
      }
      if (s.fromMemberId == s.toMemberId) {
        throw EngineException.invalid('A settlement needs two different members');
      }
      _add(nets, s.fromMemberId, s.amountMinor);
      _add(nets, s.toMemberId, Exact.negate(s.amountMinor));
    }
    return Map.unmodifiable(nets);
  }

  /// One member's net from their sums: `paid - owed + sent - received` (positive = is owed). The same rule
  /// as [netsFromTotals], for callers that need a single member.
  static int memberNet(MemberTotals t) => Exact.add(Exact.add(t.paidMinor, Exact.negate(t.owedMinor)),
      Exact.add(t.sentMinor, Exact.negate(t.receivedMinor)));

  /// Same rule as [nets] (spec 7.6) but from per-member sums instead of rows. Members without totals are 0.
  /// Returns every roster member in sortOrder order and throws if the nets do not sum to 0 (the ledger
  /// invariant: a violation is a bug, never a number to show).
  static Map<String, int> netsFromTotals(List<MemberRef> members, List<MemberTotals> totals) {
    final nets = _zeroNets(members);
    for (final t in totals) {
      _add(nets, t.memberId, memberNet(t));
    }
    var sum = 0;
    for (final v in nets.values) {
      sum = Exact.add(sum, v);
    }
    if (sum != 0) {
      throw EngineException.invalid('Balances do not sum to zero');
    }
    return Map.unmodifiable(nets);
  }

  static Map<String, int> _zeroNets(List<MemberRef> members) {
    final nets = <String, int>{};
    for (final m in stableSortedBy(members, (m) => m.sortOrder)) {
      if (nets.containsKey(m.id)) {
        throw EngineException.invalid('Duplicate member in roster');
      }
      nets[m.id] = 0;
    }
    return nets;
  }

  static void _add(Map<String, int> nets, String memberId, int delta) {
    final current = nets[memberId];
    if (current == null) {
      throw EngineException(EngineErrorCode.memberNotInGroup, 'A member in the ledger is not in the group');
    }
    nets[memberId] = Exact.add(current, delta);
  }
}
